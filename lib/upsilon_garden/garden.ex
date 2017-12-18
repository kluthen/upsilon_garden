defmodule UpsilonGarden.Garden do
  use Ecto.Schema
  import Ecto
  import Ecto.Changeset
  alias UpsilonGarden.{Plant,Garden,GardenContext,GardenData,GardenProjection,Repo,PlantContext}


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

    Repo.transaction( fn ->
      garden = garden
      |> change(dimension: context.dimension)
      |> put_embed(:context, context)
      |> Repo.insert!(returning: true)
      
      data = GardenData.generate(garden,context)
      |> GardenData.activate([3,4,5])

      garden
      |> change()
      |> put_embed(:data, data)
      |> Repo.update!(returning: true)
    end)
  end

  def create_plant(garden, segment, plant_ctx) do 
    Repo.transaction( fn ->
      plant = garden
      |> build_assoc(:plant)
      |> Plant.create(garden.data, segment, plant_ctx)
      
      influence = %GardenData.Influence{
        plant_id: plant.id,
        type: 3
      }
      data = setup_plant(garden.data, plant.roots, influence)
      garden
      |> change()
      |> put_embed(:data,data)
      |> Repo.update!(returning: true)
    end)
  end

  def setup_plant(garden_data, [],_), do: garden_data

  def setup_plant(garden_data, [root|roots], influence) do 
    GardenData.set_influence(garden_data, root.pos_x, root.pos_y, influence)
    |> setup_plant(roots, influence)
  end

  def tear_down_plant(garden, plant_id) do 
    match = %UpsilonGarden.GardenData.Influence{
      type: 3,
      plant_id: plant_id
    }
    # drop all influences related to this plant. 
    data = GardenData.drop_influence(garden.data, match)
    garden
    |> change()
    |> put_embed(:data,data)
    |> Repo.update!(returning: true)
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
