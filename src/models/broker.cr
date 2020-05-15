require "rethinkdb-orm"

require "./base/model"

module PlaceOS::Model
  class Broker < ModelBase
    include RethinkORM::Timestamps
    table :broker

    enum AuthType
      Certificate
      NoAuth
      UserPassword
    end

    enum_attribute auth_type : AuthType = -> { AuthType::UserPassword }

    attribute name : String
    attribute description : String

    attribute ip : String
    attribute port : Int32
    attribute tls : Bool = false

    attribute username : String
    attribute password : String

    attribute certificate : String

    # Regex filters for sensitive data.
    # Matches will be replaced with a SHA256(match + organisation_id).
    attribute filters : Array(String) = ->{ [] of String }
  end
end
