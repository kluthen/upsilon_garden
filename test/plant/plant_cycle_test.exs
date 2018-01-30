defmodule UpsilonGarden.Plant.PlantCycleTest do
    use ExUnit.Case, async: true
    alias UpsilonGarden.PlantCycle
    alias UpsilonGarden.GardenProjection
    alias UpsilonGarden.GardenProjection.{Alteration,Plant}

    @not_implemented
    test "determine date of completion based on projection" do
      projection = %GardenProjection{
        plants: [
          %Plant{
            plant_id: 0
            alterations: [
              %Alteration{
                component: "ABC",
                rate: 100.0,
                event_type: Alteration.absorption()
              }
            ]
          }
        ]
      }

      plant = %UpsilonGarden.Plant {
        id: 0,
        content: %UpsilonGarden.PlantContent {
          components: [
            %Component{
              composition: "AB",
              quantity: 20
            }
          ],
          max_size: 1000,
          current_size: 0
        }
        cycle: %PlantCycle {
          objectives: [
            %Component{
              composition: "AB",
              quantity: 100
            }
          ]
        }
      }

      turn = PlantCycle.compute_next_event_turns(plant, projection)

      assert turn == 1
    end

    @not_implemented
    test "determine ability to complete a cycle" do


      plant = %UpsilonGarden.Plant {
        id: 0,
        content: %UpsilonGarden.PlantContent {
          components: [
            %Component{
              composition: "AB",
              quantity: 20
            }
          ],
          max_size: 1000,
          current_size: 0
        }
        cycle: %PlantCycle {
          part: "roots"
        }
      }

      assert ["roots"] = PlantCycle.can_complete_cycle?(plant, projection)
    end

    @not_implemented
    test "in case of tie for a cycle to be completed, deepest first mode" do

    end

    @not_implemented
    test "in case of tie for a cycle to be completed, first mode" do

    end

    @not_implemented
    test "cycle completion triggers regeneration of structure" do

    end

    @not_implemented
    test "cycle not completed in time triggers removal of structure points" do

    end

    @not_implemented
    test "upon reaching 0 structure points of a non vital cycle restart cycle at level 0" do

    end

    @not_implemented
    test "upon reaching 0 structure points of a vital cycle destroy plant" do

    end

    @not_implemented
    test "turn completion with threshold out of bounds triggers removal of structure points" do

    end

    @not_implemented
    test "cycle completion updates most cycle attributes" do

    end

    @not_implemented
    test "cycle completion triggers a pivot" do

    end

    @not_implemented
    test "cycle completion triggers appearance of new cycles" do

    end

    @not_implemented
    test "cycle completion depletes plants stores" do

    end
end
