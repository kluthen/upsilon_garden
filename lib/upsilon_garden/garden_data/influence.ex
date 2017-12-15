defmodule UpsilonGarden.GardenData.Influence do
    use Ecto.Schema
    import Ecto.Changeset
    
    def components, do: 0
    def hygro, do: 1
    def plant, do: 1
    def temperature, do: 2

    embedded_schema do 
        field :type, :integer
        field :event_id, :integer
        field :source_id, :integer
        field :plant_id, :integer
        field :ratio, :float
        embeds_many :components, UpsilonGarden.GardenData.Component
    end
        
    def changeset(%UpsilonGarden.GardenData.Influence{} = influence, attrs \\ %{} ) do
        influence
        |> cast(attrs, [:type, :event_id, :source_id, :plant_id, :ratio])
        |> cast_embed(:components)
        |> validate_required([:type, :event_id, :source_id, :plant_id, :ratio, :components])
    end
end