defmodule UpsilonGarden.Segment do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.{Segment, Repo, Bloc}


  schema "segments" do
    field :depth, :integer
    field :position, :integer
    field :sunshine, :float

    belongs_to :garden, UpsilonGarden.Garden
    has_many :blocs, UpsilonGarden.Bloc 
    many_to_many :events, UpsilonGarden.Event, join_through: "events_segments"
    
    timestamps()
  end

  def create(segment) do 
    segment
    |> Repo.insert!

    for i <- 0..(get_field(segment, :depth)) do
      build_assoc(segment, :blocs)
      |> change(position: i, type: Bloc.Earth)
      |> Bloc.create
    end

  end

  @doc false
  def changeset(%Segment{} = segment, attrs) do
    segment
    |> cast(attrs, [:position, :depth, :sunshine])
    |> validate_required([:position, :depth, :sunshine])
  end
end
