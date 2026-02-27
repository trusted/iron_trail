# frozen_string_literal: true

RSpec.describe IronTrail::Migration do
  let(:connection) { ActiveRecord::Base.connection }

  after do
    connection.execute('DROP TABLE IF EXISTS ignored_db_test_table')
  end

  def run_create_table_migration
    migration = Class.new(ActiveRecord::Migration::Current) do
      def up
        create_table(:ignored_db_test_table, force: true) do |t|
          t.string :name
        end
      end
    end

    ActiveRecord::Migration.suppress_messages do
      migration.new.migrate(:up)
    end
  end

  describe 'ignored_databases' do
    context 'when the database is ignored' do
      it 'does not create a tracking trigger on the new table' do
        db_name = connection.pool.db_config.name

        IronTrail.config.ignored_databases << db_name

        run_create_table_migration

        db_fun = IronTrail::DbFunctions.new(connection)
        tracked = db_fun.collect_tracked_table_names
        expect(tracked).not_to include('ignored_db_test_table')
      ensure
        IronTrail.config.ignored_databases.delete(db_name)
      end
    end

    context 'when the database is not ignored' do
      it 'creates a tracking trigger on the new table' do
        run_create_table_migration

        db_fun = IronTrail::DbFunctions.new(connection)
        tracked = db_fun.collect_tracked_table_names
        expect(tracked).to include('ignored_db_test_table')
      end
    end
  end
end
