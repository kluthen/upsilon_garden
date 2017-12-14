defmodule UpsilonGarden.Component do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.Component


  schema "components" do
    field :component, :string
    field :number, :integer
    
    belongs_to :source, UpsilonGarden.Source
    belongs_to :event, UpsilonGarden.Event
    
    timestamps()
  end

  @doc false
  def changeset(%Component{} = component, attrs) do
    component
    |> cast(attrs, [:number, :component])
    |> validate_required([:number, :component])
  end
end
