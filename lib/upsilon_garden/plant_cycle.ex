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

      embeds_many :objectives, Component
      field :failure_impact, :float, default: 0
      field :success_impact, :float, default: 0

      field :vital, :boolean, default: false
      field :death, :integer, default: 0

      embeds_one :context, CycleContext
      embeds_many :evolution, CycleEvolution
  end

end
