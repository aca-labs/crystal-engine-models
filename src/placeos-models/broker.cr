require "rethinkdb-orm"
require "openssl"
require "random"

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

    enum_attribute auth_type : AuthType = AuthType::UserPassword

    attribute name : String
    attribute description : String = ""

    attribute host : String
    attribute port : Int32 = 1883 # Default MQTT port for non-tls connections
    attribute tls : Bool = false

    attribute username : String?
    attribute password : String?
    attribute certificate : String?
    attribute secret : String = ->{ Random::Secure.hex(64) }

    # Regex filters for sensitive data.
    # Matches will be replaced with a hmac_256(secret, match).
    attribute filters : Array(String) = ->{ [] of String }

    validates :name, presence: true
    validates :host, presence: true
    validates :secret, presence: true

    validate ->(this : Broker) {
      return unless (filters = this.filters)
      # Render regex errors
      error_string = filters.compact_map { |filter|
        error = Regex.error?(filter)
        "'#{filter}' errored with '#{error}'" if error
      }.join(" and")

      this.validation_error(:filters, error_string) unless error_string.empty?
    }

    def sanitize(payload : String)
      filters = self.filters
      return payload if filters.nil? || filters.empty?

      # TODO: Cache and reuse unless filters_changed?
      regex = Regex.union(filters)

      payload.gsub(regex) do |match_string, _|
        hmac_sha256(match_string)
      end
    rescue e : ArgumentError
      raise MalformedFilter.new(self.filters)
    end

    protected def hmac_sha256(data : String)
      OpenSSL::HMAC.hexdigest(OpenSSL::Algorithm::SHA256, self.secret.as(String), data)
    end
  end
end
