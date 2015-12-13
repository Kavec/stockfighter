use Mix.Config

# Import API keys, trading account, etc
import_config "secrets.exs"

# Break comment in case of total dev/prod/test divergence
# import_config "#{Mix.env}.exs"
case Mix.env do
  "test" -> import_config "#{Mix.env}.exs"
  _ -> :nil
end