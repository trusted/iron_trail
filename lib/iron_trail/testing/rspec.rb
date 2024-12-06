# frozen_string_literal: true

require 'iron_trail'

module IronTrail
  module Testing
    class << self
      attr_accessor :enabled

      def enable!
        DbFunctions.new(ActiveRecord::Base.connection).install_functions
        @enabled = true
      end

      def disable!
        # We "disable" it by replacing the trigger function by a no-op one.
        # This should be faster than adding/removing triggers from several
        # tables every time.
        sql = <<~SQL
          CREATE OR REPLACE FUNCTION irontrail_log_row()
          RETURNS TRIGGER AS $$
          BEGIN
            RETURN NULL;
          END;
          $$ LANGUAGE plpgsql;
        SQL

        ActiveRecord::Base.connection.execute(sql)
        @enabled = false
      end
    end
  end
end

RSpec.configure do |config|
  config.around(:each, iron_trail: true) do |example|
    enabled = IronTrail::Testing.enabled
    IronTrail::Testing.enable! unless enabled

    example.run
  ensure
    IronTrail::Testing.disable! unless enabled
  end
end
