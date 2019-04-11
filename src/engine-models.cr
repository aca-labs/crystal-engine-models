require "active-model"
require "neuroplastic"
require "json"
require "rethinkdb-orm"

require "./utils"

module Engine::Model
  abstract class ModelBase < RethinkORM::Base
    include Neuroplastic
  end

  abstract class SubModel < ActiveModel::Model
    include ActiveModel::Validation

    # RethinkDB library serializes through JSON::Any
    def to_reql
      JSON::Any.new(self.to_json)
    end
  end
end

require "./engine-models/*"
