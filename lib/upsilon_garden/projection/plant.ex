defmodule UpsilonGarden.GardenProjection.Plant do 
    import Ecto.Changeset
    use Ecto.Schema 
    alias UpsilonGarden.GardenProjection.{Plant,Alteration,PartAlteration}

    embedded_schema do 
        field :plant_id, :integer
        embeds_many :alterations, Alteration
        embeds_many :alteration_by_parts, PartAlteration
    end

    def changeset(%Plant{} = plant, attrs \\ %{}) do 
        plant
        |> cast(attrs, [:plant_id])
        |> cast_embed(:alterations)
        |> cast_embed(:alteration_by_parts)
        |> validate_required([:plant_id, :alterations, :alteration_by_parts])
    end
end

