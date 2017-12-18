defmodule UpsilonGarden.PlantData do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.{PlantData,GardenData}
    alias UpsilonGarden.GardenData.{Segment,Bloc}
    alias UpsilonGarden.PlantData.{PlantRoot}

    embedded_schema do 
        embeds_many :roots, PlantRoot
    end

    def roll(garden_data, segment, plant_ctx) do 
        %PlantData{}
    end


    def changeset(%PlantData{} = data, attrs \\ %{}) do 
        data
        |> cast_embed(:roots)
        |> validate_required([:roots])
    end
end