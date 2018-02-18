defmodule UpsilonGardenWeb.PlantController do
  use UpsilonGardenWeb, :controller

  import Ecto.Query
  alias UpsilonGarden.{Garden,GardenData,Repo,Plant, GardenProjection}
  

  def index(conn, _params) do
    
    conn
    |> render("index.html")
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
