defmodule UpsilonGarden.PlantContent do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.PlantContent
    alias UpsilonGarden.GardenData.Component

    def keep, do: 0
    def trunc_in, do: 1
    def trunc_out, do: 2

    embedded_schema do 
        embeds_many :contents, Component
        field :max_size, :float
        field :current_size, :float
    end

    def build_content(opts \\ []) do 
        content = %PlantContent{
            contents: [],
            max_size: 1000,
            current_size: 0,
        }
        |> Map.merge(Enum.into(opts, %{}))
        
        Enum.reduce(content.contents, content, fn comp, content -> 
           Map.put(content, :current_size, content.current_size + comp.quantity + comp.used) 
        end)
    end

    def apply_alteration(content, alteration, 1, rate) do 
        value = Float.round(alteration.rate * rate,2)
        apply_alteration(content, alteration, value)
    end
    
    def apply_alteration(content, alteration, turns, _rate) do 
        value = Float.round(alteration.rate * turns,2)
        apply_alteration(content, alteration, value)
    end

    def apply_alteration(content, alteration, value) do 
        case Enum.find(content.contents, nil, &(&1.composition == alteration.component)) do 
            nil -> 
                new_compo = %Component{
                    composition: alteration.component,
                    quantity: value
                } 

                Map.update(content, :contents, [new_compo] , &([new_compo| &1]) )
                |> Map.update(:current_size, content.current_size, &(&1 + value))
            _component -> 
                contents = Enum.map(content.contents, fn compo -> 
                    if compo.composition == alteration.component do 
                        Map.update(compo, :quantity, 0, &(&1 + value))
                    else
                        compo
                    end
                end)
                Map.put(content, :contents, contents)
                |> Map.update(:current_size, content.current_size, &(&1 + value))
        end
    end

    @doc """
        Find components in store matching request
        returns [component]
    """
    def find_content_matching(content, target) do 
        Enum.reduce(content.contents, [], fn %Component{composition: comp} = cmp, result -> 
            if String.starts_with?(comp,target) do 
                [cmp|result]
            else
                result
            end
        end)
    end

    @doc """
        Find exact component
        returns component or {:error, :not_found}
    """
    def find(content, target) do 
        Enum.find(content.contents, {:error, :not_found}, fn %Component{composition: comp} -> 
            comp == target
        end)
    end

    @doc """ 
        Update content to use target component
    """
    def use(content, target, nb) do 
        contents = Enum.map(content.contents, fn compo -> 
            if compo.composition == target do 
                Component.use(compo, nb)
            else
                compo
            end
        end)
        Map.put(content, :contents, contents)
    end

    def changeset(%PlantContent{} = root, attrs \\ %{}) do 
        root
        |> cast(attrs, [])
        |> cast_embed(:contents)
        |> validate_required([:contents])
    end
end