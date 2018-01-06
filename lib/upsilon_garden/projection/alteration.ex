defmodule UpsilonGarden.GardenProjection.Alteration do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.GardenProjection.Alteration

    @doc """
        event_type Rejecter: determine that a plant has been rejecting this. 
        in this case, event_type_id become the plant_id
    """
    def rejection(), do: 0 
    def absorption(), do: 1 

    embedded_schema do 
        field :component, :string 
        field :current_value, :float
        field :rate, :float
        field :next_event, :utc_datetime
        field :event_type, :integer
        field :event_type_id, :integer
    end

    def changeset(%Alteration{} = alteration, attrs \\ %{}) do 
        alteration
        |> cast(attrs, [:component, :current_value, :rate, :next_event, :event_type, :event_type_id])
        |> validate_required([:component, :current_value, :rate, :next_event, :event_type, :event_type_id])
    end
end