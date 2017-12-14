defmodule UpsilonGarden.Event do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.Event


  schema "events" do
    field :description, :string
    field :duration, :integer
    field :name, :string
    field :power, :integer
    field :start_date, :utc_datetime
    field :type, :integer

    belongs_to :garden, UpsilonGarden.Garden
    has_many :components, UpsilonGarden.Component

    timestamps()
  end

  @doc false
  def changeset(%Event{} = event, attrs) do
    event
    |> cast(attrs, [:type, :start_date, :duration, :power, :name, :description])
    |> validate_required([:type, :start_date, :duration, :power, :name, :description])
  end
end
