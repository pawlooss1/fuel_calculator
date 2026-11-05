defmodule FuelCalculator.JourneyTest do
  use ExUnit.Case, async: true

  alias FuelCalculator.Journey
  alias FuelCalculator.Journey.Planets

  describe "predefined missions" do
    test "every step uses a known action and planet" do
      missions = [
        Journey.apollo_11_mission(),
        Journey.mars_mission(),
        Journey.passenger_ship_mission()
      ]

      for mission <- missions, {action, planet} <- mission.steps do
        assert action in [:launch, :landing]
        assert planet in Planets.available_planets()
      end
    end
  end

  describe "gravity/1" do
    test "returns the planet's gravity" do
      for planet <- Planets.available_planets() do
        assert Journey.gravity(planet) == Planets.gravity(planet)
      end
    end
  end
end
