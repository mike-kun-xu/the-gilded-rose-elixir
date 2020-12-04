defmodule GildedRose.Item do
  defstruct name: nil, sell_in: nil, quality: nil

  def new(name, sell_in, quality) do
    %__MODULE__{name: name, sell_in: sell_in, quality: quality}
  end
end
