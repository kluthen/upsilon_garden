defmodule UpsilonGarden.GardenProjection.Projecter do 

    alias UpsilonGarden.Plant
    alias UpsilonGarden.GardenProjection
    alias UpsilonGarden.GardenProjection.{PartAlteration,Alteration}
    alias UpsilonGarden.GardenData.{Bloc,Component}

    @doc """
        Generate a projection for a given bloc. 
        returns updated projection.
    """
    def build_projection(bloc, plants, projection) do 

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