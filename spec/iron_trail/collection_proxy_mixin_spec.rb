# frozen_string_literal: true

RSpec.describe IronTrail::CollectionProxyMixin do
  describe '#travel_to' do
    let(:person) { Person.create!(first_name: 'Arthur', last_name: 'Schopenhauer') }
    let(:guitar) { Guitar.create!(description: 'the guitar', person:) }
    let!(:part) { travel_to(Time.utc(2025, 1, 1, 10)) { guitar.guitar_parts.create!(name: 'neck') } }

    before do
      travel_to(Time.utc(2025, 1, 2, 10)) { part.update!(name: 'body') }
      travel_to(Time.utc(2025, 1, 4, 10)) { part.update!(name: 'strings') }
    end

    def trail_queries(&)
      queries = []
      callback = lambda do |_name, _start, _finish, _id, payload|
        queries << payload[:sql] if payload[:sql].include?('irontrail_changes')
      end
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &)

      queries
    end

    context 'when the record has not changed since the given time' do
      let(:at) { Time.utc(2025, 1, 5, 10) }

      it 'bounds the lookup below by the record updated_at' do
        git = nil
        queries = trail_queries { git = part.iron_trails.travel_to(at) }

        expect(git.name).to eq('strings')
        expect(queries).to contain_exactly(a_string_including("'2025-01-04 10:00:00'"))
      end
    end

    context 'when the record changed after the given time' do
      let(:at) { Time.utc(2025, 1, 3, 10) }

      it 'bounds the lookup below by the record created_at' do
        git = nil
        queries = trail_queries { git = part.iron_trails.travel_to(at) }

        expect(git.name).to eq('body')
        expect(queries).to contain_exactly(a_string_including("'2025-01-01 10:00:00'"))
      end

      it 'accepts the time as a string' do
        expect(part.iron_trails.travel_to('2025-01-03T10:00:00Z').name).to eq('body')
      end
    end

    context 'when no change is at or after the bound' do
      before do
        part.iron_trails.where(created_at: Time.utc(2025, 1, 4, 10)).delete_all
      end

      it 'falls back to the unbounded lookup' do
        expect(part.iron_trails.travel_to(Time.utc(2025, 1, 5, 10)).name).to eq('body')
      end
    end

    it 'returns nil for a nil time' do
      expect(part.iron_trails.travel_to(nil)).to be_nil
    end
  end
end
