require "json"
require "time"

require "../engine-models"

module Engine::Model
  class Trigger < ModelBase
    table :trigger

    attribute name : String
    attribute description : String
    attribute created_at : Time = ->{ Time.utc_now }, converter: Time::EpochConverter

    # FIXME: dummy
    # attribute conditions : Array(String)
    attribute actions : Array(String)

    attribute conditions : Array(Condition)
    # attribute actions : Array(Action) = ->{ [] of Action }

    # in seconds
    attribute debounce_period : Int32 = 0
    attribute important : Bool = false

    has_many TriggerInstance, dependent: :destroy, collection_name: :trigger_instances

    after_save :reload_all

    protected def reload_all
      trigger_instances.each do |trig|
        trig.reload
      end
    end

    # ---------------------------
    # VALIDATIONS (and mutation)
    # ---------------------------

    validates :name, presence: true

    # No point fleshing out Conditions/Actions until the new API is solidified.

    # Conditions
    ###########################################################################

    alias Condition = DependentCondition | ComparisonCondition

    class DependentCondition < Engine::Model::SubModel
      attribute trigger_type : String, presence: true
      attribute value : String
      attribute time : Time

      TRIGGER_TYPES = {"at", "webhook", "cron"}
      # validates :trigger_type, inclusion: {in: TRIGGER_TYPES}
    end

    class ComparisonCondition < Engine::Model::SubModel
      attribute left : StatusVariable
      attribute operator : String
      attribute right : StatusVariable

      OPERATORS = {
        "equal", "not_equal", "greater_than", "greater_than_or_equal",
        "less_than", "less_than_or_equal", "and", "or", "exclusive_or",
      }
      # validates :operator, inclusion: {in: OPERATORS}
    end

    alias StatusValue = ConstantValue | StatusVariable
    alias ConstantValue = NamedTuple(const: Int32 | Float32 | String | Bool)
    alias StatusVariable = NamedTuple(
      mod: String,
      index: Int32,
      # Unparsed hash of a status variable
      status: String,
      keys: Array(String),
    )

    # Check conditions validity
    validate ->(this : Trigger) {
      conditions = this.conditions
      return unless conditions
      unless conditions.empty?
        valid = conditions.all?(&.valid?)
        this.validation_error(:conditions, "are not all valid") unless valid
      end
    }

    # Actions
    ###########################################################################

    # # If we go with a sub model approach
    # # Better to go with the serializable class

    # alias Action = EmailAction | FunctionAction
    # class EmailAction < SubModel
    #   attribute emails : Array(String)
    #   attribute content : String

    #   # Transform the emails on parse
    #   def from_json(input)
    #     super(input)
    #     @emails.map(&.strip)
    #   end
    # end

    # class FunctionAction < SubModel
    #   attribute mod : String
    #   attribute index : Int32
    #   attribute func : String
    #   attribute args : Array(String) = ->{ [] of String }
    # end

    # validate ->(this : Trigger) {
    #   unless this.actions.empty?
    #     valid = self.actions.all? do |action|
    #       check_action(action)
    #     end
    #     validation_error(:actions, "are not all valid") unless valid
    #   end
    # }

    # def check_action(action : Action)
    #   return false unless action.valid?
    #   case action
    #   when FunctionAction
    #     valid = !(action.index.nil? || action.mod.nil? || action.func.nil?)

    #     action, valid
    #   when :email
    #     action.emails = parse_emails(action.emails) unless action.emails.nil?
    #     valid = action.emails && !action.emails.empty?

    #     action, valid
    #   else
    #     nil, false
    #   end
    # end
  end
end
