defmodule FuelCalculator.Fuel do
  alias FuelCalculator.Journey

  @launch_coeff 0.042
  @launch_const 33
  @landing_coeff 0.033
  @landing_const 42

  def required_journey_fuel(journey) do
    journey
    |> preprocess()
    |> apply_calc()
    |> trunc()
  end

  defp preprocess(%Journey{mass: mass, steps: steps}) do
    for {type, planet} <- steps do
      {coeff, const} = resolve_type(type)
      {mass, Journey.gravity(planet), coeff, const}
    end
  end

  defp resolve_type(:launch), do: {@launch_coeff, @launch_const}
  defp resolve_type(:landing), do: {@landing_coeff, @landing_const}

  defp apply_calc(processed_journey) do
    apply_calc(Enum.reverse(processed_journey), 0)
  end

  defp apply_calc([{mass, gravity, coeff, const} | next_steps], acc) do
    step_fuel = required_fuel(mass + acc, gravity, coeff, const)
    apply_calc(next_steps, acc + step_fuel)
  end

  defp apply_calc([], acc) do
    acc
  end

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
