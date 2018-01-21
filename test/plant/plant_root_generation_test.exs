defmodule UpsilonGarden.Plant.PlantRootGenerationTest do 
    use ExUnit.Case, async: false
    import Ecto.Query
    import Ecto.Changeset
    import Ecto
    require Logger
    alias UpsilonGarden.{User,Garden,Repo,Plant,PlantContext,PlantData,GardenData,PlantContent}
    alias UpsilonGarden.GardenData.{Bloc,Influence,Component}
    alias UpsilonGarden.PlantData.{PlantRoot,PlantRootContext}

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

      # Sets context to have garden, user, plant.
      {:ok, garden: garden, user: user, plant: plant}
    end
    

    test "ensure that stone blocs aren't selectable", context do
        fixed_garden_data = GardenData.force_update_bloc(context.garden.data, 4,1, fn bloc ->
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

        {usable,used} = PlantRoot.is_bloc_usable?(4,1,4,fixed_root_ctx,fixed_garden_data,0)

        assert false == usable
        assert false == used
    end

    test "ensure that other prime roots blocs aren't selectable", context do        
        influence = %Influence{
            type: Influence.plant(),
            plant_id: 0,
            prime_root: true
        }
        
        fixed_garden_data = GardenData.force_update_bloc(context.garden.data, 4,1, fn bloc ->
            %Bloc{bloc|
                influences: [influence]
            }
        end)
        # Ensure root context seeks bloc in 4,1
        fixed_root_ctx = Map.put(context.plant.context.prime_root, :depth, 3)
        fixed_root_ctx = Map.put(fixed_root_ctx, :max_top_width, 1)
        fixed_root_ctx = Map.put(fixed_root_ctx, :max_bottom_width, 1)
        # Should only seek to go in depth, can't go sideway thus
        {usable,used} = PlantRoot.is_bloc_usable?(4,1,4,fixed_root_ctx,fixed_garden_data,context.plant.id)

        assert false == usable
        assert false == used
    end

    test "ensure that our roots blocs aren't selectable and marked as used", context do        
        influence = %Influence{
            type: Influence.plant(),
            plant_id: context.plant.id
        }
        
        fixed_garden_data = GardenData.force_update_bloc(context.garden.data, 4,1, fn bloc ->
            %Bloc{bloc|
                influences: [influence]
            }
        end)
        # Ensure root context seeks bloc in 4,1
        fixed_root_ctx = Map.put(context.plant.context.prime_root, :depth, 3)
        fixed_root_ctx = Map.put(fixed_root_ctx, :max_top_width, 1)
        fixed_root_ctx = Map.put(fixed_root_ctx, :max_bottom_width, 1)
        # Should only seek to go in depth, can't go sideway thus
        {usable,used} = PlantRoot.is_bloc_usable?(4,1,4,fixed_root_ctx,fixed_garden_data,context.plant.id)

        assert false == usable
        assert true == used
    end
    
    test "ensure that other roots blocs are selectable and not used", context do        
        influence = %Influence{
            type: Influence.plant(),
            plant_id: 0,
            prime_root: false
        }
        
        fixed_garden_data = GardenData.force_update_bloc(context.garden.data, 4,1, fn bloc ->
            %Bloc{bloc|
                influences: [influence]
            }
        end)
        # Ensure root context seeks bloc in 4,1
        fixed_root_ctx = Map.put(context.plant.context.prime_root, :depth, 3)
        fixed_root_ctx = Map.put(fixed_root_ctx, :max_top_width, 1)
        fixed_root_ctx = Map.put(fixed_root_ctx, :max_bottom_width, 1)
        # Should only seek to go in depth, can't go sideway thus
        {usable,used} = PlantRoot.is_bloc_usable?(4,1,4,fixed_root_ctx,fixed_garden_data,context.plant.id)

        assert true == usable
        assert false == used
    end

    test "ensure that stone blocs aren't selected as candidates", context do
        # As by default garden provides 3 lines clear of stones, need to add one.
        # Plant is expected to grow on segment 4
        # Can't have a stone bloc on segment 4 line 0 
        # (that would be lame ... shouldn't be able to add such plants ...) 
        
        fixed_garden_data = Enum.reduce(3..5, context.garden.data, fn x, gd -> 
            GardenData.force_update_bloc(gd, x,1, fn bloc ->
                %Bloc{bloc|
                type: Bloc.stone(),
                components: [],
                influences: [],
                sources: []
                }
            end)
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
        assert Map.has_key?(valid_blocs, 1) == true
        assert length(valid_blocs[1]) == 0
        assert Map.has_key?(valid_blocs, 2) == true
        assert length(valid_blocs[2]) == 1
    end

    test "ensure that blocs with prime roots of other plants aren't selected as candidates", context do
        # Add a line of prime root of another plant on depth 1; plants may never have id of 0 but that should be enought

        influence = %Influence{
            type: Influence.plant(),
            plant_id: 0,
            prime_root: true
        }
        
        fixed_garden_data = Enum.reduce(3..5, context.garden.data, fn x, gd -> 
            GardenData.force_update_bloc(gd, x,1, fn bloc ->
                %Bloc{bloc|
                    influences: [influence]
                }
            end)
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
        assert Map.has_key?(valid_blocs, 1) == true
        assert length(valid_blocs[1]) == 0
        assert Map.has_key?(valid_blocs, 2) == true
        assert length(valid_blocs[2]) == 1
    end

    test "ensure that blocs with prime roots of this plants aren't selected as candidates but added as used", context do
        influence = %Influence{
            type: Influence.plant(),
            plant_id: context.plant.id,
            prime_root: true
        }
        
        fixed_garden_data = GardenData.force_update_bloc(context.garden.data, 4,1, fn bloc ->
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
        # valid blocs should only contains 4,0  4,2
        # used should be 1

        assert Map.has_key?(valid_blocs, 0) == true
        assert length(valid_blocs[0]) == 1
        assert [4] = valid_blocs[0] 
        assert Map.has_key?(valid_blocs, 1) == true
        assert length(valid_blocs[1]) == 0
        assert Map.has_key?(valid_blocs, 2) == true
        assert length(valid_blocs[2]) == 1
        assert [4] = valid_blocs[2] 
        assert used == 1
    end

    test "ensure that blocs with roots of other plants are selected as candidates", context do
        influence = %Influence{
            type: Influence.plant(),
            plant_id: 0
        }
        
        fixed_garden_data = GardenData.force_update_bloc(context.garden.data, 4,1, fn bloc ->
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
        # used should be 0

        assert Map.has_key?(valid_blocs, 0) == true
        assert length(valid_blocs[0]) == 1
        assert [4] = valid_blocs[0] 
        assert Map.has_key?(valid_blocs, 1) == true
        assert length(valid_blocs[1]) == 1
        assert [4] = valid_blocs[1] 
        assert Map.has_key?(valid_blocs, 2) == true
        assert length(valid_blocs[2]) == 1
        assert [4] = valid_blocs[2] 
        assert used == 0
    end

    test "ensure that blocs with roots of this plants are not selected as candidates and added as used", context do
        influence = %Influence{
            type: Influence.plant(),
            plant_id: context.plant.id
        }
        
        fixed_garden_data = GardenData.force_update_bloc(context.garden.data, 4,1, fn bloc ->
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
        # valid blocs should only contains 4,0  4,2
        # used should be 1

        assert Map.has_key?(valid_blocs, 0) == true
        assert length(valid_blocs[0]) == 1
        assert [4] = valid_blocs[0] 
        assert Map.has_key?(valid_blocs, 1) == true
        assert length(valid_blocs[1]) == 0
        assert Map.has_key?(valid_blocs, 2) == true
        assert length(valid_blocs[2]) == 1
        assert [4] = valid_blocs[2] 
        assert used == 1
    end

    test "ensure candidates are within context bounds ( top < bottom )" do 
        assert PlantRoot.bloc_is_in_range?(3,0,1,3,3,4) == false # too much on the top left
        assert PlantRoot.bloc_is_in_range?(5,0,1,3,3,4) == false # too much on the top left
        assert PlantRoot.bloc_is_in_range?(4,0,1,3,3,4) == true # right on the spot
        assert PlantRoot.bloc_is_in_range?(4,1,1,3,3,4) == true # right on the spot
        assert PlantRoot.bloc_is_in_range?(4,2,1,3,3,4) == true # right on the spot
        assert PlantRoot.bloc_is_in_range?(3,2,1,3,3,4) == true # right on the spot
        assert PlantRoot.bloc_is_in_range?(5,2,1,3,3,4) == true # right on the spot
        assert PlantRoot.bloc_is_in_range?(2,2,1,3,3,4) == false # too much on the left
        assert PlantRoot.bloc_is_in_range?(6,2,1,3,3,4) == false # too much on the right
    end

    test "ensure candidates are within context bounds  ( top > bottom )" do 
        assert PlantRoot.bloc_is_in_range?(2,0,3,1,3,4) == false # too much on the top left
        assert PlantRoot.bloc_is_in_range?(6,0,3,1,3,4) == false # too much on the top left
        assert PlantRoot.bloc_is_in_range?(3,0,3,1,3,4) == true # right on the spot
        assert PlantRoot.bloc_is_in_range?(5,0,3,1,3,4) == true # right on the spot
        assert PlantRoot.bloc_is_in_range?(4,0,3,1,3,4) == true # right on the spot
        assert PlantRoot.bloc_is_in_range?(4,1,3,1,3,4) == true # right on the spot
        assert PlantRoot.bloc_is_in_range?(4,2,3,1,3,4) == true # right on the spot
        assert PlantRoot.bloc_is_in_range?(3,2,3,1,3,4) == false # too much on the left
        assert PlantRoot.bloc_is_in_range?(5,2,3,1,3,4) == false # too much on the right
    end
    
    test "ensure candidates are within context bounds  ( top = bottom )" do 
        assert PlantRoot.bloc_is_in_range?(2,0,3,3,3,4) == false # too much on the top left
        assert PlantRoot.bloc_is_in_range?(2,1,3,3,3,4) == false # too much on the top left
        assert PlantRoot.bloc_is_in_range?(2,2,3,3,3,4) == false # too much on the top left
        assert PlantRoot.bloc_is_in_range?(6,0,3,3,3,4) == false # too much on the top right
        assert PlantRoot.bloc_is_in_range?(6,1,3,3,3,4) == false # too much on the top right
        assert PlantRoot.bloc_is_in_range?(6,2,3,3,3,4) == false # too much on the top right
        assert PlantRoot.bloc_is_in_range?(4,2,3,3,3,4) == true # right on the spot
        assert PlantRoot.bloc_is_in_range?(3,2,3,3,3,4) == true # right on the spot
        assert PlantRoot.bloc_is_in_range?(5,2,3,3,3,4) == true # right on the spot
        assert PlantRoot.bloc_is_in_range?(4,1,3,3,3,4) == true # right on the spot
        assert PlantRoot.bloc_is_in_range?(3,1,3,3,3,4) == true # right on the spot
        assert PlantRoot.bloc_is_in_range?(5,1,3,3,3,4) == true # right on the spot
        assert PlantRoot.bloc_is_in_range?(4,0,3,3,3,4) == true # right on the spot
        assert PlantRoot.bloc_is_in_range?(3,0,3,3,3,4) == true # right on the spot
        assert PlantRoot.bloc_is_in_range?(5,0,3,3,3,4) == true # right on the spot
    end

    test "ensure candidates are selected within context bounds  ( top < bottom )",context do 
        fixed_root_ctx = Map.put(context.plant.context.prime_root, :depth, 3)
        fixed_root_ctx = Map.put(fixed_root_ctx, :max_top_width, 1)
        fixed_root_ctx = Map.put(fixed_root_ctx, :max_bottom_width, 3)

        {valid_blocs, _used} = PlantRoot.seek_valid_blocs(context.garden.data, context.plant.data, fixed_root_ctx )

        assert Map.has_key?(valid_blocs, 0) == true
        assert length(valid_blocs[0]) == 1
        assert [4] = valid_blocs[0]
        assert Map.has_key?(valid_blocs, 2) == true
        assert length(valid_blocs[2]) == 3
        assert [3,4,5] = Enum.sort(valid_blocs[2])
    end
    
    test "ensure candidates are selected within context bounds  ( top > bottom )",context do 
        fixed_root_ctx = Map.put(context.plant.context.prime_root, :depth, 3)
        fixed_root_ctx = Map.put(fixed_root_ctx, :max_top_width, 3)
        fixed_root_ctx = Map.put(fixed_root_ctx, :max_bottom_width, 1)

        {valid_blocs, _used} = PlantRoot.seek_valid_blocs(context.garden.data, context.plant.data, fixed_root_ctx )

        assert Map.has_key?(valid_blocs, 0) == true
        assert length(valid_blocs[0]) == 3
        assert [3,4,5] = Enum.sort(valid_blocs[0])
        assert Map.has_key?(valid_blocs, 2) == true
        assert length(valid_blocs[2]) == 1
        assert [4] = valid_blocs[2] 
    end


    test "ensure candidates are selected within context bounds  ( top = bottom )",context do 
        fixed_root_ctx = Map.put(context.plant.context.prime_root, :depth, 3)
        fixed_root_ctx = Map.put(fixed_root_ctx, :max_top_width, 3)
        fixed_root_ctx = Map.put(fixed_root_ctx, :max_bottom_width, 3)

        {valid_blocs, _used} = PlantRoot.seek_valid_blocs(context.garden.data, context.plant.data, fixed_root_ctx )

        assert Map.has_key?(valid_blocs, 0) == true
        assert length(valid_blocs[0]) == 3
        assert [3,4,5] = Enum.sort(valid_blocs[0])
        assert Map.has_key?(valid_blocs, 1) == true
        assert length(valid_blocs[1]) == 3
        assert [3,4,5] = Enum.sort(valid_blocs[1]) 
        assert Map.has_key?(valid_blocs, 2) == true
        assert length(valid_blocs[2]) == 3
        assert [3,4,5] = Enum.sort(valid_blocs[2])
    end

    test "ensure candidates are within context bounds; depth check ",context do 
        fixed_root_ctx = Map.put(context.plant.context.prime_root, :depth, 3)
        fixed_root_ctx = Map.put(fixed_root_ctx, :max_top_width, 1)
        fixed_root_ctx = Map.put(fixed_root_ctx, :max_bottom_width, 1)
        fixed_root_ctx = Map.put(fixed_root_ctx, :fill_rate, 1)

        {valid_blocs, _used} = PlantRoot.seek_valid_blocs(context.garden.data, context.plant.data, fixed_root_ctx )

        assert Map.has_key?(valid_blocs, 0) == true
        assert Map.has_key?(valid_blocs, 1) == true
        assert Map.has_key?(valid_blocs, 2) == true
        assert Map.has_key?(valid_blocs, 3) == false
    end

    test "ensure neighbours selection provide only results within validated blocs" do 
        valid_blocs = %{
            0 => [3],
            1 => [4]
        }
        assert [{3,0},{4,1}] = PlantRoot.get_valid_neighbours(4,0,valid_blocs)

        valid_blocs = %{
        }
        assert [] = PlantRoot.get_valid_neighbours(4,0,valid_blocs)
    end

    test "ensure that adding a root updates appropriately next potential candidates appropriately" do
        valid_blocs = %{
            0 => [3,4],
            1 => [3,4,5],
            2 => [3,4,5],
        }
        potential = [{4,0}]

        {nvalid_blocs, npotentials} = PlantRoot.add_neighbours_to_potentials(4,0, 0.5, valid_blocs, potential) 

        assert Map.has_key?(nvalid_blocs, 0)
        assert [3] = nvalid_blocs[0]
        assert length(npotentials) == 12
        assert {3,0} in npotentials
        assert {4,1} in npotentials
        assert Enum.count(npotentials, fn bloc -> bloc == {3,0} end)  == 6
        assert Enum.count(npotentials, fn bloc -> bloc == {4,1} end)  == 6

    end

    test "ensure generated rejections and absorptions are duplicated(and reverted) in case of 'both' matching" do
        root = %PlantRoot{
            absorption_matching: PlantRoot.both(),
            absorbers: [%Component{
                composition: "ABC",
                quantity: 2.0
            }],
            rejection_matching: PlantRoot.both(),
            rejecters: [%Component{
                composition: "ABC",
                quantity: 2.0
            }],
            selection_compo: PlantRoot.alpha()
        }

        result = PlantRoot.apply_selection_and_matching(root)
        assert length(result.absorbers) == 2
        assert [%Component{composition: "ABC"}, %Component{composition: "CBA"}] = result.absorbers
        assert length(result.rejecters) == 2
        assert [%Component{composition: "ABC"}, %Component{composition: "CBA"}] = result.rejecters
    end

    test "ensure generated rejections and absorptions are reverted in case of right matching" do 
        root = %PlantRoot{
            absorption_matching: PlantRoot.right(),
            absorbers: [%Component{
                composition: "ABC",
                quantity: 2.0
            }],
            rejection_matching: PlantRoot.right(),
            rejecters: [%Component{
                composition: "ABC",
                quantity: 2.0
            }],
            selection_compo: PlantRoot.alpha()
        }

        result = PlantRoot.apply_selection_and_matching(root)
        assert length(result.absorbers) == 1
        assert [%Component{composition: "CBA"}] = result.absorbers
        assert length(result.rejecters) == 1
        assert [%Component{composition: "CBA"}] = result.rejecters
    end

    test "ensure generated rejections and absorptions are sorted according to context" do 
        root = %PlantRoot{
            absorption_matching: PlantRoot.left(),
            absorbers: [%Component{
                composition: "ABC",
                quantity: 2.0
            },%Component{
                composition: "A",
                quantity: 4.0
            },%Component{
                composition: "YZ",
                quantity: 1.0
            }],
            rejection_matching: PlantRoot.left(),
            rejecters: [%Component{
                composition: "ABC",
                quantity: 2.0
            },%Component{
                composition: "A",
                quantity: 4.0
            },%Component{
                composition: "YZ",
                quantity: 1.0
            }],
            selection_compo: PlantRoot.weight()
        }

        result = PlantRoot.apply_selection_and_matching(root)
        assert length(result.absorbers) == 3
        assert [%Component{composition: "A"}, %Component{composition: "ABC"}, %Component{composition: "YZ"}] = result.absorbers
        assert length(result.rejecters) == 3
        assert [%Component{composition: "A"}, %Component{composition: "ABC"}, %Component{composition: "YZ"}] = result.rejecters

        root = Map.put(root, :selection_compo, PlantRoot.length())
        result = PlantRoot.apply_selection_and_matching(root)
        assert length(result.absorbers) == 3
        assert [%Component{composition: "A"}, %Component{composition: "YZ"}, %Component{composition: "ABC"}] = result.absorbers
        assert length(result.rejecters) == 3
        assert [%Component{composition: "A"}, %Component{composition: "YZ"}, %Component{composition: "ABC"}] = result.rejecters

        root = Map.put(root, :selection_compo, PlantRoot.quantity())
        result = PlantRoot.apply_selection_and_matching(root)
        assert length(result.absorbers) == 3
        assert [%Component{composition: "YZ"}, %Component{composition: "ABC"}, %Component{composition: "A"}] = result.absorbers
        assert length(result.rejecters) == 3
        assert [%Component{composition: "YZ"}, %Component{composition: "ABC"}, %Component{composition: "A"}] = result.rejecters
        
        root = Map.put(root, :selection_compo, PlantRoot.alpha())
        result = PlantRoot.apply_selection_and_matching(root)
        assert length(result.absorbers) == 3
        assert [%Component{composition: "A"}, %Component{composition: "ABC"}, %Component{composition: "YZ"}] = result.absorbers
        assert length(result.rejecters) == 3
        assert [%Component{composition: "A"}, %Component{composition: "ABC"}, %Component{composition: "YZ"}] = result.rejecters

        root = Map.put(root, :selection_compo, PlantRoot.random())
        result = PlantRoot.apply_selection_and_matching(root)
        assert length(result.absorbers) == 3
        assert length(result.rejecters) == 3
    end

    test "ensure generated rejections and absorptions components are filled" do 
        available_components = UpsilonGarden.Tools.prepare_range([{"AB",7}])

        components = PlantRootContext.generate_components(available_components,3)
        assert length(components) == 1
        assert [%{composition: "AB", quantity: 3}] = components

        result = PlantRoot.generate_components(components,[])
        assert length(result) == 1
        assert [%Component{composition: "AB", quantity: 3}] = result
    end
end