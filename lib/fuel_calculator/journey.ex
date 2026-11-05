defmodule FuelCalculator.Journey do
  @moduledoc """
  A flight path: the spacecraft's mass and the steps it flies, in order.

  This module is the entry point for planet data, validation rules and the predefined
  missions from the brief.
  """

  alias FuelCalculator.Journey.{Planets, Validation}

  @typedoc "What the spacecraft does at a planet."
  @type action :: :launch | :landing

  @typedoc "One action at one planet."
  @type step :: {action(), Planets.planet()}

  @typedoc "Equipment mass in kg, without fuel, and the steps in flight order."
  @type t :: %__MODULE__{mass: pos_integer(), steps: [step()]}

  defstruct [:mass, :steps]

  @doc "Returns the gravity of `planet` in m/s²."
  @spec gravity(Planets.planet()) :: float()
  defdelegate gravity(planet), to: Planets

  @doc "Lists every supported planet."
  @spec available_planets() :: [Planets.planet(), ...]
  defdelegate available_planets(), to: Planets

  @doc "Lists every action a step can have."
  @spec available_actions() :: [action(), ...]
  defdelegate available_actions(), to: Validation

  @doc "Returns the largest allowed mass in kg."
  @spec max_mass() :: pos_integer()
  defdelegate max_mass(), to: Validation

  @doc "Returns the largest allowed number of steps."
  @spec max_steps() :: pos_integer()
  defdelegate max_steps(), to: Validation

  @doc "Checks that `mass` is between 1 and `max_mass/0`."
  @spec validate_mass(integer()) :: :ok | {:error, Validation.mass_error()}
  defdelegate validate_mass(mass), to: Validation

  @doc """
  Checks that `next` can follow `previous`.

  Launches and landings must alternate, and a launch must use the planet of the previous landing.
  """
  @spec validate_sequence(step(), step()) :: :ok | {:error, Validation.sequence_error()}
  defdelegate validate_sequence(previous, next), to: Validation

  @doc "Apollo 11: from Earth to the Moon and back, at 28801 kg."
  @spec apollo_11_mission() :: t()
  def apollo_11_mission do
    %__MODULE__{
      mass: 28801,
      steps: [
        {:launch, :earth},
        {:landing, :moon},
        {:launch, :moon},
        {:landing, :earth}
      ]
    }
  end

  @doc "Mars mission: from Earth to Mars and back, at 14606 kg."
  @spec mars_mission() :: t()
  def mars_mission do
    %__MODULE__{
      mass: 14606,
      steps: [
        {:launch, :earth},
        {:landing, :mars},
        {:launch, :mars},
        {:landing, :earth}
      ]
    }
  end

  @doc "Passenger ship: from Earth to the Moon, on to Mars and back to Earth, at 75432 kg."
  @spec passenger_ship_mission() :: t()
  def passenger_ship_mission do
    %__MODULE__{
      mass: 75432,
      steps: [
        {:launch, :earth},
        {:landing, :moon},
        {:launch, :moon},
        {:landing, :mars},
        {:launch, :mars},
        {:landing, :earth}
      ]
    }
  end
end
