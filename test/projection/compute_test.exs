defmodule UpsilonGarden.Projection.ComputeTest do 
    use ExUnit.Case, async: false
    import Ecto.Query
    require Logger
    alias UpsilonGarden.{User,Garden,Repo,PlantContext,PlantContent}
    alias UpsilonGarden.GardenData.Component
    alias UpsilonGarden.GardenProjection.{Alteration}

    setup do
        # Allows Ecto to exists here:
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
        user = User.create("test_user")
  
        # Default garden provide 3 lines clear of stones by default. 
  
        garden = Garden |> last |> Repo.one
        # Plant is set up on segment 4 ( only 3,4,5 are available by default )
        # It's also added to the garden !
        {:ok, plant} = Garden.create_plant(garden,4,PlantContext.default)
  
        on_exit( :user, fn ->
          :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
          User |> Repo.delete_all
        end)
  
        # Sets context to have garden, user, plant.
        {:ok, garden: garden, user: user, plant: plant}
    end

    @tag :not_implemented
    test "when projection provides no data, recompute projection and try again" do 
        flunk "not implemented"
    end

    @tag :not_implemented
    test "when projection is still empty does nothing beside updating garden" do 
        flunk "not implemented"
    end

    @tag :not_implemented
    test "compute plant new storage after a few minutes have lapsed." do 
        flunk "not implemented"
    end

    @tag :not_implemented
    test "a plant reaching its storage limits force a recompute of projection and a new projection plan is to be applied" do 
        flunk "not implemented"
    end

    test "can apply an alteration for a few turns on content" do 
        content = %PlantContent{
            contents: [],
            max_size: 1000,
            current_size: 0
        }

        alteration = %Alteration{
            component: "ABC",
            rate: 10.0,
            event_type: Alteration.absorption()
        }

        content = PlantContent.apply_alteration(content, alteration, 5, 1)

        assert 50.0 = content.current_size
        assert [%Component{
            composition: "ABC",
            quantity: 50.0
        }] = content.contents
    end

    test "can apply alteration for one turn and apply a rate" do 
        content = %PlantContent{
            contents: [],
            max_size: 1000,
            current_size: 0
        }

        alteration = %Alteration{
            component: "ABC",
            rate: 10.0,
            event_type: Alteration.absorption()
        }

        content = PlantContent.apply_alteration(content, alteration, 1, 0.5)

        assert 5.0 = content.current_size
        assert [%Component{
            composition: "ABC",
            quantity: 5.0
        }] = content.contents
    end





end