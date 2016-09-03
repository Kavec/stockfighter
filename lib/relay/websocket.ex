alias Experimental.GenStage

defmodule Stockfighter.Relay.Websocket do
  
  def fmt_execs(account, venue) do
    "/ob/api/ws/#{account}/venues/#{venue}/executions"
  end

  def fmt_ttape(account, venue) do
    "/ob/api/ws/#{account}/venues/#{venue}/tickertape"
  end

  @doc "Spawns a new process to read data from stockfighter websocket path"
  @spec connect(binary, pid | atom) :: pid
  def connect(path, stage) do
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
        GenStage.cast(stage, {:connected, self})
        :ok
      after timeout ->
        GenStage.cast(stage, {:conn_error, "timeout"})
        :end
      end
      read_socket(conn, stage, continue?)
    end)
  end

  def shutdown(conn) do
    send(conn, :shutdown)
  end

  defp read_socket(_conn, _stage, :end), do: nil
  defp read_socket( conn,  stage, _ok) do
    continue? = receive do
      :shutdown -> 
        :gun.shutdown(conn)
        :end
      {:gun_down, ^conn, _, _, _, _} ->
        GenStage.cast(stage, {:reconnecting, self})
      {:gun_ws, ^conn, :ping} -> 
        :gun.ws_send(conn, :pong)
      {:gun_ws, ^conn, {:ping, data}} ->
        GenStage.cast(stage, {:ping_data, data})
        :gun.ws_send(conn, {:pong, data})
      {:gun_ws, ^conn, {mtype, data}} ->
        GenStage.cast(stage, {:ws, mtype, data})
      msg ->
        GenStage.cast(stage, {:unk_msg, msg})
    end

    read_socket(conn, stage, continue?)
  end
end