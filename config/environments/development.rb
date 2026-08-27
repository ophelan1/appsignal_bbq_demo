require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true

  config.active_support.deprecation = :log
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  # GitHub Codespaces serves the app from a *.app.github.dev hostname.
  # Without this, Rails' host authorisation returns "Blocked hosts".
  config.hosts << /.*\.app\.github\.dev/
  config.hosts << /.*\.githubpreview\.dev/
end
