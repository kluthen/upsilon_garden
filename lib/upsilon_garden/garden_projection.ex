defmodule UpsilonGarden.GardenProjection do 
    use Ecto.Schema
    import Ecto.Query
    import Ecto.Changeset
    alias UpsilonGarden.{Garden,GardenProjection}
    alias UpsilonGarden.GardenProjection.{Plant, Alteration, PartAlteration}

    embedded_schema do 
        field :next_event, :utc_datetime
        embeds_many :plants, Plant

    end

    @doc """
        Will create a new Projection for a provided garden. 
    """
    def generate(%Garden{} = garden) do 
        plants = if Ecto.assoc_loaded?(garden.plants) do 
            garden.plants
        else
            UpsilonGarden.Plant
            |> where(garden_id: ^(garden.id))
            |> Repo.all
        end

        if length(plants) == 0 do 
            # No plants, no projection :)
            %GardenProjection{}
        else
            
        end
    end

    @doc """
        Seek out in projection a specific plant. 
    """
    def for_plant(%GardenProjection{} = projection,plant_id) do 
        Enum.find(projection.plants,nil, fn proj -> 
            proj.plant_id == plant_id 
        end);
    end

    def changeset(%GardenProjection{} = projection, attrs \\ %{}) do 
        projection
        |> cast(attrs, [:next_event])
        |> cast_embed(:plants)
        |> validate_required([:next_event, :plants])
    end

    
end