defmodule UpsilonGarden.Projection.ProjectionTest do
    use ExUnit.Case, async: false
    import Ecto.Query
    import Ecto.Changeset
    require Logger
    alias UpsilonGarden.{User,Garden,Repo,Plant,PlantContent,PlantContext,GardenProjection,PlantCycle}
    alias UpsilonGarden.GardenProjection.{Alteration}
    alias UpsilonGarden.GardenData.Component

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


    test "provided a Garden and a Plant, generate a projection and store it in DB", context do
        projection = GardenProjection.generate(context.garden)
        context.garden
        |> change()
        |> put_embed(:projection, projection)
        |> Repo.update!(returning: true)
    end

    test "ensure sorts plant by celerity" do
        plants = [%Plant{
            id: 0,
            celerity: 5
        },%Plant{
            id: 1,
            celerity: 3
        },%Plant{
            id: 2,
            celerity: 9
        },%Plant{
            id: 3,
            celerity: 2
        }]
        |> GardenProjection.sort_plants_by_celerity

        assert [%Plant{
            id: 2
        },%Plant{
            id: 0
        },%Plant{
            id: 1
        },%Plant{
            id: 3
        }] = plants

    end

    test "ensure sorts plant by celerity in case of tie use insert date" do

        plants = [%Plant{
            id: 0,
            celerity: 5,
            inserted_at: DateTime.utc_now()
        },%Plant{
            id: 1,
            celerity: 3,
            inserted_at: DateTime.utc_now()
        },%Plant{
            id: 2,
            celerity: 5,
            inserted_at: Map.update(DateTime.utc_now(), :year, 0, &(&1 + 1)) # ensure it's older ;)
        },%Plant{
            id: 3,
            celerity: 2,
            inserted_at: DateTime.utc_now()
        }]
        |> GardenProjection.sort_plants_by_celerity

        assert [%Plant{
            id: 0
        },%Plant{
            id: 2
        },%Plant{
            id: 1
        },%Plant{
            id: 3
        }] = plants
    end

    test "plant projection ends date is the last turn where all alteration can be filled" do
        projection = %GardenProjection{
            plants: [
                %GardenProjection.Plant{
                    plant_id: 1,
                    alteration_by_parts: [
                        %GardenProjection.PartAlteration{
                            root_pos_x: 4,
                            root_pos_y: 0,
                            alterations: [
                                %Alteration{
                                    component: "AB",
                                    event_type: 1,
                                    rate: 10.0
                                },
                                %Alteration{
                                    component: "DAB",
                                    event_type: 1,
                                    rate: 10.0
                                }
                            ]
                        },
                        %GardenProjection.PartAlteration{
                            root_pos_x: 4,
                            root_pos_y: 1,
                            alterations: [
                                %Alteration{
                                    component: "AB",
                                    event_type: 1,
                                    rate: 10.0
                                },
                                %Alteration{
                                    component: "DAB",
                                    event_type: 0,
                                    rate: 3.0
                                }
                            ]
                        }
                    ]
                }
            ]
        }

        plt = %Plant{
            id: 1,
            content: PlantContent.build_content(
                max_size: 310.0
            ),
            cycle: PlantCycle.build_cycle(evolutions: [
                UpsilonGarden.Cycle.CycleEvolution.build_evolution(
                    objectives: [
                        Component.build_component(composition: "RT", quantity: 100) # ensure cycle doesn't proc, that's not what we're testing now ;)
                    ]
                )
            ])
        }

        projection = GardenProjection.compute_plants(projection,[plt])

        next_event = UpsilonGarden.Tools.compute_next_date(10)

        assert [
              %Alteration{
                  component: "AB",
                  event_type: 1,
                  rate: 20.0,
                  next_event: ^next_event
              },
              %Alteration{
                  component: "DAB",
                  event_type: 0,
                  rate: 3.0
              },
              %Alteration{
                  component: "DAB",
                  event_type: 1,
                  rate: 10.0,
                  next_event: ^next_event
              }
          ] = Enum.at(projection.plants,0).alterations
        assert Enum.at(projection.plants,0).next_event == next_event
        assert projection.next_event == next_event
    end

    
    test "plant projection ends date the turn where a cycle can be completed." do
        projection = %GardenProjection{
            plants: [
                %GardenProjection.Plant{
                    plant_id: 1,
                    alteration_by_parts: [
                        %GardenProjection.PartAlteration{
                            root_pos_x: 4,
                            root_pos_y: 0,
                            alterations: [
                                %Alteration{
                                    component: "AB",
                                    event_type: 1,
                                    rate: 10.0
                                },
                                %Alteration{
                                    component: "DAB",
                                    event_type: 1,
                                    rate: 10.0
                                }
                            ]
                        },
                        %GardenProjection.PartAlteration{
                            root_pos_x: 4,
                            root_pos_y: 1,
                            alterations: [
                                %Alteration{
                                    component: "AB",
                                    event_type: 1,
                                    rate: 10.0
                                },
                                %Alteration{
                                    component: "DAB",
                                    event_type: 0,
                                    rate: 3.0
                                }
                            ]
                        }
                    ]
                }
            ]
        }

        plt = %Plant{
            id: 1,
            content: PlantContent.build_content(
                max_size: 310.0
            ),
            cycle: PlantCycle.build_cycle(evolutions: [
                UpsilonGarden.Cycle.CycleEvolution.build_evolution(
                    objectives: [
                        Component.build_component(composition: "AB", quantity: 25) # gain 20 per turns ... should be quick ;)
                    ]
                )
            ])
        }

        projection = GardenProjection.compute_plants(projection,[plt])

        next_event = UpsilonGarden.Tools.compute_next_date(2)

        assert Enum.at(projection.plants,0).next_event == next_event
        assert projection.next_event == next_event
    end

    test "if all alterations cant be filled a turn, then end date is next turn" do
        projection = %GardenProjection{
            plants: [
                %GardenProjection.Plant{
                    plant_id: 1,
                    alteration_by_parts: [
                        %GardenProjection.PartAlteration{
                            root_pos_x: 4,
                            root_pos_y: 0,
                            alterations: [
                                %Alteration{
                                    component: "AB",
                                    event_type: 1,
                                    rate: 10.0
                                },
                                %Alteration{
                                    component: "DAB",
                                    event_type: 1,
                                    rate: 10.0
                                }
                            ]
                        },
                        %GardenProjection.PartAlteration{
                            root_pos_x: 4,
                            root_pos_y: 1,
                            alterations: [
                                %Alteration{
                                    component: "AB",
                                    event_type: 1,
                                    rate: 10.0
                                },
                                %Alteration{
                                    component: "DAB",
                                    event_type: 0,
                                    rate: 3.0
                                }
                            ]
                        }
                    ]
                }
            ]
        }

        plt = %Plant{
            id: 1,
            content: PlantContent.build_content(
                contents: [
                    Component.build_component(composition: "RT", quantity: 290.0)
                ],
                max_size: 310.0
            ),
            cycle: PlantCycle.build_cycle()
        }

        projection = GardenProjection.compute_plants(projection,[plt])

        next_event = UpsilonGarden.Tools.compute_next_date(1)

        assert Enum.at(projection.plants,0).next_event == next_event
        assert projection.next_event == next_event
    end

    @tag :not_implemented
    test "removes plants from projection when they can't handle any absorption" do
    end
end
