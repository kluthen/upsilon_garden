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
  

  @doc """
    Assemble a PlantContext with provided informations and sets up the plant
    Store it in DB.
  """
  def create(plant, garden_data, segment, plant_ctx) do 
    content = %PlantContent{}
    plant_ctx = Map.merge(PlantContext.default, plant_ctx)
    |> PlantContext.roll_dices

    plant = plant
    |> changeset(%{segment: segment, name: "My Plant"})
    |> put_embed(:context, plant_ctx)
    |> put_embed(:content, content)
    |> Repo.insert!(returning: true)

    # Based on seed, create an actual root network, and setup objectives for next stage.
    # Create also structure of the plant and most probably nexts stages of evolutions.
    data = PlantData.generate(garden_data, segment, plant, plant_ctx)
    
    plant
    |> change()
    |> put_embed(:data, data)
    |> Repo.update!(returning: true)
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
