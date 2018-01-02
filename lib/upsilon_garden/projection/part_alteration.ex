defmodule UpsilonGarden.GardenProjection.PartAlteration do 
    use Ecto.Schema 
    import Ecto.Changeset
    alias UpsilonGarden.GardenProjection.{PartAlteration,Alteration}

    embedded_schema do 
        field :part_id, :integer
        embeds_many :alterations, Alteration 
    end

    def changeset(%PartAlteration{} = part, attrs \\ %{}) do 
        part 
        |> cast(attrs, [:part_id])
        |> cast_embed(:alterations)
        |> validate_required([:part_id, :alterations])
    end
end