defmodule UpsilonGarden.GardenContext do
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.GardenContext

    import UpsilonGarden.Tools

    embedded_schema do
        field :available_components, {:array, :string}
        field :components_by_bloc,  {:array, :integer}
        field :depth_range, {:array, :integer}
        field :dimension_range, {:array, :integer}
        field :sunshine_range, {:array, :float}
        field :sources_range, {:array, :integer}
        field :source_power_range, {:array, :float}
        field :source_type_range, {:array, :integer}
        field :source_radiance_range, {:array, :integer}
        field :dirt_stone_ratio_range, {:array, :float}
        field :available_source_components, {:array, :string}
        field :available_retention, {:array, :float}
        field :available_hydro_level, {:array, :float}
        field :prepared_depth_range, {:array, :integer}
        field :prepared_depth, :integer
        field :depth, :integer
        field :dimension, :integer
        field :sunshine, :float
        field :sources, :integer
        field :dirt_stone_ratio, :float
    end

    def changeset(%GardenContext{} = context, attrs \\ %{}) do
        context
        |> cast(attrs,[:available_components, :components_by_bloc, :depth_range,
                       :dimension_range, :sunshine_range, :sources_range,
                       :dirt_stone_ratio_range, :available_source_components,
                       :depth, :dimension, :sunshine, :sources, :dirt_stone_ratio,
                       :prepared_depth, :prepared_depth_range,
                       :source_power_range, :source_radiance_range, :source_type_range,
                       :available_retention, :available_hydro_level])
        |> validate_required([:available_components, :components_by_bloc, :depth_range,
                        :dimension_range, :sunshine_range, :sources_range,
                        :dirt_stone_ratio_range, :available_source_components,
                        :depth, :dimension, :sunshine, :sources, :dirt_stone_ratio,
                        :prepared_depth, :prepared_depth_range,
                        :source_power_range,:source_type_range, :source_radiance_range,
                        :available_retention, :available_hydro_level])
    end

    def default do
        %GardenContext{
            available_components: prepare_range([{"ABC", 10}, {"AB",16},{"A",12},{"AC",3},{"BC",2},{"E",1},{"D",1}]),
            components_by_bloc: prepare_range([{4,1},{8,8},{6,1}]),
            depth_range: prepare_range([{8,1},{9,1},{10,2},{11,1},{12,1}]),
            dimension_range: prepare_range([{10,1}]),
            sunshine_range: prepare_range([{0.85,1},{0.87,2},{0.90,5},{0.92,2},{0.95,1}]),
            sources_range: prepare_range([{2,1},{3,4},{4,1}]),
            dirt_stone_ratio_range: prepare_range([{0.95,4},{0.90,2},{0.85,1},{0.80,1},{0.75,1},{0.70,1}]),
            available_source_components: prepare_range([{"ABE", 5}, {"CAD",3}, {"FAD",1}, {"BFE",1}]),
            prepared_depth_range: prepare_range([{3,1}]),
            source_power_range: prepare_range([{20,1},{30,3},{40,1}]),
            source_radiance_range: prepare_range([{2,4},{3,1}]),
            source_type_range: prepare_range([{0,5},{1,1},{2,1}]),
            available_retention: prepare_range([{0.05, 5}, {0.1,3}]),
            available_hydro_level: prepare_range([{0.05, 5}, {0.1,3}]),
            depth: 0,
            dimension: 0,
            sunshine: 0,
            sources: 0,
            dirt_stone_ratio: 0
        }
    end

    def roll_dices(context) do
        context
        |> Map.put(:depth,              Enum.random(context.depth_range))
        |> Map.put(:dimension,          Enum.random(context.dimension_range))
        |> Map.put(:sunshine,           Enum.random(context.sunshine_range))
        |> Map.put(:sources,            Enum.random(context.sources_range))
        |> Map.put(:prepared_depth,     Enum.random(context.prepared_depth_range))
        |> Map.put(:dirt_stone_ratio,   Enum.random(context.dirt_stone_ratio_range))
    end
end
