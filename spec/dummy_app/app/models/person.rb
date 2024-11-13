# frozen_string_literal: true

class Person < ApplicationRecord
  has_many :guitars

  def full_name
    "#{first_name} #{last_name}"
  end
end
