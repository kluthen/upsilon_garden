defmodule UpsilonGarden.GardenData.Component do 
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do 
        field :composition, :string
        field :quantity, :float
    end

    def changeset(%UpsilonGarden.GardenData.Component{} = component, attrs \\ %{} ) do 
        component
        |> cast(attrs, [:composition, :quantity])
        |> validate_required([:composition, :quantity])
    end

end
