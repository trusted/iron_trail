# frozen_string_literal: true

module IronTrail
  class Config
    DEFAULT_IGNORED_TABLES = %w[
      schema_migrations
      ar_internal_metadata
      sessions
    ].freeze

    include Singleton

    attr_accessor \
      :track_by_default,
      :enable,
      :track_migrations_starting_at_version

    attr_reader :ignored_tables

    def initialize
      @enable = true
      @track_by_default = true
      @ignored_tables = DEFAULT_IGNORED_TABLES.dup
      @track_migrations_starting_at_version = nil
    end

    # To prevent ever tracking unintended tables, let's disallow setting this value
    # directly.
    # It is possible to call Array#clear to empty the array and remove default
    # should that be desired.
    def ignored_tables=(v)
      raise 'Overwriting ignored_tables is not allow. Instead, add or remove to it explicitly.'
    end
  end
end
