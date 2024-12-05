# frozen_string_literal: true

module IronTrail
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load 'tasks/tracking.rake'
    end
  end
end
