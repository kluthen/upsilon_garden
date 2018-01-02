defmodule UpsilonGardenWeb.PageController do
  use UpsilonGardenWeb, :controller

  import Ecto.Query
  alias UpsilonGarden.{Garden,GardenData,Repo,Plant, GardenProjection}
  

  def index(conn, _params) do
    garden = Garden
    |> first
    |> preload(:plants)
    |> Repo.one

    plant_by_segment = Enum.reduce(garden.plants, %{}, fn plant, acc ->
      Map.put(acc, plant.segment, plant)
    end) 

    conn
    |> assign(:garden, garden.data)
    |> assign(:plants, plant_by_segment)
    |> render("index.html")
  end

  def get_segment(conn, %{"segment" => segment}) do 
    garden = Garden
    |> first
    |> Repo.one

    conn
    |> assign(:segment, GardenData.get_segment(garden.data,String.to_integer(segment)))
    |> put_layout(false)
    |> render("show_segment.html")
  end

  def get_bloc(conn, %{"segment" => segment, "bloc" => bloc}) do 
    garden = Garden
    |> first
    |> Repo.one

    bloc = GardenData.get_bloc(garden.data,String.to_integer(segment),String.to_integer(bloc))


    conn
    |> assign(:bloc, bloc)
    |> put_layout(false)
    |> render("show_bloc.html")
  end

  def get_plant(conn, %{"plant" => plant_id}) do 
    plant = Plant
    |> where(id: ^plant_id)
    |> Repo.one

    case plant do 
      nil -> 
        conn
        |> send_resp(404,"Plant not found.")
      plant ->
        conn
        |> assign(:plant, plant)
        |> put_layout(false)
        |> render("show_plant.html")
    end
  end

  def get_projection(conn, %{"plant" => plant_id}) do
    garden = Garden
    |> first
    |> Repo.one
    
    case GardenProjection.for_plant(garden.projections,String.to_integer(plant_id)) do 
      nil ->
        conn
        |> send_resp(404,"Projection for plant not found")
      projection ->
        conn
        |> assign(:projection, projection)
        |> put_layout(false)
        |> render("show_projection.html")
    end
  end
end
