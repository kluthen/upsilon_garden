defmodule UpsilonGardenWeb.PageView do
  use UpsilonGardenWeb, :view

  def bloc_classes(active, bloc) do 
    if active do 
      res = []
      res = if length(bloc.sources) > 0 do 
        types = for source <- bloc.sources do 
          source["type"]
        end

        types = for type <- Enum.uniq(types) do
          "bloc_source_#{type}"
        end

        types ++ res
      else
        res 
      end
      
      res = if length(bloc.influences) > 0 do 
        ["bloc_influenced"| res]
      else
        res 
      end

      influence = for influence <- bloc.influences do 
        if influence.type == 3 do
          if influence.prime_root do 
            "bloc_prime_root"
          else
            "bloc_root"
          end
        end
      end
      |> Enum.uniq
      |> Enum.reject(fn i -> i == nil end)

      res = ["bloc","bloc_active","bloc_type_#{bloc.type}" | res] ++ influence

      Enum.join(res, " ")
    else
      "bloc bloc_inactive"
    end
  end
end
