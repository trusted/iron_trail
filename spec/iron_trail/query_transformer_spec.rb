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

    context 'when metadata exceeds max length' do
      let(:metadata) { { 'data' => 'x' * IronTrail::QueryTransformer::METADATA_MAX_LENGTH } }

      it 'leaves the query untouched' do
        expect(transformed_query).to eq(query)
      end

      it 'logs a warning' do
        expect(Rails.logger).to receive(:warn).with(/IronTrail metadata is longer than maximum length!/)
        transformed_query
      end

      context 'when Sentry is not defined' do
        it 'does not raise' do
          expect { transformed_query }.not_to raise_error
        end
      end

      context 'when Sentry is defined' do
        before { stub_const('Sentry', double('Sentry')) }

        it 'captures a warning message in Sentry' do
          expect(Sentry).to receive(:capture_message)
            .with(/IronTrail metadata is longer than maximum length!/, level: :warning)
          transformed_query
        end
      end
    end
  end
end
