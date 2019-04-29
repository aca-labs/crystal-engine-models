require "json"
require "time"

require "../engine-models"

module Engine::Model
  class Trigger < ModelBase
    table :trigger

    attribute name : String
    attribute description : String
    attribute created_at : Time = ->{ Time.utc_now }, converter: Time::EpochConverter

    # Full path allows resolution in macros
    attribute actions : Engine::Model::Trigger::Actions = ->{ Actions.new }, es_type: "object"
    attribute conditions : Engine::Model::Trigger::Conditions = ->{ Conditions.new }, es_type: "object"

    # In seconds
    attribute debounce_period : Int32 = 0
    attribute important : Bool = false

    has_many TriggerInstance, dependent: :destroy, collection_name: :trigger_instances

    # Allows filtering in cases of a Trigger belonging to a single ControlSystem
    belongs_to ControlSystem

    # TODO: before_destroy call to remove Trigger if it belongs to a ControlSystem

    after_save :reload_all

    protected def reload_all
      trigger_instances.each do |trig|
        trig.reload
      end
    end

    # ---------------------------
    # VALIDATIONS
    # ---------------------------

    validates :name, presence: true

    validate ->(this : Trigger) {
      actions = this.actions
      if actions && !actions.valid?
        actions.errors.each do |e|
          this.validation_error(:action, e.message)
        end
      end

      conditions = this.conditions
      if conditions && !conditions.valid?
        conditions.errors.each do |e|
          this.validation_error(:condition, e.message)
        end
      end
    }

    # Conditions
    ###########################################################################

    class Conditions < SubModel
      attribute dependent_conditions : Array(DependentCondition) = ->{ [] of DependentCondition }
      attribute comparison_conditions : Array(ComparisonCondition) = ->{ [] of ComparisonCondition }

      validate ->(this : Conditions) {
        dependent_conditions = this.dependent_conditions
        this.collect_errors(:dependent_conditions, dependent_conditions) if dependent_conditions

        comparison_conditions = this.comparison_conditions
        this.collect_errors(:comparison_conditions, comparison_conditions) if comparison_conditions
      }

      class DependentCondition < SubModel
        attribute trigger_type : String, presence: true

        attribute value : String
        attribute time : Time, converter: Time::EpochConverter

        TRIGGER_TYPES = {"at", "webhook", "cron"}
        validates :trigger_type, inclusion: {in: TRIGGER_TYPES}
      end

      class ComparisonCondition < SubModel
        attribute left : StatusVariable
        attribute operator : String
        attribute right : StatusVariable

        alias StatusValue = ConstantValue | StatusVariable

        alias ConstantValue = NamedTuple(const: Int32 | Float32 | String | Bool)

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
        validates :operator, inclusion: {in: OPERATORS}
      end
    end

    # Actions
    ###########################################################################

    class Actions < SubModel
      attribute function_actions : Array(FunctionAction) = ->{ [] of FunctionAction }
      attribute email_actions : Array(EmailAction) = ->{ [] of EmailAction }

      validate ->(this : Actions) {
        function_actions = this.function_actions
        this.collect_errors(:function_actions, function_actions) if function_actions

        email_actions = this.email_actions
        this.collect_errors(:email_actions, email_actions) if email_actions
      }

      class EmailAction < SubModel
        # Attributes that define an EmailAction
        attribute emails : Array(String), presence: true
        attribute content : String = ->{ "" }
      end

      class FunctionAction < SubModel
        attribute mod : String, presence: true
        attribute func : String, presence: true
        attribute args : Array(String) = ->{ [] of String }
      end
    end
  end
end
