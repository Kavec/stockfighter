defmodule Stockfighter.Relay.Host do
  @moduledoc "API Relay host process"
  use Supervisor
  @name :relay_host

  @doc false
  def start_link do 
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  @doc false
  def init(_) do
    subordinate = [
      worker(Stockfighter.Relay.Venue, [], restart: :transient)]

    supervise subordinate, strategy: :simple_one_for_one
  end

  @doc false
  def connect(account, venue) do
    Supervisor.start_child(@name, [account, venue])
  end
end