defmodule UpsilonGarden.Component do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.Component


  @derive {Poison.Encoder, except: [:'__meta__', :source, :event]}
  schema "components" do
    field :composition, :string
    field :quantity, :integer
    
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
