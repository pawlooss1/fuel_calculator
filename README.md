# Fuel Calculator

A Phoenix LiveView app that calculates how much fuel a spacecraft needs for a flight path.

You enter the equipment mass and list the flight's steps in order: a launch from or a landing on
Earth, the Moon or Mars. The page recalculates the total fuel on every change. It checks that the
path makes sense: launches and landings must alternate, and each launch must leave from the planet
of the previous landing. Three missions from the brief (Apollo 11, Mars, passenger ship) can be
loaded from a dropdown.

The calculation lives in `FuelCalculator.Fuel`. Planet data, validation rules and the preset
missions are reached through `FuelCalculator.Journey`. The page itself is
`FuelCalculatorWeb.JourneyLive`.

## Requirements

- Elixir and Erlang/OTP. CI uses Elixir 1.20.2 on OTP 29.0.2, so those versions are known to work.
- No database. The project was generated without Ecto.

## Running the dev server

```bash
mix setup
mix phx.server
```

`mix setup` fetches dependencies, installs the Tailwind and esbuild binaries and builds the assets.
After that, open [localhost:4000](http://localhost:4000).

To get an IEx shell attached to the running server, start it with `iex -S mix phx.server` instead.
Set `PORT` to use another port, for example `PORT=4001 mix phx.server`. In dev, the LiveDashboard
is available at [localhost:4000/dev/dashboard](http://localhost:4000/dev/dashboard).

## Running tests

```bash
mix test
```

The tests are split into two groups:

- `test/fuel_calculator/` covers the fuel formula, the preset missions, planet data and the
  validation rules.
- `test/fuel_calculator_web/` covers the web layer: `JourneyForm`, which turns form params into a
  journey and error messages, and the LiveView itself (adding and removing steps, loading missions,
  the live total, and the errors for an invalid mass or step sequence).

To run one group or file, pass its path, for example `mix test test/fuel_calculator`. Use
`mix test --failed` to rerun only the tests that failed last time.

Before committing, run:

```bash
mix precommit
```

It compiles with warnings as errors, removes unused dependencies from `mix.lock`, formats the code
and runs the tests. It doesn't run Credo or Dialyzer, so see below for those.

## CI

The workflow in `.github/workflows/elixir.yml` runs on every push to `main` and on every pull
request. All jobs use `MIX_ENV=test`.

A **Build** job runs first. It fetches dependencies, fails if `mix.lock` contains unused
dependencies, and compiles with warnings as errors. It caches `deps` and `_build` for the commit,
and the other jobs then run in parallel from that cache:

| Job          | Command                        | What it checks                                                                 |
| ------------ | ------------------------------ | ------------------------------------------------------------------------------ |
| Tests        | `mix test`                     | The whole test suite passes.                                                   |
| Dialyzer     | `mix dialyzer --format github` | The typespecs agree with the code. Warnings appear as annotations on the PR.   |
| Credo        | `mix credo --strict`           | Code style and consistency, including the low-priority checks.                |
| Format check | `mix format --check-formatted` | The code is formatted as `mix format` would leave it.                          |

Dialyzer keeps its PLTs in `priv/plts` (gitignored), and CI caches that folder, so only the first
run has to build them. `.dialyzer_ignore.exs` lists one known false positive: LiveView declares
the internals of `Phoenix.LiveView.JS` as opaque, so Dialyzer rejects the `JS.t()` spec on
`JourneyComponents.row_mounted/1`.

To run the same checks locally:

```bash
mix deps.unlock --check-unused
```

```bash
MIX_ENV=test mix compile --warnings-as-errors
```

```bash
mix test
```

```bash
MIX_ENV=test mix dialyzer
```

```bash
mix credo --strict
```

```bash
mix format --check-formatted
```

The first Dialyzer run builds the PLTs and takes a few minutes. Later runs reuse them.
