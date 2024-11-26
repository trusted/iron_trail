# frozen_string_literal: true

module IronTrail
  class DbFunctions
    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end

    # Creates the SQL functions in the DB. It will not run the function or create
    # any triggers.
    def install_functions
      sql = irontrail_log_row_function
      connection.execute(sql)
    end

    def irontrail_log_row_function
      path = File.expand_path('irontrail_log_row_function.sql', __dir__)
      File.read(path)
    end

    # Queries the database information schema and returns an array with all
    # table names that have the "iron_trail_log_changes" trigger enabled.
    #
    # This effectively returns all tables which are currently being tracked
    # by IronTrail.
    def collect_tracked_table_names
      stmt = <<~SQL
        SELECT DISTINCT("event_object_table") AS "table"
        FROM "information_schema"."triggers"
        WHERE "trigger_name"='iron_trail_log_changes' AND "event_object_schema"='public'
        ORDER BY "table" ASC;
      SQL

      connection.execute(stmt).map { |row| row['table'] }
    end

    def function_present?(function: 'irontrail_log_row', schema: 'public')
      stmt = <<~SQL
        SELECT 1 FROM "pg_proc" p
        INNER JOIN "pg_namespace" ns
        ON (ns.oid = p.pronamespace)
        WHERE p."proname"=#{connection.quote(function)}
          AND ns."nspname"=#{connection.quote(schema)}
        LIMIT 1;
      SQL

      connection.execute(stmt).to_a.count > 0
    end

    def remove_functions(cascade:)
      query = +"DROP FUNCTION irontrail_log_row"
      query << " CASCADE" if cascade

      connection.execute(query)
    end

    def trigger_errors_count
      stmt = 'SELECT COUNT(*) AS c FROM "irontrail_trigger_errors"'
      connection.execute(stmt).first['c']
    end

    def collect_all_tables(schema: 'public')
      # query pg_class rather than information schema because this way
      # we can get only regular tables and ignore partitions.
      stmt = <<~SQL
        SELECT c.relname AS "table"
        FROM "pg_class" c INNER JOIN "pg_namespace" ns
        ON (ns.oid = c.relnamespace)
        WHERE ns.nspname=#{connection.quote(schema)}
          AND c.relkind IN ('r', 'p')
          AND NOT c.relispartition
        ORDER BY "table" ASC;
      SQL

      connection.execute(stmt).map { |row| row['table'] }
    end

    def enable_for_all_missing_tables
      collect_tables_tracking_status[:missing].each do |table_name|
        enable_tracking_for_table(table_name)
      end
    end

    def collect_tables_tracking_status
      ignored_tables = OWN_TABLES + (IronTrail.config.ignored_tables || [])

      all_tables = collect_all_tables - ignored_tables
      tracked_tables = collect_tracked_table_names - ignored_tables

      {
        tracked: tracked_tables,
        missing: all_tables - tracked_tables
      }
    end

    def disable_tracking_for_table(table_name)
      # Note: will disable even if table is ignored as this allows
      # one to fix ignored tables mnore easily. Since the table is already
      # ignored, it is an expected destructive operation.

      stmt = <<~SQL
        DROP TRIGGER "iron_trail_log_changes" ON
        #{connection.quote_table_name(table_name)}
      SQL

      connection.execute(stmt)
    end

    def enable_tracking_for_table(table_name)
      return false if IronTrail.ignore_table?(table_name)

      stmt = <<~SQL
        CREATE TRIGGER "iron_trail_log_changes" AFTER INSERT OR UPDATE OR DELETE ON
        #{connection.quote_table_name(table_name)}
        FOR EACH ROW EXECUTE FUNCTION irontrail_log_row();
      SQL

      connection.execute(stmt)
    end
  end
end
