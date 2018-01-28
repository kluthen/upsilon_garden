defmodule UpsilonGarden.Projection.ComputeTest do 
    use ExUnit.Case, async: false
    import Ecto.Query
    require Logger
    alias UpsilonGarden.{User,Garden,Repo,PlantContext,PlantContent,GardenProjection}
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
        garden = Garden |> last |> preload(:plants) |> Repo.one
  
        on_exit( :user, fn ->
          :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
          User |> Repo.delete_all
        end)
  
        # Sets context to have garden, user, plant.
        {:ok, garden: garden, user: user, plant: plant}
    end

    test "when projection provides no data, recompute projection and try again", context do 
        garden = Map.put(context.garden, :projection, %GardenProjection{plants: []})
        {_,projection} = Garden.prepare_projection(garden)
        assert length(projection.plants) == 1
    end

    test "when projection is still empty does nothing beside updating garden", context do 
        # Rejection criterium are simples: 
        # There must be plants in a garden to build a projection
        # Plants must have available space. (>= 0.1)

        [plant] = context.garden.plants
        plant_content = Map.put(plant.content, :current_size, 299.99)
        |> Map.put(:max_size, 300)
        plant = Map.put(plant, :content, plant_content)


        garden = Map.put(context.garden, :plants, [plant])
        {_,projection} = Garden.prepare_projection(garden)

        assert length(projection.plants) == 0
    end

    test "compute plant new storage after a few minutes have lapsed.", context do 
        # force last update of the garden to a minutes backward, which should proves sufficient to make at least 3 turns
        from_date = Timex.shift(DateTime.utc_now, minutes: -1)
        {garden,projection} = Garden.prepare_projection(context.garden) 
        garden = Map.put(garden, :updated_at, from_date)

        # Note: there is a possibility where projection can't happend ...
        # Must means that fluke provided no support for plant evolution ...
        # should ensure that default plant can survive in there.
        garden = Garden.compute_update(garden)

        turns = UpsilonGarden.Tools.compute_elapsed_turns(from_date)

        garden = Repo.preload(garden,:plants)

        [plant] = garden.plants
        [palts] = projection.plants
        total = Alteration.total(palts.alterations)

        assert plant.content.current_size == Float.round(turns * total,2) 
    end

    @tag :not_implemented
    test "a plant reaching its storage limits force a recompute of projection and a new projection plan is to be applied", context do 
        # force last update of the garden to a minutes backward, which should proves sufficient to make at least 3 turns
        from_date = Timex.shift(DateTime.utc_now, minutes: -1)
        {garden,projection} = Garden.prepare_projection(context.garden) 
        projection = Map.put(projection, :next_event, Timex.shift(DateTime.utc_now, second: -30))
        garden = Map.put(garden, :updated_at, from_date)
        |> Map.put(:projection, projection)

        # Note: there is a possibility where projection can't happend ...
        # Must means that fluke provided no support for plant evolution ...
        # should ensure that default plant can survive in there.
        garden = Garden.compute_update(garden)
        
        assert DateTime.diff(garden.projection.next_event, projection.next_event) > 0
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