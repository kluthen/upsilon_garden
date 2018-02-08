defmodule UpsilonGarden.Garden do
  use Ecto.Schema
  import Ecto
  require Logger
  import Ecto.Changeset
  alias UpsilonGarden.{Plant,PlantContent,Garden,GardenContext,GardenData,GardenProjection,Repo,PlantCycle}
  alias UpsilonGarden.GardenData.{Bloc}
  alias UpsilonGarden.GardenProjection.{Alteration}

  @derive {Poison.Encoder, except: [:'__meta__',:events,:user]}
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

    timestamps(type: :utc_datetime)
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
      |> put_embed(:data, GardenData.build())
      |> put_embed(:projection, GardenProjection.build())
      |> Repo.insert!(returning: true)

      # Generate the garden according to provided context
      # Create sources. Activate 3 segments.
      data = GardenData.generate(garden,context)
      |> GardenData.activate([3,4,5])
      |> Map.put(:id, nil)


      {garden,projection} = prepare_projection(garden)
      # Store updated garden.
      garden
      |> change()
      |> put_embed(:data, data)
      |> put_embed(:projection, projection)
      |> Repo.update!(returning: true)
    end)
  end

  @doc """
    Stores and retrieve garden
    Only updates garden name, plant, projections and data.
  """
  def update!(garden) do 
    garden
    |> change(name: garden.name)
    |> put_assoc(:plants, garden.plants)
    |> put_embed(:projection, garden.projection)
    |> put_embed(:data, garden.data)
    |> Repo.update!(returning: true)
  end

  @doc """
    Generate a new Plant according to provided PlantContext
    Insert it on provided Garden segment
    Sets up plant influence on GardenData
    returns
      {:ok, plant}
      {:error, :stone}
      {:error, :prime_root}
  """
  def create_plant(garden, segment, plant_ctx) do

    # Checks beforehand if there is a stone or a prime root here.
    bloc = GardenData.get_bloc(garden.data, segment,0)

    if bloc.type == Bloc.stone() do
      {:error, :stone}
    else
      # checks for a prime root
      if Enum.find(bloc.influences, false, fn infl ->
        infl.prime_root == true
      end) != false do
        {:error, :prime_root}
      else
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

          plant
        end)
      end
    end
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

  @doc """
    Ensure projection can occurs
  """
  def prepare_projection(garden) do
    garden =
    if not Ecto.assoc_loaded?(garden.plants) do
      garden
    else
      Repo.preload(garden, :plants)
    end

    projection =
    if length(garden.projection.plants) == 0 do
      GardenProjection.generate(garden)
    else
      garden.projection
    end

    {garden, projection}
  end

  @doc """
    Compute all plants up to now. Use projections up to next event date or now
    If next event date is reached, recompute new projection and so on.
    Triggers for each turn a test on cycles.
    Updates garden and return it once updated. ( or not.)
  """
  def compute_update(garden) do
    {garden, projection} = prepare_projection(garden)

    if length(projection.plants) == 0 do
      # still nothing, well no updates :)
      garden
      |> change
      |> Repo.update!(returning: true)
    else
      previous_date = garden.updated_at
      garden = apply_projection_for_timrange(garden, projection, previous_date, projection.next_event, DateTime.utc_now)

      update!(garden)
    end
  end

  @doc """
    apply provided projection for given timerange
    If unable to do so in one stroke, will iterate up until reaching now. 
    returns updated garden. 
  """
  def apply_projection_for_timrange(garden, projection, previous_date, next_date, target_date) do
    if next_date != nil do

      # conditions returns an updated garden.
      if DateTime.diff(next_date, target_date) <= 0 do
        turns = UpsilonGarden.Tools.compute_elapsed_turns(previous_date, next_date)
        garden = apply_projection_for_turns(garden,projection, turns)

        {_,plants} = Enum.map_reduce(garden.plants, [], fn plant, acc -> 
          case PlantCycle.turn_passed(plant, turns) do 
            {:destroyed, _plant} -> 
              # not adding it back to acc removes plant from store.
              {plant, acc}
            {:ok, plant} -> 
              cycle = PlantCycle.completable(plant)
              plant = PlantCycle.complete(plant, cycle)
              {plant, [plant|acc]}
            _ -> 
              {plant, acc}
          end
        end)
        
        garden = Map.put(garden, :plants, plants)

        # Compute a new projection
        projection = GardenProjection.generate(garden)
        garden = Map.put(garden, :projection, projection)

        # redo compute_udpate.
        apply_projection_for_timrange(garden, projection, next_date, projection.next_event,target_date)
      else
        turns = UpsilonGarden.Tools.compute_elapsed_turns(previous_date, target_date)
        apply_projection_for_turns(garden,projection, turns) # No need to recompute a projection as it hasn't changed.
      end
    else
      # projection can't project.
      garden
    end
  end

  @doc """
    Apply projection for given turns
    Check cycles incidences as well
    returns updated garden
  """
  def apply_projection_for_turns(garden, projection, turns) when turns > 0 do
      # Apply projection to all plants store.
      updated_plants = Enum.map(garden.plants, fn plant ->
        pa = Enum.find(projection.plants, nil, fn p ->
          p.plant_id == plant.id
        end)

        total = Alteration.total(pa.alterations)

        {rate, filled} =
        if plant.content.current_size + total > plant.content.max_size do
            {Float.round((plant.content.max_size - plant.content.current_size)/total,2), true}
        else
            {1.0, false}
        end

        # We found appropriate plant alteration. now update its store.


        content = Enum.reduce(pa.alterations, plant.content, fn alteration, content ->
          PlantContent.apply_alteration(content, alteration, turns,rate)
        end)

        content =
        if filled do
          Map.put(content, :current_size, content.max_size)
        else
          content
          |> Map.put(:current_size, Float.round(content.current_size, 2))
        end

        
        Map.put(plant, :content, content)        
      end)

      Map.put(garden, :plants, updated_plants)
  end

  def apply_projection_for_turns(garden, _projection, turns) when turns == 0 do
    garden
  end

  @doc false
  def changeset(%Garden{} = garden, attrs \\ %{}) do
    garden
    |> cast(attrs, [:name, :dimension])
    |> cast_embed(:context)
    |> cast_embed(:data)
    |> cast_embed(:projection)
    |> validate_required([:name, :dimension, :context, :data, :projection])
  end
end
