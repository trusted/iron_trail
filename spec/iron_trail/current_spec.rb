# frozen_string_literal: true

RSpec.describe IronTrail::Current do
  describe '.store_metadata' do
    it 'stores a value in metadata' do
      described_class.store_metadata(:foo, 'bar')

      expect(described_class.metadata).to eq({ foo: 'bar' })
    end

    context 'when key already exists' do
      before do
        described_class.metadata = { foo: { qux: 42 } }
      end

      it 'replaces the key' do
        described_class.store_metadata(:foo, { bottles: 99 })
        expect(described_class.metadata).to eq({ foo: { bottles: 99 } })
      end
    end
  end

  describe '.merge_metadata' do
    before do
      described_class.metadata = {
        foo: { qux: 42 },
        bar: { xpto: -1 }
      }
    end

    describe 'when specifying the key partially' do
      it 'replaces the value' do
        described_class.merge_metadata(%i[foo], { bottles: 99 })
        expect(described_class.metadata).to eq({
          foo: { bottles: 99, qux: 42 },
          bar: { xpto: -1 }
        })
      end
    end

    describe 'when the second parameter is not a hash' do
      it 'raises a TypeError' do
        expect {
          described_class.merge_metadata(%i[foo bottles], 99)
        }.to raise_error(TypeError, /value must be a Hash/)
      end
    end
  end
end
