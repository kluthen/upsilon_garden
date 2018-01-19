defmodule UpsilonGarden.Plant.PlantRootGenerationTest do 
    use ExUnit.Case, async: true
    import Ecto.Query
    import Ecto.Changeset
    import Ecto
    require Logger
    alias UpsilonGarden.{User,Garden,Repo,Plant,PlantContext,PlantData,GardenData,PlantContent}
    alias UpsilonGarden.GardenData.{Bloc,Influence}
    alias UpsilonGarden.PlantData.{PlantRoot}

    setup_all do
      # Allows Ecto to exists here:
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
      user = User.create("test_user")

      # Default garden provide 3 lines clear of stones by default. 

      garden = Garden |> last |> Repo.one
      # Prepare a plant ... but only superficially
      plant_ctx =  PlantContext.default
      |> PlantContext.roll_dices
      content = %PlantContent{}
      data = %PlantData{segment: 4, roots: []}

      plant = build_assoc(garden, :plants)
      |> Plant.changeset(%{segment: 4, name: "My Plant"})
      |> put_embed(:context, plant_ctx)
      |> put_embed(:content, content)
      |> put_embed(:data, data)
      |> Repo.insert!(returning: true)

      data = Map.put(plant.data, :plant_id, plant.id);
      plant = Map.put(plant, :data, data)

      # Plant is set up on segment 4 ( only 3,4,5 are available by default )

      on_exit( :user, fn ->
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
        User |> Repo.delete_all
      end)
      {:ok, garden: garden, user: user, plant: plant}
    end

    test "ensure that stone blocs aren't selected as candidates", context do
        # As by default garden provides 3 lines clear of stones, need to add one.
        # Plant is expected to grow on segment 4
        # Can't have a stone bloc on segment 4 line 0 
        # (that would be lame ... shouldn't be able to add such plants ...) 
        
        fixed_garden_data = GardenData.force_update_bloc(context.garden.data, 4,1, fn bloc ->
            %Bloc{bloc|
                type: Bloc.stone(),
                components: [],
                influences: [],
                sources: []
            }
        end)
        fixed_garden_data = GardenData.force_update_bloc(fixed_garden_data, 3,1, fn bloc ->
            %Bloc{bloc|
                type: Bloc.stone(),
                components: [],
                influences: [],
                sources: []
            }
        end)
        fixed_garden_data = GardenData.force_update_bloc(fixed_garden_data, 5,1, fn bloc ->
            %Bloc{bloc|
                type: Bloc.stone(),
                components: [],
                influences: [],
                sources: []
            }
        end)

        # Ensure root context seeks bloc in 4,1
        fixed_root_ctx = Map.put(context.plant.context.prime_root, :depth, 3)
        fixed_root_ctx = Map.put(fixed_root_ctx, :max_top_width, 1)
        fixed_root_ctx = Map.put(fixed_root_ctx, :max_bottom_width, 1)
        # Should only seek to go in depth, can't go sideway thus

        {valid_blocs, used} = PlantRoot.seek_valid_blocs(fixed_garden_data, context.plant.data, fixed_root_ctx )
        # valid blocs should only contains 4,0

        assert Map.has_key?(valid_blocs, 0) == true
        assert length(valid_blocs[0]) == 1
        assert [4] = valid_blocs[0] 
        assert used == 0
        assert Map.has_key?(valid_blocs, 1) == false
    end

    test "ensure that blocs with prime roots of other plants aren't selected as candidates", context do
        # Add a line of prime root of another plant on depth 1; plants may never have id of 0 but that should be enought

        influence = %Influence{
            type: Influence.plant(),
            plant_id: 0
        }
        
        fixed_garden_data = GardenData.force_update_bloc(context.garden.data, 4,1, fn bloc ->
            %Bloc{bloc|
                influences: [influence]
            }
        end)
        fixed_garden_data = GardenData.force_update_bloc(fixed_garden_data, 3,1, fn bloc ->
            %Bloc{bloc|
            influences: [influence]
            }
        end)
        fixed_garden_data = GardenData.force_update_bloc(fixed_garden_data, 5,1, fn bloc ->
            %Bloc{bloc|
            influences: [influence]
            }
        end)

        # Ensure root context seeks bloc in 4,1
        fixed_root_ctx = Map.put(context.plant.context.prime_root, :depth, 3)
        fixed_root_ctx = Map.put(fixed_root_ctx, :max_top_width, 1)
        fixed_root_ctx = Map.put(fixed_root_ctx, :max_bottom_width, 1)
        # Should only seek to go in depth, can't go sideway thus

        {valid_blocs, used} = PlantRoot.seek_valid_blocs(fixed_garden_data, context.plant.data, fixed_root_ctx )
        # valid blocs should only contains 4,0

        assert Map.has_key?(valid_blocs, 0) == true
        assert length(valid_blocs[0]) == 1
        assert [4] = valid_blocs[0] 
        assert used == 0
        assert Map.has_key?(valid_blocs, 1) == false
    end

    test "ensure that blocs with prime roots of this plants are selected as candidates but added as used", context do
        influence = %Influence{
            type: Influence.plant(),
            plant_id: context.plant.id
        }
        
        fixed_garden_data = GardenData.force_update_bloc(context.garden.data, 4,0, fn bloc ->
            %Bloc{bloc|
                influences: [influence]
            }
        end)
        
        # Ensure root context seeks bloc in 4,1
        fixed_root_ctx = Map.put(context.plant.context.prime_root, :depth, 3)
        fixed_root_ctx = Map.put(fixed_root_ctx, :max_top_width, 1)
        fixed_root_ctx = Map.put(fixed_root_ctx, :max_bottom_width, 1)
        # Should only seek to go in depth, can't go sideway thus

        {valid_blocs, used} = PlantRoot.seek_valid_blocs(fixed_garden_data, context.plant.data, fixed_root_ctx )
        # valid blocs should only contains 4,0 4,1 4,2
        # used should be 1

        assert Map.has_key?(valid_blocs, 0) == true
        assert length(valid_blocs[0]) == 1
        assert [4] = valid_blocs[0] 
        assert Map.has_key?(valid_blocs, 1) == true
        assert length(valid_blocs[1]) == 1
        assert [4] = valid_blocs[1] 
        assert Map.has_key?(valid_blocs, 2) == true
        assert length(valid_blocs[2]) == 1
        assert [4] = valid_blocs[2] 
        assert used == 1
    end

    test "ensure that blocs with roots of other plants are selected as candidates", context do
        
    end

    test "ensure that blocs with roots of this plants are selected as candidates and added as used", context do
        
    end

    test "ensure candidates are within context bounds" do 

    end

    test "ensure that adding a root updates appropriately next potential candidates appropriately" do

    end

    test "ensure generated absorptions are duplicated(and reverted) in case of 'both' matching" do
    end

    test "ensure generated absorptions are reverted in case of right matching" do 

    end

    test "ensure generated absorptions are sorted according to context" do 

    end

    test "ensure generated rejections are duplicated(and reverted) in case of 'both' matching" do
    end

    test "ensure generated rejections are reverted in case of right matching" do 

    end

    test "ensure generated rejections are sorted according to context" do 

    end

    test "ensure generated rejections and absorptions components are filled" do 

    end
end