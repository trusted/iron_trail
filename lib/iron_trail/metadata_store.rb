# frozen_string_literal: true

module IronTrail
  class MetadataStore
    def store_metadata(key, value)
      RequestStore.store[:irontrail_metadata] ||= {}
      RequestStore.store[:irontrail_metadata][key] = value
    end

    def merge_metadata(keys, merge_hash)
      RequestStore.store[:irontrail_metadata] ||= {}
      base = RequestStore.store[:irontrail_metadata]
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

    def current_metadata
      RequestStore.store[:irontrail_metadata]
    end
  end
end
