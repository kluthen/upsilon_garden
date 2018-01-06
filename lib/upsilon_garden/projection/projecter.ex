defmodule UpsilonGarden.GardenProjection.Projecter do 

    alias UpsilonGarden.Plant
    alias UpsilonGarden.GardenProjection
    alias UpsilonGarden.GardenProjection.{PartAlteration,Alteration}
    alias UpsilonGarden.PlantData.PlantRoot
    alias UpsilonGarden.GardenData.{Bloc,Component}

    @doc """
        Generate a projection for a given bloc. 
        returns updated projection.
    """
    def build_projection(bloc, plants, projection) do 
        # for each plant, seek appropriate root. Note: Their may be no root for this bloc !
        roots = Enum.reduce(plants, [], fn plant, acc -> 
            res = Enum.find(plant.data.roots, nil, fn root ->
                root.pos_x == bloc.segment and root.pos_y == bloc.position
            end)
            case res do 
                nil -> 
                    acc
                root ->
                    [root|acc]
            end
        end)

        components_availability = bloc.components

        # for each root, seek if there are rejection based on stock only; these should be made available asap. (update projection accordingly)
        # {projection,components_availability} = Enum.reduce(plants, {projection,components_availability}, fn plant, {projection,components_availability} ->
        #     Enum.reduce(plant.data.roots, {projection,components_availability}, fn root, {projection,components_availability} ->
        #         Enum.reduce(root.rejecters, {projection,components_availability}, fn rejecter, {projection,components_availability} -> 
        #             res = Enum.find(plant.content.components, nil, fn compo ->
        #                 rejecter.composition == compo.composition
        #             end) 
        #             case res do 
        #                 nil -> 
        #                     {projection,components_availability}
        #                 compo -> 
        #                     projection = add_part_to_plant(projection, plant.id, %PartAlteration{
        #                         root_pos_x: bloc.pos_x,
        #                         root_pos_y: bloc.pos_y,
        #                         alterations: [%Alteration{
        #                             component: rejecter.composition, 
        #                             rate: 0 # this is a goddamn problem... 
        #                             event_type: Alteration.rejection(),
        #                             event_type_id: plant.id,
        #                             # Generate next event date ... might be good to do this later on. as multiple
        #                         }]
        #                     })
        #                     {projection,Map.update(components_availability, rejecter.composition, rejecter.quantity, &(&1 + rejecter.quantity))}
        #             end
        #         end)
        #     end)
        # end)

        # for each root (they're pre sorted by celerity, inherited by plant order)  take the first item to absorb, solong there are items to absorb.
        feed(projection, bloc, components_availability, roots)
        # seek appropriate element to absorb for this bloc.
    end

    @doc """
        Fill Projection with data from roots. 
    """
    def feed(projection, bloc, components_availability, roots) do 
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
                    {components_availability, {alterations,_left_over} } = Enum.map_reduce(components_availability, {[], absorber.quantity}, fn 
                        # fast forward
                        component, {alterations, 0} -> 
                            {component, {alterations, 0}}

                        component, {alterations, left_over} ->
                            if PlantRoot.component_match?(absorber.composition, component.composition) do 
                                # We found a match ! 
                                if component.quantity > 0 do 
                                    # it still has some juice ...

                                    component_new_quantity = component.quantity - left_over

                                    # Calculating new quantity in component
                                    # whats left to be absorbed by the root
                                    # how much was absorbed

                                    {component_new_quantity, left_over, consummed} = if component_new_quantity < 0 do 
                                        {0, left_over + component_new_quantity} 
                                    else 
                                        {component_new_quantity, 0, left_over}
                                    end

                                    # Updating component, adding a new alteration , forward leftover
                                    {Map.put(comopnent, :quantity, component_new_quantity), [%Alteration{
                                        component: absorber.composition,
                                        rate: consummed,
                                        event_type: Alteration.absorption(),
                                    }|alterations], left_over}
                                else 
                                    {component, {alterations, left_over}}
                                end
                            else
                                {component, {alterations, left_over}}
                            end
                    end)

                    # Now should seek what we reject from what we captured ! 

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
            feed(projection, components_availability, roots)
        else
            projection
        end
    end

    # Returns a projection with new part added to provided plant.
    defp add_part_to_plant(projection, plant_id, %PartAlteration{} = pa) do
        Map.update(projection, :plants, [], fn plants ->
            found = Enum.find_index(plants, fn %UpsilonGarden.GardenProjection.Plant{plant_id: ^plant_id} = plant ->
                    true
                plant -> 
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