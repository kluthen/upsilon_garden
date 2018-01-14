defmodule UpsilonGarden.Plant.PlantTest do
    use ExUnit.Case, async: false
    import Ecto.Query
    require Logger
    alias UpsilonGarden.{User,Garden,Repo,Plant,PlantContext}

    setup do
      # Allows Ecto to exists here:
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
      user = User.create("test_user")
      garden = Garden |> last |> Repo.one
      on_exit( :user, fn ->
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
        User |> Repo.delete_all
      end)
      {:ok, garden: garden, user: user}
    end

    test "with a provided Garden, add a plant to it and store it in DB", context do
      Garden.create_plant(context.garden, 4, PlantContext.default)
      plant = Plant
       |> last
       |> Repo.one

      assert plant.garden_id == context.garden.id
    end



end
