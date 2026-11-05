defmodule FuelCalculator.Journey.Planets do
  @type planet :: :earth | :moon | :mars

  @spec available_planets() :: [planet(), ...]
  def available_planets do
    [:earth, :moon, :mars]
  end

  @spec gravity(planet()) :: float()
  def gravity(:earth), do: 9.807
  def gravity(:moon), do: 1.62
  def gravity(:mars), do: 3.711
end
