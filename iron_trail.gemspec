# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'iron_trail/version'

Gem::Specification.new do |s|
  s.name = 'iron_trail'
  s.version = IronTrail::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = 'Creates a trail strong as iron'

  s.homepage = 'https://github.com/trusted/iron_trail'
  s.authors  = ['André Diego Piske']
  s.email    = 'andrepiske@gmail.com'
  s.license  = 'MIT'

  s.files = Dir['lib/**/*', 'LICENSE'].reject { |f| File.directory?(f) }

  s.executables = []
  s.require_paths = ['lib']

  s.add_dependency 'rails', '>= 7.1'

  s.add_development_dependency 'appraisal', '~> 2.5'

  s.add_development_dependency 'rake', '~> 13.2'
  s.add_development_dependency 'rspec-rails', '~> 7.1'
  s.add_development_dependency 'pg', '~> 1.2'
  s.add_development_dependency 'json', '~> 2.8'
  s.add_development_dependency 'sidekiq', '~> 7.2'

  s.required_ruby_version = '>= 3.1.0'

  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/trusted/iron_trail/issues',
    'changelog_uri' => 'https://github.com/trusted/iron_trail/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://github.com/trusted/iron_trail/blob/main/README.md',
    'homepage_uri' => 'https://github.com/trusted/iron_trail',
    'source_code_uri' => 'https://github.com/trusted/iron_trail',
    'wiki_uri' => 'https://github.com/trusted/iron_trail/wiki'
  }
end
