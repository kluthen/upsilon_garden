defmodule UpsilonGarden.Tools.ToolsTest do 
    use ExUnit.Case, async: false
    alias UpsilonGarden.Tools

    test "if available spaces is next to null, can't fill it" do 
        assert 0 = Tools.turns_to_full(299.91, 300, 100)
    end

    test "if provided amount of stuff to fill space is next to null, don't fill" do 
        assert 0 = Tools.turns_to_full(0, 300, 0.05)
    end

    test "ensure prepare range does its job" do 
        results = Tools.prepare_range([{:a,5}])
        assert length(results) == 5
        assert [:a,:a,:a,:a,:a] = results
    end

    test "ensure computed date in 3 turns is appropriate" do 
        date = DateTime.utc_now
        |> Map.put(:second, 5)
        |> Map.put(:minute, 0)
        |> Tools.compute_next_date(3)
        
        assert %DateTime{minute: 1, second: 0} = date
    end

    test "ensure elapsed turns provided an accurate value" do 
        from = DateTime.utc_now
        |> Map.put(:hour,1)
        |> Map.put(:minute,0)
        |> Map.put(:second,0)
        to = DateTime.utc_now
        |> Map.put(:hour,1)
        |> Map.put(:minute,1)
        |> Map.put(:second,0)

        assert 4 = Tools.compute_elapsed_turns(from, to)
    end
    
end