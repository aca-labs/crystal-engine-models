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

    # Ensure we are only saving the host
    #
    def domain=(dom)
      parsed = URI.parse(dom)
      previous_def(parsed.host.try &.downcase)
    end

    # locates an authority by its unique domain name
    #
    def self.find_by_domain(domain : String) : Authority?
      Authority.find_all([domain], index: :domain).first?
    end
  end
end
