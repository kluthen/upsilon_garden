defmodule UpsilonGarden.GardenProjection do 
    use Ecto.Schema
    import Ecto.Query
    import Ecto.Changeset
    alias UpsilonGarden.{Garden,GardenProjection,Repo}
    alias UpsilonGarden.GardenProjection.{Plant,Projecter,Alteration}

    embedded_schema do 
        field :next_event, :utc_datetime
        embeds_many :plants, Plant
    end

    @doc """
        Will create a new Projection for a provided garden. 
        returns a GardenProjection
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
            project(garden, plants) 
        else
            %GardenProjection{}
        end
    end

    def project(garden, plants) do 
        # No plants, no projection :)
        projection = %GardenProjection{}

        # Sort plants according to their celerity.
        plants = sort_plants_by_celerity(plants)

        # iterate on each blocs, make up a budget for each plant on each bloc. add them to projection.
        Enum.reduce(garden.data.segments, projection, fn segment, projection ->
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
                
                Projecter.build_projection(bloc.segment,bloc.position, roots, components_availability , projection)
            end)
        end)
        |> compute_plants(plants)
        
    end

    def compute_plants(projection,plants) do 
        # Update projections to sums parts into general plant based projection.
        # We don't have access to plants here so, we can't compute end date.
        Map.update(projection, :plants, [], fn plants_alterations -> 
            Enum.map(plants_alterations, fn plant ->
                alterations = Enum.reduce(plant.alteration_by_parts, %{}, fn pa, acc -> 
                    Enum.reduce(pa.alterations, acc, fn alt, acc -> 
                        Map.update(acc, alt.component, [alt], fn old_alts -> 
                            Alteration.merge_alterations(old_alts, alt)
                        end)
                    end)
                end)
                |> Map.values
                |> List.flatten

                total = Enum.reduce(alterations, 0, fn alt, acc -> 
                    if alt.event_type == Alteration.absorption() do 
                        acc + alt.rate 
                    else 
                        acc
                    end
                end)

                plt = Enum.find(plants, nil, fn p ->
                    p.id == plant.plant_id 
                end)

                # well, if not found, we do have a big problem here ;)
                if total > 0 do 
                    turns_to_full = Float.ceil(((plt.content.max_size - plt.content.current_size)/1) / total) 
                    next_event = UpsilonGarden.Tools.compute_next_date(turns_to_full)
                    alterations = Enum.map(alterations, fn alt -> 
                        if alt.event_type == Alteration.absorption() do 
                            Map.put(alt,:next_event, next_event)
                        else
                            alt
                        end
                    end)

                    plant
                    |> Map.put(:alterations, alterations)
                    |> Map.put(:next_event, next_event)
                else 

                    plant
                    |> Map.put(:alterations, alterations)
                end
            end) 
        end)  
    end

    @doc """
        Sort plants by celerity, tie with age.
        return [plants]
    """
    def sort_plants_by_celerity(plants) do 
        Enum.sort(plants, fn lhs,rhs ->
            if lhs.celerity == rhs.celerity do 
                DateTime.compare(lhs.inserted_at, rhs.inserted_at) == :lt
            else
                lhs.celerity > rhs.celerity 
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