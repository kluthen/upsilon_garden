defmodule UpsilonGarden.Tools do 

    @doc """
        Provided a list of {element, nb_elements_to_add}
        will create a new list containing elements 
        return [elements]
    """
    def prepare_range(list) do 
        for {element, count} <- list do 
            for _ <- 0..(count - 1) do 
                element
            end
        end
        |> List.flatten
    end

    @seconds_by_turn 15
    @doc """
        Compute next date based on current time + provided number of turns.
        Next date begins counting from next turn begin on. 
        ie: Current date: 0:02 in 5 turns will begin at 0:15 and next event at 1:30
    """
    def compute_next_date(turns) do 
        datetime = DateTime.utc_now
        |> Map.put(:microsecond, {0,0})
        compute_next_date(datetime, turns)
    end

    def compute_next_date(base_date, turns) do 
        second =  round(turns * @seconds_by_turn + @seconds_by_turn - base_date.second)
        Timex.shift(base_date, seconds: second)
        |> Map.put(:microsecond, {0,0})
    end

    @doc """
        Compute number of turn elapsed between now and then ;)
    """
    def compute_elapsed_turns(from, to \\ DateTime.utc_now) do 
        round(Float.floor(DateTime.diff(from,to) / @seconds_by_turn))
    end
end