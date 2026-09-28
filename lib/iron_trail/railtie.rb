# frozen_string_literal: true

module IronTrail
  class Railtie < ::Rails::Railtie
    # An initializer, not on_load(:active_record): it must run before the app finishes
    # initializing, when newer Rails freezes ActiveRecord.query_transformers.
    initializer 'iron_trail.query_transformer' do
      IronTrail.setup_query_transformer
    end

    rake_tasks do
      load 'tasks/tracking.rake'
    end
  end
end
