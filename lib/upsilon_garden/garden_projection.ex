defmodule UpsilonGarden.GardenProjection do 
    use Ecto.Schema

    embedded_schema do 
        field :next_event, :utc_datetime
        embeds_many :plants, Plant
    end

    defmodule Plan do 
        use Ecto.Schema 

        embedded_schema do 
            field :plant_id, :integer
            embeds_many :alterations, Alteration
            embeds_many :alteration_by_parts, PartAlteration
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
    end

    defmodule PartAlteration do 
        use Ecto.Schema 

        embedded_schema do 
            field :part_id, :integer
            embeds_many :alterations, Alteration 
        end
    end
    
end