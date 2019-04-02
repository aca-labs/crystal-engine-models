require "rethinkdb-orm"
require "neuroplastic"

module Engine::Model
  abstract class ModelBase < RethinkORM::Base
    include Neuroplastic
  end
end

require "./engine-models/*"
