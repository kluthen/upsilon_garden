defmodule UpsilonGarden.GardenData do 
    use Ecto.Schema
    import Ecto.Changeset

    defmodule Segment do 
        use Ecto.Schema
        
        embedded_schema do 
            field :active, :boolean
            embeds_many :blocs, Bloc
        end

        def changeset(%Segment{} = segment, attrs \\ %{} ) do 
            segment
            |> cast(attrs, [:active])
            |> cast_embed(:blocs)
            |> validate_required([:active, :blocs])
        end
    end

    defmodule Component do 
        use Ecto.Schema

        embedded_schema do 
            field :composition, :string
            field :quantity, :float
        end

        def changeset(%Component{} = component, attrs \\ %{} ) do 
            component
            |> cast(attrs, [:composition, :quantity])
            |> validate_required([:composition, :quantity])
        end

    end

    defmodule Bloc do 
        use Ecto.Schema

        def dirt, do: 0
        def stone, do: 1

        embedded_schema do 
            field :type, :integer 
            embeds_many :components, Component 
            embeds_many :influences, Influence
        end 

        def changeset(%Bloc{} = bloc, attrs \\ %{}) do
            bloc
            |> cast(attrs, [:type])
            |> cast_embed(:components)
            |> cast_embed(:influences)
            |> validate_required([:type, :components, :influences])
        end

        def fill(bloc, context) do 
            components = for _ <- 0..(Enum.random(context.components_by_bloc) -1) do 
                Enum.random(context.available_components)    
            end
            {_,components} = Enum.map_reduce(components, %{}, fn itm, acc -> 
                {itm, Map.update(acc, itm, 1, &(&1 + 1))}
            end)

            components = for {comp, quantity} <- components do 
                %Component{composition: comp, quantity: quantity}
            end

            Map.put(bloc, :components, components)
        end
    end

    defmodule Influence do
        use Ecto.Schema
        def components, do: 0
        def hygro, do: 1
        def plant, do: 1
        def temperature, do: 2

        embedded_schema do 
            field :type, :integer
            field :event_id, :integer
            field :source_id, :integer
            field :plant_id, :integer
            field :ratio, :float
            embeds_many :components, Component
        end
            
        def changeset(%Influence{} = influence, attrs \\ %{} ) do
            influence
            |> cast(attrs, [:type, :event_id, :source_id, :plant_id, :ratio])
            |> cast_embed(:components)
            |> validate_required([:type, :event_id, :source_id, :plant_id, :ratio, :components])
        end
    end

    embedded_schema do 
        embeds_many :segments, Segment
    end

    def changeset(%UpsilonGarden.GardenData{} = data, _attrs \\ %{}) do
        data
        |> cast_embed(:segments)
        |> validate_required([:segments])
    end
    

    def generate(context) do 
        data = %UpsilonGarden.GardenData{}
        segments = for _pos <- 0..(context.dimension - 1) do 
            segment = %Segment{}
            blocs = for depth <- 0..(context.depth - 1 ) do
                bloc = %Bloc{}
                cond do
                    depth == context.depth - 1 -> # ensure last bloc is always stone.
                        Map.put(bloc, :type, Bloc.stone())  
                    depth < 3 -> # ensure topmost blocs are always dirt 
                        Bloc.fill(bloc, context)
                    true ->
                        if :rand.uniform > context.dirt_stone_ratio do
                            Map.put(bloc, :type, Bloc.stone())
                        else 
                            Bloc.fill(bloc, context)
                        end
                end
            end
            Map.put(segment, :blocs, blocs)
        end
        Map.put(data,:segments, segments)            
    end
end