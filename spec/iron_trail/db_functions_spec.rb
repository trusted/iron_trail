# frozen_string_literal: true

RSpec.describe IronTrail::DbFunctions do
  subject(:instance) { described_class.new(connection) }
  let(:connection) { ActiveRecord::Base.connection }

  let(:default_tables) do
    %w[
      guitar_parts
      guitars
      matrix_pills
      people
    ]
  end

  describe '#collect_all_tables' do
    subject(:table_names) { instance.collect_all_tables }

    before do
      connection.execute('CREATE TABLE qux (foo TEXT);')
    end

    it 'contains all tables' do
      expect(table_names).to contain_exactly(*(default_tables + %w[
        qux
        irontrail_changes
        irontrail_trigger_errors
        ar_internal_metadata
        schema_migrations
      ]))
    end
  end

  describe '#collect_tables_tracking_status' do
    subject(:statuses) { instance.collect_tables_tracking_status }

    context 'with default setup' do
      it 'tracks all tables but rails ones' do
        expect(statuses[:tracked]).to contain_exactly(*default_tables)
        expect(statuses[:missing]).to be_empty
      end
    end

    context 'with extra untracked tables' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE foo (id INTEGER);
          CREATE TABLE bar (id INTEGER);

          CREATE TRIGGER iron_trail_log_changes AFTER INSERT OR UPDATE OR DELETE ON
            bar FOR EACH ROW EXECUTE FUNCTION irontrail_log_row();
        SQL
      end

      it 'tracks default tables and bar but foo' do
        expect(statuses[:tracked]).to contain_exactly(*(default_tables + ['bar']))
        expect(statuses[:missing]).to contain_exactly('foo')
      end

      context 'when some tables are ignored' do
        it 'does not include ignored table anywhere' do
          orig_ignored_tables = IronTrail.config.ignored_tables
          test_ignored_tables = orig_ignored_tables + %w[foo bar]

          begin
            IronTrail.config.instance_variable_set(:@ignored_tables, test_ignored_tables)

            expect(statuses[:tracked]).to contain_exactly(*(default_tables))
            expect(statuses[:missing]).to be_empty
          ensure
            IronTrail.config.instance_variable_set(:@ignored_tables, orig_ignored_tables)
          end
        end
      end
    end
  end

  describe '#collect_tracked_table_names' do
    subject(:table_names) { instance.collect_tracked_table_names }

    context 'with default setup' do
      it 'has all tables' do
        expect(table_names).to contain_exactly(*default_tables)
      end
    end

    context 'with new untracked tables' do
      before do
        connection.execute('CREATE TABLE foobar (id INTEGER);')
      end

      it 'does not include untracked tables' do
        # sanity test that the table was actually created
        expect(instance.collect_all_tables).to include('foobar')

        expect(table_names).to contain_exactly(*default_tables)
      end
    end

  end

  describe '#trigger_errors_count' do
    it 'is empty by default' do
      expect(instance.trigger_errors_count).to be(0)
    end

    context 'when it is not empty' do
      before do
        connection.execute(<<~SQL)
        INSERT INTO "irontrail_trigger_errors" (query) VALUES ('foo');
        SQL
      end

      it 'what do you think it is now huh' do
        expect(instance.trigger_errors_count).to be(1)
      end
    end
  end

  describe '#disable_for_all_ignored_tables' do
    subject(:disable_it!) do
      instance.disable_for_all_ignored_tables
    end

    context 'when no ignored tables are tracked' do
      it 'returns an empty array' do
        expect(disable_it!).to eq([])
      end

      it 'does not call disable_tracking_for_table' do
        expect(instance).to receive(:disable_tracking_for_table).exactly(0).times

        disable_it!
      end
    end
  end

  describe 'function creation and removal' do
    context 'with default setup' do
      it 'has the function present' do
        expect(instance.function_present?).to be true
      end
    end

    it 'creates and deletes the function' do
      instance.remove_functions(cascade: true)

      expect(instance.function_present?).to be false

      instance.install_functions

      expect(instance.function_present?).to be true

      instance.enable_for_all_missing_tables
    end
  end
end
