# frozen_string_literal: true

require 'iron_trail/testing/rspec'

IronTrail::Testing.disable!

RSpec.describe 'lib/iron_trail/testing/rspec.rb' do
  let(:person) { Person.create!(first_name: 'Arthur', last_name: 'Schopenhauer') }

  subject(:do_some_changes!) do
    person.update!(first_name: 'Jim')
    person.update!(first_name: 'Jane')
  end


  describe 'IronTrail::Testing#with_iron_trail' do
    context 'when IronTrail is disabled but we enable it for a while' do
      it 'tracks only while enabled' do
        person.update!(first_name: 'Jim')

        expect(person.reload.iron_trails.length).to be(0)

        IronTrail::Testing.with_iron_trail(want_enabled: true) do
          person.update!(first_name: 'Jane')
        end

        expect(person.reload.iron_trails.length).to be(1)

        person.update!(first_name: 'Joe')

        expect(person.reload.iron_trails.length).to be(1)
      end
    end
  end

  describe 'rspec helpers' do
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
end
