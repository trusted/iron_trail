# frozen_string_literal: true

RSpec.describe IronTrail::Config do
  subject(:config) { described_class.instance }

  describe '#ignored_tables' do
    it 'has default ignored tables' do
      expect(config.ignored_tables).to include('schema_migrations', 'ar_internal_metadata', 'sessions')
    end

    it 'does not allow overwriting ignored_tables directly' do
      expect { config.ignored_tables = %w[foo] }.to raise_error(RuntimeError, /Overwriting ignored_tables/)
    end

    it 'allows appending to ignored_tables' do
      config.ignored_tables << 'custom_table'
      expect(config.ignored_tables).to include('custom_table')
    end
  end

  describe '#ignored_databases' do
    it 'defaults to an empty array' do
      expect(config.ignored_databases).to eq([])
    end

    it 'does not allow overwriting ignored_databases directly' do
      expect { config.ignored_databases = %w[foo] }.to raise_error(RuntimeError, /Overwriting ignored_databases/)
    end

    it 'allows appending to ignored_databases' do
      config.ignored_databases << 'secondary'
      expect(config.ignored_databases).to include('secondary')
    end
  end
end
