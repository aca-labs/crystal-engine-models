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

    enum_attribute auth_type : AuthType = ->{ AuthType::UserPassword }

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

    validate ->(this : Broker) {
      return unless (filters = this.filters)
      # Render regex errors
      error_string = filters.each_with_object({} of String => String?) { |filter, e|
        e[filter] = Regex.error?(filter)
      }.compact.map { |f, e| "#{f} with '#{e}'" }.join(" and")

      this.validation_error(:filters, error_string) unless error_string.empty?
    }

    def sanitize(scope : String, payload : String)
      filters = self.filters
      return payload if filters.nil? || filters.empty?

      # TODO: Cache and reuse unless filters_changed?
      regex = Regex.union(filters)

      payload.gsub(regex) do |match, _|
        sha256("#{scope}-#{match}")
      end
    rescue e : ArgumentError
      raise MalformedFilter.new(self.filters)
    end

    protected def sha256(data : String)
      hash = OpenSSL::Digest.new("SHA256")
      hash.update(data)
      hash.hexdigest
    end
  end
end
