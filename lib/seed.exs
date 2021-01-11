defmodule Seed do
alias GildedRose.Category, as: Cate
alias GildedRose.Date, as: Da

def catalog(itemName) do
  library = %{
    "+5 Dexterity Vest" => :normal,
    "Aged Brie" => :reverse,
    "Elixir of the Mongoose" => :normal,
    "Sulfuras Hand of Ragnaros" => :legendary,
    "Backstage passes to a TAFKAL80ETC concert" => :special,
    "Conjured Mana Cake" => :double
  }
  library[itemName]
end
# Called when seeding, create category and date structure for each item
  def go() do
    content = File.stream!("priv/seed.csv") |> CSV.decode
    len = Enum.count(content)
    {cate_list,date_list} = {categorize(content,len,[]),setDate(content,len,[])}
    {:ok,:ok} = {writeFile(:category, cate_list),writeFile(:date, date_list)}
  end

  defp categorize(_content,0,cate_list), do: cate_list
  defp categorize(content,len,cate_list) do
    {:ok, item} = Enum.at(content, len-1)
    itemName = Enum.at(item, 0)
    itemCate = catalog(itemName)
    cate_list = Enum.concat(cate_list, [Cate.new(itemName,itemCate)])
    categorize(content,len-1,cate_list)
  end

  defp setDate(_content,0,date_list), do: date_list
  defp setDate(content,len,date_list) do
    {:ok, item} = Enum.at(content,len-1)
    itemName = Enum.at(item,0)
    date = to_string(Date.utc_today())
    date_list = Enum.concat(date_list, [Da.new(itemName,date)])
    setDate(content,len-1,date_list)
  end

# Write files into their own .csv, data will be retrieved from those .csv files instead of seed.csv
  defp writeFile(:category,content) do
    :ok = File.write("priv/category.csv",writeCate([],content))
  end
  defp writeFile(:date,content) do
    :ok = File.write("priv/date.csv",writeDate([],content))
  end

  defp writeCate(data_list,[%{name: name, category: category}|[]]) do
    Enum.concat(data_list,[name,",",to_string(category)])
  end 
  defp writeCate(data_list,[%{name: name, category: category}|rest]) do
    data_list
    |> Enum.concat([name,",",to_string(category),"\n"])
    |> writeCate(rest)
    
  end
  defp writeDate(data_list,[%{name: name, date: date}|[]]) do 
    Enum.concat(data_list,[name,",",to_string(date)])
  end
  defp writeDate(data_list,[%{name: name, date: date}|rest]) do
    data_list
    |> Enum.concat([name,",",to_string(date),"\n"])
    |> writeDate(rest)
  end
end