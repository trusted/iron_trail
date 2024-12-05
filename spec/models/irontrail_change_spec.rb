# frozen_string_literal: true

RSpec.describe IrontrailChange do
  let(:person) { Person.create!(first_name: 'Arthur', last_name: 'Klarkey') }

  before do
    # let's have other people to ensure tests are picking up the right person
    @other_people = 3.times do |index|
      Person.create!(first_name: "Joey#{index}", last_name: "Doe#{index}").tap do |t|
        t.update!(first_name: "Ashley#{index}")
        t.update!(last_name: "X#{index}")
      end.reload
    end
  end

  describe 'IronTrail::ChangeModelConcern' do
    it 'tests the test' do
      # just ensure other people have been created
      expect(Person.count).to be >= 3
      expect(IrontrailChange.count).to be >= 9
    end

    describe 'where_object_changes_from' do
      before do
        person.update!(first_name: 'Michael')
        person.update!(first_name: 'Johnny', last_name: 'Tod')
        person.update!(first_name: 'Michael', favorite_planet: 'Saturn')
        person.update!(last_name: 'Cash')
      end

      it 'finds the expected records' do
        scope = person.iron_trails.where_object_changes_from(first_name: 'Michael')
        expect(scope.count).to eq(1)

        expect(scope.first.rec_old).to include('first_name' => 'Michael', 'last_name' => 'Klarkey')
        expect(scope.first.rec_new).to include('first_name' => 'Johnny', 'last_name' => 'Tod')
        expect(scope.first.rec_delta).to eq({
          'first_name' => ['Michael', 'Johnny'],
          'last_name' => ['Klarkey', 'Tod']
        })

        scope = person.iron_trails.where_object_changes_from(last_name: 'Tod')
        expect(scope.count).to eq(1)

        expect(scope.first.rec_old).to include('first_name' => 'Michael', 'last_name' => 'Tod')
        expect(scope.first.rec_new).to include('first_name' => 'Michael', 'last_name' => 'Cash')
        expect(scope.first.rec_delta).to eq({
          'last_name' => ['Tod', 'Cash']
        })

        scope = person.iron_trails.where_object_changes_from(last_name: 'Cash')
        expect(scope.count).to eq(0)
      end
    end

    describe 'where_object_changes_to' do
      before do
        person.update!(first_name: 'Michael')
        person.update!(first_name: 'Johnny', last_name: 'Tod')
        person.update!(first_name: 'Michael', favorite_planet: 'Saturn')
        person.update!(last_name: 'Cash')
      end

      it 'finds the expected records' do
        scope = person.iron_trails.where_object_changes_to(last_name: 'Cash')
        expect(scope.count).to eq(1)

        expect(scope.first.rec_old).to include('first_name' => 'Michael', 'last_name' => 'Tod')
        expect(scope.first.rec_new).to include('first_name' => 'Michael', 'last_name' => 'Cash')
        expect(scope.first.rec_delta).to eq({ 'last_name' => ['Tod', 'Cash'] })

        scope = person.iron_trails.where_object_changes_to(first_name: 'Michael')
          .order({
            described_class.arel_table[:created_at] => :asc,
            described_class.arel_table[:id] => :asc
          })

        expect(scope.first.rec_old).to include('first_name' => 'Arthur', 'last_name' => 'Klarkey')
        expect(scope.first.rec_new).to include('first_name' => 'Michael', 'last_name' => 'Klarkey')
        expect(scope.first.rec_delta).to eq({ 'first_name' => ['Arthur', 'Michael'] })

        expect(scope.last.rec_old).to include('first_name' => 'Johnny', 'last_name' => 'Tod', 'favorite_planet' => nil)
        expect(scope.last.rec_new).to include('first_name' => 'Michael', 'last_name' => 'Tod', 'favorite_planet' => 'Saturn')
        expect(scope.last.rec_delta).to eq({
          'first_name' => ['Johnny', 'Michael'],
          'favorite_planet' => [nil, 'Saturn']
        })

        planet_changed_record = scope.last.clone

        scope = person.iron_trails.where_object_changes_to(favorite_planet: 'Saturn')
        expect(scope.count).to eq(1)

        expect(scope.first.id).to eq(planet_changed_record.id)
      end
    end
  end
end
