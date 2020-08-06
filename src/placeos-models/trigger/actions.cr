require "../base/model"

class PlaceOS::Model::Trigger < PlaceOS::Model::ModelBase; end

module PlaceOS::Model
  class Trigger::Actions < SubModel
    class Email < SubModel
      attribute emails : Array(String) = [] of String
      attribute content : String = ""

      validates :emails, presence: true
    end

    class Function < SubModel
      attribute mod : String
      attribute method : String
      attribute args : Hash(String, JSON::Any) = ->{ {} of String => JSON::Any }

      validates :mod, presence: true
      validates :method, presence: true
    end

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
  end
end
