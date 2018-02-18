defmodule UpsilonGardenWeb.GardenController do
  use UpsilonGardenWeb, :controller

  import Ecto.Query
  alias UpsilonGarden.{Garden,Repo}
  

  def index(conn, _params) do
    gardens = Garden |> select([:id, :name]) |>Repo.all


    conn
    |> assign(:gardens, gardens)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do 
    garden = Garden |> where(id: ^id) |> preload(:plants) |> preload(sources: :components) |> Repo.one
    
    plant_by_segment = Enum.reduce(garden.plants, %{}, fn plant, acc ->
      Map.put(acc, plant.segment, plant)
    end) 


    conn
    |> assign(:garden, garden.data)
    |> assign(:plants, plant_by_segment)
    |> render("show.html")
  end

end
