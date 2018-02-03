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
          %GardenProjection.Plant{
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
          part: :roots,
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

      cycle = [
        %PlantCycle {
          level: 10,
          part: :roots,
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
      ]

      assert [{:roots,1,0}] == PlantCycle.compute_next_event_by_cycle(plant, cycle, projection, [], 0)
    end


    test "seeks only accessible dependencies" do 
      cycle = 
      %PlantCycle{
        part: :roots,
        level: 10,
        evolutions: [
          %CycleEvolution{ 
            pivot: 5,
            dependents: [
              %PlantCycle{ 
                part: :leaves,
                level: 5,
                evolutions: [ 
                  %CycleEvolution{ 
                    pivot: 15,
                    dependents: [
                      %PlantCycle{
                        part: :berries,
                        level: 0,
                        evolutions: [
                          %CycleEvolution{
                            pivot: 6
                          }
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
          }, 
          
          %CycleEvolution{ 
            pivot: 15,
            dependents: [
              %PlantCycle{ 
                part: :flower,
                level: 0,
                evolutions: [ 
                  %CycleEvolution{ 
                    pivot: 15,
                    dependents: [
                      %PlantCycle{
                        part: :fruit,
                        level: 0,
                        evolutions: [
                          %CycleEvolution{
                            pivot: 6
                          }
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }

      assert [
        %PlantCycle{part: :leaves}
      ] = PlantCycle.dependents(cycle)
    end

    test "seeks only accessible objectives" do 
      cycle = %PlantCycle {
        level: 10,
        part: :roots,
        evolutions: [
          %CycleEvolution{ 
            pivot: 0,
            objectives: [
              %Component{
                composition: "AB",
                quantity: 100
              }
            ]
          }, 
          %CycleEvolution{ 
            pivot: 2,
            objectives: [
              %Component{
                composition: "CD",
                quantity: 100
              }
            ]
          },
          %CycleEvolution{ 
            pivot: 15,
            objectives: [
              %Component{
                composition: "ZE",
                quantity: 100
              }
            ]
          }
        ]
      }

      assert [
        %Component{
          composition: "AB",
          quantity: 100
        },
        %Component{
          composition: "CD",
          quantity: 100
        }
      ] = PlantCycle.objectives(cycle)
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
          part: :roots,
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

    test "based on plant content, can find appropriate items for cycle evolution" do 
      content =  %UpsilonGarden.PlantContent {
        contents: [
          %Component{
            composition: "AB",
            quantity: 20
          },%Component{
            composition: "CD",
            quantity: 20
          },
        ],
        max_size: 1000,
        current_size: 40
      }

      assert [%Component{
        composition: "AB",
        quantity: 20
      }] = UpsilonGarden.PlantContent.find_content_matching(content, "A")
    end

    

    test "based on projection, can find appropriate items for cycle evolution" do 
      alterations =  [ 
        %Alteration{
          component: "ABC", 
          rate: 10.0,
          event_type: Alteration.absorption
        } , 
        %Alteration{
          component: "ABD", 
          rate: 10.0,
          event_type: Alteration.absorption
        }, 
        %Alteration{
          component: "EDT", 
          rate: 10.0,
          event_type: Alteration.absorption
        }
      ]

      assert [%Alteration{
        component: "ABD",
        rate: 10.0
      },%Alteration{
        component: "ABC",
        rate: 10.0
      }] = Alteration.find_alterations_matching(alterations, "A")
    end

    test "ensure that objective get correctly summed up" do 
      alterations =  [ 
        %Alteration{
          component: "ABC", 
          rate: 100.0,
          event_type: Alteration.absorption
        } , 
        %Alteration{
          component: "ABD", 
          rate: 10.0,
          event_type: Alteration.absorption
        }, 
        %Alteration{
          component: "EDT", 
          rate: 10.0,
          event_type: Alteration.absorption
        }
      ]

      content =  %UpsilonGarden.PlantContent {
        contents: [
          %Component{
            composition: "AB",
            quantity: 20.0
          },%Component{
            composition: "CD",
            quantity: 20.0
          },
        ],
        max_size: 1000.0,
        current_size: 40.0
      }

      objective = %Component{
        composition: "A",
        quantity: 100
      }

      assert %{
        composition: "A",
        target: 100, 
        store: 20.0,
        income: 110.0,
        'completable?': true,
        completion: 1,
      } = PlantCycle.make_summary(objective, content, alterations)
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
          current_size: 20
        },
        cycle: %PlantCycle {
          part: :roots
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
