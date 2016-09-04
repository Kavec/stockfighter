alias Experimental.GenStage

defmodule Stockfighter.Relay.Venue do
  @moduledoc "Main interface for each trading venue."

  use GenStage

  @doc false
  def start_link(account, venue) do
    GenStage.start_link(__MODULE__, [account, venue])
  end

  def init([account, venue]) do
    alias Stockfighter.Relay.API

    execs = 
      API.ws_execs(account, venue)
      |> API.ws_connect(self, &GenStage.cast/2)

    ttape = 
      API.ws_ttape(account, venue)
      |> API.ws_connect(self, &GenStage.cast/2)

    state = %{
      account: account,
      venue:   venue,
      conns:   {execs, ttape},
      active:  false}
      |> Map.put(execs, :connecting)
      |> Map.put(ttape, :connecting)

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

  def handle_cast({:connected, ws_pid}, state) do
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

  # NB. that terminate is only called in optimal circumstances
  @doc false
  def terminate(_reason, state) do
    alias Stockfighter.Relay.API

    Enum.each(state.conns, &API.ws_shutdown/1)
  end

end