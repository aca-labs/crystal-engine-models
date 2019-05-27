require "uri"

require "../engine-models"

module Engine::Model
  class Authority < ModelBase
    table :authority

    attribute name : String

    attribute domain : String
    ensure_unique :domain, create_index: true

    attribute description : String
    attribute login_url : String = "/login?continue={{url}}"
    attribute logout_url : String = "/auth/logout"

    attribute internals : String
    attribute config : String

    validates :name, presence: true

    # Ensure we are only saving the host
    #
    def domain=(dom)
      parsed = URI.parse(dom)
      previous_def(parsed.host.try &.downcase)
    end

    # Locates an Authority by its unique domain name
    #
    def self.find_by_domain(name)
      Authority.find_all([name], index: :name).first?
    end
  end
end
