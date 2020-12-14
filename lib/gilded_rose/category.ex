defmodule GildedRose.Category do
  defstruct name: nil, category: nil

  def new(name,category) do
    %__MODULE__{name: name, category: category}
  end 
end