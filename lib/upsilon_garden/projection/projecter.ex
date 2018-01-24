defmodule UpsilonGarden.GardenProjection.Projecter do 
    require Logger
    alias UpsilonGarden.GardenProjection.{PartAlteration,Alteration}
    alias UpsilonGarden.PlantData.PlantRoot
    alias UpsilonGarden.GardenData.{Component}

    @doc """
        Generate a projection for a given bloc. 
        returns updated projection.
    """
    def build_projection(x,y, roots, components_availability, projection) do 
        # for each root (they're pre sorted by celerity, inherited by plant order)  take the first item to absorb, solong there are items to absorb.
        feeds(projection, x,y, components_availability, roots) 
    end

    @doc """
        Fill Projection with data from roots. 
        returns projection
    """
    def feeds(projection, x,y, components_availability, roots) do 
        {roots, {projection, components_availability, should_recycle} } = Enum.map_reduce(roots,{projection, components_availability, false}, fn root, {projection, components_availability, should_recycle} ->
            case root.absorbers do 
                [absorber|rest] -> 
                    # removes from absorber the one we selected. 
                    root = Map.put(root, :absorbers, rest)

                    # prepare base part alteratin
                    part_alteration = %PartAlteration{
                        root_pos_x: x,
                        root_pos_y: y,
                    }

                    # order candidates components from availables ... 
                    components_availability = PlantRoot.sort_by_selection(components_availability, root.selection_target)
                    
                    # map for each component available how much we take from them.
                    {components_availability, alterations} = absorb(components_availability, absorber, root.absorb_mode, root.absorption_rate)

                    # Now should seek what we reject from what we captured ! 
                    {components_availability, alterations, updated_rejecters} = reject(components_availability, alterations, root.rejecters , root.rejection_rate)

                    # Update rejecters for later use
                    root = Map.put(root, :rejecters, updated_rejecters)

                    # updating part_alteration
                    part_alteration = Map.put(part_alteration,:alterations, alterations)
                    
                    # Add this part alteration to the stack. 
                    projection = add_part_to_plant(projection, root.plant_id, part_alteration)

                    case rest do 
                        [_itm|_rest] -> 
                            # we have still some work to do ;) 
                            {root, {projection, components_availability, true}}
                        [] ->
                            # no more work (on this root)
                            {root, {projection, components_availability, should_recycle}}
                        _ -> 
                            # default
                            {root, {projection, components_availability, should_recycle}}
                    end
                [] -> 
                    {root, {projection, components_availability, should_recycle}}
            end
        end)

        if should_recycle do 
            feeds(projection, x,y, components_availability, roots)
        else
            projection
        end
    end

    @doc """
        Seek withing rejecters if an absorption may reject
        if so, update components_availability with appropriate stuff
            add an alteration to the stack (so that it gets published in bloc influences later on)
        returns {components_availability, alterations, rejecters}
    """
    def reject(components_availability, alterations, rejecters, rejection_rate) do 
        reject(components_availability,alterations,rejecters, [], rejection_rate)
    end

    def reject(components_availability, alterations, [], done , _rejection_rate), do: {components_availability, alterations, done}

    def reject(components_availability, alterations, [rejecter|rejecters] , done , rejection_rate) do 
        {components_availability, alterations, rejecter_updated} = reject(components_availability, alterations, alterations, rejecter, rejecter.quantity, rejection_rate)
        {components_availability, alterations, rejecters} = reject(components_availability, alterations, rejecters, [rejecter_updated|done], rejection_rate)
        # removes alterations with rate < 0.1
        alterations = Enum.reject(alterations, fn alt -> 
            alt.rate < 0.1
        end)
        # removes rejecters with quantity < 0.1
        rejecters = Enum.reject(rejecters, fn rej -> 
            rej.quantity < 0.1
        end)
        {components_availability, alterations, rejecters}
    end

    def reject(components_availability, alterations, [], rejecter, _left_to_reject, _rejection_rate), do: {components_availability, alterations,rejecter}
    def reject(components_availability, alterations, _left_to_check, rejecter, 0, _rejection_rate), do: {components_availability, alterations,rejecter}
    def reject(components_availability, alterations, [alteration|left_to_check], rejecter, left_to_reject, rejection_rate) do 
        if alteration.event_type == Alteration.absorption() do 
            if PlantRoot.component_match?(rejecter.composition, alteration.component) do 
                
                component_new_quantity = alteration.rate - left_to_reject

                # Calculating new quantity in component
                # whats left to be absorbed by the root
                # how much was absorbed
                {component_new_quantity, left_to_reject, consummed} = if component_new_quantity < 0 do 
                    {0, -component_new_quantity, left_to_reject + component_new_quantity}  
                else 
                    {component_new_quantity, 0, left_to_reject}
                end

                rejection = %Alteration{
                    component: alteration.component,
                    rate: consummed,
                    event_type: Alteration.rejection(),
                }

                component = %Component{
                    composition: alteration.component,
                    quantity: (consummed * rejection_rate)
                }

                # update absorption so that we only absorb whats necessary. 
                # rejection thus are not needed to be removed from store.
                alteration = Map.put(alteration, :rate, component_new_quantity )
                alterations = Enum.map(alterations, fn alt -> 
                    if alteration.component == alt.component do 
                        alteration
                    else
                        alt
                    end
                end)

                # Update rejecter ;)
                rejecter = Map.put(rejecter, :quantity, left_to_reject)

                reject([component|components_availability], [rejection|alterations], left_to_check, rejecter, left_to_reject, rejection_rate)
            else 
                reject(components_availability, alterations, left_to_check, rejecter, left_to_reject, rejection_rate)
            end
        else 
            reject(components_availability, alterations, left_to_check, rejecter, left_to_reject, rejection_rate)
        end
    end

    @doc """
        Seek within components availability if absorber can do their jobs
        returns {components_availability, alterations} (updated)
    """
    def absorb(components_availability, absorber, absorb_mode, absorption_rate) do 
        {components_availability, alterations} = absorb(components_availability, absorber,  components_availability, [], absorber.quantity, absorb_mode, absorption_rate) 
        alterations = Enum.reject(alterations, fn alt -> 
            alt.rate < 0.1
        end)

        {components_availability,alterations}
    end

    def absorb(components_availability,_absorber, [], alterations, _left_over, _absorb_mode, _absorption_rate), do:  {components_availability, alterations}
    def absorb(components_availability,_absorber,  _left_to_do, alterations, 0, _absorb_mode, _absorption_rate), do: {components_availability, alterations}

    def absorb(components_availability, absorber, [component|left_to_do], alterations, left_over, absorb_mode, absorption_rate) do 
        if PlantRoot.component_match?(absorber.composition, component.composition) do 
            # We found a match ! 

            if component.quantity > 0 do 
                # it still has some juice ...

                # based on root absorb mode, tell which components we're using.
                rest = String.replace_prefix(component.composition, absorber.composition,"")
                {absorbs_components, rejects_components} = case absorb_mode do 
                    0 -> # keep
                        {[component.composition], []}
                    1 -> # trunc_in
                        {[absorber.composition, rest], []}
                    2 -> # trunc_out
                        {[absorber.composition], [rest]}
                end

                component_new_quantity = component.quantity - left_over

                # Calculating new quantity in component
                # whats left to be absorbed by the root
                # how much was absorbed

                {component_new_quantity, left_over, consummed} = if component_new_quantity < 0 do 
                    {0, -component_new_quantity, left_over + component_new_quantity} 
                else 
                    {component_new_quantity, 0, left_over}
                end

                # Generate alterations for absorptions
                absorbed = Enum.reduce(absorbs_components, [], fn absorb, absorbed ->
                    [%Alteration{
                        component: absorb ,
                        rate: (consummed* absorption_rate),
                        event_type: Alteration.absorption(),
                    }|absorbed]
                end)

                # Generate alterations and new components available due to rejections
                rejected_components = Enum.reduce(rejects_components,[], fn reject, components ->
                    [%Component{
                        composition: reject,
                        quantity: consummed
                    }|components]
                end)

                # Updating component (updating its quantity)
                components_availability = Enum.map(components_availability, fn compo -> 
                    if compo.composition == component.composition do 
                        Map.put(compo, :quantity, component_new_quantity)
                    else
                        compo
                    end
                end)
                |> Enum.reject(fn compo -> 
                    compo.quantity < 0.1
                end)
                
                absorb(components_availability ++ rejected_components , absorber, left_to_do ++ rejected_components, absorbed ++ alterations, left_over, absorb_mode, absorption_rate)
            else # Components has 0 quantity
                absorb(components_availability, absorber, left_to_do, alterations, left_over, absorb_mode, absorption_rate)
            end
        else # Component doesn't match
            absorb(components_availability, absorber, left_to_do, alterations, left_over, absorb_mode, absorption_rate)
        end
    end

    @doc """ 
        Returns a projection with new part added to provided plant.
    """
    def add_part_to_plant(projection, plant_id, %PartAlteration{} = pa) do
        Map.update(projection, :plants, [], fn plants ->
            found = Enum.find_index(plants, fn %UpsilonGarden.GardenProjection.Plant{plant_id: ^plant_id}  ->
                    true
                _plant -> 
                    false
                end)

            case found do 
                nil -> 
                    [%UpsilonGarden.GardenProjection.Plant{
                        plant_id: plant_id,
                        alteration_by_parts: [pa],
                        alterations: []
                    }| plants]
                idx -> 
                    List.replace_at(plants, idx, Map.update(Enum.at(plants,idx), :alteration_by_parts, [pa], fn aps -> 
                        Enum.map(aps,fn p ->
                           if p.root_pos_x == pa.root_pos_x and p.root_pos_y == pa.root_pos_y do 
                            Map.update(p, :alterations, pa.alterations, &(&1 ++ pa.alterations))
                           else
                            p
                           end
                        end)
                    end))
            end
        end)
    end


end