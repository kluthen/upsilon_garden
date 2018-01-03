defmodule UpsilonGarden.PlantData.PlantRootContext do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.PlantData.PlantRootContext

    embedded_schema do 

        # Roll Tables
        # define possibles values
        # each may appear multiples times allowing greater chances of being selected.
        # Keep them stored for later use ( generate new seeds ) 

        # define what a root can absorb and reject, and at which rate.
        # Note: when a root is created, all components will be rolled
        #   if they happend to be rolled twice, 
        #   root will gather this component twice as much.
        # Rate define how well the root does its job. 

        field :absorption_range, {:array, :string}
        field :absorption_rate_range, {:array, :float}
        field :absorption_count_range, {:array, :integer}

        field :rejection_range, {:array, :string}
        field :rejection_rate_range, {:array, :float}
        field :rejection_count_range, {:array, :integer}

        field :orientation_range, {:array, :float}
        field :fill_rate_range, {:array, :float}
        field :depth_range, {:array, :integer}
        field :max_top_width_range, {:array, :integer}
        field :max_bottom_width_range, {:array, :integer}
        field :root_mode_range, {:array, :integer}

        field :selection_compo_to_absorb_range, {:array,:integer}
        field :selection_target_absorption_range, {:array,:integer}
        field :absorption_matching_range, {:array,:integer}
        field :rejection_matching_range, {:array,:integer}


        # Fixed values

        # orientation: 0 -> 1; 0 fully vertical, 1 fully horizontal
        field :orientation, :float
        # max depth that a root can get to. min 1
        field :depth, :integer
        # max surface area, min 1, always odd number ;)
        field :max_top_width, :integer
        # max indepth area, min 1, always odd number ;)
        field :max_bottom_width, :integer
        # filling ratio. 0 -> 1
        field :fill_rate, :float
        # Define root absorption mode Keep(0), Trunc-in(1), Trunc-out(2)
        field :root_mode, :integer
        field :absorption_rate, :float
        field :rejection_rate, :float
        # number of components to select
        field :absorption_count, :integer
        field :rejection_count, :integer

        # Which component of the root we're going to absorb first
        field :selection_compo_to_absorb, :integer
        # Which component of the bloc we're going to absorb first
        field :selection_target_absorption, :integer

        # Matching 
        field :absorption_matching, :integer
        field :rejection_matching, :integer

        # selected components and their ratio (composition, quantity)
        field :rejection, {:array, :map}
        field :absorption, {:array, :map}

        field :prime_root, :boolean, default: false
    end

    @doc """
        Fills in default ranges, this will mostly be used for testing purpose
    """
    def default_prime do 
        %PlantRootContext{
            absorption_range: prepare_range([{"AB",7},{"A",3}, {"BC",2}, {"C", 1}, {"B",1}]),
            absorption_rate_range: prepare_range([{1.8,3},{2,5},{2.2,2}]),
            absorption_count_range: prepare_range([{3,3},{4,5},{2,2}]),
            rejection_range: prepare_range([{"C",1}, {"B",1}, {"A",1}]),
            rejection_rate_range: prepare_range([{0.2,3},{0.4,5},{0.8,2}]),
            rejection_count_range: prepare_range([{1,3},{2,5},{3,2}]),
            orientation_range: prepare_range([{0.5,2},{0.3,5},{0.7,1}]),
            fill_rate_range: prepare_range([{0.8,1}]),
            depth_range: prepare_range([{1,5},{2,3}]),
            max_top_width_range: prepare_range([{1,1}]),
            max_bottom_width_range: prepare_range([{1,1}]),
            root_mode_range: prepare_range([{0,5},{1,3},{2,1}]),
            prime_root: true,
            selection_compo_to_absorb_range: prepare_range([{0,3},{1,5},{2,4},{3,2}]),
            selection_target_absorption_range: prepare_range([{0,3},{1,5},{2,4},{3,2}]),
            absorption_matching_range: prepare_range([{0,5},{1,3},{2,1}]),
            rejection_matching_range: prepare_range([{0,5},{1,3},{2,1}])
        }
    end

    def default_secondary do 
        %PlantRootContext{
            absorption_range: prepare_range([{"AB",7},{"A",3}, {"BC",2}, {"C", 1}, {"B",1}]),
            absorption_rate_range: prepare_range([{0.9,3},{1,5},{1.1,2}]),
            absorption_count_range: prepare_range([{3,3},{4,5},{2,2}]),
            rejection_range: prepare_range([{"C",1}, {"B",1}, {"A",1}]),
            rejection_rate_range: prepare_range([{0.1,3},{0.2,5},{0.4,2}]),
            rejection_count_range: prepare_range([{1,3},{2,5},{3,2}]),
            orientation_range: prepare_range([{0.5,5},{0.3,1},{0.7,1}]),
            fill_rate_range: prepare_range([{0.5,5},{0.6,5},{0.4,5}]),
            depth_range: prepare_range([{3,5},{2,3}]),
            max_top_width_range: prepare_range([{3,5}]),
            max_bottom_width_range: prepare_range([{3,1}]),
            root_mode_range: prepare_range([{0,5},{1,3},{2,1}]),
            prime_root: false,
            selection_compo_to_absorb_range: prepare_range([{0,3},{1,5},{2,4},{3,2}]),
            selection_target_absorption_range: prepare_range([{0,3},{1,5},{2,4},{3,2}]),
            absorption_matching_range: prepare_range([{0,5},{1,3},{2,1}]),
            rejection_matching_range: prepare_range([{0,5},{1,3},{2,1}])
        }
    end

    def roll_dices(%PlantRootContext{} = plant_root_ctx) do 
        plant_root_ctx
        |> Map.put( :orientation,       Enum.random(plant_root_ctx.orientation_range))
        |> Map.put( :depth,             Enum.random(plant_root_ctx.depth_range))
        |> Map.put( :max_top_width,     Enum.random(plant_root_ctx.max_top_width_range))
        |> Map.put( :max_bottom_width,  Enum.random(plant_root_ctx.max_bottom_width_range))
        |> Map.put( :fill_rate,         Enum.random(plant_root_ctx.fill_rate_range))
        |> Map.put( :root_mode,         Enum.random(plant_root_ctx.root_mode_range))
        |> Map.put( :absorption_rate,   Enum.random(plant_root_ctx.absorption_rate_range))
        |> Map.put( :rejection_rate,    Enum.random(plant_root_ctx.rejection_rate_range))
        |> Map.put( :absorption_count,  Enum.random(plant_root_ctx.absorption_count_range))
        |> Map.put( :rejection_count,   Enum.random(plant_root_ctx.rejection_count_range))
        |> Map.put( :selection_compo_to_absorb, Enum.random(plant_root_ctx.selection_compo_to_absorb_range))
        |> Map.put( :selection_target_absorption, Enum.random(plant_root_ctx.selection_target_absorption_range))
        |> Map.put( :absorption_matching, Enum.random(plant_root_ctx.absorption_matching_range))
        |> Map.put( :rejection_matching, Enum.random(plant_root_ctx.rejection_matching_range))
        |> generate_absorption
        |> generate_rejection
    end

    def generate_absorption(plant_root_ctx) do 
        components = for _ <- 1..(plant_root_ctx.absorption_count) do 
            Enum.random(plant_root_ctx.absorption_range)
        end

        {_, components} = Enum.map_reduce(components, %{}, fn comp, acc ->
            {comp,Map.update(acc, comp, 1, &(&1 + 1))}
        end)

        components = for {k,v} <- components do 
            %{composition: k, quantity: v}
        end

        Map.put(plant_root_ctx,:absorption,components)
    end

    def generate_rejection(plant_root_ctx) do 
        components = for _ <- 1..(plant_root_ctx.rejection_count) do 
            Enum.random(plant_root_ctx.rejection_range)
        end

        {_, components} = Enum.map_reduce(components, %{}, fn comp, acc ->
            {comp,Map.update(acc, comp, 1, &(&1 + 1))}
        end)

        components = for {k,v} <- components do 
            %{composition: k, quantity: v}
        end

        Map.put(plant_root_ctx,:rejection,components)
    end
    
    def prepare_range(list) do 
        for {element, count} <- list do 
            for _ <- 0..(count - 1) do 
                element
            end
        end
        |> List.flatten
    end

    def changeset(%PlantRootContext{} = ctx, attrs \\ %{}) do 
        ctx
        |> cast(attrs, [
            :orientation, 
            :depth, 
            :max_top_width, 
            :max_bottom_width, 
            :fill_rate,
            :components_absorption_range,
            :components_absorption_rate_range,
            :components_rejection_range,
            :components_rejection_rate_range   ])
        |> validate_number(:orientation, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
        |> validate_number(:depth, greater_than_or_equal_to: 1)
        |> validate_number(:max_top_width, greater_than_or_equal_to: 1)
        |> validate_number(:max_bottom_width, greater_than_or_equal_to: 1)
        |> validate_number(:fill_rate, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
        |> validate_required([
            :orientation, 
            :depth, 
            :max_top_width, 
            :max_bottom_width, 
            :fill_rate,
            :components_absorption_range,
            :components_absorption_rate_range,
            :components_rejection_range,
            :components_rejection_rate_range])
        
    end
end