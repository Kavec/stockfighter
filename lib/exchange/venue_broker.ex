defmodule Stockfighter.Exchange.VenueBroker do
  @moduledoc "Ensures we only connect once per venue x account"
  
  use   GenServer
  alias Stockfighter.Exchange
  @name :venue_broker

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  @doc false
  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:connect, account, venue}, _from, state) do
    {vpid, instances} =
      connect_once account, venue, Map.get(state, {account, venue})

    {:reply, vpid, Map.put(state, {account, venue}, {vpid, instances})}
  end

  def handle_call({:disconnect, account, venue}, _from, state) do
    update = 
      disconnect_once Map.get(state, {account, venue})

    {:reply, :ok, Map.put(state, {account, venue}, update)}
  end

  defp connect_once(account, venue, :nil),     do: {connect(account, venue), 1}
  defp connect_once(account, venue, {_p, 0}),  do: {connect(account, venue), 1}
  defp connect_once(_acct,   _ven,  {pid, i}), do: {pid, i + 1}

  defp disconnect_once(:nil),     do: :nil
  defp disconnect_once({_, 0}),   do: :nil
  defp disconnect_once({pid, 1}), do: disconnect(pid)
  defp disconnect_once({pid, i}), do: {pid, i - 1}

  defp connect(account, venue) do
    {:ok, _pid} = Exchange.Venue.start(account, venue)
  end

  defp disconnect(pid) do
    Exchange.Venue.stop(pid)
    :nil
  end
end