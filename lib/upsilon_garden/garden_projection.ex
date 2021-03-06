defmodule UpsilonGarden.GardenProjection do 
    use Ecto.Schema
    import Ecto.Query
    import Ecto.Changeset
    require Logger
    alias UpsilonGarden.{Garden,GardenProjection,Repo,PlantCycle}
    alias UpsilonGarden.GardenProjection.{Plant,Projecter,Alteration}

    embedded_schema do
        field :next_event, :utc_datetime
        embeds_many :plants, Plant
    end

    def build(opts \\ []) do
        %GardenProjection{
            next_event: nil,
            plants: []
        }
        |> Map.merge(Enum.into(opts, %{}))
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

        # Sort plants according to their celerity.
        plants = sort_plants_by_celerity(plants)
        |> prune_plants_by_available_store

        if length(plants) != 0 do
            project(garden, plants)
        else
            GardenProjection.build
        end
    end

    def project(garden, plants) do
        # No plants, no projection :)
        projection = GardenProjection.build

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

    @doc """
        Do the maths for each plant generating a global projection (and not bloc by bloc based one )
        Seek next event date based on plant being filled
        Seek next event date based on cycles
        stores nearest event.
        returns projection
    """
    def compute_plants(projection,plants) do
        # Update projections to sums parts into general plant based projection.
        # We don't have access to plants here so, we can't compute end date.
        projection = Map.update(projection, :plants, [], fn plants_alterations ->
            Enum.map(plants_alterations, fn plant_alt ->
                alterations = Alteration.merge_part_alterations(plant_alt.alteration_by_parts)
                |> Map.values
                |> List.flatten

                total = Alteration.total(alterations)

                # well, if not found, we do have a big problem here ;)
                plt = Enum.find(plants, nil, fn p ->
                    p.id == plant_alt.plant_id
                end)

                plant_alt = plant_alt
                |> Map.put(:alterations, alterations)

                turns_to_cycle = PlantCycle.compute_next_event_turns(plt, plant_alt)
                # ensure we've work to do.
                turns_to_full = UpsilonGarden.Tools.turns_to_full(plt.content.current_size, plt.content.max_size, total)

                plant_alt =
                if total > 0.1 and turns_to_full > 0 do
                    next_event = UpsilonGarden.Tools.compute_next_date(turns_to_full)

                    # Updated next event date for all needing alterations
                    alterations = Enum.map(alterations, fn alt ->
                        if alt.event_type == Alteration.absorption() do
                            Map.put(alt,:next_event, next_event)
                        else
                            alt
                        end
                    end)

                    plant_alt
                    |> Map.put(:alterations, alterations)
                else
                    plant_alt
                end

                cond do
                    turns_to_cycle == :unable ->
                        plant_alt
                        |> Map.put(:next_event, nil)
                    turns_to_full < 1 or total < 0.1 ->
                        plant_alt
                        |> Map.put(:next_event, UpsilonGarden.Tools.compute_next_date(turns_to_cycle))
                    turns_to_cycle < turns_to_full ->
                        plant_alt
                        |> Map.put(:next_event, UpsilonGarden.Tools.compute_next_date(turns_to_cycle))
                    true ->
                        plant_alt
                        |> Map.put(:next_event, UpsilonGarden.Tools.compute_next_date(turns_to_full))
                end
            end)
        end)

        all_nil = Enum.reduce(projection.plants, true, fn _p, false -> false
                                                %UpsilonGarden.GardenProjection.Plant{next_event: nil}, true -> true
                                                _,_ -> false
        end)

        if all_nil do
            Map.put(projection, :next_event, nil)
        else
            next_event = Enum.reduce(projection.plants, Map.put(DateTime.utc_now, :microsecond, {0,0}) , fn p, old_date ->
                if p.next_event != nil do
                    if DateTime.diff(old_date,p.next_event) < 0 do
                        p.next_event
                    else
                        old_date
                    end
                else
                    old_date
                end
            end)

            Map.put(projection, :next_event, next_event)
        end
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
        Remove from projection plants that can't feed themselves.
    """
    def prune_plants_by_available_store(plants) do
        Enum.reject(plants, fn p ->
           p.content.max_size - p.content.current_size < 0.1
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
