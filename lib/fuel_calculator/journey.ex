defmodule FuelCalculator.Journey do
  alias FuelCalculator.Journey.Planets

  @type action :: :launch | :landing
  @type step :: {action(), Planets.planet()}
  @type t :: %__MODULE__{mass: pos_integer(), steps: [step()]}

  defstruct [:mass, :steps]

  @spec gravity(Planets.planet()) :: float()
  defdelegate gravity(planet), to: Planets

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
