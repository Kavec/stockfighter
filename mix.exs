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
     applications: [:logger]]
  end

  # Dependencies
  defp deps do
    [{:tube,    "~> 0.1.0"},
     {:excheck, "~> 0.5",              only: :test},
     {:triq,    github: "triqng/triq", only: :test}]
  end
end