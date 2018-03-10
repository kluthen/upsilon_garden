defmodule UpsilonGarden.GardenData.Influence do
    use Ecto.Schema
    import Ecto.Changeset

    def components, do: 0
    def well, do: 1
    def thermal, do: 2
    def plant, do: 3
    def event, do: 4
    def hydro, do: 5
    def retention, do: 6
    def default_hydro, do: 7

    embedded_schema do
        field :type, :integer
        field :event_id, :integer
        field :source_id, :integer
        field :plant_id, :integer
        field :ratio, :float
        field :power, :integer
        field :prime_root, :boolean, default: false
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

    # probably nicer way to do this ...
    def match?(influence, reference) do
        if influence.type != reference.type do
            false
        else
            cond do
                influence.type < 3 ->
                    influence.source_id == reference.source_id
                influence.type == 3 ->
                    if reference.prime_root do
                        influence.prime_root == reference.prime_root
                    else
                        influence.plant_id == reference.plant_id
                    end
                influence.type == 4 ->
                    influence.event_id == reference.event_id
                true ->
                    false # ahah
            end
        end
    end

    def changeset(%UpsilonGarden.GardenData.Influence{} = influence, attrs \\ %{} ) do
        influence
        |> cast(attrs, [:type, :event_id, :source_id, :plant_id, :ratio,:power])
        |> cast_embed(:components)
        |> validate_required([:type, :event_id, :source_id, :plant_id, :ratio, :components,:power])
    end
end
