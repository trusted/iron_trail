# IronTrail


## Install

Just add to your Gemfile:

```ruby
gem 'iron_trail'
```

Then run `rails g iron_trail:migration`

### Sidekiq

If you're using Sidekiq, you can have IronTrail inject metadata about the currently job.
You'll have to manually set this up.
In your sidekiq initializer file (e.g. `config/initializers/sidekiq.rb`), add:

```ruby
# This has to be manually loaded
require 'iron_trail/sidekiq'

# The add the following within any configure_server block
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add IronTrail::SidekiqMiddleware
  end
end
```

### Test suite

IronTrail relies on the [request_store][request_store] gem to store metadata that gets injected
into the database.

You'll likely want to clear RequestStore in your test suite before each test,
otherwise tests will interfere with one another.

For RSpec, use this in your `spec_helper.rb`:

```ruby
RSpec.configure do |config|
  config.before do
    RequestStore.clear!
  end
end
```

## Rake tasks

IronTrail comes with a few handy rake tasks you can use in your dev, test and
production environments.

### Enable tracking

To enable tracking for all tables if your Postgres, except the ones you
configured to be ignored, run:

```
rake iron_trail:tracking:enable
```

All this does is create a trigger that calls the IronTrail row logging function
for each table that doesn't yet has the trigger.

### Disable tracking

To disable tracking for all tracked tables, run:

```
rake iron_trail:tracking:disable
```

This will go through each table and drop the trigger that calls the IronTrail
row logging function.

Since this could be a potentially destructive action, you have to set the
IRONTRAIL_RUN_UNSAFE=1 environment variable if you're running this in a
production environment.

### Show tracking status

To get a glimpse of which tables are being tracked, which ones aren't
and which ones are in the ignore list, you can use the following.

```
rake iron_trail:tracking:status
```

[request_store]: https://rubygems.org/gems/request_store
