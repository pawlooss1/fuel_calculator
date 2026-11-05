defmodule FuelCalculatorWeb.JourneyLiveTest do
  use FuelCalculatorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  defp open(conn) do
    {:ok, view, _html} = live(conn, ~p"/")
    view
  end

  defp load_mission(view, id) do
    view |> form("#mission-form", mission: %{id: id}) |> render_change()
  end

  defp add_step(view), do: view |> element("#add-step") |> render_click()

  defp change_journey(view, params) do
    view |> form("#journey-form", journey: params) |> render_change()
  end

  defp row_ids(view) do
    view
    |> element("#flight-path")
    |> render()
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("#flight-path > div[id^='step-']")
    |> LazyHTML.attribute("id")
  end

  defp total?(view, text), do: has_element?(view, "#total-fuel-value", text)

  describe "empty page" do
    test "shows the form, no steps and a placeholder total", %{conn: conn} do
      view = open(conn)

      assert has_element?(view, "#mission-form")
      assert has_element?(view, "#journey-form")
      assert has_element?(view, "#no-steps")
      assert total?(view, "—")
      assert has_element?(view, "#total-fuel-hint")
      assert row_ids(view) == []
    end

    test "shows no errors before anything is touched", %{conn: conn} do
      view = open(conn)

      refute has_element?(view, "#journey-form_mass.input-error")
    end

    test "takes the mass in a text input, so bad input reaches the server", %{conn: conn} do
      # LiveView skips change events for bad input in a number field
      assert has_element?(open(conn), "#journey-form_mass[type='text']")
    end
  end

  describe "predefined missions" do
    for {id, mass, rows, total} <- [
          {"apollo_11", "28801", 4, "51,898 kg"},
          {"mars", "14606", 4, "33,388 kg"},
          {"passenger_ship", "75432", 6, "212,161 kg"}
        ] do
      test "#{id} fills in the form and shows its total", %{conn: conn} do
        view = open(conn)

        load_mission(view, unquote(id))

        assert has_element?(view, "#journey-form_mass[value='#{unquote(mass)}']")
        assert length(row_ids(view)) == unquote(rows)
        assert total?(view, unquote(total))
        refute has_element?(view, "#total-fuel-hint")
      end
    end

    test "loading a mission replaces the current form", %{conn: conn} do
      view = open(conn)
      load_mission(view, "passenger_ship")

      load_mission(view, "mars")

      assert has_element?(view, "#journey-form_mass[value='14606']")
      assert has_element?(view, "#step-1_planet option[value='mars'][selected]")
      assert length(row_ids(view)) == 4
    end

    test "the mission's rows stay editable", %{conn: conn} do
      view = open(conn)
      load_mission(view, "apollo_11")

      view |> element("#remove-step-3") |> render_click()

      assert total?(view, "kg")
      refute total?(view, "51,898 kg")
    end

    test "the dropdown goes back to its prompt on a fresh element", %{conn: conn} do
      view = open(conn)
      assert has_element?(view, "#mission-select-0")

      load_mission(view, "apollo_11")

      assert has_element?(view, "#mission-select-1 option[value=''][selected]")
      refute has_element?(view, "#mission-select-0")
    end

    test "mission rows don't take focus when they appear", %{conn: conn} do
      view = open(conn)

      load_mission(view, "apollo_11")

      refute has_element?(view, "#step-0[phx-mounted*='focus']")
    end

    test "picking the prompt changes nothing", %{conn: conn} do
      view = open(conn)
      load_mission(view, "apollo_11")

      render_change(view, "load_mission", %{"mission" => %{"id" => ""}})

      assert total?(view, "51,898 kg")
      assert has_element?(view, "#mission-select-1")
    end

    test "an unknown mission is ignored", %{conn: conn} do
      view = open(conn)

      render_change(view, "load_mission", %{"mission" => %{"id" => "voyager"}})

      assert has_element?(view, "#no-steps")
    end
  end

  describe "real-time total" do
    test "follows edits to the mass", %{conn: conn} do
      view = open(conn)
      add_step(view)

      change_journey(view, %{
        mass: "28801",
        steps: %{"0" => %{action: "landing", planet: "earth"}}
      })

      assert total?(view, "13,447 kg")

      change_journey(view, %{mass: "532"})

      assert total?(view, "130 kg")
    end

    test "follows edits to a row", %{conn: conn} do
      view = open(conn)
      add_step(view)

      change_journey(view, %{mass: "28801", steps: %{"0" => %{action: "launch", planet: "earth"}}})

      assert total?(view, "19,772 kg")

      change_journey(view, %{steps: %{"0" => %{planet: "moon"}}})

      assert total?(view, "2,024 kg")
    end

    test "shows 0 kg when a valid journey needs no fuel", %{conn: conn} do
      view = open(conn)
      add_step(view)

      change_journey(view, %{mass: "1", steps: %{"0" => %{action: "launch", planet: "earth"}}})

      assert total?(view, "0 kg")
    end
  end

  describe "adding steps" do
    test "appends a row with prompts selected and no errors", %{conn: conn} do
      view = open(conn)

      add_step(view)

      assert row_ids(view) == ["step-0"]
      refute has_element?(view, "#no-steps")
      assert has_element?(view, "#step-0_action option[value=''][selected]")
      assert has_element?(view, "#step-0_planet option[value=''][selected]")
      refute has_element?(view, "#step-0 .select-error")
      assert total?(view, "—")
    end

    test "new rows go after existing ones", %{conn: conn} do
      view = open(conn)
      load_mission(view, "apollo_11")

      add_step(view)

      assert row_ids(view) == ["step-0", "step-1", "step-2", "step-3", "step-4"]
    end

    test "a new row takes focus so it scrolls into view", %{conn: conn} do
      view = open(conn)

      add_step(view)

      assert has_element?(view, "#step-0[phx-mounted*='focus']")
    end

    test "keeps what was already entered", %{conn: conn} do
      view = open(conn)
      change_journey(view, %{mass: "28801"})

      add_step(view)

      assert has_element?(view, "#journey-form_mass[value='28801']")
    end

    test "stops at the step limit", %{conn: conn} do
      view = open(conn)
      refute has_element?(view, "#max-steps-note")

      for _ <- 1..100, do: add_step(view)

      assert length(row_ids(view)) == 100
      assert has_element?(view, "#add-step[disabled]")
      assert has_element?(view, "#max-steps-note")

      render_click(view, "add_step")
      assert length(row_ids(view)) == 100
    end
  end

  describe "removing steps" do
    test "removes the chosen row and renumbers the rest", %{conn: conn} do
      view = open(conn)
      load_mission(view, "apollo_11")

      view |> element("#remove-step-1") |> render_click()

      assert row_ids(view) == ["step-0", "step-2", "step-3"]
      assert has_element?(view, "#step-2 .badge", "2")
    end

    test "removing every row brings the empty state back", %{conn: conn} do
      view = open(conn)
      add_step(view)

      view |> element("#remove-step-0") |> render_click()

      assert has_element?(view, "#no-steps")
      assert total?(view, "—")
    end

    test "updates the total", %{conn: conn} do
      view = open(conn)
      load_mission(view, "apollo_11")

      for id <- ~w(1 2 3), do: view |> element("#remove-step-#{id}") |> render_click()

      # launch from Earth alone at 28801 kg
      assert total?(view, "19,772 kg")
    end
  end

  describe "submitting" do
    test "keeps the form and total, so Enter doesn't lose anything", %{conn: conn} do
      view = open(conn)
      load_mission(view, "apollo_11")

      view |> form("#journey-form", journey: %{mass: "28801"}) |> render_submit()

      assert total?(view, "51,898 kg")
      assert length(row_ids(view)) == 4
    end
  end
end
