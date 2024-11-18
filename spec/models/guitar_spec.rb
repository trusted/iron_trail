# frozen_string_literal: true

RSpec.describe Guitar do
  let(:person) { Person.create!(first_name: 'Arthur', last_name: 'Schopenhauer') }

  describe 'has_many trails' do
    it 'has the trails' do
      classics = PeopleManager::CLASSIC_GUITARS
      git = Guitar.create!(description: classics.first, person:)

      expect(git.trails.count).to eq(1)
      classics[1..].each_with_index do |guitar_name, index|
        git.update!(description: guitar_name)

        expect(git.trails.count).to eq(index + 2)
      end

      git.destroy!
      expect(git.trails.count).to eq(classics.length + 1)
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
        guitars = Guitar.joins(:trails, :person).where(id: [git.id]).to_a
        expect(guitars.count).to eq(2)
        expect(guitars.uniq.count).to eq(1)

        yellowz = guitars.uniq.first
        trails = yellowz.trails.sort_by(&:id)

        expect(trails[0].rec_old).to be_nil
        expect(trails[0].rec_new).to eq(git.as_json.merge('description' => 'Yellowz'))
        expect(trails[1].rec_old).to eq(git.as_json.merge('description' => 'Yellowz'))
        expect(trails[1].rec_new).to eq(git.as_json)
      end

      it 'eager loads trails for a guitar' do
        guitars = Guitar.eager_load(:trails, :person).where(id: [git.id]).to_a
        expect(guitars.count).to eq(1)

        yellowz = guitars.uniq.first
        trails = yellowz.trails.sort_by(&:id)

        expect(trails[0].rec_old).to be_nil
        expect(trails[0].rec_new).to eq(git.as_json.merge('description' => 'Yellowz'))
        expect(trails[1].rec_old).to eq(git.as_json.merge('description' => 'Yellowz'))
        expect(trails[1].rec_new).to eq(git.as_json)
      end

      it 'eager loads trails for multiple guitars' do
        guitars = Guitar
          .eager_load(:trails, :person)
          .where(id: [git.id, other_guitar.id])
          .order(Guitar.arel_table[:description] => :asc)
          .to_a
        expect(guitars.count).to eq(2)

        blues = guitars.first
        other = guitars.second

        trails_blues = blues.trails.sort_by(&:id)
        expect(trails_blues.length).to eq(2)
        expect(trails_blues[0].rec_old).to be_nil
        expect(trails_blues[0].rec_new['id']).to eq(blues.id)
        expect(trails_blues[1].rec_old['id']).to eq(blues.id)
        expect(trails_blues[1].rec_new['id']).to eq(blues.id)

        trails_other = other.trails.sort_by(&:id)
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
