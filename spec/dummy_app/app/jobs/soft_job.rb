# frozen_string_literal: true

class SoftJob
  include Sidekiq::Job

  def perform(id, favorite_planet)
    person = Person.find(id)
    person.update!(favorite_planet:)
  end
end
