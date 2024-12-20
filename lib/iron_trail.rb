# frozen_string_literal: true

require 'singleton'
require 'json'
require 'forwardable'
require 'request_store'

require 'iron_trail/version'
require 'iron_trail/config'
require 'iron_trail/db_functions'
require 'iron_trail/migration'

require 'iron_trail/metadata_store'
require 'iron_trail/query_transformer'

require 'iron_trail/association'
require 'iron_trail/reflection'
require 'iron_trail/model'
require 'iron_trail/change_model_concern'
require 'iron_trail/collection_proxy_mixin'
require 'iron_trail/reifier'

require 'iron_trail/railtie'

module IronTrail
  # These tables are owned by IronTrail and will be in the default ignore list
  OWN_TABLES = %w[
    irontrail_trigger_errors
    irontrail_changes
  ].freeze

  module SchemaDumper
    def trailer(stream)
      stream.print "\n  IronTrail.post_schema_load(self, missing_tracking: @irontrail_missing_track)\n"

      super(stream)
    end
  end

  class << self
    extend Forwardable

    attr_reader :query_transformer

    def config
      @config ||= IronTrail::Config.instance
      yield @config if block_given?
      @config
    end

    def enabled?
      config.enable
    end

    # def test_mode!
    #   if [ENV['RAILS_ENV'], ENV['RACK_ENV']].include?('production')
    #     raise "IronTrail test mode cannot be enabled in production!"
    #   end
    #   @test_mode = true
    # end
    #
    # def test_mode?
    #   @test_mode
    # end

    def ignore_table?(name)
      (OWN_TABLES + (config.ignored_tables || [])).include?(name)
    end

    def post_schema_load(context, missing_tracking: nil)
      df = IronTrail::DbFunctions.new(context.connection)
      df.install_functions

      missing_tracking.each do |table|
        df.enable_tracking_for_table(table)
      end
    end

    def setup_active_record
      ActiveRecord::Migration.prepend(IronTrail::Migration)
      ActiveRecord::SchemaDumper.prepend(IronTrail::SchemaDumper)

      @query_transformer = QueryTransformer.new
      @query_transformer.setup_active_record
    end

    def store_instance
      @store_instance ||= MetadataStore.new
    end

    def_delegators :store_instance,
                   :store_metadata,
                   :merge_metadata,
                   :current_metadata


  end
end

ActiveSupport.on_load(:active_record) do
  IronTrail.setup_active_record
end
