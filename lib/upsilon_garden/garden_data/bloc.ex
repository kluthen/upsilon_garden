defmodule UpsilonGarden.GardenData.Bloc do 
    use Ecto.Schema
    import Ecto.Changeset

    def dirt, do: 0
    def stone, do: 1

    embedded_schema do 
        field :type, :integer 
        field :position, :integer
        field :sources, {:array, :integer}
        embeds_many :components, UpsilonGarden.GardenData.Component 
        embeds_many :influences, UpsilonGarden.GardenData.Influence
    end 

    def changeset(%UpsilonGarden.GardenData.Bloc{} = bloc, attrs \\ %{}) do
        bloc
        |> cast(attrs, [:type, :position, :sources])
        |> cast_embed(:components)
        |> cast_embed(:influences)
        |> validate_required([:type, :position,:sources, :components, :influences])
    end

    def fill(bloc, context) do 
        components = for _ <- 0..(Enum.random(context.components_by_bloc) -1) do 
            Enum.random(context.available_components)    
        end
        {_,components} = Enum.map_reduce(components, %{}, fn itm, acc -> 
            {itm, Map.update(acc, itm, 1, &(&1 + 1))}
        end)

        components = for {comp, quantity} <- components do 
            %UpsilonGarden.GardenData.Component{composition: comp, quantity: quantity}
        end

        bloc 
        |> Map.put(:components, components)
        |> Map.put(:type, UpsilonGarden.GardenData.Bloc.dirt())
    end
end