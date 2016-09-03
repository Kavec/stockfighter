use Mix.Config

# Import API keys, etc
import_config "secrets.exs"

config :stockfighter, 
  api_host:       "api.stockfighter.io",
  api_port:       443, #ssl is best
  api_timeout_ms: 2500




# Break comment if dev/test/prod.exs are pulled out into separate files
# import_config ".exs"
case Mix.env do
  "test" -> config :excheck, number_iterations: 200
  _      -> :nil
end