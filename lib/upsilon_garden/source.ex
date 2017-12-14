defmodule UpsilonGarden.Source do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.Source


  schema "sources" do
    field :position, :integer
    field :power, :integer
    field :type, :integer

    belongs_to :garden, UpsilonGarden.Garden
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
