defmodule Stockfighter.Mixfile do
  use Mix.Project

  def project do
    [app:     :stockfighter,
     version: "0.0.1",
     elixir:  "~> 1.2.0-rc.0",
     build_embedded:  Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [mod: {Stockfighter, []},
     applications: [:logger, :phoenix]]
  end

  # Type "mix help deps" for more examples and options
  defp deps do
    [{:poison,  "~> 1.5"},
     {:phoenix, "~> 1.0"},
     # excheck is local to shut up warnings
     {:excheck, path: "../excheck", only: :test}, 
     {:triq, github: "krestenkrab/triq", only: :test}]
  end
end
