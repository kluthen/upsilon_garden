defmodule UpsilonGarden.Hydro.HydroTest do
    use ExUnit.Case, async: false
    import Ecto.Query
    require Logger
    alias UpsilonGarden.{User,Garden,GardenData,Repo,Plant,PlantContext}
    alias UpsilonGarden.GardenData.{Bloc,Influence}

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

    @tag not_implemented: true
    test "with a provided garden, ensure all segment have a water retention rate > 0 and a current hydro level", context do
    end

    @tag not_implemented: true
    test "we can check hydro level of a segment", context do 
    end

    @tag not_implemented: true
    test "we can check hydro level of a plant", context do 
    end

    @tag not_implemented: true
    test "we can water a segment", context do 
    end

    @tag not_implemented: true
    test "watering by 15% a segment create a watering event on the segment for a duration of 8 hours with appropriate power", context do 
    end

    @tag not_implemented: true
    test "watering by 15% a segment that has 30% retention will in effect increase water level by 4.5%", context do 

    end
end
