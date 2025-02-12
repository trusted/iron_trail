# frozen_string_literal: true

RSpec.describe IronTrail::QueryTransformer do
  subject(:instance) { described_class.new }

  let(:adapter) do
    double.tap do |dbl|
      allow(dbl).to receive(:write_query?).and_return(is_write_query)
    end
  end

  before do
    IronTrail.merge_metadata([], metadata)
  end

  describe 'transformer proc' do
    subject(:transformed_query) do
      instance.transformer_proc.call(query, adapter)
    end

    let(:query) { 'insert into foobar' }
    let(:is_write_query) { true }
    let(:metadata) { { 'some' => 'data', another: 19191919 } }

    it 'appends metadata' do
      expect(transformed_query).to eq '/*IronTrail {"some":"data","another":19191919} IronTrail*/ insert into foobar'
    end

    context 'when it is not a write query' do
      let(:query) { 'select * from foobar' }
      let(:is_write_query) { false }

      it 'leaves the query untouched' do
        expect(transformed_query).to eq(query)
      end
    end
  end
end
