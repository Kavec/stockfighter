alias Experimental.GenStage

defmodule Stockfighter.Relay.Websocket do
  use GenStage

  # // ------ Websocket Supervisor Process ------ // #

  def start_link(args) do
    GenStage.start_link(__MODULE__, args)
  end

  @doc false
  def init(opts) do
    Agent.start_link(fn ->
      {:ok, conn}   = :gun.open(to_charlist(opts[:host]), opts[:port] || 443)
      {:ok, :http}  = :gun.await_up(conn)

      :gun.ws_upgrade(conn, opts[:path] || "/")

      receive do
        {:gun_ws_upgrade, ^conn, :ok, _headers} ->

          GenStage.cast(self, :connected)
          read_socket(conn)
      after 5000 ->
          GenStage.cast(self, {:conn_error, "Timeout"})
      end
    end)

    {:producer, %{opts: opts}}    
  end

  def handle_cast(:connected, state) do
    IO.puts "Connected to #{state.opts[:host]}, happy trading!"

    {:noreply, [:connected], state}
  end

  def handle_demand(_, state) do
    read_socket(state.socket)

    {:noreply, [], state}
  end


  def handle_info(msg, state) do
    IO.puts "Received:"
    IO.puts "  #{inspect msg}"

    {:noreply, state}
  end


  defp read_socket(conn) do
   # :gun.ws_send(conn, :ping)
    
    receive do
      {:gun_down, ^conn, _, _, _, _} ->
        IO.puts "Received gun down event"
      
      {:gun_ws, ^conn, :ping} ->
        IO.puts "Received ping"
        :gun.ws_send(conn, :pong)
      {:gun_ws, ^conn, {:ping, data}} ->
        IO.puts "Received ping w/ #{inspect data}"
        :gun.ws_send(conn, :pong)

      {:gun_ws, ^conn, {_, _data}} ->
        # IO.puts "Received: #{inspect data}"
        :ok

      frame ->
        IO.puts "Received: #{inspect frame}"
    end
    
    read_socket(conn)
  end
end