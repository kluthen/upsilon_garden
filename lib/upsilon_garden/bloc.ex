defmodule UpsilonGarden.Bloc do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.{Bloc, Repo}


  schema "blocs" do
    field :position, :integer
    field :type, :integer

    belongs_to :segment, UpsilonGarden.Segment
    has_many :influences, UpsilonGarden.Influence
    has_many :components, UpsilonGarden.Component
    has_many :events, through: [:influences, :event]
    
    timestamps()
  end

  def create(bloc) do 
      bloc
      |> Repo.insert!(returning: true)
  end

  @doc false
  def changeset(%Bloc{} = bloc, attrs) do
    bloc
    |> cast(attrs, [:position, :type])
    |> validate_required([:position, :type])
  end
end
