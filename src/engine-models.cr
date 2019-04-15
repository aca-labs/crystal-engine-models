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

    # Propagate submodel validation errors to parent's
    protected def collect_errors(collection : Symbol, models)
      errors = models.compact_map do |m|
        m.errors unless m.valid?
      end
      errors.flatten.each do |e|
        self.validation_error(collection, e.message)
      end
    end
  end
end

require "./engine-models/*"
