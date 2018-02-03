defmodule UpsilonGarden.Plant.PlantCycleTest do
    use ExUnit.Case, async: false
    alias UpsilonGarden.{Repo,PlantCycle}
    alias UpsilonGarden.Cycle.CycleEvolution
    alias UpsilonGarden.GardenProjection
    alias UpsilonGarden.GardenProjection.{Alteration,Plant}
    alias UpsilonGarden.GardenData.{Component}
    
    setup_all do
      # Allows Ecto to exists here:
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    end

    test "determine date of completion based on projection" do
      projection = 
          %Plant{
            plant_id: 0,
            alterations: [
              %Alteration{
                component: "ABC",
                rate: 100.0,
                event_type: Alteration.absorption()
              }
            ]
          }

      plant = %UpsilonGarden.Plant {
        id: 0,
        content: %UpsilonGarden.PlantContent {
          contents: [
            %Component{
              composition: "AB",
              quantity: 20
            }
          ],
          max_size: 1000,
          current_size: 0
        },
        cycle: %PlantCycle {
          level: 10,
          part: "roots",
          evolutions: [
            %CycleEvolution{ 
              pivot: 0,
              objectives: [
                %Component{
                  composition: "AB",
                  quantity: 100
                }
              ]
            }
          ]
        }
      }

      turn = PlantCycle.compute_next_event_turns(plant, projection)

      assert turn == 1
    end

    test "when a projection can't determine end date, it should return unable" do
      projection =
          %Plant{
            plant_id: 0,
            alterations: [
              %Alteration{
                component: "ABC",
                rate: 100.0,
                event_type: Alteration.absorption()
              }
            ]
          }


      plant = %UpsilonGarden.Plant {
        id: 0,
        content: %UpsilonGarden.PlantContent {
          contents: [
            %Component{
              composition: "AB",
              quantity: 20
            }
          ],
          max_size: 1000,
          current_size: 0
        },
        cycle: %PlantCycle {
          level: 10,
          part: "roots",
          evolutions: [
            %CycleEvolution{ 
              pivot: 0,
              objectives: [
                %Component{
                  composition: "RT",
                  quantity: 100
                }
              ]
            }
          ]
        }
      }
      turn = PlantCycle.compute_next_event_turns(plant, projection)

      assert turn == :unable
    end

    @tag not_implemented: true
    test "determine ability to complete a cycle" do
      plant = %UpsilonGarden.Plant {
        id: 0,
        content: %UpsilonGarden.PlantContent {
            contents: [
            %Component{
              composition: "AB",
              quantity: 20
            }
          ],
          max_size: 1000,
          current_size: 0
        },
        cycle: %PlantCycle {
          part: "roots"
        }
      }


    end

    @tag not_implemented: true
    test "in case of tie for a cycle to be completed, deepest first mode" do

    end

    @tag not_implemented: true
    test "cycle completion triggers regeneration of structure" do

    end

    @tag not_implemented: true
    test "cycle not completed in time triggers removal of structure points" do

    end

    @tag not_implemented: true
    test "upon reaching 0 structure points of a non vital cycle restart cycle at level 0" do

    end

    @tag not_implemented: true
    test "upon reaching 0 structure points of a vital cycle destroy plant" do

    end
    
    @tag not_implemented: true
    test "cycle completion updates most cycle attributes" do

    end

    @tag not_implemented: true
    test "cycle completion triggers a pivot" do

    end

    @tag not_implemented: true
    test "cycle completion triggers appearance of new cycles" do

    end

    @tag not_implemented: true
    test "cycle completion depletes plants stores" do

    end
end
