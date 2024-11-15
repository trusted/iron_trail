# frozen_string_literal: true
ENV['DB'] ||= 'postgres'
require 'fileutils'
require 'bundler'

Bundler::GemHelper.install_tasks

desc 'Copy the database.DB.yml per ENV[\'DB\']'
task :install_database_yml do
  puts "installing database.yml for #{ENV['DB']}"

  FileUtils.rm('spec/dummy_app/db/database.yml', force: true)

  FileUtils.cp(
    "spec/dummy_app/config/database-template.#{ENV['DB']}.yml",
    'spec/dummy_app/config/database.yml'
  )
end

desc 'Delete generated files and databases'
task :clean do
  db = ENV.fetch('DB', 'postgres')
  puts "Will drop #{db} database"

  case db
  when 'postgres'
    system('dropdb --if-exists iron_trail_test > /dev/null 2>&1')
  else
    raise "Don't know DB '#{db}'"
  end

  # Delete generated IronTrail migrations
  migrate_path = File.expand_path('spec/dummy_app/db/migrate', __dir__)
  Dir.glob("#{migrate_path}/*.rb").each do |full_path|
    base_name = File.basename(full_path)
    next unless base_name =~ /^\d{14}_create_irontrail_.+\.rb$/

    FileUtils.rm full_path
  end
end

desc 'Create the database.'
task :create_db do
  db = ENV.fetch('DB', 'postgres')
  puts "Will create #{db} database"

  case db
  when 'postgres'
    system "createdb iron_trail_test"
  else
    raise "Don't know DB '#{db}'"
  end
end

task prepare: %i[clean install_database_yml create_db]

require 'rspec/core/rake_task'

task(:spec).clear
RSpec::Core::RakeTask.new(:spec)

task default: %i[prepare spec]
