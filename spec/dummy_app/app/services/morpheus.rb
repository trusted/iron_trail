# frozen_string_literal: true

# Morpheus knows about tables that morph, aka. STI records :-)
class Morpheus
  def just_like_in_the_movie
    {
      red: RedPill.create!(pill_size: 10),
      blue: PillBlue.create!(pill_size: 11)
    }
  end
end
