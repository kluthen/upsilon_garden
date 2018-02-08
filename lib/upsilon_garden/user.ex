defmodule UpsilonGarden.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto 
  alias UpsilonGarden.{User, Repo, Garden,PlantContext}

  schema "users" do
    field :name, :string
    has_many :gardens, UpsilonGarden.Garden

    timestamps()
  end


  def create(username) do 
    Repo.transaction( fn ->
      changeset(%User{}, %{name: username})
      |> Repo.insert!(returning: true)
      |> build_assoc(:gardens)
      |> change(name: "My First Garden")
      |> Garden.create()

      
      nil
    end )
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
