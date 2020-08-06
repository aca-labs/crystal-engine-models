require "json"
require "rethinkdb-orm"
require "time"

require "./base/model"
require "./trigger/*"

module PlaceOS::Model
  class Trigger < ModelBase
    include RethinkORM::Timestamps
    table :trigger

    attribute name : String, es_type: "keyword"
    attribute description : String = ""

    # Full path allows resolution in macros
    attribute actions : PlaceOS::Model::Trigger::Actions = ->{ Actions.new }, es_type: "object"
    attribute conditions : PlaceOS::Model::Trigger::Conditions = ->{ Conditions.new }, es_type: "object"

    # In milliseconds
    attribute debounce_period : Int32 = 0
    attribute important : Bool = false

    METHODS = %w(GET POST PUT PATCH DELETE)
    attribute enable_webhook : Bool = false
    attribute supported_methods : Array(String) = ["POST"]

    def supported_method?(method)
      !!(supported_methods.try &.includes?(method))
    end

    has_many(
      child_class: TriggerInstance,
      dependent: :destroy,
      foreign_key: "trigger_id",
      collection_name: :trigger_instances
    )

    # Allows filtering in cases of a Trigger belonging to a single ControlSystem
    belongs_to ControlSystem, foreign_key: "control_system_id"

    # ---------------------------
    # VALIDATIONS
    # ---------------------------

    validate ->(this : Trigger) {
      return unless (supported_methods = this.supported_methods)
      invalid = supported_methods - METHODS
      this.validation_error(:supported_methods, "contains invalid methods: #{invalid.join(", ")}") unless invalid.empty?
    }

    validate ->(this : Trigger) {
      if (actions = this.actions) && !actions.valid?
        actions.errors.each do |e|
          this.validation_error(:action, e.to_s)
        end
      end

      if (conditions = this.conditions) && !conditions.valid?
        conditions.errors.each do |e|
          this.validation_error(:condition, e.to_s)
        end
      end
    }
  end
end
