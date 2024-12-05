# frozen_string_literal: true

require 'iron_trail/sidekiq'

RSpec.describe SoftJob, type: 'job' do
  let!(:person) { Person.create!(first_name: 'John', last_name: 'Bunyan', favorite_planet: 'Earth') }

  before do
    Sidekiq::Worker.clear_all
  end

  describe 'IronTrail::SidekiqMiddleware' do
    subject(:update_trail!) do
      @queued_job_id = SoftJob.perform_async(person.id, 'Mars')
      SoftJob.drain

      person.reload
      person.iron_trails.where(operation: 'u').first
    end

    it 'stores job metadata' do
      update_trail!

      expect(update_trail!).not_to be_nil
      expect(update_trail!.metadata['job']).to be_a(Hash)
      expect(update_trail!.metadata['job']).to include({
        'jid' => @queued_job_id,
        'class' => 'SoftJob',
        'queue' => 'default'
      })
    end

    context 'when there is metadata set' do
      before do
        IronTrail.store_metadata('look', { 'at' => 'me', 'now' => -2 })
      end

      it 'has all the metadata' do
        expect(update_trail!.metadata['look']).to eq({
          'now' => -2,
          'at' => 'me'
        })

        expect(update_trail!.metadata['job']).to include({
          'jid' => @queued_job_id,
          'class' => 'SoftJob',
          'queue' => 'default'
        })
      end
    end

    context 'when job has a batch ID' do
      before do
        allow_any_instance_of(SoftJob).to receive(:bid).and_return(1337)
      end

      it 'stores job metadata' do
        expect(update_trail!.metadata['job']).to include({
          'jid' => @queued_job_id,
          'class' => 'SoftJob',
          'queue' => 'default',
          'bid' => 1337
        })
      end
    end
  end
end
