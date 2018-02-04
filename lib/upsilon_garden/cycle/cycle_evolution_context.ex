defmodule UpsilonGarden.Cycle.CycleEvolutionContext do
  use Ecto.Schema
  alias UpsilonGarden.Cycle.CycleContext
  require Logger

  embedded_schema do
    embeds_many :dependents, CycleContext
    field :pivot_range, {:array, :integer}

    field :objectives_range, {:array, :string}
    field :objectives_count_range, {:array, :integer}
    field :objectives_multiplier_range, {:array, :float}
    field :objectives_gain_range, {:array, :float}

    field :structure_gain_range, {:array, :float}
    field :storage_gain_range, {:array, :float}
    field :failure_impact_gain_range, {:array, :float}
    field :success_impact_gain_range, {:array, :float}
  end

end
