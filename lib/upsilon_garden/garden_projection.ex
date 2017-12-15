defmodule UpsilonGarden.GardenProjection do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.GardenProjection

    embedded_schema do 
        field :next_event, :utc_datetime
        embeds_many :plants, Plant

    end

    def changeset(%GardenProjection{} = projection, attrs \\ %{}) do 
        projection
        |> cast(attrs, [:next_event])
        |> cast_embed(:plants)
        |> validate_required([:next_event, :plants])
    end

    defmodule Plant do 
        use Ecto.Schema 

        embedded_schema do 
            field :plant_id, :integer
            embeds_many :alterations, Alteration
            embeds_many :alteration_by_parts, PartAlteration
        end

        def changeset(%Plant{} = plant, attrs \\ %{}) do 
            plant
            |> cast(attrs, [:plant_id])
            |> cast_embed(:alterations)
            |> cast_embed(:alteration_by_parts)
            |> validate_required([:plant_id, :alterations, :alteration_by_parts])
        end
    end

    defmodule Alteration do 
        use Ecto.Schema

        embedded_schema do 
            field :component, :string 
            field :current_value, :float
            field :rate, :float
            field :next_event, :utc_datetime
            field :event_type, :integer
            field :event_type_id, :integer
        end

        def changeset(%Alteration{} = alteration, attrs \\ %{}) do 
            alteration
            |> cast(attrs, [:component, :current_value, :rate, :next_event, :event_type, :event_type_id])
            |> validate_required([:component, :current_value, :rate, :next_event, :event_type, :event_type_id])
        end
    end

    defmodule PartAlteration do 
        use Ecto.Schema 

        embedded_schema do 
            field :part_id, :integer
            embeds_many :alterations, Alteration 
        end

        def changeset(%PartAlteration{} = part, attrs \\ %{}) do 
            part 
            |> cast(attrs, [:part_id])
            |> cast_embed(:alterations)
            |> validate_required([:part_id, :alterations])
        end
    end
    
end