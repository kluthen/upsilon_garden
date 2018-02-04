defmodule UpsilonGarden.Cycle.CycleEvolution do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.PlantCycle
  alias UpsilonGarden.GardenData.Component
  require Logger

  embedded_schema do
    embeds_many :dependents, PlantCycle

    embeds_many :objectives, Component
    field :pivot, :integer, default: 0
    field :structure_gain, :float, default: 0.0
    field :storage_gain, :float, default: 0.0
    field :objectives_gain, :float, default: 0.0
    field :failure_impact_gain, :float, default: 0.0
    field :success_impact_gain, :float, default: 0.0
  end

end
