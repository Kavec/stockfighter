defmodule Stockfighter.Exchange.VenueHost do
  @moduledoc "Supervises Venue feed workers"
  use   Supervisor
  alias Stockfighter.Exchange

  @name :exch_venue_host

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  @doc false
  def init(_) do
    subordinate = [
      worker(Exchange.Venue, [], restart: :transient)]

    supervise subordinate, strategy: :simple_one_for_one
  end

  @doc false
  def start_venue(account, venue) do
    Supervisor.start_child(@name, [account, venue])
  end
end