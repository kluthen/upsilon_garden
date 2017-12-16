defmodule UpsilonGarden.GardenData.Segment do 
    use Ecto.Schema
    import Ecto.Changeset
    
    embedded_schema do 
        field :active, :boolean
        field :position, :integer
        embeds_many :blocs, UpsilonGarden.GardenData.Bloc
    end

    def changeset(%UpsilonGarden.GardenData.Segment{} = segment, attrs \\ %{} ) do 
        segment
        |> cast(attrs, [:active, :position])
        |> cast_embed(:blocs)
        |> validate_required([:active, :position, :blocs])
    end
end
