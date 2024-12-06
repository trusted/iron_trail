# frozen_string_literal: true

require 'iron_trail/testing/rspec'

IronTrail::Testing.disable!

RSpec.describe 'lib/iron_trail/testing/rspec.rb' do
  let(:person) { Person.create!(first_name: 'Arthur', last_name: 'Schopenhauer') }

  subject(:do_some_changes!) do
    person.update!(first_name: 'Jim')
    person.update!(first_name: 'Jane')
  end

  context 'with IronTrail disabled' do
    it 'does not track anything' do
      do_some_changes!

      expect(person.reload.iron_trails.length).to be(0)
    end
  end

  context 'with IronTrail enabled through the helper', iron_trail: true do
    it 'does not track anything' do
      do_some_changes!

      expect(person.reload.iron_trails.length).to be(3)
    end
  end
end
