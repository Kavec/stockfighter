defmodule Stockfighter.Exchange.Stock do
  @moduledoc "Buy stocks! Sell stocks! Lose all your money!"

  alias Stockfighter.Exchange.Relay

  # Use the Exchange module to interact with stocks on an exchange.
  @doc false
  def order(symb, venue, acct, price, qty, otype, dir)
  when otype in [:limit, :fill_or_kill, :immediate_or_canx, :market]
  and  dir   in ["buy", "sell"] do
    order = %{
      "account"   => acct, "venue" => venue, "stock"     => symb,
      "qty"       => qty,  "price" => price, "orderType" => mk_ord(otype),
      "direction" => dir
    }

    Relay.request(:post, Relay.order(venue, symb), order)
      |> Relay.decode_response([])
      |> IO.inspect
  end

  defp mk_ord(:limit),             do: "limit"
  defp mk_ord(:fill_or_kill),      do: "fill-or-kill"
  defp mk_ord(:immediate_or_canx), do: "immediate-or-cancel"
  defp mk_ord(:market),            do: "market"

end