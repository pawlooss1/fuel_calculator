defmodule FuelCalculator.Journey do
  alias FuelCalculator.Journey.Planets

  defstruct [:mass, :steps]

  defdelegate gravity(planet), to: Planets

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
