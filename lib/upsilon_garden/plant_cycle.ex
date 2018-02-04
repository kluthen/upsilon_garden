defmodule UpsilonGarden.PlantCycle do
  use Ecto.Schema
  alias UpsilonGarden.{PlantCycle,PlantContent}
  alias UpsilonGarden.Cycle.{CycleContext,CycleEvolution}
  alias UpsilonGarden.GardenProjection.{Alteration}
  alias UpsilonGarden.GardenData.Component
  require Logger

  embedded_schema do
      field :part, :string
      field :level, :integer, default: 0
      field :storage, :float, default: 0.0
      field :structure_max, :float, default: 0.0
      field :structure_current, :float, default: 0.0

      field :vital, :boolean, default: false
      field :death, :integer, default: -1

      embeds_many :objectives, Component
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
      _ -> 
        :unable
    end
  end

  @doc """
    returns next in line cycles to be completed or :unable
    Deepest first
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
          target ++ res
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
    target = Enum.reduce(objectives(cycle), [], fn obj, results ->
      res = make_summary(obj,plant.content,projection.alterations)
      [res|results]
    end)   

    completable = Enum.reduce(target, 0, fn %{'completable?': false}, _completable -> :unable
                                              _ , :unable -> :unable
                                              %{completion: x}, turns when x > turns -> x
                                              %{completion: _x}, turns -> turns
                                              _ , _ -> :unable
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
    prepare summary of a given objective
    returns a %{composition, target, store, income, completable?, completion}
  """
  def make_summary(objective, content, alterations) do 
    res =%{
      composition: objective.composition,
      target: objective.quantity, 
      store: Enum.reduce(PlantContent.find_content_matching(content,objective.composition), 0, &(&1.quantity + &2)),
      income: Enum.reduce(Alteration.find_alterations_matching(alterations, objective.composition), 0, &(&1.rate + &2)),
      'completable?': false,
      completion: 0,
    }

    if res.store > res.target do 
      res 
      |> Map.put(:'completable?', true)
      |> Map.put(:completion, 0)
    else 
      if res.income > 0 do 
        res
        |> Map.put(:'completable?', true)
        |> Map.put(:completion, round(Float.ceil((res.target - res.store) / res.income)))
      else
        res
      end
    end
  end

  @doc """
    fetch all sub cycles depending on current cycle level. 
    returns [plantcycles]
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
    sums objectives based on cycle level, note takes into account cycle level and gains added to it.
    returns [component]  
  """
  def objectives(cycle) do 
    cycle.objectives
  end

  @doc """
    Tell which cycles may be completed right away. 
    In case of tie, choose deepest first
    returns [cycles]
  """
  def completable(plant) do 
    {res,_} = seek_completable_by_cycle(plant, [plant.cycle], [], 0)
    |> Enum.reduce({[], 0}, fn  {cycle, depth}, {_res, res_depth} when depth > res_depth -> {[cycle], depth}
                                {_cycle, depth}, {_res, res_depth} = res when depth < res_depth -> res
                                {cycle, depth}, {res, res_depth} when depth == res_depth -> {[cycle|res], depth}


    end)
    
    res
    |> sort
  end

  def seek_completable_by_cycle(_plant,[], results, _depth), do: results
  @doc """
    compute for each cyle if its completable or not
    returns [{cycle,depth}]
  """
  def seek_completable_by_cycle(plant,[cycle|rest], results, depth) do 

    # Assemble data necessary for computation ... 
    # map objectives to available store and projection alterations. 
    # compute end date. if able.
    target = Enum.reduce(objectives(cycle), [], fn obj, results ->
      res = make_summary(obj,plant.content,[])
      [res|results]
    end)   

    completable = Enum.reduce(target, 0, fn %{'completable?': false}, _completable -> :unable
                                              _ , :unable -> :unable
                                              %{completion: x}, turns when x > turns -> x
                                              %{completion: _x}, turns -> turns
                                              _ , _ -> :unable
    end)

    results = 
    if completable == :unable do 
      results
    else
      [{cycle, depth}| results]
    end

    results = seek_completable_by_cycle(plant,PlantCycle.dependents(cycle),results, depth + 1)
    seek_completable_by_cycle(plant,rest,results, depth)
  end

  @doc """
    Sort cycles, by level first then by alpha in case of tie.
    TODO Should follow a plant wide ordering rule.
  """
  def sort(cycles) do 
    Enum.sort(cycles, fn lhs, rhs -> 
      cond do 
        lhs.level < rhs.level -> true
        rhs.level < lhs.level -> false
        lhs.part < rhs.part -> true
        true -> false
      end
    end)
  end

  @doc """
    Do the actual evolution.
    returns updated plant
  """
  def complete(plant, cycles) do 
    Enum.reduce(cycles, plant, fn cycle, plant ->
      {new_content, success} = Enum.reduce(objectives(cycle), {plant.content, true}, 
        fn _objective, {content, false} -> 
          {content, false}
        objective, {content, true} -> 
          # TODO Should follow a plant wide rule.
          {updated_content, rest} = PlantContent.find_content_matching(content,objective.composition)
          |> Enum.reduce({content, objective.quantity}, 
            fn _compo, {content, 0} -> 
                {content, 0}
              compo, {content, needed} -> 
                to_use = Component.available(compo, needed)
                content = PlantContent.use(content, compo.composition, to_use)
                if needed - to_use < 0.1 do 
                  {content, 0}
                else 
                  {content, needed - to_use}
                end
          end)
          if rest == 0 do 
            {updated_content, true}
          else
            {content, false}
          end
      end)

      if success do 
        plant = Map.put(plant, :content, new_content)
        # now upgrade cycle
        {cycle, {plant, done}} = PlantCycle.upgrade(plant, plant.cycle, cycle.part)
        # This is top level cycle, it need to be provided to plant.
        if done do 
          Map.put(plant, :cycle, cycle)
        else
          # for some reason upgrade didn't happend ... Oo
          plant
        end
      else
        plant
      end
    end)
  end

  @doc """
    Seek cycle, add levels to it and update plante with it. 
    returns {cycle, {plant, done}}
  """
  def upgrade(plant, cycle, cycle_name) do 
    if cycle.part == cycle_name do 
      # Seek last-valid cycle ( it's the only one that matters in term of gains)

      evolution = Enum.reduce(cycle.evolutions, %CycleEvolution{pivot: -1}, fn evol, current -> 
        if evol.pivot < cycle.level and evol.pivot > current.pivot do 
          evol
        else 
          current
        end        
      end)

      cycle = Map.put(cycle, :level, cycle.level + 1)
      |> Map.put(:structure_max, cycle.structure_max + evolution.structure_gain)
      |> Map.put(:structure_current, min(cycle.structure_max + evolution.structure_gain,cycle.structure_current + evolution.structure_gain + evolution.success_impact_gain))
      |> Map.put(:storage, cycle.storage + evolution.storage_gain)
      |> Map.update(:objectives, cycle.objectives, fn objectives -> 
          Enum.map(objectives, &Map.update(&1,:quantity, &1.quantity, fn old -> (old + evolution.objectives_gain) end))
      end)
      
      # has upgrade appointed a new evolution ?
      nevolution = Enum.reduce(cycle.evolutions, %CycleEvolution{pivot: - 1}, fn evol, current -> 
        if evol.pivot < cycle.level and evol.pivot > current.pivot do 
          evol
        else 
          current
        end        
      end)

      cycle =
      if nevolution.pivot != evolution.pivot do 
        # New evolution stade ! updating objectives
        Map.put(cycle, :objectives, cycle.objectives ++ nevolution.objectives)
      else
        cycle
      end

      # update content storage ;)
      plant = Map.update(plant, :content, plant.content, fn old_content -> 
        Map.put(old_content, :max_size, old_content.max_size + evolution.storage_gain)
      end)
      
      {cycle, {plant, true}}
    else
      {evolutions, {plant, done}} = Enum.map_reduce(cycle.evolutions, {plant, false}, 
        fn evol, {plant, false} ->
          if evol.pivot < cycle.level do 
            {deps, {plant, done}} = Enum.map_reduce(evol.dependents, {plant, false}, 
              fn sub_cycle , {plant, false} -> 
                  upgrade(plant, sub_cycle, cycle_name)
                sub, res -> {sub,res}
            end)
            evol = Map.put(evol, :dependents, deps)
            
            {evol, {plant, done}}
          else
            {evol, {plant, false}}
          end
        evol, {plant, true} -> 
          {evol, {plant, true}}
      end)

      {Map.put(cycle, :evolutions, evolutions), {plant, done}}
    end
  end
end
