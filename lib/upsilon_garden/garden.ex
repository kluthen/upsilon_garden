defmodule UpsilonGarden.Garden do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.{Garden,GardenContext,GardenData,GardenProjection, Repo}


  schema "gardens" do
    field :dimension, :integer
    field :name, :string

    embeds_one :context, GardenContext
    embeds_one :data, GardenData
    embeds_one :projection, GardenProjection

    belongs_to :user, UpsilonGarden.User
    has_many :events, UpsilonGarden.Event 
    has_many :sources, UpsilonGarden.Source

    timestamps()
  end


  def create(garden, context \\ %{} ) do 
    context = Map.merge(GardenContext.default, context)
    |> GardenContext.roll_dices

    Repo.transaction( fn ->
      garden
      |> change(context: Map.from_struct(context), dimension: context.dimension, data: Map.from_struct(GardenData.generate(context)))
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
