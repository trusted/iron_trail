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
require 'pg_party'
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

Time.now.tap do |date|
  partition_name = "irontrail_chgn_#{date.strftime('%Y%m')}"
  next if ActiveRecord::Base.connection.table_exists?(partition_name)

  IrontrailChange.create_partition(
    name: partition_name,
    start_range: date,
    end_range: date.next_month
  )
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end
