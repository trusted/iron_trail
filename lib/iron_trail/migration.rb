# frozen_string_literal: true

module IronTrail
  module Migration
    def method_missing(method, *args)
      running_from_schema = is_a?(ActiveRecord::Schema) ||
        (defined?(ActiveRecord::Schema::Definition) && is_a?(ActiveRecord::Schema::Definition))

      result = super

      return result unless IronTrail.enabled? && method == :create_table

      start_at_version = IronTrail.config.track_migrations_starting_at_version
      if !running_from_schema && start_at_version
        return result if self.version < Integer(start_at_version)
      end

      table_name = args.first.to_s
      return result if IronTrail.ignore_table?(table_name)

      if running_from_schema
        @irontrail_missing_track ||= []
        @irontrail_missing_track << table_name

        return result
      end

      db_fun = IronTrail::DbFunctions.new(connection)
      if db_fun.function_present?
        db_fun.enable_tracking_for_table(table_name)
      else
        Rails.logger.warn("IronTrail will not create trigger for table #{table_name} because the trigger function does not exist in the database.")
      end

      result
    end
    ruby2_keywords(:method_missing) if respond_to?(:ruby2_keywords, true)
  end
end
