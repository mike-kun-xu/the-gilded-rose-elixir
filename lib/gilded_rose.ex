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
  defp loadItem([]), do: []
  defp loadItem(content) do
    item_to_load = hd(content) |> String.split("\,")
    itemName = Enum.at(item_to_load, 0)
    {itemSellIn, _} = Integer.parse(Enum.at(item_to_load, 1))
    {itemQuality, _} = Integer.parse(Enum.at(item_to_load, 2))
    List.flatten([Item.new(itemName, itemSellIn, itemQuality), loadItem(tl(content))])
  end

  defp loadCate([]), do: []
  defp loadCate(content) do
    item_to_load = hd(content) |> String.split("\,")
    itemName = Enum.at(item_to_load, 0)
    itemCate = Enum.at(item_to_load, 1)
    List.flatten([Cate.new(itemName, itemCate), loadCate(tl(content))])
  end

  defp loadDate([]), do: []
  defp loadDate(content) do
    item_to_load = hd(content) |> String.split("\,")
    itemName = Enum.at(item_to_load, 0)
    itemDate = Enum.at(item_to_load, 1)
    List.flatten([Da.new(itemName, itemDate), loadDate(tl(content))])
  end

  # Get all items or get items from different map.
  def items(agent), do: Agent.get(agent, & &1)
  def items(agent, :item) do
    Agent.get(agent, & &1.item)
  end
  def items(agent, :cate) do
    Agent.get(agent, & &1.cate)
  end
  def items(agent, :date) do
    Agent.get(agent, & &1.date)
  end

  # Update the quality and invoke the sell_in date and the data writing function.
  def update_quality(agent) do
    item_num = GildedRose.items(agent, :cate) |> length()

    sell_list = update(agent, :item)
    Agent.update(agent, &Map.replace(&1, :item, sell_list))
    quality_list = update_quality(agent, item_num, [])
    Agent.update(agent, &Map.replace(&1, :item, quality_list))
    date_list = update(agent, :date)
    Agent.update(agent, &Map.replace(&1, :date, date_list))
    :ok = writeData("priv/item.csv", agent)
  end

  defp update_quality(_agent, 0, list), do: list

  defp update_quality(agent, item_num, list) do
    cate = items(agent, :cate) |> Enum.at(item_num - 1)
    item = items(agent, :item) |> Enum.find(& &1.name == cate.name)
    newItem = quality_change(item, String.to_atom(cate.category))
    newList = List.flatten([list, newItem])
    update_quality(agent,item_num - 1,newList)
  end

  # Pattern match different items.
  defp quality_change(item, :normal) do
      if item.quality > 0 do
        if item.sell_in < 0 do
          %{item | quality: item.quality - 2}
        else
          %{item | quality: item.quality - 1}
        end
      else
        item
      end
  end
  defp quality_change(item, :legendary), do: item

  defp quality_change(item, :reverse) do
      if item.quality < 50 do
        %{item | quality: item.quality + 1}
      else
        item
      end
  end
  defp quality_change(item, :special) do
    item =
      cond do
        item.sell_in <= 0 -> %{item | quality: 0}
        item.sell_in <= 5 -> %{item | quality: item.quality + 3}
        item.sell_in <= 10 -> %{item | quality: item.quality + 2}
        true -> %{item | quality: item.quality + 1}
      end
    if item.quality > 50 do
      %{item | quality: 50}
    else
      item
    end
  end
  defp quality_change(item, :double) do
      if item.quality > 0 do
        if item.sell_in < 0 do
          %{item | quality: item.quality - 4}
        else
          %{item | quality: item.quality - 2}
        end
      else
        item
      end
  end

  # Update sell_in date
  defp update(agent, :item) do
    update_sell_in(items(agent, :item),agent)
  end

  defp update(agent, :date) do
    update_date(items(agent, :date))
  end

  defp update_sell_in([],_agent), do: []

  defp update_sell_in([head | tail],agent) do
    if head.name == Enum.find(items(agent,:cate),& &1.category == "legendary").name do
      List.flatten([head, update_sell_in(tail, agent)])
    else
      head = %{head | sell_in: head.sell_in - 1}
      List.flatten([head, update_sell_in(tail, agent)])
    end
  end
  defp update_date([]), do: []
  defp update_date([head | tail]) do
    head = %{head | date: to_string(Date.utc_today())}
    List.flatten([head, update_date(tail)])
  end

  # Write updated data back to the text file.
  defp writeData(filename, agent) do
    list = GildedRose.items(agent, :item)
    File.write(filename, write(list))
  end

  defp write(list) when length(list) == 1 do
    item = hd(list)
    List.flatten([item.name, ",", to_string(item.sell_in), ",", to_string(item.quality)])
  end

  defp write(list) do
    item = hd(list)

    List.flatten([
      item.name,
      ",",
      to_string(item.sell_in),
      ",",
      to_string(item.quality),
      "\n",
      write(tl(list))
    ])
  end
end