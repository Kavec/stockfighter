alias Experimental.GenStage

defmodule Stockfighter.Exchange.Venue do
  @moduledoc "Internal module handling venue-wide operations"

  use   GenStage
  alias Stockfighter.Exchange

  @doc "Connect to a venue"
  @spec connect(binary, binary) :: {:ok, pid}
  def connect(account, venue) do
    {:ok, _pid} = 
      GenServer.call(:venue_broker, {:connect, account, venue})
  end

  @doc """
    Disconnect from a venue. Feed pids may remain active after
    disconnect if venue is in use by other process. However,
    connection cannot be relied on as being active after your
    process calls for a disconnect.
  """
  @spec disconnect(binary, binary) :: :ok
  def disconnect(account, venue) do
    GenServer.call(:venue_broker, {:disconnect, account, venue})
    :ok
  end

  @doc false
  def start(account, venue) do
    Exchange.VenueHost.start_venue(account, venue)
  end

  @doc false
  def start_link(account, venue) do
    GenStage.start_link(__MODULE__, [account, venue])
  end

  @doc false
  def init([account, venue]) do
    alias Exchange.Relay

    execs = 
      Relay.ws_execs(account, venue)
      |> Relay.ws_connect(self, &GenStage.cast/2)

    ttape = 
      Relay.ws_ttape(account, venue)
      |> Relay.ws_connect(self, &GenStage.cast/2)

    state = %{
      :active => false,
      :conns  =>  {execs, ttape},
      execs   => :connecting,
      ttape   => :connecting
    }

    {:producer, state}
  end

  defp on_connect(%{:active => true}  = state), do: state
  defp on_connect(%{:active => false} = state) do
    {execs, ttape} = state.conns

    with :connected <- state[execs],
         :connected <- state[ttape] do

      IO.puts "Connected to #{state.venue} as #{state.account}, happy trading!"
      Map.put(state, :active, true)
      
    else _ -> state end
  end

  @doc false
  def stop(pid) do
    GenStage.cast(pid, :shutdown)
  end

  @doc false
  def handle_cast({:connect, ws_pid}, state) do
    state = state
      |> Map.put(ws_pid, :connected)
      |> on_connect

    {:noreply, [], state}
  end

  def handle_cast({:reconnecting, ws_pid}, state) do
    {:noreply, [], Map.put(state, ws_pid, :reconnecting)}
  end

  def handle_cast({:pong_data, data}, state) do
    IO.puts "Received unexpected ping data:"
    IO.puts " #{inspect data}"
    {:noreply, [], state}
  end

  def handle_cast({:unk_msg, msg}, state) do
    IO.puts "Websocket process received unhandled message:"
    IO.puts " #{inspect msg}"
    {:noreply, [], state}
  end

  def handle_cast({:ws, mtype, data}, state) do
    IO.puts "Received Websocket #{inspect mtype} message:"
    IO.puts "  #{data}"
    {:noreply, [], state}
  end

  def handle_cast(:shutdown, state) do
    {:stop, :shutdown, state}
  end

  # NB. that terminate is only called in optimal circumstances
  @doc false
  def terminate(_reason, state) do
    Enum.each(state.conns, &Exchange.Relay.ws_shutdown/1)
  end
end