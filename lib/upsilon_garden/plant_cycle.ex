defmodule UpsilonGarden.PlantCycle do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.PlantCycle
  require Logger

  embedded_schema do
      embeds_many :dependents, PlantCycle
  end

end
