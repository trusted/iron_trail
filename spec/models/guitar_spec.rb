# frozen_string_literal: true

RSpec.describe Guitar do
  let(:person) { Person.create!(first_name: 'Arthur', last_name: 'Schopenhauer') }

  describe 'iron_trails.version_at' do
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
      git = guitar.iron_trails.version_at('2005-05-08T14:00:03Z')

      expect(git).to be_a(Guitar)
      expect(git.id).to eq(guitar.id)
      expect(git.description).to eq('guitar 2')
    end

    it 'has no ghost reified attributes' do
      git = guitar.iron_trails.version_at('2005-05-08T14:00:03Z')
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
        let(:git) { guitar.iron_trails.version_at('2005-05-08T14:00:15Z') }

        it 'contains ghost reified attributes' do
          expect(git).to be_a(Guitar)
          expect(git.id).to eq(guitar.id)
          expect(git.description).to eq('guitar 3')
          expect(git.irontrail_reified_ghost_attributes).to eq({ foo: 'ghosted!' }.with_indifferent_access)
        end
      end

      describe 'a little late' do
        let(:git) { guitar.iron_trails.version_at('2005-05-08T14:00:17Z') }

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
        let(:git) { guitar.iron_trails.version_at(destroy_time) }

        it 'recovers the correct record' do
          expect(git).to be_a(Guitar)
          expect(git.id).to eq(guitar.id)
          expect(git.description).to eq('guitar 4')
        end
      end

      describe 'a little late' do
        let(:git) { guitar.iron_trails.version_at(Time.parse(destroy_time) + 5) }

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
