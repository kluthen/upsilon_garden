defmodule UpsilonGardenWeb.PlantController do
  use UpsilonGardenWeb, :controller

  import Ecto.Query
  alias UpsilonGarden.{Garden,GardenData,Repo,Plant, GardenProjection}
  

  def index(conn, _params) do
    
    conn
    |> render("index.html")
  end

  
end
