# Contributing

## Setup a local dev env

This guide helps you in setting up a local development environment.

First, install all dependencies:

```shell
bundle install
bundle exec appraisal install
```

A Postgres is required to run tests. The recommended way is to run a postgres instance
via docker. This makes it easier to get to a clean slate (just restart the container)
and to develop against a specific postgres version. Run the following in a different terminal
window or tab:

```shell
docker run --rm -ti -p 6000:5432 -e POSTGRES_PASSWORD=safe --name irontrail-pg postgres:17
```

## Developing

In the terminal window or tab you'll use to run specs, set the env var:

```shell
export IRONTRAIL_TEST_DOCKER=irontrail-pg
```

The env var value must match the Postgres docker container name (`--name` argument). The Rakefile
will drop and create databases in that specified container.
If you don't set that env var, then the Rakefile won't use use docker and you'll have to manually
configure the env vars to connect to your postgres instance.

A common development workflow should be to make some changes and then run the specs. You'll
have to specify (from the `Appraisals` file) the rails version you'll use to run the specs.
Then having chosen, e.g. rails 7.2, just run:

```
bundle exec appraisal rails-7.2 rake
```

This will reset the DB and run all specs. A faster way to iterate on changes is to run
the `prepare` rake task once, then run `rspec` as many times as you want. For instance:

```
# Prepare/reset the database
bundle exec appraisal rails-7.2 rake prepare
# Run most specs
bundle exec appraisal rails-7.2 rspec
```

There's a caveat when running specs. The default rake task is to run the
`prepare spec testing_spec` rake tasks. The `testing_spec` rake task will leave the DB
in an unclean state, so you'll always want to run `prepare` before anything else again.
This is because it runs a spec that needs some isolation.

## Testing

Given that the `iron_trail` gem is designed to work within a Rails app,
the test suite uses a dummy rails app to run its specs.

The dummy rails app lives in the `spec/dummy_app` directory. Part of the app
boot process is located in `spec/spec_helper.rb`.

The dummy rails app database configuration lives in the
`spec/dummy_app/config/database-template.postgres.yml` file.

## Publishing to Rubygems

Please do not publish the gem manually from your machine. Instead,
create a new release via the Github Releases feature. This will then trigger
the `.github/workflows/publish.yml` workflow which will publish the gem to
rubygems.org.

To publish a new version:

1. Open a pull request bumping the version in `lib/iron_trail/version.rb` and adjusting the `CHANGELOG.md` file (there's a link with instructions within the changelog file)
2. Go to https://github.com/trusted/iron_trail/releases/new to create a new release
3. Specify a new tag with the version prefixed with `v` (e.g. `v1.2.3`)
4. For the release contents, you may copy the changes from the changelog file (not the whole file)
5. After creating the release, github actions will publish the new gem version
