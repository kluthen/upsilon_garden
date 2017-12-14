defmodule UpsilonGarden.GardenData do 
    defmodule Segment do 
        defstruct active: false, blocs: []
    end

    defmodule Bloc do 
        def dirt, do: 0
        def stone, do: 1

        defstruct type: dirt(), components: [], influences: []

        def fill(bloc, context) do 
            components = for _ <- 0..(Enum.random(context.components_by_bloc) -1) do 
                Enum.random(context.available_components)    
            end
            component = Enum.map_reduce(components, %{}, fn itm, acc -> 
                {itm, Map.update(acc, itm, 1, &(&1 + 1))}
            end)

            components = for {comp, quantity} <- components do 
                %Component{composition: comp, quantity: quantity}
            end

            Map.put(bloc, :components, components)
        end
    end

    defmodule Component do 
        defstruct composition: "", quantity: 0.0
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
                    type: components()
    end

    defstruct segments: []

    def generate(context) do 
        data = %UpsilonGarden.GardenData{}
        segments = for _pos <- 0..(context.dimension -1) do 
            segment = %Segment{}
            segment.blocs = for depth <- 0..(context.depth -1 ) do
                bloc = %Bloc{}
                bloc = cond 
                    depth == context.depth - 1 ->
                        Map.put(bloc, :type, Bloc.stone())  
                    depth < 3: 
                        Bloc.fill(bloc, context)
                    _ ->
                        if :rand.uniform > context.dirt_stone_ratio do
                            Map.put(bloc, :type, Bloc.stone())
                        else 
                            Bloc.fill(bloc, context)
                        end
                    end
                end
            end
            segment
        end
        Map.put(data,:segments, segments)            
    end
end