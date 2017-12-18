defmodule UpsilonGarden.PlantData.PlantRoot do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.PlantData.PlantRoot
    alias UpsilonGarden.GardenData.Component

    def keep, do: 0
    def trunc_in, do: 1
    def trunc_out, do: 2

    embedded_schema do 
        embeds_many :absorbers, UpsilonGarden.GardenData.Component
        embeds_many :rejecters, UpsilonGarden.GardenData.Component
        embeds_many :objectives, UpsilonGarden.GardenData.Component
        field :absorb_mode, :integer, default: 0
        field :efficience, :float, default: 1.0 
        field :pos_x, :integer
        field :pos_y, :integer
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