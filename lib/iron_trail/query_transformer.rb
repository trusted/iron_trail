# frozen_string_literal: true

module IronTrail
  # The class itself is what gets registered in ActiveRecord.query_transformers, not a proc, so it
  # stays Ractor-shareable: newer Rails runs `Ractor.make_shareable(ActiveRecord.query_transformers)`
  # after the app initializes, which deep-freezes the array and rejects procs bound to an instance.
  class QueryTransformer
    METADATA_MAX_LENGTH = 1048576 # 1 MiB

    attr_reader :transformer_proc

    def self.call(query, adapter)
      current_metadata = IronTrail::Current.metadata
      return query unless adapter.write_query?(query) && (current_metadata.is_a?(Hash) && !current_metadata.empty?)

      metadata = JSON.dump(current_metadata)

      if metadata.length > METADATA_MAX_LENGTH
        msg = "IronTrail metadata is longer than maximum length! #{metadata.length} > #{METADATA_MAX_LENGTH}"
        Rails.logger.warn(msg)
        Sentry.capture_message(msg, level: :warning) if defined?(Sentry)
        return query
      end

      safe_md = metadata.gsub('*/', '\\u002a\\u002f')
      "/*IronTrail #{safe_md} IronTrail*/ #{query}"
    end

    def initialize
      @transformer_proc = self.class.method(:call).to_proc
    end

    def setup_active_record
      return if ActiveRecord.query_transformers.include?(self.class)

      ActiveRecord.query_transformers << self.class
    end
  end
end
