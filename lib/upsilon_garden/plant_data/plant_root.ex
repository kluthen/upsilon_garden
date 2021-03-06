defmodule UpsilonGarden.PlantData.PlantRoot do
    use Ecto.Schema
    require Logger
    import Ecto.Changeset
    alias UpsilonGarden.{PlantData, GardenData}
    alias UpsilonGarden.PlantData.{PlantRoot,PlantRootContext}
    alias UpsilonGarden.GardenData.{Component,Bloc,Influence}

    # Root mode
    def keep, do: 0
    def trunc_in, do: 1
    def trunc_out, do: 2

    # Selection mode
    def random, do: 0
    def weight, do: 1
    def length, do: 2
    def alpha , do: 3
    def quantity , do: 4

    # Matching mode
    def left, do: 0
    def right, do: 1
    def both, do: 2

    embedded_schema do
        embeds_many :absorbers, UpsilonGarden.GardenData.Component
        embeds_many :rejecters, UpsilonGarden.GardenData.Component
        field :absorb_mode, :integer, default: 0
        field :selection_compo, :integer, default: 0
        field :selection_reject, :integer, default: 0
        field :selection_target, :integer, default: 0
        field :absorption_matching, :integer, default: 0
        field :rejection_matching, :integer, default: 0
        field :absorption_rate, :float, default: 1.0
        field :rejection_rate, :float, default: 1.0
        field :pos_x, :integer
        field :pos_y, :integer
        field :plant_id, :integer
        field :prime_root, :boolean, default: false
    end

    @doc """
        Generate roots, stores them in plant data
        returns plant_data
    """
    def generate_roots(%GardenData{} = garden_data, %PlantData{} = plant_data, %PlantRootContext{} = root_ctx) do
        # basic root without position ...
        basic_root = %PlantRoot{
            absorbers: generate_components(root_ctx.absorption,[]),
            rejecters: generate_components(root_ctx.rejection,[]),
            absorb_mode: root_ctx.root_mode,
            absorption_rate: root_ctx.absorption_rate,
            rejection_rate: root_ctx.rejection_rate,
            prime_root: root_ctx.prime_root,
            plant_id: plant_data.plant_id,
            selection_compo: root_ctx.selection_compo_to_absorb,
            selection_target: root_ctx.selection_target_absorption,
            absorption_matching: root_ctx.absorption_matching,
            rejection_matching: root_ctx.rejection_matching,
        }
        |> apply_selection_and_matching


        # Seek out "valid" blocs beforehand.

        # valid_blocs is a depth to valid items list.
        {valid_blocs, used} = seek_valid_blocs(garden_data, plant_data, root_ctx)

        # seek out potentials targets.
        {valid_blocs, potential} = if root_ctx.prime_root do
            # first prime root is directly on the plant segment topmost bloc.
            {valid_blocs,[{plant_data.segment, 0}]}
        else
            # seek out all previously known roots (should be prime) and from there on add to potentials.
            Enum.reduce(plant_data.roots, {valid_blocs, []}, fn root, {valid_blocs,potential} ->
                 add_neighbours_to_potentials(root.pos_x,root.pos_y, root_ctx.orientation,valid_blocs,potential)
            end)
        end

        # Seek number of root to create

        # valid blocs doesn't count already root used stuff ;) so adding it to total space.
        total_space = Enum.reduce( valid_blocs, used, fn {_,d},acc -> length(d) + acc end)
        # but remove them from those to be created. might round down to 0 ... :) or less.
        expected_root_count = round((total_space+ used) * root_ctx.fill_rate) 

        # now fill
        {plant_data, _pots} = fill_roots(garden_data,plant_data,potential,root_ctx,valid_blocs,expected_root_count,basic_root)
        plant_data
    end

    @doc """
        add/replace components to match absorption and rejection matching.
        if it's "both" that has been selected, then add mirror of the component
        if "right" replace each component by it's mirror.

        order components appropriately
    """
    def apply_selection_and_matching(basic_root) do
       
        abs = case basic_root.absorption_matching do
            0 -> # Left side first ... keep it as such.
                basic_root.absorbers
            1 -> # right side
                Enum.map(basic_root.absorbers, fn compo ->
                    Map.put(compo, :composition, String.reverse(compo.composition))
                end)
            2 -> # both sides
                basic_root.absorbers ++ Enum.map(basic_root.absorbers, fn compo ->
                    Map.put(compo, :composition, String.reverse(compo.composition))
                end)
            _ ->
                basic_root.absorbers
        end

        # reorder absorbers and rejecters to match selection_compo
        basic_root = Map.put(basic_root, :absorbers, sort_by_selection(abs, basic_root.selection_compo))

        rej = case basic_root.rejection_matching do
            0 -> # Left side first ... keep it as such.
                basic_root.rejecters
            1 -> # right side
                Enum.map(basic_root.rejecters, fn compo ->
                    Map.put(compo, :composition, String.reverse(compo.composition))
                end)
            2 -> # both side
                basic_root.rejecters ++ Enum.map(basic_root.rejecters, fn compo ->
                    Map.put(compo, :composition, String.reverse(compo.composition))
                end)
            _ ->
                basic_root.rejecters
        end

        # reorder absorbers and rejecters to match selection_compo
        Map.put(basic_root, :rejecters, sort_by_selection(rej, basic_root.selection_compo))
    end

    @doc """
        Sort array of %{:composition, :quantity} by selection type.
        return ordered components.
    """
    def sort_by_selection(components, selection) do
        case selection do
            0 -> # random
                Enum.shuffle(components)
            1 -> # weigth
                Enum.sort(components, fn lhs, rhs ->
                    Component.weight(lhs.composition) < Component.weight(rhs.composition)
                end)
            2 -> # length
                Enum.sort(components, fn lhs, rhs ->
                    Component.length(lhs.composition) < Component.length(rhs.composition)
                end)
            3 -> # alpha
                Enum.sort(components, fn lhs, rhs ->
                    lhs.composition < rhs.composition
                end)
            4 -> # quantity
                Enum.sort(components, fn lhs, rhs ->
                    lhs.quantity < rhs.quantity
                end)
            _ -> # random
                Enum.shuffle(components)
        end
    end

    @doc """
        Tell whether target matches reference
    """
    def component_match?(reference, target) do
        String.starts_with?(target,reference)
    end

    @doc """
     Seek blocs that allow new roots within range of the context.
     returns {valid_blocs, used} with used blocs already root of current plant.
     with valid_blocs is map; for each line store a list of valid segments ( for each y store a list of x)
    """
    def seek_valid_blocs(garden_data, plant_data, root_ctx) do

        greater_width = max(root_ctx.max_top_width, root_ctx.max_bottom_width)
        min_x = trunc(plant_data.segment - (greater_width - 1) / 2)
        max_x = round(plant_data.segment + (greater_width - 1) / 2)

        Enum.reduce(0..(root_ctx.depth - 1), {%{},0}, fn depth, {valid_blocs, current_used} ->
            {_, {_,last,result, used}} = Enum.map_reduce(min_x..max_x, {false,[], [], 0}, fn x, {in_range, current_list, result, used} ->
                {current_in_range, already_used} = is_bloc_usable?(x,depth,plant_data.segment,root_ctx,garden_data,plant_data.plant_id)
                
                used = if already_used do
                    used + 1
                else
                    used
                end

                if current_in_range do
                    {x, {true, [x|current_list], result, used}}
                else
                    if in_range do
                        {x, {false, [], [current_list|result], used}}
                    else
                        {x, {in_range, current_list, result, used}}
                    end
                end
            end)

            { Map.put(valid_blocs, depth, List.flatten([last|result])) , used + current_used}
        end)
    end


    @doc """
        Tell whether bloc is usable or not.
        return {usable, already_used} both bools
    """
    def is_bloc_usable?(x,y,segment,root_ctx,garden_data,plant_id) do 
        current_in_range = bloc_is_in_range?(x,y,root_ctx.max_top_width,root_ctx.max_bottom_width,root_ctx.depth, segment)
        current_in_range = current_in_range and GardenData.get_bloc(garden_data, x,y).type != Bloc.stone()
        # Check that there aren't any other prime root in store
        match = %Influence{type: Influence.plant(), prime_root: true}
        current_in_range = current_in_range and Enum.empty?(Enum.filter(GardenData.get_bloc(garden_data, x,y).influences, fn bloc_i ->
            # it's a prime root                 but not our plants
            Influence.match?(bloc_i, match) and bloc_i.plant_id != plant_id
        end)) # Must not have any of these.

        # Check if target bloc is already used by our plant
        match = %Influence{type: Influence.plant(), plant_id: plant_id}
        already_used = not Enum.empty?(Enum.filter(GardenData.get_bloc(garden_data, x,y).influences, &Influence.match?(&1, match))) 
    
        {current_in_range and not already_used , already_used}

    end

    def bloc_is_in_range?(x,y, _max_top_width, _max_bottom_width, max_depth, _segment) when x < 0 or y >= max_depth do
        false
    end


    def bloc_is_in_range?(x,y, max_top_width, _max_bottom_width, _max_depth, segment) when y==0 do
        x >= segment - max_top_width/2 and x <= segment + max_top_width/2
    end

    def bloc_is_in_range?(x,y, max_top_width, max_bottom_width, max_depth, segment) when y == max_depth-1 or max_top_width == max_bottom_width do
        x >= segment - max_bottom_width/2 and x <= segment + max_bottom_width/2
    end

    @doc """
        Tell whether provided bloc is in range of the plant based on its properties
        returns true or false.
    """
    def bloc_is_in_range?(x,y, max_top_width, max_bottom_width, max_depth, segment) when max_top_width > max_bottom_width do
        ratio = max_bottom_width-max_top_width / max_depth-2
        x >= Float.round(segment - (max_top_width + ratio*y)/2) and x <= Float.round(segment + (max_top_width + ratio*y)/2)
    end
    
    def bloc_is_in_range?(x,y, max_top_width, max_bottom_width, max_depth, segment) when max_top_width < max_bottom_width do
        ratio = max_bottom_width-max_top_width / max_depth-2
        x >= Float.floor(segment - (max_top_width + ratio*y)/2) and x <= Float.floor(segment + (max_top_width + ratio*y)/2)
    end

    # Couldn't validate any other solution, so it's false, no matter what.
    def bloc_is_in_range?(_x,_y, _max_top_width, _max_bottom_width, _max_depth, _segment) do
        false
    end

    defp fill_roots(_garden_data, plant_data, [], _root_ctx, _valid_blocs, _root_count,_basic_root), do: {plant_data,[]}
    defp fill_roots(_garden_data, plant_data, potential, _root_ctx, _valid_blocs, root_count,_basic_root) when root_count <= 0 do
        {plant_data, potential}
    end

    #    Roll a potential, removes it from the stack.
    #    create a root at rolled spot, add to potential newly available and valid bloc with appropriate probability.
    #    continue up until expected root count has been reached.
    #    returns {plant_data,new_potentials}
    defp fill_roots(%GardenData{} = garden_data, %PlantData{} = plant_data, potential, %PlantRootContext{} = root_ctx, valid_blocs, root_count, %PlantRoot{} = basic_root) do
        # Roll a new root position !
        {r_x,r_y} = Enum.random(potential)

        # Remove it from potential list
        potential = Enum.reject(potential, fn {x,y} ->
            x == r_x and y == r_y
        end)

        # Create and add it to the plant.

        new_root = basic_root
        |> Map.put(:pos_x, r_x)
        |> Map.put(:pos_y, r_y)

        plant_data = plant_data
        |> Map.update(:roots, [new_root], &([new_root|&1]))


        {valid_blocs, npots} = add_neighbours_to_potentials(r_x,r_y, root_ctx.orientation,valid_blocs,potential )

        # next !
        fill_roots(garden_data,plant_data,npots,root_ctx, valid_blocs,root_count - 1, basic_root)
    end

    @doc """
        removes target bloc (r_x,r_y) from valid blocs and from potentials
        seek out new blocs to put in potentials
        update potentials appropriately

        returns {valid_blocs, potentials} both updated.
    """
    def add_neighbours_to_potentials(r_x,r_y, orientation,valid_blocs, potential ) do
        valid_blocs = Enum.map(valid_blocs, fn {y, xs} ->
            if y == r_y do 
                {y, Enum.reject(xs, &(&1 == r_x))}
            else
                {y,xs}
            end
        end)
        |> Map.new

        potential = Enum.reject(potential, fn {x,y} ->
            x == r_x and y == r_y
        end)

        neighbours = get_valid_neighbours(r_x,r_y,valid_blocs)
        neighbours = Enum.filter(neighbours, fn {n_x,n_y} ->
            # check if not already in potential
            # if already there, just leave it out

            Enum.find(potential, nil, fn    {^n_x,^n_y} -> true
                                            {_,_} -> false
            end) == nil
        end)

        # compute ratio of it's presence in potential and add to it.

        horizontal_ratio =  1 + trunc(orientation * 10)
        vertical_ratio = 1 + (10 - trunc(orientation * 10))

        npots = for {_x,y} = pot <- neighbours do
            if y == r_y do
                for _ <- 1..horizontal_ratio do
                    pot
                end
            else
                for _ <- 1..vertical_ratio do
                    pot
                end
            end
        end
        |> List.flatten

        new_potentials = potential ++ npots
        {valid_blocs, new_potentials}
    end

    @doc """
        for a given bloc, seek out neighbours within valid_blocs
        return true or false
    """
    def get_valid_neighbours(r_x,r_y,valid_blocs) do
        # Seek its neighbour and check them for availability (not already added, not a stone )
        Enum.filter([{r_x-1,r_y},{r_x,r_y+1},{r_x+1,r_y}], fn target ->
            is_valid?(target, valid_blocs)
        end)
    end

    # Tell whether a targeted bloc is valid or not.
    defp is_valid?({x,y}, valid_blocs)  do
        if Map.has_key?(valid_blocs, y) do 
            x in valid_blocs[y]
        else
            false
        end
    end

    def generate_components([], acc), do: acc

    # Convert storable components into real components
    def generate_components([%{composition: x,quantity: y} |rest], acc) do
        generate_components(rest, [%Component{composition: x, quantity: y} | acc])
    end

    def changeset(%PlantRoot{} = root, attrs \\ %{}) do
        root
        |> cast(attrs, [:absorb_mode,
                        :selection_compo,
                        :selection_target,
                        :absorption_matching,
                        :rejection_matching,
                        :absorption_rate,
                        :rejection_rate,
                        :pos_x,
                        :pos_y,
                        :prime_root])
        |> cast_embed(:absorbers)
        |> cast_embed(:rejecters)
        |> cast_embed(:objectives)
        |> validate_required([  :absorb_mode,
                                :objectives,
                                :absorbers,
                                :rejecters,
                                :selection_compo,
                                :selection_target,
                                :absorption_matching,
                                :rejection_matching,
                                :absorption_rate,
                                :rejection_rate,
                                :pos_x,
                                :pos_y,
                                :prime_root])
    end
end
