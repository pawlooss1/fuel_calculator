defmodule FuelCalculatorWeb.JourneyForm do
  @moduledoc """
  Turns raw journey form params into what the page renders and, when valid, a `Journey`.

  Params hold `"mass"` and `"steps"`, a map from row id to that row's `"action"` and
  `"planet"`. New rows always get the highest id, so numeric id order is flight order.
  """

  import Phoenix.Component, only: [to_form: 2]

  alias FuelCalculator.Journey
  alias Phoenix.HTML.Form

  # "" keeps the prompt option selected, and the _unused_ markers hide errors until the row is used
  @blank_row %{"action" => "", "_unused_action" => "", "planet" => "", "_unused_planet" => ""}

  @typedoc "Raw form params, as sent by the browser."
  @type params :: %{optional(String.t()) => term()}

  @typedoc "A flight-path row, ready to render. `step` is `nil` until both selects are valid."
  @type row :: %{
          id: String.t(),
          form: Form.t(),
          step: Journey.step() | nil,
          error: String.t() | nil
        }

  @typedoc "Label and value pairs for a select."
  @type select_options :: [{label :: String.t(), value :: String.t()}, ...]

  @typedoc "What the page renders, plus the `Journey` when the params are valid."
  @type t :: %__MODULE__{
          form: Form.t(),
          rows: [row()],
          hint: String.t() | nil,
          journey: Journey.t() | nil
        }

  @typep parsed(value) :: {:ok, value} | {:error, message :: String.t()}

  defstruct [:form, :rows, :hint, :journey]

  @doc "Validates `params` and builds everything the page needs from them."
  @spec new(params()) :: t()
  def new(params) do
    mass = parse_mass(Map.get(params, "mass", ""))
    rows = build_rows(Map.get(params, "steps", %{}))
    journey = build_journey(mass, rows)

    %__MODULE__{
      form: to_form(params, as: :journey, id: "journey-form", errors: field_errors(mass: mass)),
      rows: rows,
      hint: hint(journey, mass, rows),
      journey: journey
    }
  end

  @doc "Converts `journey` to form params."
  @spec from_journey(Journey.t()) :: params()
  def from_journey(%Journey{mass: mass, steps: steps}) do
    rows =
      steps
      |> Enum.with_index()
      |> Map.new(fn {{action, planet}, index} ->
        row = %{"action" => Atom.to_string(action), "planet" => Atom.to_string(planet)}
        {Integer.to_string(index), row}
      end)

    %{"mass" => Integer.to_string(mass), "steps" => rows}
  end

  @doc "Adds a blank row at the end of the path, unless the path is already at its step limit."
  @spec add_row(params()) :: params()
  def add_row(params) do
    steps = Map.get(params, "steps", %{})

    if map_size(steps) < Journey.max_steps() do
      Map.put(params, "steps", Map.put(steps, next_row_id(steps), @blank_row))
    else
      params
    end
  end

  @doc "Removes the row with the given id."
  @spec remove_row(params(), String.t()) :: params()
  def remove_row(params, id) do
    Map.update(params, "steps", %{}, &Map.delete(&1, id))
  end

  @doc "Returns the options for a step's action select, starting with its prompt."
  @spec action_options() :: select_options()
  def action_options do
    [{"Select action…", ""} | Enum.map(Journey.available_actions(), &action_option/1)]
  end

  @doc "Returns the options for a step's planet select, starting with its prompt."
  @spec planet_options() :: select_options()
  def planet_options do
    [{"Select planet…", ""} | Enum.map(Journey.available_planets(), &planet_option/1)]
  end

  @doc "Formats `number` with thousands separators, such as `51,898`."
  @spec format_number(integer()) :: String.t()
  def format_number(number) do
    number
    |> Integer.to_string()
    |> String.replace(~r/\B(?=(\d{3})+$)/, ",")
  end

  @spec parse_mass(String.t()) :: parsed(pos_integer())
  defp parse_mass(raw) do
    with trimmed when trimmed != "" <- String.trim(raw),
         {mass, ""} <- Integer.parse(trimmed),
         :ok <- Journey.validate_mass(mass) do
      {:ok, mass}
    else
      "" -> {:error, "can't be blank"}
      {:error, :not_positive} -> {:error, "must be greater than 0"}
      {:error, :too_large} -> {:error, "must be at most #{format_number(Journey.max_mass())}"}
      _not_a_whole_number -> {:error, "must be a whole number"}
    end
  end

  @spec build_rows(%{optional(String.t()) => params()}) :: [row()]
  defp build_rows(steps_params) do
    {rows, _last_step} =
      steps_params
      # numeric sort: as strings, row 10 would come before row 2
      |> Enum.sort_by(fn {id, _row_params} -> String.to_integer(id) end)
      |> Enum.take(Journey.max_steps())
      |> Enum.map_reduce(nil, fn {id, row_params}, previous_step ->
        row = build_row(id, row_params, previous_step)
        {row, row.step}
      end)

    rows
  end

  @spec build_row(String.t(), params(), Journey.step() | nil) :: row()
  defp build_row(id, row_params, previous_step) do
    action = parse_choice(row_params["action"], Journey.available_actions())
    planet = parse_choice(row_params["planet"], Journey.available_planets())
    step = to_step(action, planet)

    %{
      id: id,
      form:
        to_form(row_params,
          as: "journey[steps][#{id}]",
          id: "step-#{id}",
          errors: field_errors(action: action, planet: planet)
        ),
      step: step,
      error: sequence_error(previous_step, step)
    }
  end

  @spec parse_choice(term(), [choice, ...]) :: parsed(choice) when choice: atom()
  defp parse_choice(raw, _allowed) when raw in [nil, ""], do: {:error, "can't be blank"}

  defp parse_choice(raw, allowed) do
    case Enum.find(allowed, &(Atom.to_string(&1) == raw)) do
      nil -> {:error, "is invalid"}
      choice -> {:ok, choice}
    end
  end

  @spec to_step(parsed(Journey.action()), parsed(Journey.Planets.planet())) ::
          Journey.step() | nil
  defp to_step({:ok, action}, {:ok, planet}), do: {action, planet}
  defp to_step(_action, _planet), do: nil

  @spec sequence_error(Journey.step() | nil, Journey.step() | nil) :: String.t() | nil
  defp sequence_error(previous, step) when is_nil(previous) or is_nil(step), do: nil

  defp sequence_error(previous, step) do
    case Journey.validate_sequence(previous, step) do
      :ok -> nil
      {:error, reason} -> sequence_message(reason)
    end
  end

  @spec sequence_message(FuelCalculator.Journey.Validation.sequence_error()) :: String.t()
  defp sequence_message(:expected_landing), do: "A launch must be followed by a landing."
  defp sequence_message(:expected_launch), do: "A landing must be followed by a launch."

  defp sequence_message({:expected_launch_from, planet}) do
    "Must launch from #{planet_label(planet)}, where the previous step landed."
  end

  @spec build_journey(parsed(pos_integer()), [row()]) :: Journey.t() | nil
  defp build_journey({:ok, mass}, [_first | _rest] = rows) do
    if Enum.all?(rows, &(&1.step && is_nil(&1.error))) do
      %Journey{mass: mass, steps: Enum.map(rows, & &1.step)}
    end
  end

  defp build_journey(_mass, _rows), do: nil

  @spec hint(Journey.t() | nil, parsed(pos_integer()), [row()]) :: String.t() | nil
  defp hint(%Journey{}, _mass, _rows), do: nil
  defp hint(nil, {:error, _message}, _rows), do: "Enter a valid spacecraft mass."
  defp hint(nil, {:ok, _mass}, []), do: "Add at least one step."
  defp hint(nil, {:ok, _mass}, _rows), do: "Complete every step and fix any errors."

  @spec field_errors(keyword(parsed(term()))) :: keyword({String.t(), keyword()})
  defp field_errors(parsed_fields) do
    for {field, {:error, message}} <- parsed_fields, do: {field, {message, []}}
  end

  @spec next_row_id(%{optional(String.t()) => params()}) :: String.t()
  defp next_row_id(steps) when map_size(steps) == 0, do: "0"

  defp next_row_id(steps) do
    steps
    |> Map.keys()
    |> Enum.map(&String.to_integer/1)
    |> Enum.max()
    |> Kernel.+(1)
    |> Integer.to_string()
  end

  @spec action_option(Journey.action()) :: {String.t(), String.t()}
  defp action_option(:launch), do: {"Launch", "launch"}
  defp action_option(:landing), do: {"Land", "landing"}

  @spec planet_option(Journey.Planets.planet()) :: {String.t(), String.t()}
  defp planet_option(planet), do: {planet_label(planet), Atom.to_string(planet)}

  @spec planet_label(Journey.Planets.planet()) :: String.t()
  defp planet_label(planet), do: Phoenix.Naming.humanize(planet)
end
