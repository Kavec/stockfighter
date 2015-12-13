use Mix.Config

# Import API keys, trading account, etc
import_config "secrets.exs"

# Break comment in case of dev/prod/test divergence
# import_config "#{Mix.env}.exs"