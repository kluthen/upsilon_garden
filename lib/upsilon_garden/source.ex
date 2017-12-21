defmodule UpsilonGarden.Source do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.{Source,Repo,GardenData}
  alias UpsilonGarden.GardenData.{Influence,Component}

  def component, do: 0
  def thermal, do: 1
  def well, do: 2

  schema "sources" do
    field :power, :integer
    # define action range
    field :radiance, :integer
    field :type, :integer

    belongs_to :garden, UpsilonGarden.Garden
    has_many :components, UpsilonGarden.Component

    timestamps()
  end

  @doc """
    Seek an "appropriate" source origin, and set sources up.
    Updates and return GardenData with added influence of the new source. 
  """
  def create(source, data, context) do 
    # roll segment
    segment_id = :rand.uniform(context.dimension - 1)
    # roll bloc
    bloc_id = :rand.uniform(context.depth - 1)
    # roll type
    type = Enum.random(context.source_type_range)
    # roll radiance
    radiance = Enum.random(context.source_radiance_range)
    # roll power
    power = Enum.random(context.source_power_range)

    # store source in DB
    source = source
    |> change(type: type, radiance: radiance, power: power)
    |> Repo.insert!(returning: true)


    segment = Enum.at(data.segments, segment_id)
    bloc = Enum.at(segment.blocs, bloc_id)
    sources = [ Map.take(source, [:id, :type])  | bloc.sources]
    bloc = Map.put(bloc, :sources, sources)
    segment = Map.put(segment, :blocs, List.replace_at(segment.blocs,bloc_id,bloc))
    segments = List.replace_at(data.segments,segment_id, segment)

    # generate base influence.
    base_influence = case type do 
      0 -> # Component
        # Components gets only 1/10 of the power value as number of components to generate.
        nb_components = Kernel.trunc(power/10)

        components = for _ <- 0..(nb_components - 1) do 
          Enum.random(context.available_source_components)    
        end
        {_,components} = Enum.map_reduce(components, %{}, fn itm, acc -> 
            {itm, Map.update(acc, itm, 1, &(&1 + 1))}
        end)
        components = for {compo,quantity} <- components do 
          %Component{
              composition: compo,
              quantity: quantity
          }
        end

        generate_components(components, source)

        %Influence{
          type: Influence.components,
          components: components,
          source_id: source.id,
          power: power
        }
      1 -> # Thermal
        %Influence{
          type: Influence.thermal,
          source_id: source.id,
          power: power
        }
      2 -> # Well 
        %Influence{
          type: Influence.well,
          source_id: source.id,
          power: power
        }
    end    
    # add pattern selection here centered on segment_id,bloc_id 
    Map.put(data, :segments, segments)
    generate_influences(data, [{segment_id, bloc_id}], radiance, base_influence )
  end


  def generate_components([], _), do: nil
  
  @doc """
    Select and add components to database. Link them to source.
  """
  def generate_components([%Component{} = compo|rest], source) do 
    Ecto.build_assoc(source, :components)
    |> change(component: compo.composition, number: compo.quantity)
    |> Repo.insert! 
    generate_components(rest, source)
  end

  @doc """
    Generate Influence; update GardenData with them. 
    Read through the garden layout and select a "zone of interest"
    (that is, a square around targets enlarged by radiance:power)
  """
  def generate_influences(data, targets,power, base_influence) do 
    min_x = max(seek_min(targets, length(data.segments), 0) - power, 0)
    min_y = max(seek_min(targets, length(data.segments), 1) - power, 0)
    max_x = min(seek_max(targets, 0, 0) + power, length(data.segments))
    max_y = min(seek_max(targets, 0, 1) + power, length(Enum.at(data.segments,0).blocs))

    generate_row_influences(data,min_y,max_y, min_x,max_x, targets, power, base_influence)
  end

  @doc """
    Updates row by row for influences.
  """
  def generate_row_influences(data,y, max_y, min_x, max_x, targets, power, base_influence) do 
    if y < max_y do 
      segments = generate_cell_influences(data,y , min_x, max_x, targets, power, base_influence)
      generate_row_influences(data,y+1, max_y, min_x, max_x, targets, power, base_influence)
    else 
      data
    end
  end

  @doc """
    For each cell in a row, check whether it's near enough or not. 
    If it's near a target, generate an influence, with appropriate rate (ratio distance to target)
    Add it to GardenData.
  """
  def generate_cell_influences(data, y, x, max_x, targets, power, base_influence) do 
    if x < max_x do 
      dist = distance(targets, 99, x, y)
      if dist <= power do 
        # update bloc/segment.
        data = GardenData.set_influence(data,x,y, power, dist, base_influence)
        generate_cell_influences(data,y, x+1, max_x, targets, power, base_influence)
      else
        generate_cell_influences(data,y, x+1, max_x, targets, power, base_influence)
      end
    else
      data
    end
  end


  
  def seek_min([],current_min,_), do: current_min

  @doc """
    Seek the smallest item;
    position: {x,y}
    pos reflect which we should use.
  """
  def seek_min([position|targets], current_min, pos) do 
    if elem(position,pos) < current_min do 
      seek_min(targets, elem(position,pos), pos)
    else 
      seek_min(targets, current_min, pos)
    end
  end

  def seek_max([],current_max,_), do: current_max
   
  @doc """
    Seek the highest item;
    position: {x,y}
    pos reflect which we should use.
  """
  def seek_max([position|targets], current_max, pos) do 
    if elem(position,pos) > current_max do 
      seek_max(targets, elem(position,pos), pos)
    else 
      seek_max(targets, current_max, pos)
    end
  end

  def distance([],max_distance,_,_), do: max_distance

  @doc """
    Calculate distance to the nearest of the targets. 
    Return nearest distance. 
    Use a simple distance method. 
    Should be updated to reflect positions of stones bloc
  """
  def distance([{to_x,to_y}|rest], max_distance, x,y) do 
      dist = abs(x - to_x) + abs( y - to_y )
      if dist < max_distance do 
        distance(rest, dist, x,y)
      else
        distance(rest,max_distance, x,y)
      end
  end

  @doc false
  def changeset(%Source{} = source, attrs) do
    source
    |> cast(attrs, [:type, :power, :position])
    |> validate_required([:type, :power, :position])
  end
end
