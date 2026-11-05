defmodule FuelCalculatorWeb.JourneyLiveValidationTest do
  use FuelCalculatorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  defp open(conn) do
    {:ok, view, _html} = live(conn, ~p"/")
    view
  end

  defp load_apollo(view) do
    view |> form("#mission-form", mission: %{id: "apollo_11"}) |> render_change()
  end

  defp change_journey(view, params) do
    view |> form("#journey-form", journey: params) |> render_change()
  end

  defp placeholder_total?(view), do: has_element?(view, "#total-fuel-value", "—")

  describe "mass" do
    for mass <- ["", "abc", "12.5", "1e5", "5-", "0", "-5", "1000000001"] do
      test "#{inspect(mass)} shows an error and hides the total", %{conn: conn} do
        view = open(conn)
        load_apollo(view)

        change_journey(view, %{mass: unquote(mass)})

        assert has_element?(view, "#journey-form_mass.input-error")
        assert has_element?(view, "#total-fuel-hint")
        assert placeholder_total?(view)
      end
    end

    test "both ends of the allowed range calculate", %{conn: conn} do
      view = open(conn)
      load_apollo(view)

      for mass <- ["1", "1000000000"] do
        change_journey(view, %{mass: mass})

        refute has_element?(view, "#journey-form_mass.input-error")
        refute placeholder_total?(view)
      end
    end

    test "fixing the mass brings the total back", %{conn: conn} do
      view = open(conn)
      load_apollo(view)
      change_journey(view, %{mass: "abc"})

      change_journey(view, %{mass: "28801"})

      refute has_element?(view, "#journey-form_mass.input-error")
      assert has_element?(view, "#total-fuel-value", "51,898 kg")
    end

    test "a number too large for float math doesn't crash the page", %{conn: conn} do
      view = open(conn)
      load_apollo(view)

      change_journey(view, %{mass: "1" <> String.duplicate("0", 400)})

      assert has_element?(view, "#journey-form_mass.input-error")
      assert placeholder_total?(view)
    end
  end

  describe "selections" do
    test "a used blank selection shows an error and hides the total", %{conn: conn} do
      view = open(conn)
      load_apollo(view)

      change_journey(view, %{steps: %{"0" => %{planet: ""}}})

      assert has_element?(view, "#step-0_planet.select-error")
      refute has_element?(view, "#step-0_action.select-error")
      assert placeholder_total?(view)
    end

    test "an unused blank selection shows no error yet", %{conn: conn} do
      view = open(conn)

      render_change(view, "change", %{
        "journey" => %{
          "mass" => "28801",
          "steps" => %{
            "0" => %{
              "action" => "",
              "_unused_action" => "",
              "planet" => "",
              "_unused_planet" => ""
            }
          }
        }
      })

      refute has_element?(view, "#step-0 .select-error")
      assert has_element?(view, "#total-fuel-hint")
      assert placeholder_total?(view)
    end

    test "a crafted value outside the options doesn't crash the page", %{conn: conn} do
      view = open(conn)

      render_change(view, "change", %{
        "journey" => %{
          "mass" => "28801",
          "steps" => %{"0" => %{"action" => "hover", "planet" => "pluto"}}
        }
      })

      assert has_element?(view, "#step-0_action.select-error")
      assert has_element?(view, "#step-0_planet.select-error")
      assert placeholder_total?(view)
    end

    test "crafted rows past the limit are dropped", %{conn: conn} do
      view = open(conn)

      steps =
        Map.new(0..149, fn index ->
          action = if rem(index, 2) == 0, do: "launch", else: "landing"
          {Integer.to_string(index), %{"action" => action, "planet" => "earth"}}
        end)

      render_change(view, "change", %{"journey" => %{"mass" => "1000", "steps" => steps}})

      assert has_element?(view, "#step-99")
      refute has_element?(view, "#step-100")
      refute placeholder_total?(view)
    end
  end

  describe "flight-path sequence" do
    test "two launches in a row block the total", %{conn: conn} do
      view = open(conn)
      load_apollo(view)

      change_journey(view, %{steps: %{"1" => %{action: "launch"}}})

      assert has_element?(view, "#step-1-error")
      assert has_element?(view, "#total-fuel-hint")
      assert placeholder_total?(view)
    end

    test "two landings in a row block the total", %{conn: conn} do
      view = open(conn)
      load_apollo(view)

      change_journey(view, %{steps: %{"2" => %{action: "landing"}}})

      assert has_element?(view, "#step-2-error")
      assert placeholder_total?(view)
    end

    test "a launch from the wrong planet blocks the total", %{conn: conn} do
      view = open(conn)
      load_apollo(view)

      change_journey(view, %{steps: %{"2" => %{planet: "mars"}}})

      assert has_element?(view, "#step-2-error", "Moon")
      assert placeholder_total?(view)
    end

    test "fixing the sequence brings the total back", %{conn: conn} do
      view = open(conn)
      load_apollo(view)
      change_journey(view, %{steps: %{"2" => %{planet: "mars"}}})

      change_journey(view, %{steps: %{"2" => %{planet: "moon"}}})

      refute has_element?(view, "#step-2-error")
      assert has_element?(view, "#total-fuel-value", "51,898 kg")
    end

    test "removing a row can break the sequence", %{conn: conn} do
      view = open(conn)
      load_apollo(view)

      view |> element("#remove-step-1") |> render_click()

      assert has_element?(view, "#step-2-error")
      assert placeholder_total?(view)
    end

    test "the error shows even on a row the client reports as unused", %{conn: conn} do
      # rows from a loaded mission stay unused until touched, which hides <.input> errors
      view = open(conn)

      render_change(view, "change", %{
        "journey" => %{
          "mass" => "28801",
          "steps" => %{
            "0" => %{"action" => "landing", "planet" => "moon"},
            "1" => %{
              "action" => "launch",
              "_unused_action" => "",
              "planet" => "mars",
              "_unused_planet" => ""
            }
          }
        }
      })

      assert has_element?(view, "#step-1-error")
    end

    test "a single landing is a valid path", %{conn: conn} do
      view = open(conn)
      view |> element("#add-step") |> render_click()

      change_journey(view, %{
        mass: "28801",
        steps: %{"0" => %{action: "landing", planet: "earth"}}
      })

      assert has_element?(view, "#total-fuel-value", "13,447 kg")
    end

    test "rows stay in order past row 10", %{conn: conn} do
      view = open(conn)
      for _ <- 1..12, do: view |> element("#add-step") |> render_click()

      steps =
        Map.new(0..11, fn index ->
          action = if rem(index, 2) == 0, do: "launch", else: "landing"
          {Integer.to_string(index), %{action: action, planet: "earth"}}
        end)

      change_journey(view, %{mass: "28801", steps: steps})

      # a string sort would put row 10 before row 2 and break the alternation
      refute has_element?(view, "[id$='-error'][id^='step-']")
      refute placeholder_total?(view)
      assert has_element?(view, "#step-11 .badge", "12")
    end
  end
end
