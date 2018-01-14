defmodule UpsilonGarden.Garden do
  use Ecto.Schema
  import Ecto
  import Ecto.Changeset
  alias UpsilonGarden.{Plant,Garden,GardenContext,GardenData,GardenProjection,Repo}


  schema "gardens" do
    field :dimension, :integer
    field :name, :string

    embeds_one :context, GardenContext, on_replace: :delete
    embeds_one :data, GardenData, on_replace: :delete
    embeds_one :projection, GardenProjection, on_replace: :delete

    belongs_to :user, UpsilonGarden.User
    has_many :events, UpsilonGarden.Event
    has_many :plants, UpsilonGarden.Plant
    has_many :sources, UpsilonGarden.Source

    timestamps()
  end


  @doc """
    Assemble a GardenContext, and roll a new Garden according to this context;
    Ensure 3 segments are active for user.
    Rolls sources and update Garden for it.
  """
  def create(garden, context \\ %{} ) do
    # Using Select values for provided context.
    context = Map.merge(GardenContext.default, context)
    |> GardenContext.roll_dices

    Repo.transaction( fn ->
      # Store the new garden.
      garden = garden
      |> change(dimension: context.dimension)
      |> put_embed(:context, context)
      |> Repo.insert!(returning: true)

      # Generate the garden according to provided context
      # Create sources. Activate 3 segments.
      data = GardenData.generate(garden,context)
      |> GardenData.activate([3,4,5])
      |> Map.put(:id, nil)

      # Store updated garden.
      garden
      |> change()
      |> put_embed(:data, data)
      |> Repo.update!(returning: true)
    end)
  end

  @doc """
    Generate a new Plant according to provided PlantContext
    Insert it on provided Garden segment
    Sets up plant influence on GardenData
  """
  def create_plant(garden, segment, plant_ctx) do
    Repo.transaction( fn ->
      # Build up a new plant associated to this garden.
      # Generate it based on seed context.
      plant = garden
      |> build_assoc(:plants)
      |> Plant.create(garden.data, segment, plant_ctx)

      # Integrate plant influence onto garden
      # (What it rejects)
      influence = %GardenData.Influence{
        plant_id: plant.id,
        type: 3
      }

      data = setup_plant(garden.data, plant.data.roots, influence)
      |> Map.put(:id, nil)

      # Update garden with new data.
      garden
      |> change()
      |> put_embed(:data,data)
      |> Repo.update!(returning: true)
    end)
  end

  def setup_plant(garden_data, [],_), do: garden_data

  @doc """
    Seek blocs where influence of the plant should be added.
    Update GardenData and returns it.
  """
  def setup_plant(garden_data, [root|roots], influence) do
    # update influence with appropriate informations ...
    ninfluence=influence
    |> Map.put(:components, root.rejecters)
    |> Map.put(:prime_root, root.prime_root)

    GardenData.set_influence(garden_data, root.pos_x, root.pos_y, ninfluence)
    |> setup_plant(roots, influence)
  end

  @doc """
    Remove a plant influence from garden.
  """
  def tear_down_plant(garden, plant_id) do
    match = %UpsilonGarden.GardenData.Influence{
      type: UpsilonGarden.GardenData.Influence.plant(),
      plant_id: plant_id
    }
    # drop all influences related to this plant.
    data = GardenData.drop_influence(garden.data, match)
    |> Map.put(:id, nil)

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
