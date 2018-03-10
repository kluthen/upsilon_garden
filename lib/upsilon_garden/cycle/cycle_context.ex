defmodule UpsilonGarden.Cycle.CycleContext do
  use Ecto.Schema
  alias UpsilonGarden.Cycle.{CycleContext,CycleEvolutionContext}
  require Logger
  import UpsilonGarden.Tools

  embedded_schema do
    embeds_many :evolutions, CycleEvolutionContext

    field :base_storage_range, {:array, :float}
    field :base_structure_range, {:array, :float}
    field :base_failure_impact_range, {:array, :float}
    field :base_success_impact_range, {:array, :float}
    field :vital, :boolean, default: false
    field :death_range, {:array, :integer}

    field :base_storage, :float
    field :base_structure, :float
    field :base_failure_impact, :float
    field :base_sucess_impact, :float
    field :death, :integer, default: 0

  end

  def build_context(opts \\ []) do
    %CycleContext{
      evolutions: [],
      base_storage_range: [],
      base_structure_range: [],
      base_failure_impact_range: [],
      base_success_impact_range: [],
      vital: false,
      death_range: []
    }
    |> Map.merge(Enum.into(opts, %{}))
  end

  def default() do
    # %CycleContext{
    #   base_storage_range: prepare_range(),
    #   base_structure_range: prepare_range(),
    #   base_failure_impact_range: prepare_range(),
    #   base_success_impact_range: prepare_range(),
    #   vital: false,
    #   death_range: prepare_range(),
    # }
    %CycleContext{}
  end

  def roll_dices(%CycleContext{} = ctx) do
    ctx
  end

end
