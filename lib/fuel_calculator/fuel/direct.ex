defmodule FuelCalculator.Fuel.Direct do
  @launch_coeff 0.042
  @launch_const 33
  @landing_coeff 0.033
  @landing_const 42

  def required_launch_fuel(mass, gravity),
    do: required_fuel(mass, gravity, @launch_coeff, @launch_const)

  def required_landing_fuel(mass, gravity),
    do: required_fuel(mass, gravity, @landing_coeff, @landing_const)

  defp required_fuel(mass, gravity, coeff, const) do
    cg = coeff * gravity
    (cg * mass - const) / (1 - cg)
  end
end
