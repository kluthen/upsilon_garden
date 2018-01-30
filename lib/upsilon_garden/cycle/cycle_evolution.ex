defmodule UpsilonGarden.Cycle.CycleEvolution do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.PlantCycle
  alias UpsilonGarden.GardenData.Component
  require Logger

  embedded_schema do
    embeds_many :dependents, PlantCycle

    field :pivot, :integer
    field :structure_gain, :float
    field :storage_gain, :float
    field :failure_impact_gain, :float
    field :success_impact_gain, :float
  end

end
