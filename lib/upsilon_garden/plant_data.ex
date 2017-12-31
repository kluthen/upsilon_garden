defmodule UpsilonGarden.PlantData do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.{Plant,PlantData,PlantContext,GardenData}
    alias UpsilonGarden.GardenData.{Component}
    alias UpsilonGarden.PlantData.{PlantRoot}

    embedded_schema do 
        embeds_many :roots, PlantRoot
        field :segment, :integer
    end


    @doc """
        Based on PlantContext, generate a build structural plant.
        ATM, it will mostly generate roots, seek how to position them. 


        returns updated plant data.
        """
    def generate(%GardenData{} = garden_data, segment, %Plant{} = plant, %PlantContext{} = plant_ctx) do 
        plant_data = %PlantData{
            segment: plant.segment
        }

        # Note: we expect here that 0,0 won't be a stone, ofcourse ...

        {plant_data, potential} = PlantRoot.generate_roots(garden_data, plant_data, [{segment,0}], plant_ctx.prime_root)
        {plant_data, _} = PlantRoot.generate_roots(garden_data, plant_data, potential, plant_ctx.secondary_root)

        # That's it for the moment. 
        plant_data
    end


    def changeset(%PlantData{} = data, _attrs \\ %{}) do 
        data
        |> cast_embed(:roots)
        |> validate_required([:roots])
    end
end