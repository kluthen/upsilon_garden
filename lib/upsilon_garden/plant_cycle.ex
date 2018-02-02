defmodule UpsilonGarden.PlantCycle do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.PlantCycle
  alias UpsilonGarden.Cycle.{CycleContext,CycleEvolution}
  alias UpsilonGarden.GardenData.Component
  require Logger

  embedded_schema do
      field :part, :string
      field :level, :integer, default: 0
      field :storage, :float
      field :structure_max, :float
      field :structure_current, :float

      field :failure_impact, :float, default: 0
      field :success_impact, :float, default: 0

      field :vital, :boolean, default: false
      field :death, :integer, default: 0

      embeds_one :context, CycleContext
      embeds_many :evolutions, CycleEvolution
  end

  @doc """
    returns number of turns it would take for a projection to validate a cycle.
            or :unable : not able to complete anything.
    turns or :unable
  """
  def compute_next_event_turns(plant, projection) do
    case seek_to_be_completed_cycles(plant, projection) do 
      :unable -> 
        :unable
      [{_,turns,_}|_] ->
        turns
    end
  end

  @doc """
    returns next in line cycles to be completed or :unable
    [{part, turns, depth}] or :unable
  """
  def seek_to_be_completed_cycles(plant,projection) do 
    compute_next_event_by_cycle(plant,[plant.cycle], projection, [], 0)
    |> Enum.reduce(:unable, 
      fn {_part, :unable} , res -> 
          res
        target , :unable -> 
          [target]
        {_part, turns, _depth} = target, [{_p,t,_d}|_] = _res when turns < t -> 
          [target]
        {_part, turns, _depth} = _target, [{_p,t,_d}|_] = res when turns > t -> 
          [res]
        {_part, turns, depth} = target, [{_p,t,d}|_] = _res when turns == t and depth > d -> 
          [target]
        {_part, turns, depth} = _target, [{_p,t,d}|_] = res when turns == t and depth < d -> 
          [res]
        {_part, turns, depth} = _target, [{_p,t,d}|_] = res when turns == t and depth < d -> 
          [res]
        {_part, turns, depth} = target, [{_p,t,d}|_] = res when turns == t and depth == d -> 
          [target|res]
      end)
  end


  def compute_next_event_by_cycle(_plant,[], _projection, results, _depth), do: results
  @doc """
    compute for each cyle it's end date based on current plant data and projection.
    returns [{part, turns, depth} or {part, unable}]
  """
  def compute_next_event_by_cycle(plant,[cycle|rest], projection, results, depth) do 
    # compute compute ... 

    # Assemble data necessary for computation ... 
    # map objectives to available store and projection alterations. 
    # compute end date. if able.
    target = Enum.reduce(objectives(cycle), %{}, fn obj, results ->
      res = %{
        composition: obj.composition,
        target: obj.quantity, 
        store: Enum.reduce(PlantContent.find_content_matching(plant.content,obj.composition), 0, &(&1.quantity + &2)),
        income: Enum.reduce(Alteration.find_alterations_matching(projection.alterations, obj.composition), 0, &(&1.rate + &2))
        'completable?': false,
        completion: 0,
      }

      res = 
      if res.store > res.target do 
        res 
        |> Map.put(:'completable?', true)
        |> Map.put(:completion, 0)
      else 
        if res.income > 0 do 
          res
          |> Map.put(:'completable?', true)
          |> Map.put(:completion, Float.ceil((res.target - res.store) / res.income))
        else
          res
        end
      end

      Map.put(results, res.composition, res)
    end)   

    completable = Enum.reduce(target, 0, fn %{'completable?': false}, _completable -> :unable
                                              _ , :unable -> :unable
                                              %{completion: x}, turns when x > turns -> x
                                              %{completion: x}, turns -> turns
                                              _ -> :unable
    end)

    results = 
    if completable == :unable do 
      [{cycle.part, :unable}| results]
    else
      [{cycle.part, completable, depth}| results]
    end

    results = compute_next_event_by_cycle(plant,PlantCycle.dependents(cycle),projection,results, depth + 1)
    compute_next_event_by_cycle(plant,rest,projection,results, depth)
  end

  @doc """
    fetch all sub cycles depending on current cycle level. 
  """
  def dependents(cycle) do 
    Enum.reduce(cycle.evolutions, [], fn evol, res ->
      if evol.pivot <= cycle.level do 
        evol.dependents ++ res
      else
        res
      end
    end)
  end

  @doc """
    sums objectives 
    returns [component]  
  """
  def objectives(cycle) do 
    Enum.reduce(cycle.evolutions, %{}, fn evol, res ->
      if evol.pivot <= cycle.level do 
        Enum.reduce(evol.objectives, res, fn cmp, res ->
          Map.update(res, cmp.composition, cmp, &Map.put(&1, :quantity, &1.quantity + cmp.quantity))
        end)
      else
        res
      end
    end)
    |> Map.values
  end

end
