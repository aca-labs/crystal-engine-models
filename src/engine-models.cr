require "rethinkdb-orm"
require "neuroplastic"
require "active-model"

module Engine::Model
  abstract class ModelBase < RethinkORM::Base
    include Neuroplastic
  end

  abstract class SubModel < ActiveModel::Model
    include ActiveModel::Validation

    # Generate string for field
    def to_reql
      self.to_json
    end
  end
end

require "./engine-models/*"
