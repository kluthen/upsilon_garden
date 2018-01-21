defmodule UpsilonGarden.PlantData do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.{Plant,PlantData,PlantContext,GardenData}
    alias UpsilonGarden.PlantData.{PlantRoot}
    require Logger

    embedded_schema do 
        embeds_many :roots, PlantRoot
        field :segment, :integer
        field :plant_id, :integer
    end

    @doc """
        Based on PlantContext, generate a build structural plant.
        ATM, it will mostly generate roots, seek how to position them. 

        returns updated plant data.
        """
    def generate(%GardenData{} = garden_data, %Plant{} = plant, %PlantContext{} = plant_ctx) do 
        plant_data = %PlantData{
            segment: plant.segment,
            plant_id: plant.id
        }

        # Note: we expect here that 0,0 won't be a stone, ofcourse ...

        plant_data = PlantRoot.generate_roots(garden_data, plant_data, plant_ctx.prime_root)
        plant_data = PlantRoot.generate_roots(garden_data, plant_data, plant_ctx.secondary_root)

        # That's it for the moment. 
        plant_data
    end

    def get_root(%PlantData{} = plant_data, pos_x, pos_y) do
        Enum.find(plant_data.roots, nil, fn root ->
           root.pos_x == pos_x and root.pos_y == pos_y 
        end)
    end

    def changeset(%PlantData{} = data, _attrs \\ %{}) do 
        data
        |> cast_embed(:roots)
        |> validate_required([:roots])
    end
end