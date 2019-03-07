require "rethinkdb-orm"

module Engine
  abstract class Model < RethinkORM::Base
  end
end

require "./engine-models/*"
require "./engine-models/**"
