defmodule FuelCalculator.Journey do
  @moduledoc """
  A flight path: the spacecraft's mass and the steps it flies, in order.

  Also provides the predefined missions from the brief.
  """

  alias FuelCalculator.Journey.Planets

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
