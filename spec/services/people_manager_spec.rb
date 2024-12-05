# frozen_string_literal: true

RSpec.describe PeopleManager do
  subject(:instance) { described_class.new }

  describe '#give_birth_to' do
    it 'has a birth history' do
      person = instance.give_birth_to('John', 'Doe', at: Time.now)

      expect(person.persisted?).to be true

      results = ActiveRecord::Base.connection.execute("select * from irontrail_changes WHERE rec_table='people' AND rec_id=#{person.id}::text").to_a
      expect(results.length).to be 1

      record_new = JSON.parse(results.first['rec_new'])
      expect(record_new).to eq(person.as_json)
    end

  end

  describe '#employ_classic_guitars' do
    context 'people with classic guitars' do
      let(:names) { ['Jane Doe', 'Kate Pop', 'Bob Ross'] }
      let(:people) { names.map { |n| instance.give_birth_to(*(n.split(' ', 2)), at: Time.now) } }

      # per guitar, one create plus (guitars - 1) updates, plus a final destroy
      let(:expected_change_count) { (described_class::CLASSIC_GUITARS.length + 1) * people.count }

      subject(:guitar_ids) { people.zip(names).map { |person, name| instance.employ_classic_guitars(person, name) } }

      it 'registers the right amount of changes' do
        people # Ensure people exist beforehand

        expect { guitar_ids }.to change {
          ActiveRecord::Base.connection.execute("select count(*) as c from irontrail_changes").to_a.first['c'].to_i
        }.by(expected_change_count)

        # expect no errors
        res = ActiveRecord::Base.connection.execute("select count(*) as c from irontrail_trigger_errors").to_a.first
        expect(res['c']).to eq(0)
      end

      it 'creates the right change records per person based on person ID' do
        guitar_ids

        people.each do |person|
          res = ActiveRecord::Base.connection.execute(<<~SQL).to_a
            SELECT * FROM irontrail_changes WHERE
            rec_table='guitars' AND rec_new->>'person_id'='#{person.id}'
            ORDER BY id ASC
          SQL

          expected_guitar_names = described_class::CLASSIC_GUITARS.map do |n|
            "#{n} #{person.full_name}"
          end
          actual_names = res.map do |change_record|
            new_record = JSON.parse(change_record['rec_new'])
            new_record['description']
          end

          expect(actual_names).to eq(expected_guitar_names)
        end
      end
    end
  end
end
