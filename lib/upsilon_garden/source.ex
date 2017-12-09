defmodule UpsilonGarden.Source do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.Source


  schema "sources" do
    field :position, :integer
    field :power, :integer
    field :type, :integer

    has_many :influences, UpsilonGarden.Influence
    has_many :components, UpsilonGarden.Component

    timestamps()
  end

  @doc false
  def changeset(%Source{} = source, attrs) do
    source
    |> cast(attrs, [:type, :power, :position])
    |> validate_required([:type, :power, :position])
  end
end
