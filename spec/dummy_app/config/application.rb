# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
# Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    rails_major_minor = ActiveSupport.gem_version.segments[0..1].join('.')

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults rails_major_minor

    # config.encoding = "utf-8"
    # config.filter_parameters += [:password]
    # config.active_support.escape_html_entities_in_json = true
    # config.active_support.test_order = :sorted
    # config.secret_key_base = "A fox regularly kicked the screaming pile of biscuits."

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    # config.autoload_lib(ignore: %w[assets tasks])
    config.eager_load = false

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    # config.generators.system_tests = nil
  end
end
