defmodule UpsilonGarden.Influence do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.Influence


  schema "influences" do
    field :ratio, :float
    field :type, :integer

    belongs_to :bloc, UpsilonGarden.Bloc
    belongs_to :event, UpsilonGarden.Event
    belongs_to :plant, UpsilonGarden.Plant
    belongs_to :source, UpsilonGarden.Source
    
    timestamps()
  end

  @doc false
  def changeset(%Influence{} = influence, attrs) do
    influence
    |> cast(attrs, [:type, :ratio])
    |> validate_required([:type, :ratio])
  end
end
