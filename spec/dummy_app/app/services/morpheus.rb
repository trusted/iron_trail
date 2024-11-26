# frozen_string_literal: true

# Morpheus knows about tables that morph, aka. STI records :-)
class Morpheus
  def just_like_in_the_movie
    {
      red: RedPill.create!,
      blue: PillBlue.create!
    }
  end

  def guitar_hero
  end
end
