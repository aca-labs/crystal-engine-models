require "json"
require "rethinkdb-orm"
require "time"

require "../engine-models"

module Engine::Model
  class Trigger < ModelBase
    include RethinkORM::Timestamps
    table :trigger

    attribute name : String, es_type: "keyword"
    attribute description : String

    # Full path allows resolution in macros
    attribute actions : Engine::Model::Trigger::Actions = ->{ Actions.new }, es_type: "object"
    attribute conditions : Engine::Model::Trigger::Conditions = ->{ Conditions.new }, es_type: "object"

    # In seconds
    attribute debounce_period : Int32 = 0
    attribute important : Bool = false

    has_many TriggerInstance, dependent: :destroy, collection_name: :trigger_instances

    # Allows filtering in cases of a Trigger belonging to a single ControlSystem
    belongs_to ControlSystem

    # FIXME: Is this offloaded to core?
    #  Old engine: reloads the trigger instance to the module manager.
    #  New engine: hits the trigger service to re-enable the trigger
    # after_save :reload_all
    # protected def reload_all
    #   trigger_instances.each do |trig|
    #     trig.reload
    #   end
    # end

    # ---------------------------
    # VALIDATIONS
    # ---------------------------

    validates :name, presence: true

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

    # Conditions
    ###########################################################################

    class Conditions < SubModel
      attribute dependents : Array(Dependent) = ->{ [] of Dependent }
      attribute comparisons : Array(Comparison) = ->{ [] of Comparison }

      validate ->(this : Conditions) {
        if (dependents = this.dependents)
          this.collect_errors(:dependent, dependents)
        end
        if (comparisons = this.comparisons)
          this.collect_errors(:comparison, comparisons)
        end
      }

      class Dependent < SubModel
        attribute type : String, presence: true

        attribute value : String
        attribute time : Time, converter: Time::EpochConverter

        TRIGGER_TYPES = {"at", "webhook", "cron"}
        validates :type, inclusion: {in: TRIGGER_TYPES}
      end

      class Comparison < SubModel
        attribute left : Value
        attribute operator : String
        attribute right : Value

        alias Value = StatusVariable | Constant

        # Constant value
        alias Constant = Int32 | Float32 | String | Bool

        # Status of a Module
        alias StatusVariable = NamedTuple(
          # Module that defines the status variable
          mod: String,
          # Unparsed hash of a status variable
          status: String,
          # Keys to look up in the module
          keys: Array(String),
        )

        OPERATORS = {
          "equal", "not_equal", "greater_than", "greater_than_or_equal",
          "less_than", "less_than_or_equal", "and", "or", "exclusive_or",
        }

        validates :operator, inclusion: {in: OPERATORS}, presence: true
      end
    end

    # Actions
    ###########################################################################

    class Actions < SubModel
      attribute functions : Array(Function) = ->{ [] of Function }
      attribute mailers : Array(Email) = ->{ [] of Email }

      validate ->(this : Actions) {
        if (mailers = this.mailers)
          this.collect_errors(:mailers, mailers)
        end
        if (functions = this.functions)
          this.collect_errors(:functions, functions)
        end
      }

      class Email < SubModel
        attribute emails : Array(String)
        attribute content : String = ->{ "" }

        validates :emails, presence: true
      end

      class Function < SubModel
        attribute mod : String
        attribute method : String
        attribute args : Array(String) = ->{ [] of String }

        validates :mod, presence: true
        validates :method, presence: true
      end
    end
  end
end
