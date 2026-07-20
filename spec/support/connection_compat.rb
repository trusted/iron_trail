# frozen_string_literal: true

# Compatibility helper so the suite can lease a connection uniformly across the
# supported Rails range. ActiveRecord::Base.lease_connection was introduced in
# Rails 7.2; on Rails 7.1 it does not exist yet, so we fall back to the
# (soft-deprecated on Rails 8.1+) ActiveRecord::Base.connection.
module ConnectionCompat
  def lease_connection
    if ActiveRecord::Base.respond_to?(:lease_connection)
      ActiveRecord::Base.lease_connection
    else
      ActiveRecord::Base.connection
    end
  end
end

RSpec.configure do |config|
  config.include ConnectionCompat
end
