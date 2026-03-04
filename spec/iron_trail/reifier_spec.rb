# frozen_string_literal: true

RSpec.describe IronTrail::Reifier do
  describe '.model_from_table_name' do
    # Ensure models are loaded so they appear in ActiveRecord::Base.descendants
    before do
      Person
      MatrixPill
      RedPill
      PillBlue
    end
    it 'returns the correct class for a simple table' do
      expect(described_class.model_from_table_name('people')).to eq(Person)
    end

    it 'returns the correct STI subclass when sti_type is present' do
      expect(described_class.model_from_table_name('matrix_pills', 'RedPill')).to eq(RedPill)
      expect(described_class.model_from_table_name('matrix_pills', 'PillBlue')).to eq(PillBlue)
    end

    it 'returns the base STI class when sti_type is nil' do
      expect(described_class.model_from_table_name('matrix_pills')).to eq(MatrixPill)
    end

    it 'raises an error for an unknown table' do
      expect {
        described_class.model_from_table_name('nonexistent_table')
      }.to raise_error(/Cannot infer model from table named 'nonexistent_table'/)
    end

    it 'raises an error for an unknown STI type' do
      expect {
        described_class.model_from_table_name('matrix_pills', 'GreenPill')
      }.to raise_error(/Cannot infer STI model for table matrix_pills and type 'GreenPill'/)
    end

    context 'when a polluting class shares the same table_name' do
      before do
        stub_const('TestPollution::Persoo', Class.new(ActiveRecord::Base) {
          self.table_name = 'people'
        })
      end

      it 'returns the conventionally-named class when sti_type is nil' do
        expect(described_class.model_from_table_name('people')).to eq(Person)
      end

      it 'returns the polluting class when explicitly requested via sti_type' do
        expect(described_class.model_from_table_name('people', 'TestPollution::Persoo')).to eq(TestPollution::Persoo)
      end
    end

    context 'when multiple classes share a table and none matches the conventional name' do
      before do
        stub_const('Aardvark', Class.new(ActiveRecord::Base) {
          self.table_name = 'widgets'
        })
        stub_const('Zebra', Class.new(ActiveRecord::Base) {
          self.table_name = 'widgets'
        })
      end

      it 'raises an error when sti_type is nil' do
        expect {
          described_class.model_from_table_name('widgets', nil)
        }.to raise_error(/Cannot infer model/)
      end
    end

    context 'when a polluting class shares an STI table' do
      before do
        stub_const('TestPollution::MatrixPilz', Class.new(ActiveRecord::Base) {
          self.table_name = 'matrix_pills'
        })
      end

      it 'returns the base STI class when sti_type is nil' do
        expect(described_class.model_from_table_name('matrix_pills')).to eq(MatrixPill)
      end

      it 'still resolves STI subclasses correctly' do
        expect(described_class.model_from_table_name('matrix_pills', 'RedPill')).to eq(RedPill)
      end
    end
  end
end
