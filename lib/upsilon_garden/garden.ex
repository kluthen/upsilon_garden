defmodule UpsilonGarden.Garden do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.{Garden, Repo, Segment}


  schema "gardens" do
    field :dimension_max, :integer
    field :dimension_min, :integer
    field :name, :string

    belongs_to :user, UpsilonGarden.User
    has_many :events, UpsilonGarden.Event 
    has_many :segments, UpsilonGarden.Segment

    timestamps()
  end

  def create(garden) do 
    garden
    |> Repo.insert!

    for i <- 50..(50 + get_field(garden,dimension_min)) do 
      build_assoc(garden, :segments)
      |> change(depth: 10, position: i, sunshine: 0.9)
      |> Segment.create
    end
  end

  @doc false
  def changeset(%Garden{} = garden, attrs) do
    garden
    |> cast(attrs, [:name, :dimension_min, :dimension_max])
    |> validate_required([:name, :dimension_min, :dimension_max])
  end
end
