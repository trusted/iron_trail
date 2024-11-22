# frozen_string_literal: true

appraise "rails-7.1" do
  gem "rails", "~> 7.1.5"
end

appraise "rails-7.2" do
  gem "rails", "~> 7.2.2"
end

appraise "rails-8.0" do
  gem "rails", "~> 8.0.0"

  # branch ref is 'Rails8Support'
  # pg_party trunk needs Rails < 8.0, so let's use https://github.com/rkrage/pg_party/pull/86
  gem 'pg_party', github: 'AlexKovynev/pg_party', ref: 'Rails8Support'
end
