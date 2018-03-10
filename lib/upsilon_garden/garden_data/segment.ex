defmodule UpsilonGarden.GardenData.Segment do
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.GardenData.{Segment,Bloc,Influence}
    alias UpsilonGarden.{Garden,Event,GardenData}

    embedded_schema do
        field :active, :boolean
        field :position, :integer
        field :retention, :float, default: 0.5
        field :hydro_level, :float, default: 0.15
        field :default_hydro_level, :float, default: 0.15
        embeds_many :blocs, UpsilonGarden.GardenData.Bloc
        embeds_many :influences, UpsilonGarden.GardenData.Influence
    end

    def compute_hydro(segment,events) do
      {def_retention, def_default_hydro_level} = Enum.reduce(segment.blocs, {0,0}, fn bloc, {ret, dhydro} ->
        {ret + bloc.retention, dhydro + bloc.hydro_level}
      end)

      # Seek out events relatives to provided segment that influences hydro

      {mod_retention, mod_default_hydro, mod_hydro} = Enum.reduce(segment.influences, {0,0,0}, fn infl, {ret, dhydro, hydro} = res ->
        case infl.type do
            5 -> # hydro
              {ret, dhydro, hydro + infl.power}
            6 -> # retention
              {ret+ infl.power, dhydro, hydro}
            7 -> # default_hydro
              {ret, dhydro + infl.power, hydro}
            _ ->
              res
        end
      end)

      retention = max(min(def_retention + mod_retention, 1), 0)
      d_hydro = max(min(def_default_hydro_level + mod_default_hydro, 1),0)
      hydro = min(d_hydro + (mod_hydro*retention), 0.99 )

      segment
      |> Map.put(:retention, retention)
      |> Map.put(:default_hydro_level, d_hydro)
      |> Map.put(:hydro_level, hydro)
    end

    def changeset(%UpsilonGarden.GardenData.Segment{} = segment, attrs \\ %{} ) do
        segment
        |> cast(attrs, [:active, :position,
                        :retention, :hydro_level,
                        :default_hydro_level])
        |> cast_embed(:blocs)
        |> validate_required([:active, :position, :blocs,
                        :retention, :hydro_level,
                        :default_hydro_level])
    end
end
