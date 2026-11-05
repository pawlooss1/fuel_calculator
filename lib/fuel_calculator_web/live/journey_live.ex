defmodule FuelCalculatorWeb.JourneyLive do
  @moduledoc """
  The page for building a flight path and seeing the fuel it needs, updated on every change.
  """

  use FuelCalculatorWeb, :live_view

  import FuelCalculatorWeb.JourneyComponents

  alias FuelCalculator.{Fuel, Journey}
  alias FuelCalculatorWeb.JourneyForm
  alias Phoenix.LiveView.{Rendered, Socket}

  @typep mission :: {id :: String.t(), label :: String.t(), load :: (-> Journey.t())}

  @impl true
  @spec mount(map(), map(), Socket.t()) :: {:ok, Socket.t()}
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(mission_form: to_form(%{"id" => ""}, as: :mission), mission_loads: 0)
      |> assign_journey(%{})

    {:ok, socket}
  end

  @impl true
  @spec handle_event(String.t(), map(), Socket.t()) :: {:noreply, Socket.t()}
  def handle_event("change", %{"journey" => params}, socket) do
    {:noreply, assign_journey(socket, params)}
  end

  def handle_event("add_step", _params, socket) do
    {:noreply, assign_journey(socket, JourneyForm.add_row(socket.assigns.params))}
  end

  def handle_event("remove_step", %{"id" => id}, socket) do
    {:noreply, assign_journey(socket, JourneyForm.remove_row(socket.assigns.params, id))}
  end

  def handle_event("load_mission", %{"mission" => %{"id" => id}}, socket) do
    case List.keyfind(missions(), id, 0) do
      {_id, _label, load} ->
        socket =
          socket
          |> assign_journey(JourneyForm.from_journey(load.()))
          |> update(:mission_loads, &(&1 + 1))

        {:noreply, socket}

      nil ->
        {:noreply, socket}
    end
  end

  @impl true
  @spec render(Socket.assigns()) :: Rendered.t()
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Plan your flight
        <:subtitle>Build a flight path and see how much fuel it needs.</:subtitle>
      </.header>

      <.fuel_total fuel={@fuel} hint={@hint} />

      <div class="card border border-base-300 bg-base-200">
        <div class="card-body gap-2">
          <%!-- a new DOM id resets the select: LiveView won't overwrite a focused one --%>
          <.mission_picker
            form={@mission_form}
            select_id={"mission-select-#{@mission_loads}"}
            options={mission_options()}
          />

          <div class="divider my-1"></div>

          <.form for={@form} id="journey-form" phx-change="change" phx-submit="change">
            <%!-- not type="number": LiveView skips change events on bad input like "5-", which would leave a stale total --%>
            <.input
              field={@form[:mass]}
              type="text"
              label="Spacecraft mass (kg)"
              placeholder="28801"
              inputmode="numeric"
              autocomplete="off"
            />
            <.flight_path rows={@rows} />
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @spec assign_journey(Socket.t(), JourneyForm.params()) :: Socket.t()
  defp assign_journey(socket, params) do
    journey_form = JourneyForm.new(params)

    assign(socket,
      params: params,
      form: journey_form.form,
      rows: journey_form.rows,
      hint: journey_form.hint,
      fuel: required_fuel(journey_form.journey)
    )
  end

  @spec required_fuel(Journey.t() | nil) :: non_neg_integer() | nil
  defp required_fuel(nil), do: nil
  defp required_fuel(%Journey{} = journey), do: Fuel.required_journey_fuel(journey)

  @spec missions() :: [mission(), ...]
  defp missions do
    [
      {"apollo_11", "Apollo 11", &Journey.apollo_11_mission/0},
      {"mars", "Mars Mission", &Journey.mars_mission/0},
      {"passenger_ship", "Passenger Ship", &Journey.passenger_ship_mission/0}
    ]
  end

  @spec mission_options() :: JourneyForm.select_options()
  defp mission_options do
    [{"Load mission…", ""} | Enum.map(missions(), fn {id, label, _load} -> {label, id} end)]
  end
end
