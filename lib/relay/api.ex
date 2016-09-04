defmodule Stockfighter.Relay.API do

  def ws_execs(account, venue) do
    "/ob/api/ws/#{account}/venues/#{venue}/executions"
  end

  def ws_ttape(account, venue) do
    "/ob/api/ws/#{account}/venues/#{venue}/tickertape"
  end


  @doc "Spawn a new process to read data from stockfighter websocket API"
  @spec ws_connect(binary, pid | atom, (tuple -> :ok|:end)) :: pid
  def ws_connect(path, receiver, talk) do
    spawn_link(fn ->
      host    = Application.fetch_env!(:stockfighter, :api_host)
      port    = Application.fetch_env!(:stockfighter, :api_port)
      timeout = Application.fetch_env!(:stockfighter, :api_timeout_ms)

      # Connect over http 1.1 and upgrade to websockets
      {:ok, conn}  = :gun.open(to_charlist(host), port)
      {:ok, :http} = :gun.await_up(conn)

      :gun.ws_upgrade(conn, path || "/")

      continue? = receive do
      {:gun_ws_upgrade, ^conn, :ok, _hdrs} ->
        talk.(receiver, {:connected, self})
      after timeout ->
        talk.(receiver, {:conn_error, "timeout"})
      end
      ws_read(conn, receiver, talk, continue?)
    end)
  end

  def ws_shutdown(conn) do
    send(conn, :shutdown)
  end

  defp ws_read(_conn, _rcv, _talk, :end), do: nil
  defp ws_read( conn,  rcv,  talk, _ok) do
    continue? = receive do
      :shutdown ->
        :gun.shutdown(conn)
        :end
      {:gun_down, ^conn, _, _, _, _} ->
        talk.(rcv, {:reconnecting, self})
      {:gun_ws, ^conn, :ping} -> 
        :gun.ws_send(conn, :pong)
      {:gun_ws, ^conn, {:ping, data}} ->
        talk.(rcv, {:ping_data, data})
        :gun.ws_send(conn, {:pong, data})
      {:gun_ws, ^conn, {mtype, data}} ->
        talk.(rcv, {:ws, mtype, data})
      msg ->
        talk.(rcv, {:unk_msg, msg})
    end

    ws_read(conn, rcv, talk, continue?)
  end
end