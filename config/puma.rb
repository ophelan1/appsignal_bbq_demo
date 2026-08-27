threads_count = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
threads threads_count, threads_count

port ENV.fetch("PORT", 3000)
environment ENV.fetch("RAILS_ENV", "development")

# Codespaces forwards the port, so bind to all interfaces there.
bind "tcp://0.0.0.0:#{ENV.fetch("PORT", 3000)}"

plugin :tmp_restart
