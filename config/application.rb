require_relative "boot"

require "digest"
require "rails"

# Only the frameworks this app actually uses. Action Mailer, Action Cable,
# Active Storage and Action Text are deliberately not loaded — fewer moving
# parts to go wrong, and nothing here needs them.
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)

module AppsignalBbq
  class Application < Rails::Application
    config.load_defaults 8.1

    # Background jobs run in-process. Good enough for a demo, and it means no
    # Redis, no Solid Queue tables and no second process to babysit — while
    # still producing real Active Job traces in AppSignal.
    config.active_job.queue_adapter = :async

    # Styling is a single hand-written stylesheet served straight from public/,
    # so there is no asset pipeline, no importmap and no build step.
    config.public_file_server.enabled = true

    config.autoload_lib(ignore: %w[tasks])

    config.time_zone = "UTC"
  end
end
