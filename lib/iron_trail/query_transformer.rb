# frozen_string_literal: true

module IronTrail
  class QueryTransformer
    METADATA_MAX_LENGTH = 1048576 # 1 MiB

    attr_reader :transformer_proc

    def initialize
      @transformer_proc = create_query_transformer_proc
    end

    def setup_active_record
      ActiveRecord.query_transformers << @transformer_proc
    end

    private

    def create_query_transformer_proc
      proc do |query, adapter|
        current_metadata = IronTrail::Current.metadata
        next query unless adapter.write_query?(query) && (current_metadata.is_a?(Hash) && !current_metadata.empty?)

        metadata = JSON.dump(current_metadata)

        if metadata.length > METADATA_MAX_LENGTH
          Rails.logger.warn("IronTrail metadata is longer than maximum length! #{metadata.length} > #{METADATA_MAX_LENGTH}")
          next query
        end

        safe_md = metadata.gsub('*/', '\\u002a\\u002f')
        "/*IronTrail #{safe_md} IronTrail*/ #{query}"
      end
    end
  end
end
