defmodule UpsilonGarden.Tools do 
    require Logger
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

    @doc """
        Provided available space, determine and a total added by turns,
        determine how many turns are expected before being full.
        returns 0 if available space < 0.1
        returns 1 even if full before that
        otherwise return a number of turns up that can fully absorb
    """
    def turns_to_full(current_size, max_size, total) do 
        if total < 0.1 do 
            0
        else 
            if max_size - current_size < 0.1 do 
                0
            else
                max(round(Float.floor(((max_size - current_size)/1) / total)),1) 
            end
        end
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
        second =  round(turns * @seconds_by_turn + (@seconds_by_turn - rem(base_date.second,@seconds_by_turn)))
        Timex.shift(base_date, seconds: second)
        |> Map.put(:microsecond, {0,0})
    end

    @doc """
        Compute number of turn elapsed between now and then ;)
    """
    def compute_elapsed_turns(from, to \\ DateTime.utc_now) do 
        round(Float.floor(DateTime.diff(to,from) / @seconds_by_turn))
    end
end