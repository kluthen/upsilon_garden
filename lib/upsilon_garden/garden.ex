defmodule UpsilonGarden.Garden do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto
  alias UpsilonGarden.{Garden, Repo, Segment}


  schema "gardens" do
    field :dimension, :integer
    field :name, :string
    field :context, :map

    belongs_to :user, UpsilonGarden.User
    has_many :events, UpsilonGarden.Event 
    has_many :segments, UpsilonGarden.Segment

    timestamps()
  end

  def create(garden, context \\ %{} ) do 
    Repo.transaction( fn ->
      garden = garden
      |> change(context: context)
      |> Repo.insert!(returning: true)

      for i <- 0..(garden.dimension) do 
        build_assoc(garden, :segments)
        |> change(depth: 10, position: i, sunshine: 0.9)
        |> Segment.create(garden.context)
      end
    end)
  end

  @doc false
  def changeset(%Garden{} = garden, attrs) do
    garden
    |> cast(attrs, [:name, :dimension, :context])
    |> validate_required([:name, :dimension, :context])
  end
end
