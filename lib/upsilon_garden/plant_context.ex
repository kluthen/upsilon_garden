defmodule UpsilonGarden.PlantContext do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.PlantContext


    embedded_schema do 
        field :components_absorption_range, {:array, :string}
        field :components_absorption_rate_range, {:array, :float}

        field :components_rejection_range, {:array, :string}
        field :components_rejection_rate_range, {:array, :float}

        field :prime_root_depth_range, {:array, :integer}
        field :prime_root_components_range, {:array, :integer}
        field :prime_root_density_range, {:array, :integer}
        field :prime_root_mode_range, {:array, :integer}
        field :prime_root_fuzyness_range, {:array, :float}
        field :prime_root_absorption_efficience_range, {:array, :float}
        field :prime_root_rejection_efficience_range, {:array, :float}

        # kind of orientation, sort of. 
        # just tell whether it's bound to bottom (0)
        # or just everywhere (0.5)
        field :roots_fuzyness_range, {:array, :float}
        # tell maximum distance from a prime_root a root is allowed to.
        field :roots_travel_range, {:array, :integer}
        # tell number of roots for this step. 
        field :roots_density_range, {:array, :integer}
        # tell efficience of absorption and rejection. 
        field :roots_absorption_effience_range, {:array, :float}
        field :roots_rejection_effience_range, {:array, :float}
        # tell which root mode is to be used (keep, trunc-in, trunc-out)
        field :roots_mode_range, {:array, :integer}
        # tell how many components may be gathered by each root. 
        field :roots_components_range, {:array, :integer}

        field :prime_root_fuzyness, :float
        field :prime_root_depth, :integer
        field :prime_root_density, :integer
        field :prime_root_absorption_efficience, :float
        field :prime_root_rejection_efficience, :float

        field :roots_fuzyness, :float
        field :roots_travel, :integer
        field :roots_density, :integer
        field :roots_absorption_efficience, :float
        field :roots_rejection_efficience, :float
    end

    def default do 
        %PlantContext{
            components_absorption_range: prepare_range([{"AB",7},{"A",3}, {"BC",2}, {"C", 1}, {"B",1}])
            components_absorption_rate_range: prepare_range([{0.9,3},{1,5},{1.1,2}])
            components_rejection_range: prepare_range([{"C",1}, {"B",1}, {"A",1}])
            components_rejection_rate_range: prepare_range([{0.1,3},{0.2,5},{0.4,2}])
            prime_root_depth_range: prepare_range([{1,5},{2,1}])
            prime_root_components_range: prepare_range([{6,3},{5,3},{4,2},{3,5}])
            prime_root_fuzyness_range: prepare_range([{0.1,9}, {0.3,2}])
            prime_root_absorption_efficience_range: prepare_range([{2,4}, {2.2,1}, {1.8,1}])
            prime_root_rejection_efficience_range: prepare_range([{2,4}, {2.2,1}, {1.8,1}])
            roots_fuzyness_range: prepare_range([{0.4,9}, {0.7,2}])
            roots_travel_range: prepare_range([{3,9}, {4,2}])
            roots_density_range: prepare_range([{4,9}, {5,2}])
            roots_components_range: prepare_range([{4,9}, {3,2}])
            roots_absorption_effience_range: prepare_range([{1,4}, {1.1,1}, {0.9,1}])
            roots_rejection_effience_range: prepare_range([{1,4}, {1.1,1}, {0.9,1}])
            prime_root_fuzyness: 0,
            prime_root_depth: 0,
            prime_root_density: 0,
            prime_root_absorption_efficience: 0,
            prime_root_rejection_efficience: 0,
            roots_fuzyness: 0,
            roots_travel: 0,
            roots_density: 0,
            roots_absorption_efficience: 0,
            roots_rejection_efficience: 0,
        }
    end
    
    def prepare_range(list) do 
        for {element, count} <- list do 
            for _ <- 0..(count - 1) do 
                element
            end
        end
        |> List.flatten
    end

    def roll_dices(plant_ctx) do 
        plant_ctx
        |> Map.put(:prime_root_fuzyness, Enum.random(plant_ctx.prime_root_fuzyness_range))
        |> Map.put(:prime_root_depth, Enum.random(plant_ctx.prime_root_depth_range))
        |> Map.put(:prime_root_density, Enum.random(plant_ctx.prime_root_density_range))
        |> Map.put(:prime_root_absorption_efficience, Enum.random(plant_ctx.prime_root_absorption_efficience_range))
        |> Map.put(:prime_root_rejection_efficience, Enum.random(plant_ctx.prime_root_rejection_efficience_range))
        |> Map.put(:roots_fuzyness, Enum.random(plant_ctx.roots_fuzyness_range))
        |> Map.put(:roots_travel, Enum.random(plant_ctx.roots_travel_range))
        |> Map.put(:roots_density, Enum.random(plant_ctx.roots_density_range))
        |> Map.put(:roots_absorption_efficience, Enum.random(plant_ctx.roots_absorption_effience_range))
        |> Map.put(:roots_rejection_efficience, Enum.random(plant_ctx.roots_rejection_effience_range))
    end


    def changeset(%PlantContext{} = root, attrs \\ %{}) do 
        root
        |> cast(attrs, [
            :components_absorption_range,
            :components_absorption_rate_range,
            :components_rejection_range,
            :components_rejection_rate_range,
            :prime_root_depth_range,
            :prime_root_components_range,
            :prime_root_fuzyness_range,
            :prime_root_absorption_efficience_range,
            :prime_root_rejection_efficience_range,
            :roots_fuzyness_range,
            :roots_travel_range,
            :roots_density_range,
            :roots_components_range,
            :roots_absorption_effience_range,
            :roots_rejection_effience_range,
            :prime_root_fuzyness,
            :prime_root_depth,
            :prime_root_density,
            :prime_root_absorption_efficience,
            :prime_root_rejection_efficience,
            :roots_fuzyness,
            :roots_travel,
            :roots_density,
            :roots_absorption_efficience,
            :roots_rejection_efficience
        ])
        |> validate_required([
            :components_absorption_range,
            :components_absorption_rate_range,
            :components_rejection_range,
            :components_rejection_rate_range,
            :prime_root_depth_range,
            :prime_root_components_range,
            :prime_root_fuzyness_range,
            :prime_root_absorption_efficience_range,
            :prime_root_rejection_efficience_range,
            :roots_fuzyness_range,
            :roots_travel_range,
            :roots_density_range,
            :roots_components_range,
            :roots_absorption_effience_range,
            :roots_rejection_effience_range,
            :prime_root_fuzyness,
            :prime_root_depth,
            :prime_root_density,
            :prime_root_absorption_efficience,
            :prime_root_rejection_efficience,
            :roots_fuzyness,
            :roots_travel,
            :roots_density,
            :roots_absorption_efficience,
            :roots_rejection_efficience])
    end
end