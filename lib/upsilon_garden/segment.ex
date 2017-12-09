defmodule UpsilonGarden.Segment do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto
  alias UpsilonGarden.{Segment, Repo, Bloc}


  schema "segments" do
    field :depth, :integer
    field :position, :integer
    field :sunshine, :float
    field :active, :boolean

    belongs_to :garden, UpsilonGarden.Garden
    has_many :blocs, UpsilonGarden.Bloc 
    many_to_many :events, UpsilonGarden.Event, join_through: "events_segments"
    
    timestamps()
  end

  def create(segment, context) do 
    segment = segment
    |> Repo.insert!(returning: true)

    for i <- 0..(segment.depth - 2) do
      build_assoc(segment, :blocs)
      |> change(position: i, type: Bloc.earth)
      |> Bloc.create(context)
    end

    build_assoc(segment, :blocs)
    |> change(position: (segment.depth-1), type: Bloc.stone)
    |> Bloc.create(context)

  end

  @doc false
  def changeset(%Segment{} = segment, attrs) do
    segment
    |> cast(attrs, [:position, :depth, :active, :sunshine])
    |> validate_required([:position, :depth, :active, :sunshine])
  end
end
