# frozen_string_literal: true

RSpec.describe Morpheus do
  subject(:instance) { described_class.new }
  subject(:pills) { instance.just_like_in_the_movie }

  it 'has the type attribute serialized' do
    red = pills[:red]

    red.update!(pill_size: 44)
    trails = red.reload.iron_trails.order(id: :asc)

    expect(trails.length).to eq(2)
    expect(trails[0].rec_new['type']).to eq('RedPill')
    expect(trails[1].rec_new['type']).to eq('RedPill')
  end

  describe 'object morphing' do
    it 'morphs colors' do
      blue = pills[:blue]
      pills[:red].destroy!

      blue.update!(pill_size: 15)
      blue.update!(pill_size: 25)

      trail = blue.iron_trails.where_object_changes_to(pill_size: 15).first
      trail.rec_new['type'] = 'RedPill' # likely invalid case in the real world, but good for testing.
      trail.save!
      blue.reload

      red = blue.iron_trails.where_object_changes_to(pill_size: 15).first.reify
      expect(red).to be_a(RedPill)

      blue_again = blue.iron_trails.where_object_changes_to(pill_size: 25).first.reify
      expect(blue_again).to be_a(PillBlue)
    end
  end
end
