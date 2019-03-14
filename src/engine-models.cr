require "rethinkdb-orm"

module Engine::Model
  abstract class ModelBase < RethinkORM::Base
  end
end

require "./engine-models/*"
