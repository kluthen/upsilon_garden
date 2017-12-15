defmodule UpsilonGarden.GardenData do 
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do 
        embeds_many :segments, UpsilonGarden.GardenData.Segment
    end

    def changeset(%UpsilonGarden.GardenData{} = data, _attrs \\ %{}) do
        data
        |> cast_embed(:segments)
        |> validate_required([:segments])
    end
    

    def generate(context) do 
        data = %UpsilonGarden.GardenData{}
        segments = for _pos <- 0..(context.dimension - 1) do 
            segment = %UpsilonGarden.GardenData.Segment{}
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