defmodule UpsilonGarden.GardenProjection do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.GardenProjection

    embedded_schema do 
        field :next_event, :utc_datetime
        embeds_many :plants, Plant

    end

    def for_plant(%GardenProjection{} = projection,plant_id) do 
        Enum.find(projection.plants,nil, fn proj -> 
            proj.plant_id == plant_id 
        end);
    end

    def changeset(%GardenProjection{} = projection, attrs \\ %{}) do 
        projection
        |> cast(attrs, [:next_event])
        |> cast_embed(:plants)
        |> validate_required([:next_event, :plants])
    end

    
end