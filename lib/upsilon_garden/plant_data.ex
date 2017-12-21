defmodule UpsilonGarden.PlantData do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.{PlantData,GardenData}
    alias UpsilonGarden.GardenData.{Component}
    alias UpsilonGarden.PlantData.{PlantRoot}

    embedded_schema do 
        embeds_many :roots, PlantRoot
        embeds_many :objectives, {:array, {:array, Component}}
    end

    @doc """
        Based on PlantContext, generate a build structural plant.
        ATM, it will mostly generate roots, seek how to position them. 
    """
    def generate(garden_data, segment, plant_ctx) do 
        
        %PlantData{}
    end


    def changeset(%PlantData{} = data, attrs \\ %{}) do 
        data
        |> cast_embed(:roots)
        |> validate_required([:roots])
    end
end