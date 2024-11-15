# frozen_string_literal: true

module IronTrail
  class DbFunctions
    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end

    def install_functions
      sql = irontrail_log_row_function
      connection.execute(sql)
    end

    def irontrail_log_row_function
      path = File.expand_path('irontrail_log_row_function.sql', __dir__)
      File.read(path)
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
