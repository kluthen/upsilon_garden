defmodule UpsilonGarden.EventSegment do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.EventSegment


  schema "events_segments" do
    field :event_id, :id
    field :segment_id, :id

    timestamps()
  end

  @doc false
  def changeset(%EventSegment{} = event_segment, attrs) do
    event_segment
    |> cast(attrs, [])
    |> validate_required([])
  end
end
