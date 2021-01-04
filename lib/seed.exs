defmodule Seed do
alias GildedRose.Category, as: Cate

# Called when seeding, create category and date structure for each item
  def go() do
    content = File.stream!("priv/seed.csv") |> CSV.decode
    len = content |> Enum.count
    {cate_list,date_list} = {categorize(content,len,[]),setDate(content,len,[])}
    {:ok,:ok} = {writeFile(:category, cate_list),writeFile(:date, date_list)}
  end

  defp categorize(_content,0,cate_list), do: cate_list
  defp categorize(content,len,cate_list) do
    {:ok, item} = content |> Enum.at(len-1)
    itemName = item |> Enum.at(0)
    itemCate =
    case itemName do
      "+5 Dexterity Vest" -> :normal
      "Aged Brie" -> :reverse
      "Elixir of the Mongoose" -> :normal
      "Sulfuras Hand of Ragnaros" -> :legendary
      "Backstage passes to a TAFKAL80ETC concert" -> :special
      "Conjured Mana Cake" -> :double
    end
    cate_list = List.flatten([cate_list, Cate.new(itemName,itemCate)])
    categorize(content,len-1,cate_list)
  end

  defp setDate(_content,0,date_list), do: date_list
  defp setDate(content,len,date_list) do
    {:ok, item} = content |> Enum.at(len-1)
    itemName = item |> Enum.at(0)
    date = Date.utc_today() |> to_string()
    date_list = List.flatten([date_list, GildedRose.Date.new(itemName,date)])
    setDate(content,len-1,date_list)
  end

# Write files into their own .csv, data will be retrieved from those .csv files instead of seed.csv
  defp writeFile(:category,content) do
    data_list = writeCate(content,[])
    File.write("priv/category.csv",data_list)
  end
  defp writeFile(:date,content) do
    data_list = writeDate(content,[])
    File.write("priv/date.csv",data_list)
  end

  defp writeCate(list,data_list) when length(list) == 1 do
    item = hd(list)
    List.flatten(data_list,[item.name,",",to_string(item.category)])
  end 
  defp writeCate(list,data_list) do
    item = hd(list)
    data_list = List.flatten(data_list,[item.name,",",to_string(item.category),"\n"])
    writeCate(tl(list),data_list)
  end
  defp writeDate(list,data_list) when length(list) == 1 do 
    item = hd(list)
    List.flatten(data_list,[item.name,",",to_string(item.date)])
  end
  defp writeDate(list,data_list) do
    item = hd(list)
    data_list = List.flatten(data_list,[item.name,",",to_string(item.date),"\n"])
    writeDate(tl(list),data_list)
  end
end
