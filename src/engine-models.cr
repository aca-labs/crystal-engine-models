require "rethinkdb-orm"

require "./utils"
require "./jwt-base"
require "./model-base"

module Engine::Model
  # Expose RethinkDB connection
  # Use for configuration, raw queries
  class Connection < RethinkORM::Connection
  end
end

require "./engine-models/*"
