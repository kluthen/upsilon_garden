defmodule UpsilonGarden.PlantContext do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.PlantContext


    embedded_schema do 
        
    end

    def changeset(%PlantContext{} = root, attrs \\ %{}) do 
        root
    #    |> cast(attrs, [:absorb_mode])
    #    |> cast_embed(:absorbers)
    #    |> cast_embed(:rejecters)
    #    |> cast_embed(:objectives)
    #    |> validate_required([:absorb_mode, :objectives, :absorbers, :rejecters])
    end
end