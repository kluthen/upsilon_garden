defmodule UpsilonGarden.GardenProjection.Alteration do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.GardenProjection.Alteration

    @doc """
        event_type Rejecter: determine that a plant has been rejecting this. 
        in this case, event_type_id become the plant_id
    """
    def rejection(), do: 0 
    def absorption(), do: 1 

    embedded_schema do 
        field :component, :string 
        field :current_value, :float
        field :rate, :float
        field :next_event, :utc_datetime
        field :event_type, :integer
        field :event_type_id, :integer
    end

    @doc """
        Provided a list of part alterations, will sum those that share a same event_type.
        If none exists, simply add it to the pack
        returns [alteration]
    """
    def merge_part_alterations(part_alterations) do 
        Enum.reduce(part_alterations, %{}, fn pa, acc -> 
            Enum.reduce(pa.alterations, acc, fn alt, acc -> 
                Map.update(acc, alt.component, [alt], fn old_alts -> 
                    merge_alterations(old_alts, alt)
                end)
            end)
        end)
    end

    @doc """
        Provided a list of alterations, will sum those that share a same event_type.
        If none exists, simply add it to the pack
        returns [alteration]
    """
    def merge_alterations(alterations, new_alt) do 
        {alterations, done} = Enum.map_reduce(alterations, false, fn alt, done -> 
            if alt.event_type == new_alt.event_type do 
               {Map.put(alt, :rate, alt.rate + new_alt.rate), true}
            else 
               {alt, done}
            end
        end)

        if not done do 
            [new_alt|alterations]
        else 
            alterations
        end
    end

    @doc """
        Retrieve total absorbed rate (or whatever alteration type you want)
    """
    def total(alterations) do 
        total(alterations, [Alteration.absorption()])
    end
    def total(alterations, types) do 
        Enum.reduce(alterations, 0, fn alt, acc -> 
            if alt.event_type in types do 
                acc + alt.rate 
            else 
                acc
            end
        end)

    end

    
    @doc """
        Find alterations in store matching request
        returns [component]
    """
    def find_alterations_matching(alterations, target) do 
        Enum.reduce(alterations, [], fn %Alteration{component: comp} = cmp, result -> 
            if String.starts_with?(comp,target) do 
                [cmp|result]
            else
                result
            end
        end)
    end

    def changeset(%Alteration{} = alteration, attrs \\ %{}) do 
        alteration
        |> cast(attrs, [:component, :current_value, :rate, :next_event, :event_type, :event_type_id])
        |> validate_required([:component, :current_value, :rate, :next_event, :event_type, :event_type_id])
    end
end