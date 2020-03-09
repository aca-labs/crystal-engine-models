require "rethinkdb-orm"

require "./models/base/*"

module PlaceOS::Model
  # Expose RethinkDB connection
  # Use for configuration, raw queries
  class Connection < RethinkORM::Connection
  end
end

require "./models/*"
