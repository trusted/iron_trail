
require 'singleton'

require 'iron_trail/version'
require 'iron_trail/config'
require 'iron_trail/db_functions'
require 'iron_trail/migration'

module IronTrail
  # These tables are owned by IronTrail and will always be ignored, that is,
  # they will never be tracked for changes.
  OWN_TABLES = %w[
    irontrail_trigger_errors
    irontrail_changes
  ].freeze

  class << self
    def config
      @config ||= IronTrail::Config.instance
      yield @config if block_given?
      @config
    end

    def enabled?
      config.enable
    end

    def ignore_table?(name)
      (OWN_TABLES + (config.ignored_tables || [])).include?(name)
    end

    def post_schema_load(context, missing_track: nil)
      df = IronTrail::DbFunctions.new(context.connection)
      df.install_functions

      missing_track.each do |table|
        df.enable_tracking_for_table(table)
      end
    end
  end
end

module IronTrail
  module SchemaDumper
    def trailer(stream)
      stream.print "\n\n  IronTrail.post_schema_load(self, missing_track: @irontrail_missing_track)\n\n"

      super(stream)
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Migration.prepend(IronTrail::Migration)
  ActiveRecord::SchemaDumper.prepend(IronTrail::SchemaDumper)
end
