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

      validate ->(this : TimeDependent) do
        this.validation_error(:time_dependent, "must specify `time` or `cron`") if {this.time, this.cron}.none?
      end
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

      # Validation
      #############################################################################################

      OPERATORS = %w(and equal exclusive_or greater_than greater_than_or_equal less_than less_than_or_equal not_equal or)

      validates :operator, inclusion: {in: OPERATORS}
    end

    attribute comparisons : Array(Comparison) = ->{ [] of Comparison }
    attribute time_dependents : Array(TimeDependent) = ->{ [] of TimeDependent }

    # Validation
    ###############################################################################################

    validate ->(this : Conditions) {
      this.collect_errors(:time_dependents, this.time_dependents)
      this.collect_errors(:comparisons, this.comparisons)
    }
  end
end
