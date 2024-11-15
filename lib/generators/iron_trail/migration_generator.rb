# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'

module IronTrail
  class MigrationGenerator < Rails::Generators::Base
    include ::Rails::Generators::Migration

    source_root File.expand_path("templates", __dir__)

    desc "Generates a migration adding the iron trail changes table"
    def create_changes_migration_file
      migration_dir = File.expand_path("db/migrate")

      migration_template(
        "create_irontrail_changes.rb.erb",
        "db/migrate/create_irontrail_changes.rb"
      )

      migration_template(
        "create_irontrail_support_tables.rb.erb",
        "db/migrate/create_irontrail_support_tables.rb"
      )
    end

    def self.next_migration_number(dirname)
      ActiveRecord::Generators::Base.next_migration_number(dirname)
    end
  end
end
