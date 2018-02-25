defmodule UpsilonGarden.Time.EventsTest do
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
    test "can set an event on a segment", context do
    end

    @tag not_implemented: true
    test "can set an event on a bloc", context do
    end

    @tag not_implemented: true
    test "can set an event on a bloc that radiates for 2 blocs with reducing power", context do
    end

    @tag not_implemented: true
    test "an event has an end date, which when reached removes this event", context do
    end

    @tag not_implemented: true
    test "events may trigger projection deadline", context do 

    end

    @tag not_implemented: true
    test "events adding water on blocs or segments are used for plant hydro level computing", context do 

    end

    @tag not_implemented: true
    test "events adding components on blocs or segments are used for plant absorpotion", context do 

    end

end
