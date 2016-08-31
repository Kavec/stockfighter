defmodule Stockfighter.Relay.Boss do
  @moduledoc "API Relay host process"
  use Supervisor

  @name :relay_boss
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  def init(_) do
    subordinates = []

    supervise subordinates, stategy: :simple_one_for_one
  end
end