# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
ENV['RACK_ENV'] ||= ENV['RAILS_ENV']
ENV['DB'] ||= 'postgres'

RSpec.configure do |config|
  config.order = :random
  config.example_status_persistence_file_path = '.rspec_results'
  Kernel.srand config.seed

  config.before do
    RequestStore.clear!
  end
end

########################################################################
########################################################################
########################################################################
## Emulate Rails boot (config/boot.rb)
Bundler.setup

require 'active_record/railtie'
require 'action_controller/railtie'

require 'iron_trail'
require 'debug'
require 'rspec/rails'

require 'sidekiq'
require 'sidekiq/testing'
require 'iron_trail/sidekiq'

Sidekiq::Testing.fake!
Sidekiq::Testing.server_middleware do |chain|
  chain.add IronTrail::SidekiqMiddleware
end

require File.expand_path('dummy_app/config/environment', __dir__)

require_relative 'support/iron_trail_spec_migrator'
::IronTrailSpecMigrator.new.migrate

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.include ActiveSupport::Testing::TimeHelpers
end
