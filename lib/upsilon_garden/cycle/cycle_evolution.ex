defmodule UpsilonGarden.Cycle.CycleEvolution do
  use Ecto.Schema
  alias UpsilonGarden.PlantCycle
  alias UpsilonGarden.GardenData.Component
  alias UpsilonGarden.Cycle.CycleEvolution
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

  def build_evolution(opts \\ []) do 
    %CycleEvolution{
      pivot: 0,
      structure_gain: 0.0,
      storage_gain: 0.0,
      objectives_gain: 0.0,
      failure_impact_gain: 0.0,
      success_impact_gain: 0.0,
      dependents: [],
      objectives: []
    }
    |> Map.merge(Enum.into(opts, %{}))
  end

end
