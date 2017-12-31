defmodule UpsilonGarden.PlantContent do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.PlantContent
    alias UpsilonGarden.GardenData.Component

    def keep, do: 0
    def trunc_in, do: 1
    def trunc_out, do: 2

    embedded_schema do 
        embeds_many :contents, Component
    end

    def changeset(%PlantContent{} = root, attrs \\ %{}) do 
        root
        |> cast(attrs, [])
        |> cast_embed(:contents)
        |> validate_required([:contents])
    end
end