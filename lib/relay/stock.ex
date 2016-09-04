defmodule Stockfighter.Relay.Stock do
  @moduledoc "Buy stocks! Sell stocks! Lose all your money!"
  alias Stockfighter.Relay


  # TODO: Make this a bit less annoying to work with
  # TODO: Log into venue and then just sym/price/qty/otype?
  # TODO: Or "objects"?
  def buy(stock, venue, account, price, qty, otype) do
    issue_order(stock, venue, account, qty, otype, price, "buy")
  end

  def sell(stock, venue, account, price, qty, otype) do
    issue_order(stock, venue, account, qty, otype, price, "sell")
  end

  defp issue_order(stock, venue, account, price, qty, otype, dir) 
  when otype in ["fill-or-kill", "market", "immediate-or-cancel", "limit"]
  and  dir   in ["buy", "sell"] do
    order = %{
      "account"   => account, "venue" => venue, "stock"     => stock,
      "qty"       => qty,     "price" => price, "orderType" => otype,
      "direction" => dir}

    Relay.API.request(:post, Relay.API.order(venue, stock), order)
      |> Relay.API.decode_response([])
      |> IO.inspect
  end
end