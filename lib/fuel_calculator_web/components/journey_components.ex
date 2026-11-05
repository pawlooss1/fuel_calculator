defmodule FuelCalculatorWeb.JourneyComponents do
  @moduledoc """
  Function components for the journey page.
  """

  use FuelCalculatorWeb, :html

  alias FuelCalculator.Journey
  alias FuelCalculatorWeb.JourneyForm
  alias Phoenix.LiveView.Rendered

  @doc "Renders the dropdown that loads a predefined mission."
  attr :form, Phoenix.HTML.Form, required: true
  attr :select_id, :string, required: true, doc: "changing it resets the select to its prompt"
  attr :options, :list, required: true

  @spec mission_picker(map()) :: Rendered.t()
  def mission_picker(assigns) do
    ~H"""
    <.form for={@form} id="mission-form" phx-change="load_mission" phx-auto-recover="ignore">
      <.input
        field={@form[:id]}
        id={@select_id}
        type="select"
        label="Predefined missions"
        options={@options}
      />
    </.form>
    """
  end

  @doc "Renders the editable list of flight-path rows and the button that adds one."
  attr :rows, :list, required: true

  @spec flight_path(map()) :: Rendered.t()
  def flight_path(assigns) do
    ~H"""
    <section id="flight-path" class="mt-4 space-y-3">
      <h2 class="text-sm font-semibold">Flight path</h2>

      <p :if={@rows == []} id="no-steps" class="text-sm text-base-content/70">
        No steps yet. Add one, or load a predefined mission.
      </p>

      <.step_row :for={{row, position} <- Enum.with_index(@rows, 1)} row={row} position={position} />

      <div class="flex flex-wrap items-center gap-3">
        <button
          type="button"
          id="add-step"
          class="btn btn-soft btn-primary btn-sm"
          phx-click="add_step"
          disabled={length(@rows) >= Journey.max_steps()}
        >
          <.icon name="hero-plus" class="size-4" /> Add step
        </button>
        <p
          :if={length(@rows) >= Journey.max_steps()}
          id="max-steps-note"
          class="text-sm text-base-content/70"
        >
          A flight path can have at most {Journey.max_steps()} steps.
        </p>
      </div>
    </section>
    """
  end

  @doc "Renders one flight-path row: its position, action and planet selects, and remove button."
  attr :row, :map, required: true
  attr :position, :integer, required: true

  @spec step_row(map()) :: Rendered.t()
  def step_row(assigns) do
    ~H"""
    <div
      id={"step-#{@row.id}"}
      class="flex items-start gap-2 rounded-box border border-base-300 bg-base-100 p-3 sm:gap-3"
      phx-mounted={
        JS.transition(
          {"ease-out duration-200", "opacity-0 -translate-y-1", "opacity-100 translate-y-0"}
        )
      }
    >
      <span class="badge badge-neutral badge-sm mt-2 w-7 shrink-0">{@position}</span>

      <div class="min-w-0 flex-1">
        <div class="grid gap-x-3 sm:grid-cols-2">
          <.input
            field={@row.form[:action]}
            type="select"
            options={JourneyForm.action_options()}
            aria-label={"Step #{@position} action"}
          />
          <.input
            field={@row.form[:planet]}
            type="select"
            options={JourneyForm.planet_options()}
            aria-label={"Step #{@position} planet"}
          />
        </div>

        <%!-- not an <.input> error: those stay hidden on rows the client reports as unused --%>
        <p
          :if={@row.error}
          id={"step-#{@row.id}-error"}
          class="mb-2 flex items-center gap-2 text-sm text-error"
        >
          <.icon name="hero-exclamation-circle" class="size-5 shrink-0" />
          {@row.error}
        </p>
      </div>

      <button
        type="button"
        id={"remove-step-#{@row.id}"}
        class="btn btn-ghost btn-sm btn-square shrink-0"
        phx-click="remove_step"
        phx-value-id={@row.id}
        aria-label={"Remove step #{@position}"}
      >
        <.icon name="hero-trash" class="size-4" />
      </button>
    </div>
    """
  end

  @doc "Renders the total fuel, or a placeholder and hint while the form is incomplete or invalid."
  attr :fuel, :integer, default: nil
  attr :hint, :string, default: nil

  @spec fuel_total(map()) :: Rendered.t()
  def fuel_total(assigns) do
    ~H"""
    <section
      id="total-fuel"
      aria-live="polite"
      class="stats sticky bottom-4 z-10 w-full border border-base-300 bg-base-100 shadow-lg"
    >
      <div class="stat">
        <div class="stat-title">Total fuel required</div>
        <div
          id="total-fuel-value"
          class={[
            "stat-value text-3xl whitespace-normal break-all transition-colors",
            if(@fuel, do: "text-primary", else: "text-base-content/40")
          ]}
        >
          {if @fuel, do: "#{JourneyForm.format_number(@fuel)} kg", else: "—"}
        </div>
        <div :if={@hint} id="total-fuel-hint" class="stat-desc whitespace-normal">{@hint}</div>
      </div>
    </section>
    """
  end
end
