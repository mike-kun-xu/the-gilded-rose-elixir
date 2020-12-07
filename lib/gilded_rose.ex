defmodule GildedRose do
  use Agent
  alias GildedRose.Item
  alias GildedRose.Info

# Retrieving data from database (using text file to simulate) and load into Agent.
  def new() do
    {:ok, content} = File.read("data.txt")
    content = String.split(content, "\n", trim: true)
    {:ok, agent} = Agent.start_link(fn ->[] end)
    GildedRose.loadData(content, agent)
  end

# Load data functionality.
  def loadData([],agent) do
   agent
  end
  def loadData(content, agent) do
    item_to_load = GildedRose.getFirstItem(content) |> String.split("\, ")
    itemName = Enum.at(item_to_load,0)
    {itemSellIn,_} = Integer.parse(Enum.at(item_to_load,1))
    {itemQuality,_} = Integer.parse(Enum.at(item_to_load,2))
    Agent.update(agent, & &1 ++ [Item.new(itemName,itemSellIn,itemQuality)])
    GildedRose.loadData(tl(content),agent)    
  end

# Get first item of the list retrieved in.
  def getFirstItem(content) do
    Enum.map(content, fn x -> Regex.replace(~r/\"/,x,"") end) |> hd()
  end

  def items(agent), do: Agent.get(agent, & &1)

  def update_quality(agent) do
    item_num = Agent.get(agent, &length/1)
    GildedRose.update_sell_in(agent, item_num)
    GildedRose.update_quality(agent, item_num)
    GildedRose.writeData("a.txt", agent)
  end
  def update_quality(agent, 0) do 
  "Update finish"
  end
  def update_quality(agent, item_num) do
    item = Agent.get(agent, &Enum.at(&1, item_num - 1))
    item =
    cond do
      item.name == "+5 Dexterity Vest" or item.name == "Elixir of the Mongoose" ->
      if item.quality > 0 do
        if item.sell_in < 0 do
          %{item | quality: item.quality - 2}
        else
          %{item | quality: item.quality - 1}
        end
      else 
        item 
      end
      item.name == "Sulfuras Hand of Ragnaros" -> item
      item.name == "Aged Brie" ->
      if item.quality < 50 do
        %{item | quality: item.quality + 1}
      else
        item
      end
      item.name == "Backstage passes to a TAFKAL80ETC concert" ->
        item =
        cond do
          item.sell_in <= 0 -> %{item | quality: 0}
          item.sell_in <= 5 -> %{item | quality: item.quality + 3}
          item.sell_in <= 10 -> %{item | quality: item.quality + 2}
          true -> %{item | quality: item.quality + 1}
        end
        if item.quality > 50 do %{item | quality: 50} 
        else 
          item
        end
      item.name == "Conjured Mana Cake" ->
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
    Agent.update(agent, &List.replace_at(&1, item_num - 1, item))
    GildedRose.update_quality(agent, item_num - 1)
  end

  # Update sell_in date
  def update_sell_in(agent,0) do "Sell_in date updated" end
  def update_sell_in(agent, item_num) do
    item = Agent.get(agent, &Enum.at(&1, item_num - 1))
    item =
    if item.name == "Sulfuras Hand of Ragnaros" do
      item
    else
      %{item | sell_in: item.sell_in - 1}
    end
    Agent.update(agent, &List.replace_at(&1, item_num - 1, item))
    GildedRose.update_sell_in(agent, item_num - 1)
  end

  # Write updated data back to the text file.
  def writeData(filename, agent) do
    data_list = []
    item_num = Agent.get(agent, &length/1)
    GildedRose.writeData(filename, agent, item_num, data_list)
  end
  def writeData(filename, agent, 0, data_list) do
    File.write(filename, data_list)
    "Data updated."
  end
  def writeData(filename, agent, 1, data_list) do
    item = Agent.get(agent, &Enum.at(&1, 0))
    data_list = List.flatten([item.name,", ",to_string(item.sell_in),", ",to_string(item.quality)],data_list)
    GildedRose.writeData(filename,agent,0, data_list)
  end
  def writeData(filename, agent, item_num, data_list) do
    item = Agent.get(agent, &Enum.at(&1, item_num - 1))
    data_list = List.flatten(["\n",item.name,", ",to_string(item.sell_in),", ",to_string(item.quality)],data_list)
    GildedRose.writeData(filename,agent,item_num - 1, data_list)
  end
end