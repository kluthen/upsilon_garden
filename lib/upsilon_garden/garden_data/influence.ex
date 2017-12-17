defmodule UpsilonGarden.GardenData.Influence do
    use Ecto.Schema
    import Ecto.Changeset
    
    def components, do: 0
    def well, do: 1
    def thermal, do: 2
    def plant, do: 3
    def event, do: 3

    embedded_schema do 
        field :type, :integer
        field :event_id, :integer
        field :source_id, :integer
        field :plant_id, :integer
        field :ratio, :float
        field :power, :integer
        embeds_many :components, UpsilonGarden.GardenData.Component
    end

    def influence_type(infl) do 
        case infl.type do
            0 -> "Components"
            1 -> "Well"
            2 -> "Thermal"
            3 -> "Plant"
            4 -> "Event"
        end
    end
        
    def changeset(%UpsilonGarden.GardenData.Influence{} = influence, attrs \\ %{} ) do
        influence
        |> cast(attrs, [:type, :event_id, :source_id, :plant_id, :ratio,:power])
        |> cast_embed(:components)
        |> validate_required([:type, :event_id, :source_id, :plant_id, :ratio, :components,:power])
    end
end