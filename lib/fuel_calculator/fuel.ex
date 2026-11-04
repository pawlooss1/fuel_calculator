defmodule FuelCalculator.Fuel do
  alias FuelCalculator.Fuel.Iterative
  alias FuelCalculator.Fuel.Direct

  def required_launch_fuel(mass, gravity, :iterative),
    do: Iterative.required_launch_fuel(mass, gravity)

  def required_launch_fuel(mass, gravity, :direct),
    do: Direct.required_launch_fuel(mass, gravity)

  def required_landing_fuel(mass, gravity, :iterative),
    do: Iterative.required_landing_fuel(mass, gravity)

  def required_landing_fuel(mass, gravity, :direct),
    do: Direct.required_landing_fuel(mass, gravity)
end
