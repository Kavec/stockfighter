defmodule Stockfighter.Exchange do
  @moduledoc "Primary interface to remote stock exchanges."
  alias __MODULE__, as: Exchange

  defstruct [:account, :venue]
  @opaque t :: %Exchange{
    account: binary,
    venue:   binary
  }

  @spec connect(binary, binary) :: %Exchange{}
  @doc "Connects to a stock exchange venue as a trading account"
  def connect(account, venue) do
    Exchange.Venue.connect(account, venue)
    %Exchange{account: account, venue: venue}
  end

  @doc "Purchase a stock on an exchange"
  def buy(exch, symb, price, qty, otype \\ :limit)
  when otype in [:limit, :fill_or_kill, :immediate_or_canx, :market] do
    Exchange.Stock.order(symb, exch.venue, exch.account, price, qty, otype, "buy")
  end

  @doc "Sell a stock on an exchange"
  def sell(exch, symb, price, qty, otype \\ :limit)
  when otype in [:limit, :fill_or_kill, :immediate_or_canx, :market] do
    Exchange.Stock.order(symb, exch.venue, exch.account, price, qty, otype, "sell")
  end

  @doc "Disconnect from a stock exchange venue"
  def disconnect(exch) do
    Exchange.Venue.disconnect(exch.account, exch.venue)
  end

  # ----------- Exchange Supervisor ----------- #
  use Supervisor
  @name :exchange

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  @doc false
  def init(_) do
    subordinates = [
      supervisor(Exchange.VenueHost, []),

      worker(Exchange.VenueBroker, [])
    ]

    supervise subordinates, strategy: :rest_for_one
  end
end