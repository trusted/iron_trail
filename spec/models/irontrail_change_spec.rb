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

      context 'when change is from a nil value' do
        it 'finds the expected record' do
          scope = person.iron_trails.where_object_changes_from(favorite_planet: nil)
          expect(scope.count).to eq(1)
          expect(scope.first.rec_old).to include('first_name' => 'Johnny', 'last_name' => 'Tod')
          expect(scope.first.rec_new).to include('first_name' => 'Michael', 'last_name' => 'Tod')
        end
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
        person.update!(last_name: 'Cash', favorite_planet: nil)
      end

      context 'when change is to a nil value' do
        it 'finds the expected record' do
          scope = person.iron_trails.where_object_changes_to(favorite_planet: nil)
          expect(scope.count).to eq(1)
          expect(scope.first.rec_new).to include('first_name' => 'Michael', 'last_name' => 'Cash')
        end
      end

      it 'finds the expected records' do
        scope = person.iron_trails.where_object_changes_to(last_name: 'Cash')
        expect(scope.count).to eq(1)

        expect(scope.first.rec_old).to include('first_name' => 'Michael', 'last_name' => 'Tod')
        expect(scope.first.rec_new).to include('first_name' => 'Michael', 'last_name' => 'Cash')
        expect(scope.first.rec_delta).to eq({
          'last_name' => ['Tod', 'Cash'],
          'favorite_planet' => ['Saturn', nil]
        })

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

    describe 'with_delta_other_than' do
      subject(:trails) { person.iron_trails.with_delta_other_than(*columns) }

      before do
        person.update!(first_name: 'Michael')
        person.update!(first_name: 'Bob', favorite_planet: 'Saturn')
        person.update!(favorite_planet: 'Pluto*')
        person.update!(last_name: 'Cash')
      end

      let(:columns) { [:favorite_planet] }

      it 'has basic functionality' do
        expect(trails.count).to eq(3)
        expect(trails.order(id: :asc).map(&:rec_delta)).to eq([
          { 'first_name' => ['Arthur', 'Michael'] },
          { 'first_name' => ['Michael', 'Bob'], 'favorite_planet' => [nil, 'Saturn'] },
          { 'last_name' => ['Klarkey', 'Cash'] },
        ])

        all_change_values_to = trails.flat_map { |x| x.rec_delta.values.map(&:second) }
        expect(all_change_values_to).to include('Bob')
        expect(all_change_values_to).not_to include('Pluto*')
      end

      context 'when there are multiple columns' do
        let(:columns) { ['favorite_planet', :first_name] }

        it 'ignored all changes that only change favorite_planet and/or first_name' do
          expect(trails.count).to eq(1)
          expect(trails.first.rec_delta).to eq({ 'last_name' => ['Klarkey', 'Cash'] })
        end
      end

      context 'when columns is empty' do
        let(:columns) { [] }

        it 'returns all updates' do
          expect(trails.count).to eq(4)
        end

        # rec_delta is null for insert and delete opertations, this means
        # they're implicitly excluded when #with_delta_other_than is applied.
        it 'returns update operations only' do
          operations = trails.map(&:operation).uniq
          expect(operations).to contain_exactly('u')
        end
      end
    end
  end
end
