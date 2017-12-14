defmodule UpsilonGarden.Garden do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto
  alias UpsilonGarden.{Garden, Repo, Segment}


  schema "gardens" do
    field :dimension, :integer
    field :name, :string
    field :context, :map
    field :data, :map
    field :projection, :map

    belongs_to :user, UpsilonGarden.User
    has_many :events, UpsilonGarden.Event 
    has_many :sources, UpsilonGarden.Source

    timestamps()
  end


  def create(garden, context \\ %{} ) do 
    context = Map.merge(Garden.default_context, context)
    |> roll_dices

    Repo.transaction( fn ->
      garden = garden
      |> change(context: context, dimension: context.dimension)
      |> Repo.insert!(returning: true)
    end)
  end



  @doc false
  def changeset(%Garden{} = garden, attrs) do
    garden
    |> cast(attrs, [:name, :dimension, :context])
    |> validate_required([:name, :dimension, :context])
  end
end
