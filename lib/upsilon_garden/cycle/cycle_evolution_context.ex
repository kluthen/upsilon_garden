defmodule UpsilonGarden.Cycle.CycleContext do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.Cycle.CycleContext
  alias UpsilonGarden.GardenData.Component
  require Logger

  embedded_schema do
    embeds_many :dependents, CycleContext
    field :pivot_range, {:array, :integer}

    field :objectives_range, {:array, :string}
    field :objectives_count_range, {:array, :integer}

    field :structure_gain_range, {:array, :float}
    field :storage_gain_range, {:array, :float}
    field :failure_impact_gain_range, {:array, :float}
    field :success_impact_gain_range, {:array, :float}
  end

end
