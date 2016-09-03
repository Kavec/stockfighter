defmodule Stockfighter.Relay do
  @moduledoc "Stockfighter API Relay"
  use GenServer
  
  alias __MODULE__, as: Relay
  
  @name :relay

  defstruct [
    :account,
    :venue,
    :stocks,
    :traded
  ]

  @type t :: %Relay{
    account: binary,
    venue:   binary,
    stocks:  %{},
    traded:  %{}
  }

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  def init(_) do
    IO.puts "#{inspect Process.whereis(@name)}"
    {:ok, %{}}
  end

  @spec access(binary, binary) :: pid
  def access(account, venue) do
    GenServer.call(@name, {:access, account, venue})
  end

  @doc false
  def handle_call({:access, account, venue}, _from, state) do
    {:ok, pid} =
      case Map.get(state, {account, venue}) do
        nil -> {:ok, pid} = Relay.Host.connect(account, venue)
        pid -> {:ok, pid}
      end

    {:reply, pid, Map.put_new(state, {account, venue}, pid)}
  end

  def handle_call(msg, _from, state) do
    IO.puts "Received other msg:"
    IO.puts "  #{inspect msg}"
    {:reply, nil, state}
  end
end