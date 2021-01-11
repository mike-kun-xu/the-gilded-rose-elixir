defmodule GildedRose do
  use Agent
  alias GildedRose.Item
  alias GildedRose.Category, as: Cate
  alias GildedRose.Date, as: Da

  # Data seeding when initialize the system
  def seed() do
    {:ok, content} = File.read("priv/seed.csv")
    :ok = File.write("priv/item.csv", content)
    Seed.go()
  end

  # Retrieving data from database (using text file to simulate) and load into Agent.
  def new() do
    {:ok, item_content} = File.read("priv/item.csv")
    {:ok, cate_content} = File.read("priv/category.csv")
    {:ok, date_content} = File.read("priv/date.csv")
    item_content = String.split(item_content, "\n", trim: true)
    cate_content = String.split(cate_content, "\n", trim: true)
    date_content = String.split(date_content, "\n", trim: true)
    {:ok, agent} = Agent.start_link(fn -> %{} end)
    Agent.update(agent, &Map.put(&1, :item, loadItem(item_content)))
    Agent.update(agent, &Map.put(&1, :cate, loadCate(cate_content)))
    Agent.update(agent, &Map.put(&1, :date, loadDate(date_content)))
    agent
  end

  # Load data functionality.
  defp loadItem(itemList) do
    Enum.reduce(itemList, [], fn list, acc ->
        [itemName,itemSellIn,itemQuality] = String.split(list,"\,")
        [Item.new(itemName, String.to_integer(itemSellIn),String.to_integer(itemQuality))]
        |> Enum.concat(acc)
        end)
  end

  defp loadCate(itemList) do
    Enum.reduce(itemList, [], fn list, acc ->
        [itemName,itemCate] = String.split(list,"\,")
        [Cate.new(itemName, itemCate)]
        |> Enum.concat(acc)
        end)
  end

  defp loadDate(itemList) do
    Enum.reduce(itemList, [], fn list, acc ->
        [itemName,itemDate] = String.split(list,"\,")
        [Da.new(itemName, itemDate)]
        |> Enum.concat(acc)
        end)
  end

  # Get all items or get items from different map.
  def items(agent), do: Agent.get(agent, & &1)
  def items(agent, :item), do: Agent.get(agent, & &1.item)
  def items(agent, :cate), do: Agent.get(agent, & &1.cate)
  def items(agent, :date), do: Agent.get(agent, & &1.date)

  # Update the quality and invoke the sell_in date and the data writing function.
  def update_quality(agent) do
    item_num = items(agent, :cate) |> length()
    sell_list = update_sell_in(items(agent,:item),agent)

    :ok = Agent.update(agent, &Map.replace(&1, :item, sell_list))
    quality_list = update_quality(agent, item_num, [])
    :ok = Agent.update(agent, &Map.replace(&1, :item, quality_list))
    date_list = update_date(items(agent,:date),agent)
    :ok = Agent.update(agent, &Map.replace(&1, :date, date_list))
    :ok = writeData("priv/item.csv", agent)
  end

  defp update_quality(_agent, 0, list), do: list

  defp update_quality(agent, item_num, list) do
    cate = items(agent, :cate) |> Enum.at(item_num - 1)
    item = items(agent, :item) |> Enum.find(& &1.name == cate.name)
    newItem = quality_change(item, String.to_atom(cate.category))
    newList = Enum.concat(list, [newItem])
    update_quality(agent,item_num - 1,newList)
  end

  # Pattern match different items.
  defp quality_change(item = %{quality: quality}, :normal) when quality < 0 do
    item
  end
  defp quality_change(item = %{quality: quality, sell_in: sell}, :normal) when sell > 0 do
    %{item | quality: quality - 1}
  end
  defp quality_change(item = %{quality: quality}, :normal) do
    %{item | quality: quality - 2}
  end

  defp quality_change(item, :legendary), do: item

  defp quality_change(item = %{quality: quality}, :reverse) when quality < 50 do
    %{item | quality: quality + 1}
  end
  defp quality_change(item,:reverse), do: item

  defp quality_change(item = %{sell_in: sell}, :special) when sell <= 0 do
    %{item | quality: 0}
  end
  defp quality_change(item = %{quality: quality, sell_in: sell}, :special) when sell <= 5 do
    %{item | quality: quality + 3} |> fifty?(quality)
  end
  defp quality_change(item = %{quality: quality, sell_in: sell}, :special) when sell <= 10 do
    %{item | quality: quality + 2} |> fifty?(quality)
  end
  defp quality_change(item = %{quality: quality}, :special) do
    %{item | quality: quality + 1} |> fifty?(quality)
  end

  defp quality_change(item = %{quality: quality}, :double) when quality < 0 do
    item
  end
  defp quality_change(item = %{quality: quality, sell_in: sell}, :double) when sell > 0 do
    %{item | quality: quality - 2}
  end
  defp quality_change(item = %{quality: quality}, :double) do
    %{item | quality: quality - 4}
  end

  defp fifty?(item, quality) when quality > 50 do
    %{item | quality: 50}
  end
  defp fifty?(item,_quality), do: item

  # Update sell_in date

  defp update_sell_in(itemList, agent) do
    %{name: legendary} = Enum.find(items(agent,:cate), & &1.category == "legendary")
    Enum.reduce(itemList,[],fn list, acc ->
      %{name: name, sell_in: sell} = list
      if name == legendary do
        Enum.concat([list],acc)
      else
        list = %{list | sell_in: sell - 1}
        Enum.concat([list],acc)
      end
    end)
  end

  defp update_date(itemList, _agent) do
    Enum.reduce(itemList,[],fn list,acc ->
     list = %{list | date: to_string(Date.utc_today())}
     Enum.concat([list],acc)
    end)
  end

  # Write updated data back to the text file.
  defp writeData(filename, agent) do
    list = items(agent, :item)
    :ok = File.write(filename, write(list,[]))
  end

  defp write([%{name: name, sell_in: sell, quality: quality}|[]],result) do
    Enum.concat([name, ",", to_string(sell), ",", to_string(quality)],result)
  end

  defp write([%{name: name, sell_in: sell, quality: quality}|rest],result) do
    result = Enum.concat([name,",",to_string(sell),",",to_string(quality),"\n"],result)
    write(rest,result)
  end
end