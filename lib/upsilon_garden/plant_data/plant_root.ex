defmodule UpsilonGarden.PlantData.PlantRoot do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.{PlantData, GardenData}
    alias UpsilonGarden.PlantData.{PlantRoot,PlantRootContext}
    alias UpsilonGarden.GardenData.Component

    def keep, do: 0
    def trunc_in, do: 1
    def trunc_out, do: 2

    embedded_schema do 
        embeds_many :absorbers, UpsilonGarden.GardenData.Component
        embeds_many :rejecters, UpsilonGarden.GardenData.Component
        embeds_many :objectives, UpsilonGarden.GardenData.Component
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

        valid_blocs = [[]]

        greater_width = max(root_ctx.max_top_width, root_ctx.max_bottom_width)
        min_x = segment - (greater_width - 1) / 2
        max_x = segment + (greater_width - 1) / 2

        for depth <- 0..(root_ctx.depth - 1) do 

        end

        # Seek number of root to create 

        expected_root_count = 0
        
        # now fill 
        fill_root(garden_data,plant_data,potential,root_ctx,valid_blocs,expected_root_count)
    end

    defp bloc_is_in_range?(x,y, max_top_width, max_bottom_width, max_depth, segment) when x < 0 or y > max_depth do 
        false
    end
    
    defp bloc_is_in_range?(x,y, max_top_width, max_bottom_width, max_depth, segment) when (max_top_width - max_bottom_width) <= 2 and y <= max_depth do 
        greater_width = max(root_ctx.max_top_width, root_ctx.max_bottom_width)
        segment - (greater_width - 1) / 2 <= x and x <= segment + (greater_width - 1) / 2
    end

    @doc """
        Tell whether provided bloc is in range of the plant based on its properties
        returns true or false.
    """
    defp bloc_is_in_range?(x,y, max_top_width, max_bottom_width, max_depth, segment) when y <= max_depth do 
        common_width = min(root_ctx.max_top_width, root_ctx.max_bottom_width) + 2
        if segment - (common_width - 1) / 2 <= x and x <= segment + (common_width - 1) / 2 do 
            true
        else 
            if x < segment do 
                # seeking left border equation
                coef = max_depth / ((segment + (max_bottom_width - 1) / 2) -  (segment + (max_top_width - 1) / 2))
                p = 0 - (coef * (segment + (max_top_width - 1) / 2)) 
                # y = coef x + p 
                # coef x - y + p = 0
                if max_top_width > max_bottom_width do 

                else

                end
            else
                if max_top_width > max_bottom_width do 

                else

                end
            end
        end
    end 
    
    # Couldn't validate any other solution, so it's false, no matter what.
    defp bloc_is_in_range?(_x,_y, _max_top_width, _max_bottom_width, _max_depth, _segment) do 
        false
    end

    defp fill_roots(_garden_data, plant_data, [], _root_ctx, _valid_blocs, _root_count), do: {plant_data,[]}
    defp fill_roots(_garden_data, plant_data, potential, _root_ctx, _valid_blocs, 0), do: {plant_data,potential}

    @doc """
        Roll a potential, removes it from the stack.
        create a root at rolled spot, add to potential newly available and valid bloc with appropriate probability.
        continue up until expected root count has been reached. 
        returns {plant_data,new_potentials}
    """
    defp fill_roots(%GardenData{} = garden_data, %PlantData{} = plant_data, potential, %PlantRootContext{} = root_ctx, valid_blocs, root_count) do 

    end

    
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