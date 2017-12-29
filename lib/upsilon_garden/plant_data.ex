defmodule UpsilonGarden.PlantData do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.{PlantData,PlantContext,GardenData}
    alias UpsilonGarden.GardenData.{Component,Influence,Bloc}
    alias UpsilonGarden.PlantData.{PlantRoot}

    embedded_schema do 
        embeds_many :roots, PlantRoot
        embeds_many :objectives, {:array, {:array, Component}}
    end

    defp generate_components([], acc), do: acc
    defp generate_components([%{composition: x,quantity: y} |rest], acc) do 
        generate_components(rest, [%Component{composition: x, quantity: y} | acc])
    end

    @doc """
        Based on PlantContext, generate a build structural plant.
        ATM, it will mostly generate roots, seek how to position them. 


        returns updated garden data.
        """
    def generate(%GardenData{} = garden_data, segment, %Plant{} = plant, %PlantContext{} = plant_ctx) do 
        %PlantData{}

        # Position prime root first
        # bloc 0,0 is always a prime root. (0,0: segment where the plant is, topmost bloc)
        base_prime_influence = %Influence{
            plant_id: plant.id,
            type: Influence.plant(),
            components: generate_components(plant_ctx.prime_root.rejection, []),
            power: 1,
            ratio: 1,
        }

        # Note: we expect here that 0,0 won't be a stone, ofcourse ...

        garden_data = GardenData.set_influence(garden_data, segment, 0, base_prime_influence)
        {garden_data, border} = fill_influence(garden_data, [{segment,0}], plant_ctx.prime_root)

        # Position secondary root
        base_secondary_influence = %Influence{
            plant_id: plant.id,
            type: Influence.plant(),
            components: generate_components(plant_ctx.secondary_root.rejection, []),
            power: 1,
            ratio: 1,
        }

        {garden_data, _} = fill_influence(garden_data, [{segment,0}], plant_ctx.prime_root)

        # That's it for the moment. 
        garden_data
    end

    def fill_influence(garden_data, border, root_ctx) do 

    end
    
    def changeset(%PlantData{} = data, attrs \\ %{}) do 
        data
        |> cast_embed(:roots)
        |> validate_required([:roots])
    end
end