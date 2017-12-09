defmodule UpsilonGarden.Plant do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.Plant


  schema "plants" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(%Plant{} = plant, attrs) do
    plant
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
