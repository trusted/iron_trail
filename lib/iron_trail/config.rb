# frozen_string_literal: true

module IronTrail
  class Config
    include Singleton

    attr_accessor \
      :track_by_default,
      :enable,
      :ignored_tables,
      :track_migrations_starting_at_version

    def initialize
      @enable = true
      @track_by_default = true
      @ignored_tables = nil
      @track_migrations_starting_at_version = nil
    end
  end
end
