defmodule UpsilonGarden.GardenProjection do 
    use Ecto.Schema
    import Ecto.Query
    import Ecto.Changeset
    alias UpsilonGarden.{Garden,GardenProjection,Repo}
    alias UpsilonGarden.GardenProjection.{Plant,Projecter}

    embedded_schema do 
        field :next_event, :utc_datetime
        embeds_many :plants, Plant

    end

    @doc """
        Will create a new Projection for a provided garden. 
    """
    def generate(%Garden{} = garden) do 
        plants = if Ecto.assoc_loaded?(garden.plants) do 
            garden.plants
        else
            UpsilonGarden.Plant
            |> where(garden_id: ^(garden.id))
            |> Repo.all
        end

        if length(plants) != 0 do 
            # No plants, no projection :)
            projection = %GardenProjection{}

            # Sort plants according to their celerity.
            plants = sort_plants_by_celerity(plants)

            # iterate on each blocs, make up a budget for each plant on each bloc. add them to projection.
            Enum.reduce(garden.segments, projection, fn segment, projection ->
                Enum.reduce(segment.blocs, projection, fn bloc, projection ->
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
                    
                    Projecter.build_projection(bloc, roots, components_availability , projection)
                end)
            end)
            |> compute_plants
        else
            %GardenProjection{}
        end
    end
    # Seek each plant and sum up all parts.
    defp compute_plants(projection) do 
        Map.update(projection, :plants, [], fn plants ->
            Enum.map(plants, fn plant ->
                Enum.reduce(plant.alteration_by_parts, %{}, fn pa, acc -> 
                    Enum.reduce(pa.alterations, %{}, fn alteration, pacc ->
                        Map.put(pacc, alteration.component, alteration)
                    end)
                    |> Map.merge(acc, fn _key, lhs, rhs ->
                        lhs = Map.update(lhs, :rate, lhs.rate, &(&1 + rhs.rate))
                        case DateTime.compare(lhs.next_event, rhs.next_event) do
                                :gt ->
                                    Map.put(lhs, :next_event, rhs.next_event)
                                    |> Map.put(:event_type, rhs.event_type)
                                    |> Map.put(:event_type_id, rhs.event_type_id)
                                :lt ->
                                    lhs
                                _ ->
                                    lhs
                        end
                    end)
                end)
                |> Map.values
            end)
        end)
    end

    # Sort plants by celerity, tie with age.
    defp sort_plants_by_celerity(plants) do 
        plants = Enum.sort(plants, fn lhs,rhs ->
            if lhs.celerity == rhs.celerity do 
                DateTime.compare(lhs.inserted_at, rhs.inserted_at) == :lt
            else
                lhs.celerity < rhs.celerity 
            end
        end)
    end

    @doc """
        Seek out in projection a specific plant. 
    """
    def for_plant(%GardenProjection{} = projection,plant_id) do 
        Enum.find(projection.plants,nil, fn proj -> 
            proj.plant_id == plant_id 
        end);
    end


    def changeset(%GardenProjection{} = projection, attrs \\ %{}) do 
        projection
        |> cast(attrs, [:next_event])
        |> cast_embed(:plants)
        |> validate_required([:next_event, :plants])
    end

    
end