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

    conn
    |> assign(:garden, garden)
    |> render("show.html")
  end


end
