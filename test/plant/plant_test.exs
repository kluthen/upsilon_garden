defmodule UpsilonGarden.Plant.PlantTest do
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

    test "with a provided Garden, add a plant to it and store it in DB", context do
      {:ok, created_plant} = Garden.create_plant(context.garden, 4, PlantContext.default)
      plant = Plant
       |> last
       |> Repo.one

      assert plant.garden_id == context.garden.id
      assert plant.id == created_plant.id
    end

    test "can't add a plant on a segment that has on line 0 a stone", context do 
      fixed_garden_data = GardenData.force_update_bloc(context.garden.data, 4,0, fn bloc ->
        %Bloc{bloc|
            type: Bloc.stone(),
            components: [],
            influences: [],
            sources: []
        }
      end)
      garden = Map.put(context.garden, :data, fixed_garden_data)

      {:error, :stone} = Garden.create_plant(garden, 4, PlantContext.default)
    end

    test "can't add a plant on a segment that has on line 0 a prime root", context do 
      fixed_garden_data = GardenData.force_update_bloc(context.garden.data, 4,0, fn bloc ->
        %Bloc{bloc|
          influences: [%Influence{
            type: Influence.plant(),
            prime_root: true, 
            plant_id: 0 # Our plant won't ever have plant_id 0 but isn't checked against that. 
          }]
        }
      end)
      garden = Map.put(context.garden, :data, fixed_garden_data)

      {:error, :prime_root} = Garden.create_plant(garden, 4, PlantContext.default)
    end


end
