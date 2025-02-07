# frozen_string_literal: true

RSpec.describe IronTrail::Current do
  describe '.store_metadata' do
    it 'stores a value in RequestStore' do
      described_class.store_metadata(:foo, 'bar')

      expect(described_class.metadata).to eq({ foo: 'bar' })
    end
  end
end
