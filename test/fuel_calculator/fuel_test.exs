defmodule FuelCalculator.FuelTest do
  use ExUnit.Case, async: true

  alias FuelCalculator.{Fuel, Journey}

  defp fuel(mass, steps), do: Fuel.required_journey_fuel(%Journey{mass: mass, steps: steps})

  describe "required_journey_fuel/1 with predefined missions" do
    test "Apollo 11 mission" do
      assert Fuel.required_journey_fuel(Journey.apollo_11_mission()) == 51_898
    end

    test "Mars mission" do
      assert Fuel.required_journey_fuel(Journey.mars_mission()) == 33_388
    end

    test "passenger ship mission" do
      assert Fuel.required_journey_fuel(Journey.passenger_ship_mission()) == 212_161
    end
  end

  describe "required_journey_fuel/1 with a single step" do
    test "landing Apollo 11 CSM on Earth includes fuel for the fuel" do
      assert fuel(28_801, [{:landing, :earth}]) == 13_447
    end

    # expected values computed separately with exact decimal arithmetic
    for {action, planet, expected} <- [
          {:launch, :earth, 19_772},
          {:launch, :moon, 2_024},
          {:launch, :mars, 5_186},
          {:landing, :earth, 13_447},
          {:landing, :moon, 1_535},
          {:landing, :mars, 3_874}
        ] do
      test "#{action} on #{planet} at 28801 kg needs #{expected} kg" do
        assert fuel(28_801, [{unquote(action), unquote(planet)}]) == unquote(expected)
      end
    end
  end

  describe "required_journey_fuel/1 with several steps" do
    test "step order changes the total" do
      assert fuel(28_801, [{:launch, :earth}, {:landing, :moon}]) == 22_380
      assert fuel(28_801, [{:landing, :moon}, {:launch, :earth}]) == 22_420
    end

    test "earlier steps also carry the fuel burned by later steps" do
      landing_fuel = fuel(28_801, [{:landing, :moon}])
      launch_fuel = fuel(28_801 + landing_fuel, [{:launch, :earth}])

      assert fuel(28_801, [{:launch, :earth}, {:landing, :moon}]) == launch_fuel + landing_fuel
    end

    test "fuel never decreases as mass grows" do
      steps = Journey.apollo_11_mission().steps
      totals = for mass <- 1..5_000//50, do: fuel(mass, steps)

      assert totals == Enum.sort(totals)
    end
  end

  describe "required_journey_fuel/1 edge cases" do
    test "a journey without steps needs no fuel" do
      assert fuel(28_801, []) == 0
    end

    test "fuel first appears once the formula floors to a positive value" do
      assert fuel(82, [{:launch, :earth}]) == 0
      assert fuel(83, [{:launch, :earth}]) == 1
    end

    test "additional fuel of exactly zero ends the chain" do
      # 532 kg burns 130 kg, and 130 kg floors to 0 more
      assert fuel(532, [{:landing, :earth}]) == 130
    end

    test "zero and negative mass need no fuel" do
      assert fuel(0, [{:launch, :earth}]) == 0
      assert fuel(-5, [{:landing, :moon}]) == 0
    end

    test "a float mass still gives an integer result" do
      assert fuel(1000.5, [{:launch, :earth}]) === 519
    end

    test "an unknown planet raises" do
      assert_raise FunctionClauseError, fn -> fuel(1000, [{:launch, :pluto}]) end
    end

    test "an unknown action raises" do
      assert_raise FunctionClauseError, fn -> fuel(1000, [{:hover, :earth}]) end
    end

    test "a mass too large for float math raises" do
      assert_raise ArithmeticError, fn -> fuel(1.0e308, [{:launch, :earth}]) end
    end
  end
end
