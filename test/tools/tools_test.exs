defmodule UpsilonGarden.Tools.ToolsTest do 
    use ExUnit.Case, async: false
    alias UpsilonGarden.Tools

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
    
end