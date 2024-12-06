# IronTrail [![CI](https://github.com/trusted/iron_trail/actions/workflows/test.yml/badge.svg)](https://github.com/trusted/iron_trail/actions/workflows/test.yml)

IronTrail is a CDC (Change Data Capture) solution
which keeps track of data changes in the database. It is similar to
[paper_trail](https://rubygems.org/gems/paper_trail) in many aspects,
but it tracks changes at the database level using a PL/pgSQL function
and triggers.

Using database triggers has the benefit of not depending on ActiveRecord callbacks
which can be skipped and could often result in missed change captures.

It works with PostgreSQL databases only.

## How it works

The tracking occurs in the PL/pgSQL function ([here][irontrail_log_row_function])
which has to be attached to tables with a CREATE TRIGGER statement.

Every change to every row is logged into the `irontrail_changes` table, which
stores both old and new record versions in JSON format as well as a _delta_
stating what has changed.

The gem is not necessary for the capture to work, but it provides a few niceties
such as allowing metadata (e.g. currently logged in user, current request info)
to be tracked and easy setup and testing utilities.

## Install

Just add to your Gemfile:

```ruby
gem 'iron_trail'
```

Then run `rails g iron_trail:migration`

### Sidekiq

IronTrail can inject metadata about the currently running Sidekiq job.
You'll have to manually set this up in your sidekiq initializer file
(e.g. `config/initializers/sidekiq.rb`). Add the following to it:

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

You'll likely also want to require [lib/iron_trail/testing/rspec.rb](lib/iron_trail/testing/rspec.rb)
in your `rails_helper.rb`, then explicitly either disable or enable IronTrail in tests:

```ruby
require 'iron_trail/testing/rspec'
IronTrail::Testing.enable! # to have it enabled by default in specs
IronTrail::Testing.disable! # to have it disabled by default in specs
```

You don't make it explicit, IronTrail will be enabled by default, which will
likely impact your test suite performance slightly.

In case you disable it by default, you can enable it per rspec context with:

```ruby
describe 'in a "describe" block', iron_trail: true do
  it 'or also in an "it" block', iron_trail: true do
    # ...
  end
end
```

Enabling/disabling IronTrail in specs works by replacing the trigger function in Postgres
with a dummy no-op function or with the real function and it won't add or drop triggers from
any tables.

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
[irontrail_log_row_function]: lib/iron_trail/irontrail_log_row_function.sql
