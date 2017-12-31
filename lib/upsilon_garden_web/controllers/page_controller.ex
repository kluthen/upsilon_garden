defmodule UpsilonGardenWeb.PageController do
  use UpsilonGardenWeb, :controller

  import Ecto.Query
  alias UpsilonGarden.{Garden,GardenData,Repo}
  

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
end
