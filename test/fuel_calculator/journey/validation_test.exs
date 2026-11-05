defmodule FuelCalculator.Journey.ValidationTest do
  use ExUnit.Case, async: true

  alias FuelCalculator.{Fuel, Journey}
  alias FuelCalculator.Journey.Validation

  describe "validate_mass/1" do
    test "accepts both ends of the allowed range" do
      assert Validation.validate_mass(1) == :ok
      assert Validation.validate_mass(1_000_000_000) == :ok
    end

    test "rejects zero and negative mass" do
      assert Validation.validate_mass(0) == {:error, :not_positive}
      assert Validation.validate_mass(-1) == {:error, :not_positive}
    end

    test "rejects a mass above the limit" do
      assert Validation.validate_mass(1_000_000_001) == {:error, :too_large}
    end
  end

  describe "validate_sequence/2" do
    test "a landing can follow a launch on any planet, including the one just left" do
      for planet <- Journey.available_planets() do
        assert Validation.validate_sequence({:launch, :earth}, {:landing, planet}) == :ok
      end
    end

    test "a launch can't follow a launch" do
      assert Validation.validate_sequence({:launch, :earth}, {:launch, :earth}) ==
               {:error, :expected_landing}
    end

    test "a landing can't follow a landing" do
      assert Validation.validate_sequence({:landing, :moon}, {:landing, :moon}) ==
               {:error, :expected_launch}
    end

    test "a launch must use the planet of the previous landing" do
      assert Validation.validate_sequence({:landing, :moon}, {:launch, :moon}) == :ok

      assert Validation.validate_sequence({:landing, :moon}, {:launch, :mars}) ==
               {:error, {:expected_launch_from, :moon}}
    end

    test "every predefined mission follows the rules" do
      missions = [
        Journey.apollo_11_mission(),
        Journey.mars_mission(),
        Journey.passenger_ship_mission()
      ]

      for mission <- missions,
          [previous, next] <- Enum.chunk_every(mission.steps, 2, 1, :discard) do
        assert Validation.validate_sequence(previous, next) == :ok
      end
    end
  end

  describe "limits" do
    test "the heaviest allowed journey stays within float math" do
      steps =
        [{:launch, :earth}, {:landing, :earth}]
        |> Stream.cycle()
        |> Enum.take(Validation.max_steps())

      journey = %Journey{mass: Validation.max_mass(), steps: steps}

      assert Fuel.required_journey_fuel(journey) > 0
    end
  end

  describe "the Journey context root" do
    test "exposes the rules" do
      assert Journey.available_actions() == Validation.available_actions()
      assert Journey.max_mass() == Validation.max_mass()
      assert Journey.max_steps() == Validation.max_steps()
      assert Journey.validate_mass(0) == {:error, :not_positive}

      assert Journey.validate_sequence({:landing, :moon}, {:launch, :mars}) ==
               {:error, {:expected_launch_from, :moon}}
    end
  end
end
