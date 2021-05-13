require "../base/model"
require "json"

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

      enum Operator
        And
        Equal
        ExclusiveOr
        GreaterThan
        GreaterThanOrEqual
        LessThan
        LessThanOrEqual
        NotEqual
        Or

        # ameba:disable Metrics/CyclomaticComplexity
        def compare(left : JSON::Any::Type, right : JSON::Any::Type) : Bool
          case self
          in And
            left != false && right != false && !left.nil? && !right.nil?
          in Or
            (left != false && !left.nil?) || (right != false && !right.nil?)
          in Equal
            left == right
          in NotEqual
            left != right
          in ExclusiveOr
            if left != false && right != false && !left.nil? && !right.nil?
              false
            else
              (left != false && !left.nil?) || (right != false && !right.nil?)
            end
          in GreaterThan
            left.as(Float64 | Int64) > right.as(Float64 | Int64)
          in GreaterThanOrEqual
            left.as(Float64 | Int64) >= right.as(Float64 | Int64)
          in LessThan
            left.as(Float64 | Int64) < right.as(Float64 | Int64)
          in LessThanOrEqual
            left.as(Float64 | Int64) <= right.as(Float64 | Int64)
          end
        end
      end

      attribute left : Value
      attribute operator : Operator
      attribute right : Value
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
