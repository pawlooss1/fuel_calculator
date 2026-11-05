defmodule FuelCalculatorWeb.JourneyFormTest do
  use ExUnit.Case, async: true

  alias FuelCalculator.Journey
  alias FuelCalculatorWeb.JourneyForm

  defp params(mass, steps \\ [{"launch", "earth"}]) do
    rows =
      steps
      |> Enum.with_index()
      |> Map.new(fn {{action, planet}, index} ->
        {Integer.to_string(index), %{"action" => action, "planet" => planet}}
      end)

    %{"mass" => mass, "steps" => rows}
  end

  defp mass_errors(journey_form), do: journey_form.form[:mass].errors

  describe "new/1 with valid params" do
    test "builds the journey and needs no hint" do
      journey_form = JourneyForm.new(params("28801", [{"launch", "earth"}, {"landing", "moon"}]))

      assert journey_form.journey == %Journey{
               mass: 28_801,
               steps: [{:launch, :earth}, {:landing, :moon}]
             }

      assert journey_form.hint == nil
    end

    test "accepts a path starting with a landing or ending with a launch" do
      assert JourneyForm.new(params("1000", [{"landing", "earth"}])).journey
      assert JourneyForm.new(params("1000", [{"launch", "earth"}])).journey
    end

    test "ignores surrounding whitespace in the mass" do
      assert JourneyForm.new(params(" 42 ")).journey.mass == 42
    end
  end

  describe "new/1 with an invalid mass" do
    for {raw, message} <- [
          {"", "can't be blank"},
          {"   ", "can't be blank"},
          {"abc", "must be a whole number"},
          {"12.5", "must be a whole number"},
          {"1e5", "must be a whole number"},
          {"5-", "must be a whole number"},
          {"0", "must be greater than 0"},
          {"-5", "must be greater than 0"},
          {"1000000001", "must be at most 1,000,000,000"}
        ] do
      test "#{inspect(raw)} gives #{inspect(message)} and no journey" do
        journey_form = JourneyForm.new(params(unquote(raw)))

        assert mass_errors(journey_form) == [{unquote(message), []}]
        assert journey_form.journey == nil
        assert journey_form.hint == "Enter a valid spacecraft mass."
      end
    end

    test "a number too large for float math is rejected before any calculation" do
      journey_form = JourneyForm.new(params("1" <> String.duplicate("0", 400)))

      assert mass_errors(journey_form) == [{"must be at most 1,000,000,000", []}]
    end

    test "a missing mass counts as blank" do
      assert mass_errors(JourneyForm.new(%{})) == [{"can't be blank", []}]
    end
  end

  describe "new/1 with invalid selections" do
    test "blank selections leave the row without a step" do
      [row] = JourneyForm.new(params("1000", [{"", ""}])).rows

      assert row.step == nil
      assert row.form[:action].errors == [{"can't be blank", []}]
      assert row.form[:planet].errors == [{"can't be blank", []}]
    end

    test "values outside the allowed lists are invalid" do
      [row] = JourneyForm.new(params("1000", [{"hover", "pluto"}])).rows

      assert row.step == nil
      assert row.form[:action].errors == [{"is invalid", []}]
      assert row.form[:planet].errors == [{"is invalid", []}]
    end

    test "an incomplete row blocks the journey" do
      journey_form = JourneyForm.new(params("1000", [{"launch", "earth"}, {"landing", ""}]))

      assert journey_form.journey == nil
      assert journey_form.hint == "Complete every step and fix any errors."
    end
  end

  describe "new/1 sequence checks" do
    test "two launches in a row" do
      journey_form = JourneyForm.new(params("1000", [{"launch", "earth"}, {"launch", "moon"}]))

      assert [%{error: nil}, %{error: "A launch must be followed by a landing."}] =
               journey_form.rows

      assert journey_form.journey == nil
      assert journey_form.hint == "Complete every step and fix any errors."
    end

    test "two landings in a row" do
      journey_form = JourneyForm.new(params("1000", [{"landing", "moon"}, {"landing", "mars"}]))

      assert [%{error: nil}, %{error: "A landing must be followed by a launch."}] =
               journey_form.rows
    end

    test "a launch from the wrong planet names the right one" do
      journey_form = JourneyForm.new(params("1000", [{"landing", "moon"}, {"launch", "mars"}]))

      assert [%{error: nil}, %{error: "Must launch from Moon, where the previous step landed."}] =
               journey_form.rows
    end

    test "a blank neighbour isn't checked" do
      journey_form =
        JourneyForm.new(params("1000", [{"launch", "earth"}, {"", ""}, {"launch", "moon"}]))

      assert Enum.map(journey_form.rows, & &1.error) == [nil, nil, nil]
    end
  end

  describe "new/1 row handling" do
    test "orders rows numerically past row 10" do
      steps =
        [{"launch", "earth"}, {"landing", "earth"}]
        |> Stream.cycle()
        |> Enum.take(12)

      journey_form = JourneyForm.new(params("1000", steps))

      assert Enum.map(journey_form.rows, & &1.id) == Enum.map(0..11, &Integer.to_string/1)
      assert journey_form.journey.steps == Enum.map(steps, &to_step/1)
    end

    test "drops rows past the step limit" do
      steps =
        [{"launch", "earth"}, {"landing", "earth"}]
        |> Stream.cycle()
        |> Enum.take(Journey.max_steps() + 5)

      journey_form = JourneyForm.new(params("1000", steps))

      assert length(journey_form.rows) == Journey.max_steps()
      assert length(journey_form.journey.steps) == Journey.max_steps()
    end

    test "no rows gives no journey and asks for a step" do
      journey_form = JourneyForm.new(%{"mass" => "1000"})

      assert journey_form.rows == []
      assert journey_form.journey == nil
      assert journey_form.hint == "Add at least one step."
    end

    test "row fields are named so the browser sends them back under the row id" do
      [row] = JourneyForm.new(params("1000")).rows

      assert row.form[:action].name == "journey[steps][0][action]"
      assert row.form[:action].id == "step-0_action"
    end
  end

  describe "from_journey/1" do
    test "round-trips every predefined mission" do
      missions = [
        Journey.apollo_11_mission(),
        Journey.mars_mission(),
        Journey.passenger_ship_mission()
      ]

      for mission <- missions do
        assert JourneyForm.new(JourneyForm.from_journey(mission)).journey == mission
      end
    end
  end

  describe "add_row/1" do
    test "starts at id 0 and then uses the next highest id" do
      once = JourneyForm.add_row(%{})
      assert Map.keys(once["steps"]) == ["0"]

      with_gap = %{"steps" => %{"3" => %{}, "10" => %{}}}
      assert Map.has_key?(JourneyForm.add_row(with_gap)["steps"], "11")
    end

    test "new rows show their prompts and no errors yet" do
      [row] = JourneyForm.new(JourneyForm.add_row(%{})).rows

      assert row.form[:action].value == ""
      refute Phoenix.Component.used_input?(row.form[:action])
      refute Phoenix.Component.used_input?(row.form[:planet])
    end

    test "keeps other params" do
      assert JourneyForm.add_row(%{"mass" => "1000"})["mass"] == "1000"
    end

    test "does nothing at the step limit" do
      full = %{"steps" => Map.new(1..Journey.max_steps(), &{Integer.to_string(&1), %{}})}

      assert JourneyForm.add_row(full) == full
    end
  end

  describe "remove_row/2" do
    test "removes only the given row" do
      params = params("1000", [{"launch", "earth"}, {"landing", "moon"}])

      assert Map.keys(JourneyForm.remove_row(params, "0")["steps"]) == ["1"]
    end

    test "ignores an unknown row" do
      params = params("1000")

      assert JourneyForm.remove_row(params, "99") == params
    end

    test "copes with params that have no rows" do
      assert JourneyForm.remove_row(%{"mass" => "1000"}, "0")["steps"] == %{}
    end
  end

  describe "select options" do
    test "start with a blank prompt and cover every allowed value" do
      assert [{"Select action…", ""} | actions] = JourneyForm.action_options()
      assert [{"Select planet…", ""} | planets] = JourneyForm.planet_options()

      assert Enum.map(actions, &elem(&1, 1)) ==
               Enum.map(Journey.available_actions(), &Atom.to_string/1)

      assert Enum.map(planets, &elem(&1, 1)) ==
               Enum.map(Journey.available_planets(), &Atom.to_string/1)
    end

    test "label the landing action as Land" do
      assert {"Land", "landing"} in JourneyForm.action_options()
    end
  end

  describe "format_number/1" do
    test "adds thousands separators" do
      assert JourneyForm.format_number(0) == "0"
      assert JourneyForm.format_number(999) == "999"
      assert JourneyForm.format_number(1_000) == "1,000"
      assert JourneyForm.format_number(51_898) == "51,898"
      assert JourneyForm.format_number(1_000_000_000) == "1,000,000,000"
    end
  end

  defp to_step({action, planet}) do
    {String.to_existing_atom(action), String.to_existing_atom(planet)}
  end
end
