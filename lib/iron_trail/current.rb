# frozen_string_literal: true

module IronTrail
  class Current < ActiveSupport::CurrentAttributes
    attribute :metadata

    def self.store_metadata(key, value)
      self.metadata ||= {}
      self.metadata[key] = value
    end

    def self.merge_metadata(keys, merge_hash)
      self.metadata ||= {}
      base = self.metadata
      keys.each do |key|
        if base.key?(key)
          base = base[key]
        else
          h = {}
          base[key] = h
          base = h
        end
      end
      base.merge!(merge_hash)
    end
  end
end
