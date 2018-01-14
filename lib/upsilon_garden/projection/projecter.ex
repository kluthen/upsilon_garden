defmodule UpsilonGarden.GardenProjection.Projecter do 
    alias UpsilonGarden.GardenProjection.{PartAlteration,Alteration}
    alias UpsilonGarden.PlantData.PlantRoot
    alias UpsilonGarden.GardenData.{Component}

    @doc """
        Generate a projection for a given bloc. 
        returns updated projection.
    """
    def build_projection(bloc, roots, components_availability, projection) do 

        # for each root (they're pre sorted by celerity, inherited by plant order)  take the first item to absorb, solong there are items to absorb.
        feeds(projection, bloc, components_availability, roots) 
    end

    @doc """
        Fill Projection with data from roots. 
        returns projection
    """
    def feeds(projection, bloc, components_availability, roots) do 
        {roots, {projection, components_availability, should_recycle} } = Enum.map_reduce(roots,{projection, components_availability, false}, fn root, {projection, components_availability, should_recycle} ->
            case root.absorbers do 
                [absorber|rest] -> 
                    # removes from absorber the one we selected. 
                    root = Map.put(root, :absorbers, rest)

                    # prepare base part alteratin
                    part_alteration = %PartAlteration{
                        root_pos_x: bloc.pos_x,
                        root_pos_y: bloc.pos_y,
                    }

                    # order candidates components from availables ... 
                    components_availability = PlantRoot.sort_by_selection(components_availability, root.selection_target)
                    
                    # map for each component available how much we take from them.
                    {components_availability, alterations} = absorb(components_availability, absorber, root.absorb_mode)

                    # Now should seek what we reject from what we captured ! 
                    {components_availability, alterations} = reject(components_availability, alterations, root.rejecters )

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
            feeds(projection, bloc, components_availability, roots)
        else
            projection
        end
    end

    defp reject(components_availability, alterations, [] ), do: {components_availability, alterations}

    # Seek withing rejecters if an absorption may reject
    # if so, update components_availability with appropriate stuff
    #        add an alteration to the stack (so that it gets published in bloc influences later on)
    defp reject(components_availability, alterations, [rejecter|rejecters] ) do 
        {components_availability, alterations} = reject(components_availability, alterations, alterations, rejecter, rejecter.quantity)
        reject(components_availability, alterations, rejecters)
    end

    defp reject(components_availability, alterations, [], _rejecter, _left_to_reject), do: {components_availability, alterations}
    defp reject(components_availability, alterations, _left_to_check, _rejecter, 0), do: {components_availability, alterations}
    defp reject(components_availability, alterations, [alteration|left_to_check], rejecter, left_to_reject) do 
        if alteration.event_type == Alteration.absorption() do 
            if PlantRoot.component_match?(rejecter.composition, alteration.component) do 
                
                component_new_quantity = alteration.quantity - left_to_reject

                # Calculating new quantity in component
                # whats left to be absorbed by the root
                # how much was absorbed
                {component_new_quantity, left_to_reject, consummed} = if component_new_quantity < 0 do 
                    {0, -component_new_quantity, left_to_reject + component_new_quantity}  
                else 
                    {component_new_quantity, 0, left_to_reject}
                end

                rejection = %Alteration{
                    component: rejecter.composition,
                    rate: consummed,
                    event_type: Alteration.rejection(),
                }

                component = %Component{
                    composition: rejecter.composition,
                    quantity: consummed
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

                reject([component|components_availability], [rejection|alterations], left_to_check, rejecter, left_to_reject)
            else 
                reject(components_availability, alterations, left_to_check, rejecter, left_to_reject)
            end
        else 
            reject(components_availability, alterations, left_to_check, rejecter, left_to_reject)
        end
    end

    defp absorb(components_availability, absorber, absorb_mode) do 
        absorb(components_availability, absorber,  components_availability, [], absorber.quantity, absorb_mode) 
    end

    defp absorb(components_availability,_absorber,  _left_to_do, alterations, 0, _absorb_mode), do: {components_availability, alterations}

    defp absorb(components_availability, absorber, [component|left_to_do], alterations, left_over, absorb_mode) do 
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
                        component: absorb,
                        rate: consummed,
                        event_type: Alteration.absorption(),
                    }|absorbed]
                end)

                # Generate alterations and new components available due to rejections
                {rejected, rejected_components} = Enum.reduce(rejects_components, {[],[]}, fn reject, {absorbed,components} ->
                    {[%Alteration{
                        component: reject,
                        rate: consummed,
                        event_type: Alteration.rejection(),
                    }|absorbed], [%Component{
                        composition: reject,
                        quantity: consummed
                    }|components]}
                end)

                # Updating component (updating its quantity)
                components_availability = Enum.map(components_availability, fn compo -> 
                    if compo.composition == component.composition do 
                        Map.put(compo, :quantity, component_new_quantity)
                    else
                        compo
                    end
                end)
                
                absorb(components_availability ++ rejected_components , absorber, left_to_do ++ rejected_components, absorbed ++ rejected ++ alterations, left_over, absorb_mode)
            else # Components has 0 quantity
                absorb(components_availability, absorber, left_to_do, alterations, left_over, absorb_mode)
            end
        else # Component doesn't match
            absorb(components_availability, absorber, left_to_do, alterations, left_over, absorb_mode)
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
                    List.replace_at(plants, idx, Map.update(plants[idx], :alteration_by_parts, [], &([pa|&1])))
            end
        end)
    end


end