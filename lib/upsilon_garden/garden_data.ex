defmodule UpsilonGarden.GardenData do 
    defmodule Segment do 
        defstruct active: false, blocs: []
    end

    defmodule Component do 
        defstruct composition: "", quantity: 0.0
    end

    defmodule Bloc do 
        def dirt, do: 0
        def stone, do: 1

        defstruct type: 0, components: [], influences: []

        def fill(bloc, context) do 
            components = for _ <- 0..(Enum.random(context.components_by_bloc) -1) do 
                Enum.random(context.available_components)    
            end
            components = Enum.map_reduce(components, %{}, fn itm, acc -> 
                {itm, Map.update(acc, itm, 1, &(&1 + 1))}
            end)

            components = for {comp, quantity} <- components do 
                %Component{composition: comp, quantity: quantity}
            end

            Map.put(bloc, :components, components)
        end
    end

    defmodule Influence do
        def components, do: 0
        def hygro, do: 1
        def temperature, do: 2

        defstruct   event_id: nil,
                    source_id: nil,
                    plant_id: nil,
                    ratio: 1.0,
                    components: [],
                    type: 0
    end

    defstruct segments: []

    def generate(context) do 
        data = %UpsilonGarden.GardenData{}
        segments = for _pos <- 0..(context.dimension -1) do 
            segment = %Segment{}
            blocs = for depth <- 0..(context.depth -1 ) do
                bloc = %Bloc{}
                cond do
                    depth == context.depth - 1 ->
                        Map.put(bloc, :type, Bloc.stone())  
                    depth < 3 -> 
                        Bloc.fill(bloc, context)
                    true ->
                        if :rand.uniform > context.dirt_stone_ratio do
                            Map.put(bloc, :type, Bloc.stone())
                        else 
                            Bloc.fill(bloc, context)
                        end
                end
            end
            Map.put(segment, :blocs, blocs)
        end
        Map.put(data,:segments, segments)            
    end
end