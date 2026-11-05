defmodule FuelCalculator.Journey.Planets do
  @moduledoc """
  The planets a journey can visit and their gravity.
  """

  @typedoc "A supported planet."
  @type planet :: :earth | :moon | :mars

  @doc "Lists every supported planet."
  @spec available_planets() :: [planet(), ...]
  def available_planets do
    [:earth, :moon, :mars]
  end

  @doc "Returns the gravity of `planet` in m/s²."
  @spec gravity(planet()) :: float()
  def gravity(:earth), do: 9.807
  def gravity(:moon), do: 1.62
  def gravity(:mars), do: 3.711
end
