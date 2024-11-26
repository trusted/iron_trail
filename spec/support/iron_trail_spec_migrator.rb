# frozen_string_literal: true

class IronTrailSpecMigrator
  def initialize
    @migrations_path = dummy_app_migrations_dir
  end

  def migrate
    Rails.application.load_generators
    Rails::Generators.invoke 'iron_trail:migration', [], behavior: :invoke, destination_root: Rails.root

    schema_migration =
      if Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new('7.2')
        ::ActiveRecord::Base.connection.schema_migration
      else
        ::ActiveRecord::SchemaMigration.new(
          ActiveRecord::Tasks::DatabaseTasks.migration_connection_pool
        )
      end

    ::ActiveRecord::MigrationContext.new(@migrations_path, schema_migration).migrate
  end

  private

  def dummy_app_migrations_dir
    Pathname.new(File.expand_path('../dummy_app/db/migrate', __dir__))
  end
end
