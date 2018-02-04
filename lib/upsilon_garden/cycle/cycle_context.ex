defmodule UpsilonGarden.Cycle.CycleContext do
  use Ecto.Schema
  alias UpsilonGarden.Cycle.{CycleContext,CycleEvolutionContext}
  require Logger

  embedded_schema do
    embeds_many :evolutions, CycleEvolutionContext
    
    field :base_storage_range, {:array, :float}
    field :base_structure_range, {:array, :float}
    field :base_failure_impact_range, {:array, :float}
    field :base_success_impact_range, {:array, :float}
    field :vital, :boolean, default: false
    field :death, {:array, :integer}
  end

  def build_context(opts \\ []) do 
    %CycleContext{
      evolutions: [],
      base_storage_range: [],
      base_structure_range: [],
      base_failure_impact_range: [],
      base_success_impact_range: [],
      vital: false,
      death: []
    }
    |> Map.merge(Enum.into(opts, %{}))
  end

end
