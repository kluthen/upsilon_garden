defmodule UpsilonGarden.Garden do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.{Garden,GardenContext,GardenData,GardenProjection, Repo}


  schema "gardens" do
    field :dimension, :integer
    field :name, :string

    embeds_one :context, GardenContext, on_replace: :delete
    embeds_one :data, GardenData, on_replace: :delete
    embeds_one :projection, GardenProjection, on_replace: :delete

    belongs_to :user, UpsilonGarden.User
    has_many :events, UpsilonGarden.Event 
    has_many :sources, UpsilonGarden.Source

    timestamps()
  end


  def create(garden, context \\ %{} ) do 
    context = Map.merge(GardenContext.default, context)
    |> GardenContext.roll_dices

    data = GardenData.generate(context)
    |> GardenData.activate([3,4,5])

    Repo.transaction( fn ->
      garden
      |> change(dimension: context.dimension)
      |> put_embed(:context, context)
      |> put_embed(:data, data)
      |> Repo.insert!(returning: true)
    end)
  end



  @doc false
  def changeset(%Garden{} = garden, attrs) do
    garden
    |> cast(attrs, [:name, :dimension])
    |> cast_embed(:context)
    |> cast_embed(:data)
    |> cast_embed(:projection)
    |> validate_required([:name, :dimension, :context, :data, :projection])
  end
end
