defmodule UpsilonGardenWeb.PageController do
  use UpsilonGardenWeb, :controller

  import Ecto.Query
  alias UpsilonGarden.{Garden,Repo}
  

  def index(conn, _params) do
    garden = Garden
    |> first
    |> Repo.one

    conn
    |> assign(:garden, garden.data)
    |> render("index.html")
  end
end
