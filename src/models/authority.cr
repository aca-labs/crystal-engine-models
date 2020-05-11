require "uri"
require "json"
require "./base/model"

module PlaceOS::Model
  class Authority < ModelBase
    include RethinkORM::Timestamps

    table :authority

    attribute name : String, es_type: "keyword"
    attribute description : String
    attribute domain : String
    ensure_unique :domain, create_index: true

    # TODO: feature request: autogenerate login url
    attribute login_url : String = "/auth/login?continue={{url}}"
    attribute logout_url : String = "/auth/logout"

    attribute internals : Hash(String, JSON::Any) = {} of String => JSON::Any
    attribute config : Hash(String, JSON::Any) = {} of String => JSON::Any

    validates :name, presence: true

    macro finished
      # Ensure we are only saving the host
      #
      def domain=(value : String | Nil)
        host = value.try do |domain|
          URI.parse(domain).host.try &.downcase
        end
        previous_def(host)
      end
    end

    # locates an authority by its unique domain name
    #
    def self.find_by_domain(domain : String) : Authority?
      host = URI.parse(domain).host || ""
      Authority.find_all([host], index: :domain).first?
    end
  end
end
