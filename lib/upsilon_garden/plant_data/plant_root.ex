defmodule UpsilonGarden.PlantData.PlantRoot do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.{PlantData, GardenData}
    alias UpsilonGarden.PlantData.{PlantRoot,PlantRootContext}
    alias UpsilonGarden.GardenData.{Component,Bloc}

    def keep, do: 0
    def trunc_in, do: 1
    def trunc_out, do: 2

    embedded_schema do 
        embeds_many :absorbers, UpsilonGarden.GardenData.Component
        embeds_many :rejecters, UpsilonGarden.GardenData.Component
        field :absorb_mode, :integer, default: 0
        field :absorbtion_rate, :float, default: 1.0 
        field :rejection_rate, :float, default: 1.0 
        field :pos_x, :integer
        field :pos_y, :integer
    end

    @doc """
        Generate roots, stores them in plant data
        returns {plant_data, new_potentials}
    """
    def generate_roots(%GardenData{} = garden_data, %PlantData{} = plant_data, potential, %PlantRootContext{} = root_ctx) do 
        # basic root without position ...
        basic_root = %PlantRoot{
            absorbers: generate_components(root_ctx.absorption,[]),
            rejecters: generate_components(root_ctx.rejection,[]),
            absorb_mode: root_ctx.root_mode,
            absorbtion_rate: root_ctx.absorption_rate,
            rejection_rate: root_ctx.rejection_rate,
        }

        # Seek out "valid" blocs beforehand.

        

        greater_width = max(root_ctx.max_top_width, root_ctx.max_bottom_width)
        min_x = trunc(plant_data.segment - (greater_width - 1) / 2)
        max_x = round(plant_data.segment + (greater_width - 1) / 2)

        valid_blocs = for depth <- 0..(root_ctx.depth - 1) do 
            {_, {_,last,result}} = Enum.map_reduce(min_x..max_x, {false,[], []}, fn x, {in_range, current_list, result} = acc ->
                
                current_in_range = bloc_is_in_range?(x,depth,root_ctx.max_top_width,root_ctx.max_bottom_width,root_ctx.depth, plant_data.segment)
                current_in_range = current_in_range and GardenData.get_bloc(garden_data, x,depth).type != Bloc.stone()

                if current_in_range do 
                    {x, {true, [x|current_list], result}}
                else
                    if in_range do 
                        {x, {false, [], [current_list|result]}}
                    else 
                        {x, acc}
                    end
                end
            end)

            List.flatten [last|result]
        end

        # valid_blocs is a depth to valid items list.

        # Seek number of root to create 
        expected_root_count = round(Enum.reduce( valid_blocs, 0, fn d,acc -> length(d) + acc end) * root_ctx.fill_rate)
        
        # now fill 
        fill_roots(garden_data,plant_data,potential,root_ctx,valid_blocs,expected_root_count,basic_root)
    end

    defp bloc_is_in_range?(x,y, _max_top_width, _max_bottom_width, max_depth, _segment) when x < 0 or y > max_depth do 
        false
    end
    
    defp bloc_is_in_range?(x,y, max_top_width, max_bottom_width, max_depth, segment) when (max_top_width - max_bottom_width) <= 2 and y <= max_depth do 
        greater_width = max(max_top_width, max_bottom_width)
        segment - (greater_width - 1) / 2 <= x and x <= segment + (greater_width - 1) / 2
    end

    #    Tell whether provided bloc is in range of the plant based on its properties
    #    returns true or false.
    defp bloc_is_in_range?(x,y, max_top_width, max_bottom_width, max_depth, segment) when y <= max_depth do 
        common_width = min(max_top_width, max_bottom_width) + 2
        max_width = max(max_top_width, max_bottom_width)
        cond do
            segment - (common_width - 1) / 2 <= x and x <= segment + (common_width - 1) / 2 ->
                true
            segment - (max_width - 1) / 2 > x and x > segment + (max_width - 1) / 2 ->
                false
            true ->
                # Find a better solution ;)
                # # # if x < segment do 
                # # #     # seeking left border equation
                # # #     coef = max_depth / ((segment + (max_bottom_width - 1) / 2) -  (segment + (max_top_width - 1) / 2))
                # # #     p = 0 - (coef * (segment + (max_top_width - 1) / 2)) 
                # # #     # y = coef x + p 
                # # #     # coef x - y + p = 0
                # # #     if max_top_width > max_bottom_width do 
                # # #     else
                # # #     end
                # # # else
                # # #     if max_top_width > max_bottom_width do 
                # # #     else
                # # #     end
                # # # end
                :rand.uniform(2) == 2
        end
    end 
    
    # Couldn't validate any other solution, so it's false, no matter what.
    defp bloc_is_in_range?(_x,_y, _max_top_width, _max_bottom_width, _max_depth, _segment) do 
        false
    end

    defp fill_roots(_garden_data, plant_data, [], _root_ctx, _valid_blocs, _root_count,_basic_root), do: {plant_data,[]}
    defp fill_roots(_garden_data, plant_data, potential, _root_ctx, _valid_blocs, 0,_basic_root), do: {plant_data,potential}

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

        # Seek its neighbour and check them for availability (not already added, not a stone )
        neighbours = Enum.filter([{r_x-1,r_y},{r_x,r_y+1},{r_x+1,r_y}], fn {x,y} = target ->
            is_valid?(target, valid_blocs)
                and GardenData.get_bloc(garden_data, x,y).type == Bloc.dirt() 
                and Enum.find(plant_data.roots, false, fn root -> root.pos_x == x and root.pos_y == y end) == false
        end)
        

        # compute ratio of it's presence in potential and add to it.

        horizontal_ratio =  1 + trunc(root_ctx.orientation * 10)
        vertical_ratio = 1 + (10 - trunc(root_ctx.orientation * 10))

        npots = for {_x,y} = pot <- neighbours do 
            if y == r_y do 
                for _ <- 0..horizontal_ratio do 
                    pot
                end
            else 
                for _ <- 0..vertical_ratio do 
                    pot
                end
            end
        end
        |> List.flatten

        # next !
        fill_roots(garden_data,plant_data,npots ++ potential,root_ctx, valid_blocs,root_count - 1, basic_root)
    end

    defp is_valid?(_, []), do: false 

    defp is_valid?({x,y}, [_|valid_blocs]) when y != 0 do 
        is_valid?({x,y-1}, valid_blocs)
    end
    
    # Tell whether a targeted bloc is valid or not. 
    # Valid blocs is a list of list of valid blocs. Each item of the englobing list represent a depth level. 
    defp is_valid?({x,_y}, [valid_blocs|_]) do 
        x in valid_blocs
    end
    
    defp is_valid?(_, _), do: false 
    
    
    defp generate_components([], acc), do: acc
    defp generate_components([%{composition: x,quantity: y} |rest], acc) do 
        generate_components(rest, [%Component{composition: x, quantity: y} | acc])
    end

    def changeset(%PlantRoot{} = root, attrs \\ %{}) do 
        root
        |> cast(attrs, [:absorb_mode])
        |> cast_embed(:absorbers)
        |> cast_embed(:rejecters)
        |> cast_embed(:objectives)
        |> validate_required([:absorb_mode, :objectives, :absorbers, :rejecters])
    end
end