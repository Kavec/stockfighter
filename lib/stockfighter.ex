defmodule Stockfighter do
  use Application

  def start(_type, _args) do
    Stockfighter.start_link([])
  end

  # // ---- ---- ---- ---- ---- ---- ---- // #
  use Supervisor

  def start_link(args \\ []) do
    Supervisor.start_link(__MODULE__, args)
  end

  # Host supervisor init
  def init(_) do
    subordinates = [
      # Define subordinates in startup order, eg:
        # worker(Stockfighter.Worker, [arg1, ..., argN]),
        # supervisor(Stockfighter.Sup, [arg1, ..., argN])
      supervisor(Stockfighter.Exchange, [])
    ]

    # Launch subordinate programs and get goin'!
    supervise subordinates, strategy: :rest_for_one
  end
end