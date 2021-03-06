defmodule UpsilonGarden.PlantContext do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.PlantContext
    alias UpsilonGarden.PlantData.PlantRootContext
    alias UpsilonGarden.Cycle.CycleContext


    embedded_schema do 
        embeds_one :cycle, CycleContext
        embeds_one :prime_root, PlantRootContext
        embeds_one :secondary_root, PlantRootContext
    end

    @doc """
        Fills in default ranges, this will mostly be used for testing purpose
    """
    def default do 
        %PlantContext{
            prime_root: PlantRootContext.default_prime,
            secondary_root: PlantRootContext.default_secondary,
            cycle: CycleContext.default
        }
    end
    
    def roll_dices(%PlantContext{} = plant_ctx) do 
        plant_ctx
        |> Map.put(:prime_root, PlantRootContext.roll_dices(plant_ctx.prime_root))
        |> Map.put(:secondary_root, PlantRootContext.roll_dices(plant_ctx.secondary_root))
        |> Map.put(:cycle, CycleContext.roll_dices(plant_ctx.cycle))
    end

    def changeset(%PlantContext{} = root, _attrs \\ %{}) do 
        root
        |> cast_embed(:prime_root)
        |> cast_embed(:secondary_root)
        |> cast_embed(:cycle)
    end
end