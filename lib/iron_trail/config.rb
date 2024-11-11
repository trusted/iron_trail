# frozen_string_literal: true

module IronTrail
  class Config
    include Singleton

    attr_accessor \
      :track_by_default,
      :enable,
      :ignored_tables

    def initialize
      @enable = true
      @track_by_default = true
      @ignored_tables = nil
    end
  end
end
