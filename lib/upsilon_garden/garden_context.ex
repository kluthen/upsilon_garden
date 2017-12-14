defmodule UpsilonGarden.GardenContext do 
    defstruct available_components: prepare_range([{"ABC", 10}, {"AB",8},{"A",6},{"AC",3},{"BC",2},{"E",1},{"D",1}]),
            components_by_bloc: prepare_range([{4,1},{5,3},{6,1}]),
            depth_range: prepare_range([{8,1},{9,1},{10,2},{11,1},{12,1}]),
            dimension_range: prepare_range([{8,1},{9,1},{10,2},{11,1},{12,1}]),
            sunshine_range: prepare_range([{0.85,1},{0.87,2},{0.90,5},{0.92,2},{0.95,1}]),
            sources_range: prepare_range([{2,1},{3,4},{4,1}]),
            dirt_stone_ratio_range: prepare_range([{0.95,4},{0.90,2},{0.85,1},{0.80,1},{0.75,1},{0.70,1}]),
            available_source_components: prepare_range([{"ABE", 5}, {"CAD",3}, {"FAD",1}, {"BFE",1}]),
            depth: 0,
            dimension: 0,
            sunshine: 0,
            sources: 0,
            dirt_stone_ratio: 0
        
    
    def prepare_range(list) do 
        for {element, count} <- list do 
            res = for _ <- 0..(count - 1) do 
                element
            end
        end
        |> List.flatten
    end

    def roll_dices(context) do
        context
        |> Map.put(:depth,              Enum.random(context.depth_range))
        |> Map.put(:dimension,          Enum.random(context.dimension_range))
        |> Map.put(:sunshine,           Enum.random(context.sunshine_range))
        |> Map.put(:sources,            Enum.random(context.sources_range))
        |> Map.put(:dirt_stone_ratio,   Enum.random(context.dirt_stone_ratio_range))
    end


end