defmodule UpsilonGarden.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto 
  import Ecto.Query
  alias UpsilonGarden.{User, Repo, Garden}

  schema "users" do
    field :name, :string
    has_many :gardens, UpsilonGarden.Garden

    timestamps()
  end


  def create(username) do 
    Repo.transaction( fn ->
      user = changeset(%User{}, %{name: username})
      |> Repo.insert!(returning: true)
      |> build_assoc(:gardens)
      |> change(dimension: 10, name: "My First Garden", context: %{})
      |> Garden.create()
      {:ok, user} 
    end )
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
