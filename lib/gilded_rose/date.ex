defmodule GildedRose.Date do
  defstruct name: nil, date: nil

  def new(name,date) do
    %__MODULE__{name: name, date: date}
  end 
end