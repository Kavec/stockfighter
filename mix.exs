defmodule Stockfighter.Mixfile do
  use Mix.Project

  # Project metadata definition
  def project do
    [app:             :stockfighter,
     version:         "0.1.0", 
     elixir:          "~> 1.3", 
     build_embedded:  Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps:            deps]
  end

  # OTP Application Config
  def application do
    [mod:          {Stockfighter, []},
     applications: [:logger, :gen_stage, :gun]]
  end

  # Dependencies
  defp deps do
    [{:httpoison, "~> 0.9.0"},
     {:gen_stage, "~> 0.4"},
     {:gun,       "~> 1.0.0-pre.1"},
     {:excheck,   "~> 0.5",              only: :test},
     {:triq,      github: "triqng/triq", only: :test}]
  end
end