require "rethinkdb-orm"

module Engine::Model
  private abstract class ModelBase < RethinkORM::Base
  end
end

require "./engine-models/*"
