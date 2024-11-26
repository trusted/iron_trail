# frozen_string_literal: true

namespace :iron_trail do
  namespace :tracking do
    desc 'Enables tracking for all missing tables.'
    task enable: :environment do
      tables = db_functions.collect_tables_tracking_status[:missing]
      unless tables.length.positive?
        puts 'All tables are being tracked already (no missing tables found).'
        puts 'If you think this is wrong, check your ignored_tables list.'
        return
      end

      puts "Will start tracking #{tables.length} tables."
      tables.each do |table_name|
        db_functions.enable_tracking_for_table(table_name)
      end
    end

    desc 'Disables tracking all tables. Dangerous!'
    task disable: :environment do
      abort_when_unsafe!

      tables = db_functions.collect_tables_tracking_status[:tracked]
      puts "Will stop tracking #{tables.length} tables."
      tables.each do |table_name|
        db_functions.disable_tracking_for_table(table_name)
      end

      tables = db_functions.collect_tables_tracking_status[:tracked]
      if tables.length.positive?
        puts "WARNING: Something went wrong. There are still #{tables.length} " \
             'tables being tracked.'
      else
        puts 'Done!'
      end
    end

    desc 'Shows which tables are tracking, missing and ignored.'
    task status: :environment do
      status = db_functions.collect_tables_tracking_status
      ignored = IronTrail.config.ignored_tables || []

      # We likely want to keep this structure of text untouched as someone
      # could use it to perform automation (e.g. monitoring).
      puts "Tracking #{status[:tracked].length} tables."
      puts "Missing #{status[:missing].length} tables."
      puts "There are #{ignored.length} ignored tables."

      puts 'Tracked tables:'
      status[:tracked].sort.each do |table_name|
        puts "\t#{table_name}"
      end

      puts 'Missing tables:'
      status[:missing].sort.each do |table_name|
        puts "\t#{table_name}"
      end

      puts 'Ignored tables:'
      ignored.sort.each do |table_name|
        puts "\t#{table_name}"
      end
    end

    private

    def db_functions
      @db_functions ||= IronTrail::DbFunctions.new(ActiveRecord::Base.connection)
    end

    def abort_when_unsafe!
      run_unsafe = %w[true 1 yes].include?(ENV['IRONTRAIL_RUN_UNSAFE'])
      return unless Rails.env.production? && !run_unsafe

      puts 'Aborting: operation is dangerous in a production environment. ' \
           'Override this behavior by setting the IRONTRAIL_RUN_UNSAFE=1 env var.'

      exit(1)
    end
  end
end
