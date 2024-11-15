# frozen_string_literal: true

RSpec.describe Guitar do
  describe 'has_many trails' do
    it 'has the trails' do
      person = Person.create!(first_name: 'Arthur', last_name: 'Schopenhauer')

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
  end
end
