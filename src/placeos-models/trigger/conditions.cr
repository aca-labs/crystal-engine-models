require "../base/model"

class PlaceOS::Model::Trigger < PlaceOS::Model::ModelBase; end

module PlaceOS::Model
  class Trigger::Conditions < SubModel
    class TimeDependent < SubModel
      enum Type
        At
        Cron
      end

      attribute type : Type

      attribute time : Time?, converter: Time::EpochConverter
      attribute cron : String?

      validates :type, presence: true
    end

    class Comparison < SubModel
      attribute left : Value
      attribute operator : String
      attribute right : Value

      alias Value = StatusVariable | Constant

      # Constant value
      alias Constant = Int64 | Float64 | String | Bool

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

    attribute comparisons : Array(Comparison) = ->{ [] of Comparison }
    attribute time_dependents : Array(TimeDependent) = ->{ [] of TimeDependent }

    validate ->(this : Conditions) {
      if (time_dependents = this.time_dependents)
        this.collect_errors(:time_dependents, time_dependents)
      end

      if (comparisons = this.comparisons)
        this.collect_errors(:comparisons, comparisons)
      end
    }
  end
end
