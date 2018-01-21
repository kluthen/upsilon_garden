defmodule UpsilonGarden.Tools.ToolsTest do 
    use ExUnit.Case, async: false
    alias UpsilonGarden.Tools

    test "ensure prepare range does its job" do 
        results = Tools.prepare_range([{:a,5}])
        assert length(results) == 5
        assert [:a,:a,:a,:a,:a] = results
    end
end