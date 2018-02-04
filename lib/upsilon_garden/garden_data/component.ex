defmodule UpsilonGarden.GardenData.Component do 
    use Ecto.Schema
    import Ecto.Changeset
    require Logger
    alias UpsilonGarden.GardenData.Component

    embedded_schema do 
        field :composition, :string
        field :quantity, :float, default: 0.0
        field :used, :float, default: 0.0
    end

    @doc """
        Weight of a composition is the sum of all letters, where A is weigthed as 1 and Z 26 
    """
    def weight(comp) do 
        compute_weight(to_charlist(comp), 0)
    end

    @doc """
        tell whether can use requested quantity of component.
    """
    def can_use?(comp, nb) do
        comp.quantity < nb
    end

    @doc """
        returns available out of provided number
    """
    def available(comp, nb) do 
        min(nb, comp.quantity)
    end

    @doc """
        mark some quantity to be used. 
        fail if not enough is available.
    """
    def use(comp,nb) do 
        Map.update(comp, :quantity, 0, fn old -> 
            if old - nb < 0 do 
                Logger.error "Can't use requested quantity, use can_use? to check availability"
                raise "Unable to use requested quantity"
            else 
                old - nb
            end
        end)
        |> Map.update(:used, nb, &(&1 + nb))
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

    def changeset(%Component{} = component, attrs \\ %{} ) do 
        component
        |> cast(attrs, [:composition, :quantity])
        |> validate_required([:composition, :quantity])
    end

end
