# frozen_string_literal: true

RSpec.describe IronTrail::MetadataStore do
  subject(:instance) { described_class.new }

  describe '#store_metadata' do
    it 'stores a value in RequestStore' do
      instance.store_metadata(:foo, 'bar')

      expect(RequestStore.store[:irontrail_metadata][:foo]).to eq('bar')
    end
  end
end
