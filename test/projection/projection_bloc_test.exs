defmodule UpsilonGarden.Projection.ProjectionBlocTest do 
    use ExUnit.Case, async: true
    alias UpsilonGarden.GardenProjection
    alias UpsilonGarden.GardenProjection.{Projecter,Alteration,PartAlteration}
    alias UpsilonGarden.PlantData.PlantRoot    
    alias UpsilonGarden.GardenData.{Component}



    test "ensure a root can absorb in keep mode" do 
        components_availability = [%Component{composition: "ABCD",quantity: 1.0},%Component{composition: "AB",quantity: 1.0},%Component{composition: "A",quantity: 1.0}]
        {components_availability, alterations} = Projecter.absorb(components_availability, %Component{composition: "AB",quantity: 1.0}, PlantRoot.keep())

        assert [%Component{composition: "AB",quantity: 1.0},%Component{composition: "A",quantity: 1.0}] = components_availability
        assert [%Alteration{component: "ABCD", rate: 1.0, event_type: 1}]  = alterations
    end

    test "ensure a root can reject what got absorbed" do 
        components_availability = [%Component{composition: "AB",quantity: 1.0},%Component{composition: "A",quantity: 1.0}]
        {components_availability, alterations, _rejecters} = Projecter.reject(components_availability, [%Alteration{component: "ABCD", rate: 1.0, event_type: 1}], [%Component{composition: "AB",quantity: 1.0}])
        
        assert [%Component{composition: "ABCD",quantity: 1.0},%Component{composition: "AB",quantity: 1.0},%Component{composition: "A",quantity: 1.0}] = components_availability
        assert [%Alteration{component: "ABCD", rate: 1.0, event_type: 0}]  = alterations

        components_availability = [%Component{composition: "AB",quantity: 1.0},%Component{composition: "A",quantity: 1.0}]
        {components_availability, alterations, _rejecters} = Projecter.reject(components_availability, [%Alteration{component: "ABCD", rate: 1.0, event_type: 1}], [%Component{composition: "AB",quantity: 0.2}])
        
        assert [%Component{composition: "ABCD",quantity: 0.2},%Component{composition: "AB",quantity: 1.0},%Component{composition: "A",quantity: 1.0}] = components_availability
        assert [%Alteration{component: "ABCD", rate: 0.2, event_type: 0},%Alteration{component: "ABCD", rate: 0.8, event_type: 1}]  = alterations
    end

    test "ensure a root in trunc-out mode can absorb what it rejected" do 
        components_availability = [
            %Component{composition: "ABCD",quantity: 1.0},%Component{composition: "AB",quantity: 1.0},%Component{composition: "A",quantity: 1.0}
        ]
        {components_availability, alterations} = Projecter.absorb(components_availability, %Component{composition: "AB",quantity: 1.0}, PlantRoot.trunc_out())

        assert [%Component{composition: "AB",quantity: 1.0},%Component{composition: "A",quantity: 1.0},%Component{composition: "CD",quantity: 1.0}] = components_availability
        assert [%Alteration{component: "AB", rate: 1.0, event_type: 1}]  = alterations
    end

    test "ensure a root in trunc-in mode get both components in its alterations" do 
        components_availability = [
            %Component{composition: "ABCD",quantity: 1.0},%Component{composition: "AB",quantity: 1.0},%Component{composition: "A",quantity: 1.0}
        ]
        {components_availability, alterations} = Projecter.absorb(components_availability, %Component{composition: "AB",quantity: 1.0}, PlantRoot.trunc_in())

        assert [%Component{composition: "AB",quantity: 1.0},%Component{composition: "A",quantity: 1.0}] = components_availability
        assert [%Alteration{component: "CD",rate: 1.0, event_type: 1},%Alteration{component: "AB", rate: 1.0, event_type: 1}]  = alterations
    end

    test "ensure absorbed quantities matches root stats" do 
        components_availability = [
            %Component{composition: "ABCD",quantity: 3.0},%Component{composition: "AB",quantity: 1.0},%Component{composition: "A",quantity: 1.0}
        ]
        {components_availability, alterations} = Projecter.absorb(components_availability, %Component{composition: "AB",quantity: 1.0}, PlantRoot.keep())

        assert [%Component{composition: "ABCD",quantity: 2.0},%Component{composition: "AB",quantity: 1.0},%Component{composition: "A",quantity: 1.0}] = components_availability
        assert [%Alteration{component: "ABCD", rate: 1.0, event_type: 1}]  = alterations
    end

    test "ensure absorption will may seek out multiples components to get its share" do 
        components_availability = [
            %Component{composition: "ABCD",quantity: 1.0},%Component{composition: "AB",quantity: 1.0},%Component{composition: "A",quantity: 1.0}
        ]
        {components_availability, alterations} = Projecter.absorb(components_availability, %Component{composition: "AB",quantity: 2.0}, PlantRoot.keep())

        assert [%Component{composition: "A",quantity: 1.0}] = components_availability
        assert [%Alteration{component: "AB", rate: 1.0, event_type: 1},%Alteration{component: "ABCD", rate: 1.0, event_type: 1}]  = alterations
    end

    test "ensure a single rejection may be used multiples times so long it has spaces left" do 
        components_availability = [%Component{composition: "AB",quantity: 1.0},%Component{composition: "A",quantity: 1.0}]
        {_components_availability, _alterations, rejecters} = Projecter.reject(components_availability, [%Alteration{component: "ABCD", rate: 1.0, event_type: 1}], [%Component{composition: "AB",quantity: 2.0}])
        
        assert [%Component{composition: "AB",quantity: 1.0}] = rejecters
    end

    test "ensure absorptions and rejections are stored under appropriate plant" do
        components_availability = [%Component{composition: "ABCD",quantity: 1.0},%Component{composition: "AB",quantity: 1.0},%Component{composition: "A",quantity: 1.0}]
        roots = [%PlantRoot{
            pos_x: 4,
            pos_y: 0,
            absorb_mode: PlantRoot.keep(),
            absorption_rate: 1.0,
            rejection_rate: 1.0,
            prime_root: true,
            plant_id: 1,
            selection_compo: PlantRoot.alpha(),
            selection_target: PlantRoot.alpha(),
            absorption_matching: PlantRoot.left(),
            rejection_matching: PlantRoot.left(),
            absorbers: [%Component{composition: "AB", quantity: 1.0}],
            rejecters: [%Component{composition: "AB", quantity: 0.2}],
        }]
        projection = Projecter.feeds(%GardenProjection{}, 4,0, components_availability , roots) 

        assert %GardenProjection{plants: [%GardenProjection.Plant{plant_id: 1}]} = projection

        plant = Enum.at(projection.plants, 0)
        assert [%PartAlteration{root_pos_x: 4, root_pos_y: 0}] = plant.alteration_by_parts

        pa = Enum.at(plant.alteration_by_parts, 0)

        assert [%Alteration{component: "AB", rate: 0.2, event_type: 0},%Alteration{component: "AB", rate: 0.8, event_type: 1}] = pa.alterations
    end

    test "ensure global absorption and rejection rate are respected" do 

    end

    test "ensure a root can absorb multiples components" do 

    end

    test "ensure a trunc-in mode absorption can trigger multiples rejections" do 

    end
end