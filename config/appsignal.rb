# AppSignal configuration.
#
# The only thing you must supply is a push API key. Either export it:
#
#     export APPSIGNAL_PUSH_API_KEY="your-key"
#
# or drop it into a .env-style shell profile. Without a key AppSignal simply
# stays inactive and the app runs normally — nothing breaks.

Appsignal.configure do |config|
  config.name = ENV.fetch("APPSIGNAL_APP_NAME", "Smokestack BBQ Supply")

  config.push_api_key = ENV["APPSIGNAL_PUSH_API_KEY"]

  # Only report when a key is actually present, so a fresh clone with no key
  # does not spam the logs with "not active" warnings on every request.
  config.active = !ENV["APPSIGNAL_PUSH_API_KEY"].to_s.strip.empty?


  # Shows up in AppSignal as the deploy marker, so you can point at a specific
  # version during a demo.
  config.revision = ENV["GIT_SHA"] || "demo"

  # Outbound HTTP is instrumented so the /demo/external_http trace shows the
  # call as its own event in the timeline.
  config.instrument_net_http = true

  # This is a demo store with fake customers, but the habit is worth modelling:
  # never ship session contents to your monitoring provider.
  config.send_session_data = false

  config.ignore_errors = []

  config.log_level = ENV.fetch("APPSIGNAL_LOG_LEVEL", "info")
end
