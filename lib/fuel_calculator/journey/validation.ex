defmodule FuelCalculator.Journey.Validation do
  @moduledoc """
  The rules a user-built journey must follow before its fuel is calculated.
  """

  alias FuelCalculator.Journey
  alias FuelCalculator.Journey.Planets

  @max_mass 1_000_000_000
  @max_steps 100

  @typedoc "Why a mass isn't allowed."
  @type mass_error :: :not_positive | :too_large

  @typedoc "Why a step can't follow the previous one."
  @type sequence_error ::
          :expected_landing | :expected_launch | {:expected_launch_from, Planets.planet()}

  @doc "Lists every action a step can have."
  @spec available_actions() :: [Journey.action(), ...]
  def available_actions, do: [:launch, :landing]

  @doc "Returns the largest allowed mass in kg."
  @spec max_mass() :: pos_integer()
  def max_mass, do: @max_mass

  @doc "Returns the largest allowed number of steps."
  @spec max_steps() :: pos_integer()
  def max_steps, do: @max_steps

  @doc "Checks that `mass` is between 1 and `max_mass/0`."
  @spec validate_mass(integer()) :: :ok | {:error, mass_error()}
  def validate_mass(mass) when mass < 1, do: {:error, :not_positive}
  def validate_mass(mass) when mass > @max_mass, do: {:error, :too_large}
  def validate_mass(_mass), do: :ok

  @doc """
  Checks that `next` can follow `previous`.

  Launches and landings must alternate, and a launch must use the planet of the previous landing.
  """
  @spec validate_sequence(Journey.step(), Journey.step()) :: :ok | {:error, sequence_error()}
  def validate_sequence({:launch, _planet}, {:landing, _next_planet}), do: :ok

  def validate_sequence({:launch, _planet}, {:launch, _next_planet}),
    do: {:error, :expected_landing}

  def validate_sequence({:landing, planet}, {:launch, planet}), do: :ok

  def validate_sequence({:landing, planet}, {:launch, _next_planet}),
    do: {:error, {:expected_launch_from, planet}}

  def validate_sequence({:landing, _planet}, {:landing, _next_planet}),
    do: {:error, :expected_launch}
end
