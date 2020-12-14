defmodule Seed do
alias GildedRose.Category, as: Cate

# Called when seeding, create category data structure for each item
  def categorize(content) do
    item_to_load = String.split(content, "\n", trim: true)
    categorize(item_to_load,[])
  end
  defp categorize([],cate_list), do: cate_list
  defp categorize(content,cate_list) do
    itemName = hd(content) |> String.split("\,") |> Enum.at(0)
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
    categorize(tl(content),cate_list)
  end

# Called when seeding, create date data structure for each item
  def setDate(content) do
    item_to_load = String.split(content, "\n", trim: true)
    setDate(item_to_load,[])      
  end
  defp setDate([],date_list), do: date_list
  defp setDate(content,date_list) do
    itemName = hd(content) |> String.split("\,") |> Enum.at(0)
    date = Date.utc_today() |> to_string()
    date_list = List.flatten([date_list, GildedRose.Date.new(itemName,date)])
    setDate(tl(content),date_list)
  end

# Write files into their own .csv, data will be retrieved from those .csv files instead of seed.csv
  def writeFile(type,content) when type == :category do
    data_list = writeCate(content,[])
    File.write("data/category.csv",data_list)
  end
  def writeFile(type,content) when type == :date do
    data_list = writeDate(content,[])
    File.write("data/date.csv",data_list)
  end

  defp writeCate(list,data_list) when length(list) == 1 do
    item = hd(list)
    data_list = List.flatten(data_list,[item.name,",",to_string(item.category)])
  end 
  defp writeCate(list,data_list) do
    item = hd(list)
    data_list = List.flatten(data_list,[item.name,",",to_string(item.category),"\n"])
    writeCate(tl(list),data_list)
  end
  defp writeDate(list,data_list) when length(list) == 1 do 
    item = hd(list)
    data_list = List.flatten(data_list,[item.name,",",to_string(item.date)])
  end
  defp writeDate(list,data_list) do
    item = hd(list)
    data_list = List.flatten(data_list,[item.name,",",to_string(item.date),"\n"])
    writeDate(tl(list),data_list)
  end
end