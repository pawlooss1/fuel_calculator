defmodule FuelCalculator.Fuel do
  alias FuelCalculator.Journey

  @launch_coeff 0.042
  @launch_const 33
  @landing_coeff 0.033
  @landing_const 42

  @typep step_params ::
           {mass :: pos_integer(), gravity :: float(), coeff :: float(), const :: pos_integer()}
  @typep fuel_formula :: (mass :: number() -> fuel :: float())

  @spec required_journey_fuel(Journey.t()) :: non_neg_integer()
  def required_journey_fuel(journey) do
    journey
    |> preprocess()
    |> apply_calc()
    |> trunc()
  end

  @spec preprocess(Journey.t()) :: [step_params()]
  defp preprocess(%Journey{mass: mass, steps: steps}) do
    for {type, planet} <- steps do
      {coeff, const} = resolve_type(type)
      {mass, Journey.gravity(planet), coeff, const}
    end
  end

  @spec resolve_type(Journey.action()) :: {coeff :: float(), const :: pos_integer()}
  defp resolve_type(:launch), do: {@launch_coeff, @launch_const}
  defp resolve_type(:landing), do: {@landing_coeff, @landing_const}

  @spec apply_calc([step_params()]) :: number()
  defp apply_calc(processed_journey) do
    apply_calc(Enum.reverse(processed_journey), 0)
  end

  @spec apply_calc([step_params()], number()) :: number()
  defp apply_calc([{mass, gravity, coeff, const} | next_steps], acc) do
    step_fuel = required_fuel(mass + acc, gravity, coeff, const)
    apply_calc(next_steps, acc + step_fuel)
  end

  defp apply_calc([], acc) do
    acc
  end

  @spec required_fuel(number(), float(), float(), pos_integer()) :: number()
  defp required_fuel(mass, gravity, coeff, const) do
    f = fn m -> formula(m, gravity, coeff, const) end
    initial_fuel = f.(mass)

    additional_fuel(f, [initial_fuel])
    |> Enum.sum()
  end

  @spec additional_fuel(fuel_formula(), [float(), ...]) :: [float()]
  defp additional_fuel(f, [fuel | _] = all_fuel) when fuel > 0 do
    additional = f.(fuel)
    additional_fuel(f, [additional | all_fuel])
  end

  defp additional_fuel(_f, [fuel | all_fuel]) when fuel <= 0 do
    all_fuel
  end

  @spec formula(number(), float(), float(), pos_integer()) :: float()
  defp formula(mass, gravity, coeff, const) do
    Float.floor(mass * gravity * coeff - const)
  end
end
