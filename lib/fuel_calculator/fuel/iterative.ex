defmodule FuelCalculator.Fuel.Iterative do
  @launch_coeff 0.042
  @launch_const 33
  @landing_coeff 0.033
  @landing_const 42

  def required_launch_fuel(mass, gravity),
    do: required_fuel(mass, gravity, @launch_coeff, @launch_const)

  def required_landing_fuel(mass, gravity),
    do: required_fuel(mass, gravity, @landing_coeff, @landing_const)

  defp required_fuel(mass, gravity, coeff, const) do
    f = fn m -> formula(m, gravity, coeff, const) end
    initial_fuel = f.(mass)

    additional_fuel(f, [initial_fuel])
    |> Enum.sum()
  end

  defp additional_fuel(f, [fuel | _] = all_fuel) when fuel > 0 do
    additional = f.(fuel)
    additional_fuel(f, [additional | all_fuel])
  end

  defp additional_fuel(_f, [fuel | all_fuel]) when fuel <= 0 do
    all_fuel
  end

  defp formula(mass, gravity, coeff, const) do
    Float.floor(mass * gravity * coeff - const)
  end
end
