defmodule UpsilonGarden.GardenData.Component do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.GardenData.Component

    embedded_schema do 
        field :composition, :string
        field :quantity, :float
    end

    @doc """
        Weight of a composition is the sum of all letters, where A is weigthed as 1 and Z 26 
    """
    def weight(comp) do 
        compute_weight(to_charlist(comp), 0)
    end

    defp compute_weight([], acc), do: acc
    defp compute_weight([comp|rest], acc) do 
        compute_weight(rest, 1 + acc + (comp - ?A))
    end

    @doc """
        Length of a composition is the length of it's string.
    """
    def length(comp) do 
        String.length(comp)
    end

    def changeset(%UpsilonGarden.GardenData.Component{} = component, attrs \\ %{} ) do 
        component
        |> cast(attrs, [:composition, :quantity])
        |> validate_required([:composition, :quantity])
    end

end
