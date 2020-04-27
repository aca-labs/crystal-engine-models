require "log"
require "rethinkdb-orm"

require "./models/base/*"

module PlaceOS::Model
  Log = ::Log.for(self)

  # Expose RethinkDB connection
  # Use for configuration, raw queries
  class Connection < RethinkORM::Connection
  end
end

require "./models/*"
