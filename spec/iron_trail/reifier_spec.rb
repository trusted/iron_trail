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

    context 'when multiple classes share a table and none matches the conventional name' do
      before do
        @stub_aardvark = Class.new(ActiveRecord::Base) { self.table_name = 'widgets' }
        @stub_zebra = Class.new(ActiveRecord::Base) { self.table_name = 'widgets' }
        stub_const('Aardvark', @stub_aardvark)
        stub_const('Zebra', @stub_zebra)
      end

      after do
        @stub_aardvark.table_name = nil
        @stub_zebra.table_name = nil
      end

      it 'raises an error when sti_type is nil' do
        expect {
          described_class.model_from_table_name('widgets', nil)
        }.to raise_error(/Cannot infer model/)
      end
    end

    context 'when a polluting class shares an STI table' do
      before do
        @stub_pilz = Class.new(ActiveRecord::Base) { self.table_name = 'matrix_pills' }
        stub_const('TestPollution::MatrixPilz', @stub_pilz)
      end

      after do
        @stub_pilz.table_name = nil
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
