# frozen_string_literal: true

if ENV['RAILS_ENV'] == 'production'
  raise 'This file should not be required in production. ' \
    'Change the RAILS_ENV env var temporarily to override this.'
end

require 'iron_trail'

module IronTrail
  module Testing
    module InstanceMethods
      def irontrail_set_actor(actor)
        if actor.nil?
          IronTrail::Current.metadata.delete(:_actor_type)
          IronTrail::Current.metadata.delete(:_actor_id)
        else
          IronTrail::Current.merge_metadata([], {
            _actor_type: actor.class.name,
            _actor_id: actor.id
          })
        end
      end
    end

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

      def with_iron_trail(want_enabled:, &block)
        was_enabled = IronTrail::Testing.enabled

        if want_enabled
          ::IronTrail::Testing.enable! unless was_enabled
        else
          ::IronTrail::Testing.disable! if was_enabled
        end

        block.call
      ensure
        if want_enabled && !was_enabled
          ::IronTrail::Testing.disable!
        elsif !want_enabled && was_enabled
          ::IronTrail::Testing.enable!
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include ::IronTrail::Testing::InstanceMethods

  config.around(:each, iron_trail: true) do |example|
    IronTrail::Testing.with_iron_trail(want_enabled: true) { example.run }
  end

  config.around(:each, iron_trail: false) do |example|
    raise "Using iron_trail: false does not do what you might think it does. To disable iron_trail, " \
      "use IronTrail::Testing.with_iron_trail(want_enabled: false) { ... } instead."
  end

  config.before(:each) do
    IronTrail::Current.reset
  end
end
