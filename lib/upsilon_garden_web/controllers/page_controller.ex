defmodule UpsilonGardenWeb.PageController do
  use UpsilonGardenWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
