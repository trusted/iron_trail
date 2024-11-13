# frozen_string_literal: true

class PeopleManager
  CLASSIC_GUITARS = [
    'Fender CD-60S',
    'Yamaha FG800',
    'Martin LX1E Little Martin',
    'Taylor GS Mini Acoustic Guitar',
    'Epiphone Inspired By Gibson J-45',
    'Taylor 110e acoustic guitar'
  ].freeze

  def give_birth_to(first_name, last_name, at:)
    Person.create!(
      first_name:,
      last_name:
    )
  end

  def employ_classic_guitars(person, variation)
    # Disclaimer: I know nothing about guitars, this is just some random
    # stuff I got from out there.
    guitar = Guitar.new(person:)

    CLASSIC_GUITARS.each do |name|
      guitar.description = "#{name} #{variation}"
      guitar.save!
    end

    guitar.destroy!

    guitar.id
  end
end
