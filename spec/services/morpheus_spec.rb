# frozen_string_literal: true

RSpec.describe Morpheus do
  subject(:instance) { described_class.new }

  describe '#just_like_in_the_movie' do
    xit 'offers two pills' do
      3.times { described_class.new.just_like_in_the_movie }

      pills = described_class.new.just_like_in_the_movie
    end
  end
end
