defmodule UpsilonGarden.Cycle.CycleContext do
  use Ecto.Schema
  alias UpsilonGarden.Cycle.{CycleEvolutionContext}
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

end
