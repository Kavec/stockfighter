defmodule Stockfighter.Exchange.Relay do
  @moduledoc "Nuts and bolts of interacting with Stockfighter's API"
  use HTTPoison.Base
  alias HTTPoison.{Response, Error}

  @doc "Formats path for orders"
  def order(venue, stock) do
    "/ob/api/venues/#{venue}/stocks/#{stock}/orders"
  end

  @doc "Formats path for ws execution calls"
  def ws_execs(account, venue) do
    "/ob/api/ws/#{account}/venues/#{venue}/executions"
  end

  @doc "Formats path for ws quotes calls"
  def ws_ttape(account, venue) do
    "/ob/api/ws/#{account}/venues/#{venue}/tickertape"
  end

  @doc "Retrieve API host from configuration"
  def host! do
    Application.fetch_env!(:stockfighter, :api_host)
  end

  @doc "Retrieve API port from configuration"
  def port! do
    Application.fetch_env!(:stockfighter, :api_port)
  end

  @doc "Retrieve API timeout from configuration"
  def timeout! do
    Application.fetch_env!(:stockfighter, :api_timeout_ms)
  end

  @doc "Retrieve API key from configuration"
  def key! do
    Application.fetch_env!(:stockfighter, :api_key)
  end

  @doc "Spawn a new process to read data from stockfighter websocket API"
  @spec ws_connect(binary, pid | atom, (tuple -> :ok|:end)) :: pid
  def ws_connect(path, receiver, talk) do
    spawn_link(fn ->
      # Connect over http 1.1 and upgrade to websockets
      {:ok, conn}  = :gun.open(to_charlist(host!), port!)
      {:ok, :http} = :gun.await_up(conn)

      :gun.ws_upgrade(conn, path || "/")

      continue? = receive do
      {:gun_ws_upgrade, ^conn, :ok, _hdrs} ->
        talk.(receiver, {:connected, self})
      after timeout! ->
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


  # HTTP request primitives
  @doc false
  defp process_url(path), do: "https://" <> host! <> path

  @doc false 
  defp process_request_headers(hdrs) do
    hdrs |> Keyword.put(:"X-Starfighter-Authorization", key!)
  end

  @doc false
  def request(:get, path) do
    case get(path) do
      {:ok, %Response{status_code: status, body: body}} -> {status, body}
      {:error, %Error{reason: reason}} -> {:error, reason}
    end
  end

  @doc false
  def request(:delete, path) do
    case delete(path) do
      {:ok, %Response{status_code: status, body: body}} -> {status, body}
      {:error, %Error{reason: reason}} -> {:error, reason}
    end
  end

  @doc false
  def request(:post, path, body) do
    case post(path, body) do
      {:ok, %Response{status_code: status, body: body}} -> {status, body}
      {:error, %Error{reason: reason}} -> {:error, reason}
    end
  end

  @doc false
  def decode_response({:error, reason}, _opts) do
    IO.puts "API encountered error:"
    IO.puts "  #{inspect reason}"

    {:error, reason}
  end

  def decode_response({200, body}, opts) do
    opts = opts |> Keyword.put(:keys, :atoms)

    Poison.decode(body, opts)
  end

  def decode_response({code, body}, _opts) do
    IO.puts "API returned code #{code}:"
    IO.puts "  #{inspect body}"
    
    {:error, code}
  end
end