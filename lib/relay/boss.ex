defmodule Stockfighter.Relay.Boss do
  @moduledoc "API Relay host process"
  use Supervisor

  @name :relay_boss
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  def init(_) do
    subordinates = [
      worker(Stockfighter.Relay.Websocket, [[
        host: "api.stockfighter.io",
        path: "/ob/api/ws/SAK5403822/venues/IQSBEX/tickertape"]])]

    supervise subordinates, strategy: :one_for_one
  end
end