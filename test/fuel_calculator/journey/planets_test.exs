defmodule FuelCalculator.Journey.PlanetsTest do
  use ExUnit.Case, async: true

  alias FuelCalculator.Journey.Planets

  describe "available_planets/0" do
    test "lists the supported planets" do
      assert Enum.sort(Planets.available_planets()) == [:earth, :mars, :moon]
    end
  end

  describe "gravity/1" do
    test "is defined for every available planet" do
      for planet <- Planets.available_planets() do
        assert is_float(Planets.gravity(planet))
      end
    end

    test "raises for an unknown planet" do
      # apply/3 stops the type checker flagging this deliberate bad call
      assert_raise FunctionClauseError, fn -> apply(Planets, :gravity, [:pluto]) end
    end
  end
end
