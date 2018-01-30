defmodule UpsilonGarden.Cycle.CycleContext do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.Cycle.{CycleContext,CycleEvolutionContext}
  alias UpsilonGarden.GardenData.Component
  require Logger

  embedded_schema do
    embeds_many :evolutions, CycleEvolutionContext
    
    field :base_storage_range, {:array, :float}
    field :base_structure_range, {:array, :float}
    field :base_failure_impact_range, {:array, :float}
    field :base_success_impact_range, {:array, :float}
    field :vital, :boolean
    field :death, {:array, :integer}
  end

end
