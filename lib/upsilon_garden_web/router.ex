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
  end

  scope "/", UpsilonGardenWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/:segment/", PageController, :get_segment
    get "/:segment/bloc/:bloc/", PageController, :get_bloc
  end

  # Other scopes may use custom stacks.
  # scope "/api", UpsilonGardenWeb do
  #   pipe_through :api
  # end
end
