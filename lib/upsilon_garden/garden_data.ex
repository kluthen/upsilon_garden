defmodule UpsilonGarden.GardenData do 
    use Ecto.Schema
    import Ecto.Changeset
    alias UpsilonGarden.{Garden,Source}
    alias UpsilonGarden.GardenData.{Segment,Influence}

    embedded_schema do 
        embeds_many :segments, UpsilonGarden.GardenData.Segment
    end

    def changeset(%UpsilonGarden.GardenData{} = data, _attrs \\ %{}) do
        data
        |> cast_embed(:segments)
        |> validate_required([:segments])
    end

    @doc """
        helper for set_influence, ensure ratio is set to 1
    """
    def set_influence(data, x,y, influence) do 
        # enforce full power
        set_influence(data,x,y,1,0,influence)
    end
    
    @doc """
        Seek bloc, and apply Influence with a ratio based on power/distance relationship.
        Update and return GardenData.
    """
    def set_influence(data, x,y, power, dist, influence) do 
        update_bloc(data,x,y, fn bloc -> 
            influence = Map.put(influence, :ratio, Float.round(1 - (dist/(power+1)),2))
            influences = [influence | bloc.influences]
            Map.put(bloc, :influences, influences)
        end )
    end

    @doc """
        Update a bloc located by x,y with provided function.
        fn(bloc) -> updated_bloc

        Note: won't work on bloc typed stone. 
        returns updated garden data
    """
    def update_bloc(data,x,y, update_function) do 
        segment = Enum.at(data.segments, x) 
        bloc = Enum.at(segment.blocs, y)
        if bloc.type == UpsilonGarden.GardenData.Bloc.stone() do 
        # leave it alone if bloc is a stone ;)
            data
        else
            bloc = update_function.(bloc)
            segment = Map.put(segment, :blocs, List.replace_at(segment.blocs,y,bloc))
            Map.put(data, :segments, List.replace_at(data.segments,x, segment))
        end
    end

    @doc """
        Seek influence on all bloc matching provided Influence.
        If they match ( type_id / <influencer>_id ), influence will be droped 
        Update and return GardenData.
    """
    def drop_influence(data, match) do 
        segments = Enum.map(data.segments, fn segment ->
            blocs = Enum.map(segment.blocs, fn bloc ->
                influences = Enum.reject(bloc.influences, &Influence.match?(&1, match))
                Map.put(bloc, :influences, influences)
            end)
            Map.put(segment, :blocs, blocs)
        end)
        Map.put(data, :segments, segments)
    end

    @doc """
        Seek within Garden blocs that have matching influence.
        Return [{x,y}]
    """
    def seek_influence(data, match) do 
        {_,segments} = Enum.map_reduce(data.segments, [], fn segment,acc ->
            {_,blocs} = Enum.map_reduce(segment.blocs, [], fn bloc,acc ->
                influences = Enum.filter(bloc.influences, &Influence.match?(&1, match))
                if length(influences) > 0 do 
                    {bloc,[bloc.position|acc]}
                else
                    {bloc, acc}
                end
            end)
            if length(blocs) > 0 do 
                {segment,[{segment.position,blocs}|acc]}
            else
                {segment,acc}
            end
        end)

        for {seg, blocs} <- segments do 
            for b <- blocs do 
                {seg,b}
            end
        end
        |> List.flatten
    end

    # might not be needed ... on_replace: :delete was set. 
    def change_activate(cs, data, targets) do
        # expect cs to be a Garden Data changeset. 
        new_segments = for segment <- data.segments do 
            if segment.position in targets do 
                Segment.changeset(segment)
                |> change(active: true)
            end
        end
        |> Enum.reject(fn nil -> false
                          _ -> true 
                        end)
        
        put_embed(cs, :segments, new_segments)
    end

    @doc """
        Mark targets segments as active.
        Update and return GardenData.
    """
    def activate(data, targets) do 
        new_segments = for segment <- data.segments do 
            if segment.position in targets do 
                Map.put(segment, :active, true)
            else
                segment
            end
        end
        Map.put(data, :segments, new_segments)
    end

    def get_segment(data, sid) do 
        if length(data.segments) > sid do 
            Enum.at(data.segments, sid)
        else
            nil
        end
    end

    def get_bloc(data, sid, bid) do 
        if length(data.segments) > sid do 
            segment = Enum.at(data.segments, sid)
            if length(segment.blocs) > bid do 
                Enum.at(segment.blocs, bid)
            else
                nil
            end
        else
            nil
        end
    end

    @doc """
        From a GardenContext, build up structural garden.
        Fills segments with blocs and blocs with Components according to the context.
        Once done, seek sources out, place them and update GardenData with their influence.
    """
    def generate(garden, context) do 
        data = %UpsilonGarden.GardenData{}
        segments = for pos <- 0..(context.dimension - 1) do 
            segment = %UpsilonGarden.GardenData.Segment{position: pos, active: false}
            blocs = for depth <- 0..(context.depth - 1 ) do
                bloc = %UpsilonGarden.GardenData.Bloc{position: depth, sources: []}
                cond do
                    depth == context.depth - 1 -> # ensure last bloc is always stone.
                        Map.put(bloc, :type, UpsilonGarden.GardenData.Bloc.stone())  
                    depth < context.prepared_depth -> # ensure topmost blocs are always dirt 
                        UpsilonGarden.GardenData.Bloc.fill(bloc, context)
                    true ->
                        if :rand.uniform > context.dirt_stone_ratio do
                            Map.put(bloc, :type, UpsilonGarden.GardenData.Bloc.stone())
                        else 
                            UpsilonGarden.GardenData.Bloc.fill(bloc, context)
                        end
                end
            end
            Map.put(segment, :blocs, blocs)
        end
        data = Map.put(data,:segments, segments)
        generate_sources(garden,data,context)
    end


    @doc """
        Roll a source, store it in DB and add it influence to GardenData.
    """
    def generate_sources(%Garden{} = garden, data, context) do 
        targets = Enum.to_list(0..(Enum.random(context.sources_range)))
        generate_sources(targets,garden,data,context)    
    end

    def generate_sources([],_,data,_), do: data 

    def generate_sources([_|rest],garden,data, context) do
        source = Ecto.build_assoc(garden,:sources)
        data = Source.create(source,data, context)
        generate_sources(rest,garden,data,context)
    end

end