defmodule UpsilonGarden.Plant do
  use Ecto.Schema
  import Ecto.Changeset
  alias UpsilonGarden.{Plant,PlantContent,PlantContext,PlantData,Repo}


  schema "plants" do
    field :name, :string
    field :segment, :integer

    embeds_one :content, PlantContent, on_replace: :delete
    embeds_one :context, PlantContext, on_replace: :delete
    embeds_one :data, PlantData, on_replace: :delete

    timestamps()
  end
  

  def create(plant, garden_data, segment, plant_ctx) do 
    content = %PlantContent{}
    data = PlantData.roll(garden_data, segment,plant_ctx)

    plant
    |> changeset(%{segment: segment, name: "My Plant"})
    |> put_embed(:context, plant_ctx)
    |> put_embed(:content, content)
    |> put_embed(:data, data)
    |> Repo.insert!(returning: true)
  end



  @doc false
  def changeset(%Plant{} = plant, attrs) do
    plant
    |> cast(attrs, [:name,:segment])
    |> cast_embed(:context)
    |> cast_embed(:data)
    |> cast_embed(:content)
    |> validate_required([:name,:segment])
  end
end
