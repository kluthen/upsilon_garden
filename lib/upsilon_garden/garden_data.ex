defmodule UpsilonGarden.GardenData do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.{Garden,Source}
    alias UpsilonGarden.GardenData.{Segment}

    embedded_schema do 
        embeds_many :segments, UpsilonGarden.GardenData.Segment
    end

    def changeset(%UpsilonGarden.GardenData{} = data, _attrs \\ %{}) do
        data
        |> cast_embed(:segments)
        |> validate_required([:segments])
    end

    # might not be needed ... on_replace: :delete was set. 
    def change_activate(cs, data, targets) do
        # expect cs to be a Garden Data changeset. 
        new_segments = for segment <- data.segments do 
            if segment.position in targets do 
                Segment.changeset(segment)
                |> change(active: true)
            end
        end
        |> Enum.reject(fn nil -> false
                          _ -> true 
                        end)
        
        put_embed(cs, :segments, new_segments)
    end

    def activate(data, targets) do 
        new_segments = for segment <- data.segments do 
            if segment.position in targets do 
                Map.put(segment, :active, true)
            else
                segment
            end
        end
        Map.put(data, :segments, new_segments)
    end

    def get_segment(data, sid) do 
        if length(data.segments) > sid do 
            Enum.at(data.segments, sid)
        else
            nil
        end
    end

    def get_bloc(data, sid, bid) do 
        if length(data.segments) > sid do 
            segment = Enum.at(data.segments, sid)
            if length(segment.blocs) > bid do 
                Enum.at(segment.blocs, bid)
            else
                nil
            end
        else
            nil
        end
    end

    def generate(garden, context) do 
        data = %UpsilonGarden.GardenData{}
        segments = for pos <- 0..(context.dimension - 1) do 
            segment = %UpsilonGarden.GardenData.Segment{position: pos, active: false}
            blocs = for depth <- 0..(context.depth - 1 ) do
                bloc = %UpsilonGarden.GardenData.Bloc{position: depth, sources: []}
                cond do
                    depth == context.depth - 1 -> # ensure last bloc is always stone.
                        Map.put(bloc, :type, UpsilonGarden.GardenData.Bloc.stone())  
                    depth < context.prepared_depth -> # ensure topmost blocs are always dirt 
                        UpsilonGarden.GardenData.Bloc.fill(bloc, context)
                    true ->
                        if :rand.uniform > context.dirt_stone_ratio do
                            Map.put(bloc, :type, UpsilonGarden.GardenData.Bloc.stone())
                        else 
                            UpsilonGarden.GardenData.Bloc.fill(bloc, context)
                        end
                end
            end
            Map.put(segment, :blocs, blocs)
        end
        data = Map.put(data,:segments, segments)
        generate_sources(garden,data,context)
    end

    def generate_sources(%Garden{} = garden, data, context) do 
        targets = Enum.to_list(0..(Enum.random(context.sources_range)))
        generate_sources(targets,garden,data,context)    
    end

    def generate_sources([],_,data,_), do: data 

    def generate_sources([_|rest],garden,data, context) do
        source = Ecto.build_assoc(garden,:sources)
        data = Source.create(source,data, context)
        generate_sources(rest,garden,data,context)
    end

end