# frozen_string_literal: true

RSpec.describe Guitar do
  let(:person) { Person.create!(first_name: 'Arthur', last_name: 'Schopenhauer') }

  describe 'IronTrail::ChangeModelConcern' do
    describe 'helper methods' do
      before do
        person.update!(first_name: 'Joe')
        person.update!(first_name: 'Joey')
        person.destroy!
      end

      it 'correctly classifies operations' do
        expect(person.iron_trails.length).to eq(4)
        expect(person.iron_trails.inserts.length).to eq(1)
        expect(person.iron_trails.updates.length).to eq(2)
        expect(person.iron_trails.deletes.length).to eq(1)

        expect(person.iron_trails.inserts[0].insert_operation?).to be(true)
        expect(person.iron_trails.inserts[0].update_operation?).to be(false)
        expect(person.iron_trails.inserts[0].delete_operation?).to be(false)

        expect(person.iron_trails.updates[0].insert_operation?).to be(false)
        expect(person.iron_trails.updates[0].update_operation?).to be(true)
        expect(person.iron_trails.updates[0].delete_operation?).to be(false)
        expect(person.iron_trails.updates[1].insert_operation?).to be(false)
        expect(person.iron_trails.updates[1].update_operation?).to be(true)
        expect(person.iron_trails.updates[1].delete_operation?).to be(false)

        expect(person.iron_trails.deletes[0].insert_operation?).to be(false)
        expect(person.iron_trails.deletes[0].update_operation?).to be(false)
        expect(person.iron_trails.deletes[0].delete_operation?).to be(true)
      end
    end
  end

  describe 'metadata _created_at attribute' do
    let(:guitar) { Guitar.create!(description: 'the guitar', person:) }

    before do
      @time_now_db = ActiveRecord::Base.connection.query('SELECT NOW()').flatten.first
      expect { guitar }.to change{ Guitar.count }.by(+1)

      IronTrail.store_metadata(:_created_at, Time.parse('2023-10-12T17:05:22+0200').to_f)
      guitar.update!(description: 'guitar 2')

      IronTrail.store_metadata(:_created_at, Time.parse('2023-11-29T04:55:28+0200').to_f)
      guitar.update!(description: 'guitar 3')
    end

    let(:trails) { guitar.reload.iron_trails.order({ id: :asc, created_at: :asc }) }

    it 'has the expected timestamps' do
      expect(trails.count).to eq(3)

      expect(trails[0]).to have_attributes(operation: 'i')
      expect(trails[0].created_at).to be_within(2.seconds).of(@time_now_db)

      expect(trails[1]).to have_attributes(operation: 'u', created_at: Time.parse('2023-10-12T15:05:22Z'))
      expect(trails[2]).to have_attributes(operation: 'u', created_at: Time.parse('2023-11-29T02:55:28Z'))
    end

    it 'has _created_at removed from metadata' do
      expect(trails[1].metadata).not_to include('_created_at')
      expect(trails[2].metadata).not_to include('_created_at')
    end

    it 'has _db_created_at in metadata whenever _created_at is passed in' do
      expect(trails[0].metadata).to be_nil
      expect(trails[1].metadata).to include('_db_created_at')
      expect(trails[2].metadata).to include('_db_created_at')

      expect(Time.at(trails[1].metadata['_db_created_at'])).to be_within(1.second).of(@time_now_db)
      expect(Time.at(trails[2].metadata['_db_created_at'])).to be_within(1.second).of(@time_now_db)
    end
  end

  describe 'iron_trails.travel_to' do
    let(:guitar) { Guitar.create!(description: 'the guitar', person:) }

    before do
      fake_timestamps = [
        Time.parse('2005-04-15T13:44:59Z'),
        Time.parse('2005-05-08T14:00:03Z'),
        Time.parse('2005-05-08T14:00:15Z'),
        Time.parse('2005-05-08T14:02:00Z')
      ]

      guitar.update!(description: 'guitar 2')
      guitar.update!(description: 'guitar 3')
      guitar.update!(description: 'guitar 4')
      @trail_ids = guitar.iron_trails.order(id: :asc).pluck(:id)

      expect(@trail_ids.length).to eq(4)

      @trail_ids.zip(fake_timestamps).each do |trail_id, fake_ts|
        query = "UPDATE irontrail_changes SET created_at='#{fake_ts}' WHERE id=#{trail_id}"
        result = ActiveRecord::Base.connection.execute(query)
        expect(result.cmd_tuples).to eq(1)
      end
      guitar.reload
    end

    it 'recovers the correct record' do
      git = guitar.iron_trails.travel_to('2005-05-08T14:00:03Z')

      expect(git).to be_a(Guitar)
      expect(git.id).to eq(guitar.id)
      expect(git.description).to eq('guitar 2')
    end

    it 'has no ghost reified attributes' do
      git = guitar.iron_trails.travel_to('2005-05-08T14:00:03Z')
      expect(git.irontrail_reified_ghost_attributes).to be_nil
    end

    context 'when a version has attributes that dont exist anymore' do
      before do
        trail_id = @trail_ids[2]
        trail = IrontrailChange.find_by!(id: trail_id)

        rec_old = trail.rec_old.merge('foo' => 'perfectly fine')
        rec_new = trail.rec_new.merge('foo' => 'ghosted!')

        query = <<~SQL
          UPDATE irontrail_changes SET
            rec_old=#{ActiveRecord::Base.connection.quote(JSON.dump(rec_old))}::jsonb,
            rec_new=#{ActiveRecord::Base.connection.quote(JSON.dump(rec_new))}::jsonb
          WHERE id=#{trail_id}
        SQL

        result = ActiveRecord::Base.connection.execute(query)
        expect(result.cmd_tuples).to eq(1)
      end

      describe 'on time' do
        let(:git) { guitar.iron_trails.travel_to('2005-05-08T14:00:15Z') }

        it 'contains ghost reified attributes' do
          expect(git).to be_a(Guitar)
          expect(git.id).to eq(guitar.id)
          expect(git.description).to eq('guitar 3')
          expect(git.irontrail_reified_ghost_attributes).to eq({ foo: 'ghosted!' }.with_indifferent_access)
        end
      end

      describe 'a little late' do
        let(:git) { guitar.iron_trails.travel_to('2005-05-08T14:00:17Z') }

        it 'contains ghost reified attributes' do
          expect(git).to be_a(Guitar)
          expect(git.description).to eq('guitar 3')
          expect(git.irontrail_reified_ghost_attributes).to eq({ foo: 'ghosted!' }.with_indifferent_access)
        end
      end
    end

    context 'when the object has been destroyed' do
      let(:destroy_time) { '2006-10-21T06:00:00Z' }
      before do
        guitar.destroy!
        query = "UPDATE irontrail_changes SET created_at='#{destroy_time}' WHERE operation='d' AND rec_id='#{guitar.id}'"
        result = ActiveRecord::Base.connection.execute(query)
        expect(result.cmd_tuples).to eq(1)
      end

      describe 'on time' do
        let(:git) { guitar.iron_trails.travel_to(destroy_time) }

        it 'recovers the correct record' do
          expect(git).to be_a(Guitar)
          expect(git.id).to eq(guitar.id)
          expect(git.description).to eq('guitar 4')
        end
      end

      describe 'a little late' do
        let(:git) { guitar.iron_trails.travel_to(Time.parse(destroy_time) + 5) }

        it 'recovers the correct record' do
          expect(git).to be_a(Guitar)
          expect(git.id).to eq(guitar.id)
          expect(git.description).to eq('guitar 4')
        end
      end
    end
  end

  describe 'has_many trails' do
    it 'has the trails' do
      classics = PeopleManager::CLASSIC_GUITARS
      git = Guitar.create!(description: classics.first, person:)

      expect(git.iron_trails.count).to eq(1)
      classics[1..].each_with_index do |guitar_name, index|
        git.update!(description: guitar_name)

        expect(git.iron_trails.count).to eq(index + 2)
      end

      git.destroy!
      expect(git.iron_trails.count).to eq(classics.length + 1)
    end

    context 'with interfering records' do
      subject(:other_guitar) do
        og_ = Guitar.create!(description: 'Second', person:)

        og_.update!(description: 'MidSecond')
        og_.update!(description: 'NewSecond')

        og_
      end

      # Set up 2 guitars so to ensure there won't be cross contamination
      subject(:git) do
        git_ = Guitar.create!(description: 'Yellowz', person:)
        git_.update!(description: 'Blues')

        git_
      end

      before do
        expect(Guitar.count).to eq(0)
        git

        other_guitar
        expect(Guitar.count).to eq(2)
      end

      it 'joins the correct records' do
        guitars = Guitar.joins(:iron_trails, :person).where(id: [git.id]).to_a
        expect(guitars.count).to eq(2)
        expect(guitars.uniq.count).to eq(1)

        yellowz = guitars.uniq.first
        trails = yellowz.iron_trails.sort_by(&:id)

        expect(trails[0].id).not_to be_nil

        expect(trails[0].rec_old).to be_nil
        expect(trails[0].rec_new).to eq(git.as_json.merge('description' => 'Yellowz'))
        expect(trails[1].rec_old).to eq(git.as_json.merge('description' => 'Yellowz'))
        expect(trails[1].rec_new).to eq(git.as_json)
      end

      it 'eager loads trails for a guitar' do
        guitars = Guitar.eager_load(:iron_trails, :person).where(id: [git.id]).to_a
        expect(guitars.count).to eq(1)

        yellowz = guitars.uniq.first
        trails = yellowz.iron_trails.sort_by(&:id)

        expect(trails[0].id).not_to be_nil

        expect(trails[0].rec_old).to be_nil
        expect(trails[0].rec_new).to eq(git.as_json.merge('description' => 'Yellowz'))
        expect(trails[1].rec_old).to eq(git.as_json.merge('description' => 'Yellowz'))
        expect(trails[1].rec_new).to eq(git.as_json)
      end

      it 'eager loads trails for multiple guitars' do
        guitars = Guitar
          .eager_load(:iron_trails, :person)
          .where(id: [git.id, other_guitar.id])
          .order(Guitar.arel_table[:description] => :asc)
          .to_a
        expect(guitars.count).to eq(2)

        blues = guitars.first
        other = guitars.second

        trails_blues = blues.iron_trails.sort_by(&:id)
        expect(trails_blues.length).to eq(2)
        expect(trails_blues[0].rec_old).to be_nil
        expect(trails_blues[0].rec_new['id']).to eq(blues.id)
        expect(trails_blues[1].rec_old['id']).to eq(blues.id)
        expect(trails_blues[1].rec_new['id']).to eq(blues.id)

        trails_other = other.iron_trails.sort_by(&:id)
        expect(trails_other.length).to eq(3)

        expect(trails_other[0].rec_old).to be_nil
        expect(trails_other[0].rec_new['id']).to eq(other.id)
        expect(trails_other[1].rec_old['id']).to eq(other.id)
        expect(trails_other[1].rec_new['id']).to eq(other.id)
        expect(trails_other[2].rec_old['id']).to eq(other.id)
        expect(trails_other[2].rec_new['id']).to eq(other.id)
      end
    end
  end
end
