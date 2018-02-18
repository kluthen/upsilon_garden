defmodule UpsilonGardenWeb.Router do
  use UpsilonGardenWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", UpsilonGardenWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/info/plant/:plant", PageController, :get_plant
    get "/info/projection/:plant", PageController, :get_projection
    get "/info/segment/:segment/", PageController, :get_segment
    get "/info/segment/:segment/bloc/:bloc/", PageController, :get_bloc

    

    get "/garden/", GardenController, :index
    get "/garden/:id", GardenController, :show
  end

  scope "/api", UpsilonGardenWeb do 
    pipe_through :json
    
    get "/garden/:id", GardenController, :show
    get "/plant/:id", PlantController, :show
    get "/plant/projection/:plant", PlantController, :get_projection
    
    put "/garden/:id/measure_water/:segment", GardenController, :measure_water
    put "/garden/:id/water/:segment", GardenController, :water
    put "/garden/:id/harvest/:segment", GardenController, :harvest
  end

end
