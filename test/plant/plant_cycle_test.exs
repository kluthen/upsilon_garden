defmodule UpsilonGarden.Plant.PlantCycleTest do
    use ExUnit.Case, async: false
    require Logger
    alias UpsilonGarden.{Repo,PlantCycle,PlantContent}
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
        content: PlantContent.build_content(max_size: 1000.0, contents: [Component.build_component(composition: "AB", quantity: 20.0)]),
        cycle: PlantCycle.build_cycle(level: 1, part: :roots, objectives: [Component.build_component(composition: "AB", quantity: 100.0)]) 
      }

      res = PlantCycle.compute_next_event_by_cycle(plant, [plant.cycle], projection, [], 0)
      assert [{:roots,1,0}] == res
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
          objectives: [
            %Component{
              composition: "RT",
              quantity: 100
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
        quantity: 100.0
      }

      assert %{
        composition: "A",
        target: 100.0, 
        store: 20.0,
        income: 110.0,
        'completable?': true,
        completion: 1,
      } = PlantCycle.make_summary(objective, content, alterations)
    end

    test "determine ability to complete a cycle" do
      plant = %UpsilonGarden.Plant {
        id: 0,
        content: %UpsilonGarden.PlantContent {
          contents: [
            %Component{
              composition: "AB",
              quantity: 200.0
            }
          ],
          max_size: 1000.0,
          current_size: 200.0
        },
        cycle: %PlantCycle {
          level: 1,
          part: :roots,
          objectives: [
            %Component{
              composition: "AB",
              quantity: 100.0
            }
          ]
        }
      }

      assert [%PlantCycle{
        part: :roots
      }] = PlantCycle.completable(plant)
    end
    
    test "completable cycles are sorted by level, lower level first, in case of tie use alpha ordering." do
      plant = %UpsilonGarden.Plant {
        id: 0,
        content: %UpsilonGarden.PlantContent {
          contents: [
            %Component{
              composition: "AB",
              quantity: 200.0
            }
          ],
          max_size: 1000.0,
          current_size: 200.0
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
                  quantity: 500.0
                }
              ], 
              dependents: [
                %PlantCycle {
                  level: 9,
                  part: :leaves,
                  evolutions: [
                    %CycleEvolution{ 
                      pivot: 0,
                      objectives_gain: 0,
                      objectives: [
                        %Component{
                          composition: "AB",
                          quantity: 50.0
                        }
                      ]
                    }
                  ]
                }, 
                %PlantCycle {
                  level: 10,
                  part: :flowers,
                  evolutions: [
                    %CycleEvolution{ 
                      pivot: 0,
                      objectives_gain: 0,
                      objectives: [
                        %Component{
                          composition: "AB",
                          quantity: 10.0
                        }
                      ]
                    }
                  ]
                },
                %PlantCycle {
                  level: 10,
                  part: :bulbs,
                  evolutions: [
                    %CycleEvolution{ 
                      pivot: 0,
                      objectives_gain: 0,
                      objectives: [
                        %Component{
                          composition: "AB",
                          quantity: 25.0
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
      }

      # order matters !
      assert [%PlantCycle{part: :leaves},%PlantCycle{part: :bulbs},%PlantCycle{part: :flowers}] = PlantCycle.completable(plant)
    end
    
    test "cycle completion depletes plants stores and updates cycle attributes" do
      plant = %UpsilonGarden.Plant {
        id: 0,
        content: %UpsilonGarden.PlantContent {
          contents: [
            %Component{
              composition: "AB",
              quantity: 200.0,
              used: 0.0
            }
          ],
          max_size: 1000.0,
          current_size: 200.0
        },
        cycle: %PlantCycle {
          level: 10,
          part: :roots,
          storage: 100,
          structure_current: 100,
          structure_max: 100,
          objectives: [
            %Component{
              composition: "AB",
              quantity: 100.0
            }
          ], 
          evolutions: [
            %CycleEvolution{ 
              pivot: 0,
              objectives_gain: 1,
              storage_gain: 1,
              success_impact_gain: 1,
              structure_gain: 1
            }
          ]
        }
      }

      cycle = PlantCycle.completable(plant)
      plant = PlantCycle.complete(plant, cycle)

      component = PlantContent.find(plant.content,"AB")

      assert %Component{
        used: 100.0,
        quantity: 100.0
      } = component

      assert %PlantCycle{
        level: 11,
        part: :roots,
        storage: 101,
        structure_current: 101,
        structure_max: 101,
        objectives: [
          %Component{
            composition: "AB",
            quantity: 101.0
          }
        ]
      } = plant.cycle
    end
    
    test "multiple cycle completion depletes plants stores" do
      plant = %UpsilonGarden.Plant {
        id: 0,
        content: %UpsilonGarden.PlantContent {
          contents: [
            %Component{
              composition: "AB",
              quantity: 200.0
            }
          ],
          max_size: 1000.0,
          current_size: 200.0
        },
        cycle: %PlantCycle {
          level: 10,
          part: :roots,
          storage: 100,
          structure_current: 100,
          structure_max: 100,
          objectives: [
            %Component{
              composition: "AB",
              quantity: 500.0
            }
          ],
          evolutions: [
            %CycleEvolution{ 
              pivot: 0,
              objectives_gain: 0,
              dependents: [
                %PlantCycle {
                  level: 9,
                  part: :leaves,
                  storage: 100,
                  structure_current: 100,
                  structure_max: 100,
                  objectives: [
                    %Component{
                      composition: "AB",
                      quantity: 50.0
                    }
                  ],
                  evolutions: [
                    %CycleEvolution{ 
                      pivot: 0,
                      objectives_gain: 0  ,
                      storage_gain: 0,
                      success_impact_gain: 0,
                      structure_gain: 0                    
                    }
                  ]
                }, 
                %PlantCycle {
                  level: 10,
                  part: :flowers,
                  storage: 100,
                  structure_current: 100,
                  structure_max: 100,
                  objectives: [
                    %Component{
                      composition: "AB",
                      quantity: 10.0
                    }
                  ],
                  evolutions: [
                    %CycleEvolution{ 
                      pivot: 0,
                      objectives_gain: 0 ,
                      storage_gain: 0,
                      success_impact_gain: 0,
                      structure_gain: 0                     
                    }
                  ]
                },
                %PlantCycle {
                  level: 10,
                  part: :bulbs,
                  storage: 100,
                  structure_current: 100,
                  structure_max: 100,
                  objectives: [
                    %Component{
                      composition: "AB",
                      quantity: 25.0
                    }
                  ],
                  evolutions: [
                    %CycleEvolution{ 
                      pivot: 0,
                      objectives_gain: 0,
                      storage_gain: 0,
                      success_impact_gain: 0,
                      structure_gain: 0
                    }
                  ]
                }
              ]
            }
          ]          
        }
      }

      cycle = PlantCycle.completable(plant)
      plant = PlantCycle.complete(plant, cycle)


      component = PlantContent.find(plant.content,"AB")

      assert %Component{
        used: 85.0,
        quantity: 115.0
      } = component
    end

    
    test "multiple cycle completion may not all succeed" do
      plant = %UpsilonGarden.Plant {
        id: 0,
        content: %UpsilonGarden.PlantContent {
          contents: [
            %Component{
              composition: "AB",
              quantity: 200.0
            }
          ],
          max_size: 1000.0,
          current_size: 200.0
        },
        cycle: %PlantCycle {
          level: 10,
          part: :roots,
          storage: 100,
          structure_current: 100,
          structure_max: 100,
          objectives: [
            %Component{
              composition: "AB",
              quantity: 500
            }
          ],
          evolutions: [
            %CycleEvolution{ 
              pivot: 0,
              objectives_gain: 0,
              dependents: [
                %PlantCycle {
                  level: 9,
                  part: :leaves,
                  storage: 100,
                  structure_current: 100,
                  structure_max: 100,
                  objectives: [
                    %Component{
                      composition: "AB",
                      quantity: 150.0
                    }
                  ],
                  evolutions: [
                    %CycleEvolution{ 
                      pivot: 0,
                      objectives_gain: 0,
                      storage_gain: 0,
                      success_impact_gain: 0,
                      structure_gain: 0
                    }
                  ]
                }, 
                %PlantCycle {
                  level: 10,
                  part: :flowers,
                  storage: 100,
                  structure_current: 100,
                  structure_max: 100,
                  objectives: [
                    %Component{
                      composition: "AB",
                      quantity: 10.0
                    }
                  ],
                  evolutions: [
                    %CycleEvolution{ 
                      pivot: 0,
                      objectives_gain: 0,
                      storage_gain: 0,
                      success_impact_gain: 0,
                      structure_gain: 0
                    }
                  ]
                },
                %PlantCycle {
                  level: 10,
                  part: :bulbs,
                  storage: 100,
                  structure_current: 100,
                  structure_max: 100,
                  objectives: [
                    %Component{
                      composition: "AB",
                      quantity: 100.0
                    }
                  ],
                  evolutions: [
                    %CycleEvolution{ 
                      pivot: 0,
                      objectives_gain: 0,
                      storage_gain: 0,
                      success_impact_gain: 0,
                      structure_gain: 0
                    }
                  ]
                }
              ]
            }
          ]          
        }
      }

      cycle = PlantCycle.completable(plant)
      plant = PlantCycle.complete(plant, cycle)

      component = PlantContent.find(plant.content,"AB")

      assert %Component{
        used: 160.0,
        quantity: 40.0
      } = component

      sub_cycles = Enum.at(plant.cycle.evolutions,0).dependents
      |> PlantCycle.sort
      
      assert [
        %PlantCycle{part: :bulbs, level: 10},
        %PlantCycle{part: :leaves, level: 10},
        %PlantCycle{part: :flowers, level: 11}
      ] = sub_cycles 
      
    end
    
    test "cycle completion triggers regeneration of structure" do
      plant = %UpsilonGarden.Plant {
        id: 0,
        content: %UpsilonGarden.PlantContent {
          contents: [
            %Component{
              composition: "AB",
              quantity: 200.0,
              used: 0.0
            }
          ],
          max_size: 1000.0,
          current_size: 200.0
        },
        cycle: %PlantCycle {
          level: 10,
          part: :roots,
          storage: 100,
          structure_current: 50,
          structure_max: 100,
          objectives: [
            %Component{
              composition: "AB",
              quantity: 100.0
            }
          ], 
          evolutions: [
            %CycleEvolution{ 
              pivot: 0,
              objectives_gain: 1,
              storage_gain: 1,
              success_impact_gain: 20,
              structure_gain: 1
            }
          ]
        }
      }

      cycle = PlantCycle.completable(plant)
      plant = PlantCycle.complete(plant, cycle)

      component = PlantContent.find(plant.content,"AB")

      assert %Component{
        used: 100.0,
        quantity: 100.0
      } = component

      assert %PlantCycle{
        level: 11,
        part: :roots,
        storage: 101,
        structure_current: 71,
        structure_max: 101,
        objectives: [
          %Component{
            composition: "AB",
            quantity: 101.0
          }
        ]
      } = plant.cycle
    end

    
    test "cycle completion triggers a pivot" do

      plant = %UpsilonGarden.Plant {
        id: 0,
        content: %UpsilonGarden.PlantContent {
          contents: [
            Component.build_component(composition: "AB", quantity: 500.0),
            Component.build_component(composition: "CD", quantity: 500.0)
          ],
          max_size: 1000.0,
          current_size: 400.0
        },
        cycle: %PlantCycle {
          level: 10,
          part: :roots,
          storage: 100,
          structure_current: 50,
          structure_max: 100,
          objectives: [
            %Component{
              composition: "AB",
              quantity: 100.0
            }
          ], 
          evolutions: [
            %CycleEvolution{ 
              pivot: 0,
              objectives_gain: 0,
              storage_gain: 1,
              success_impact_gain: 20,
              structure_gain: 1
            }, 
            %CycleEvolution{ 
              pivot: 11,
              objectives_gain: 0,
              storage_gain: 1,
              success_impact_gain: 20,
              structure_gain: 1, 
              objectives: [
                Component.build_component(composition: "CD", quantity: 100.0)
              ]
            }
          ]
        }
      }

      cycle = PlantCycle.completable(plant)
      plant = PlantCycle.complete(plant, cycle)
      
      cycle = PlantCycle.completable(plant)
      plant = PlantCycle.complete(plant, cycle)

      component = PlantContent.find(plant.content,"AB")

      assert %Component{
        used: 200.0,
        quantity: 300.0
      } = component

      component = PlantContent.find(plant.content,"CD")

      assert %Component{
        used: 100.0,
        quantity: 400.0
      } = component

    end

    test "cycle completion triggers appearance of new cycles" do

      plant = %UpsilonGarden.Plant {
        id: 0,
        content: %UpsilonGarden.PlantContent {
          contents: [
            Component.build_component(composition: "AB", quantity: 500.0),
            Component.build_component(composition: "CD", quantity: 500.0)
          ],
          max_size: 1000.0,
          current_size: 400.0
        },
        cycle: %PlantCycle {
          level: 10,
          part: :roots,
          storage: 100,
          structure_current: 50,
          structure_max: 100,
          objectives: [
            %Component{
              composition: "AB",
              quantity: 100.0
            }
          ], 
          evolutions: [
            %CycleEvolution{ 
              pivot: 0,
              objectives_gain: 0,
              storage_gain: 1,
              success_impact_gain: 20,
              structure_gain: 1,
              dependents: [
                %PlantCycle{
                  level: 0,
                  part: :leaves,
                  evolutions: [
                    %CycleEvolution{ 
                      pivot: 0,
                      objectives_gain: 0,
                      objectives: [
                        %Component{
                          composition: "CD",
                          quantity: 50.0
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
      }

      cycle = PlantCycle.completable(plant)
      plant = PlantCycle.complete(plant, cycle)
      
      cycle = PlantCycle.completable(plant)
      assert [%PlantCycle{part: :leaves}] = cycle
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
    test "Cycle sorting should follow plant-level rules(level, alpha, depth)" do 

    end

    @tag not_implemented: true
    test "Cycle selection should follow plant-level rules(level, alpha, depth)" do 

    end

    @tag not_implemented: true
    test "Cycle completion component selection should follow cycle-level rules(same as selection)" do 
      
    end
end
