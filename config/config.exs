use Mix.Config

# Import API keys, trading account, etc
import_config "secrets.exs"

# Break comment if dev/test/prod.exs are pulled out into separate files
# import_config ".exs"

case Mix.env do
  "test" -> config :excheck, number_iterations: 200
  _      -> :nil
end