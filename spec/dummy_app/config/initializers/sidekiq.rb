# frozen_string_literal: true

require 'iron_trail/sidekiq'
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add IronTrail::SidekiqMiddleware
  end
end
