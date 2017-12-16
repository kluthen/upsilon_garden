defmodule UpsilonGarden.GardenData do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.{GardenData}
    alias UpsilonGarden.GardenData.{Segment, Bloc}

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

    def generate(context) do 
        data = %UpsilonGarden.GardenData{}
        segments = for pos <- 0..(context.dimension - 1) do 
            segment = %UpsilonGarden.GardenData.Segment{position: pos}
            blocs = for depth <- 0..(context.depth - 1 ) do
                bloc = %UpsilonGarden.GardenData.Bloc{}
                cond do
                    depth == context.depth - 1 -> # ensure last bloc is always stone.
                        Map.put(bloc, :type, UpsilonGarden.GardenData.Bloc.stone())  
                    depth < 3 -> # ensure topmost blocs are always dirt 
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
        Map.put(data,:segments, segments)            
    end
end