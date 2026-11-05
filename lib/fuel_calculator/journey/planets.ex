defmodule FuelCalculator.Journey.Planets do

  def available_planets do
    [:earth, :moon, :mars]
  end

  def gravity(:earth), do: 9.807
  def gravity(:moon), do: 1.62
  def gravity(:mars), do: 3.711
end
