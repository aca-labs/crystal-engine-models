require "uri"
require "json"
require "./base/model"

module PlaceOS::Model
  # see: https://github.com/omniauth/omniauth-ldap
  class LdapAuthentication < ModelBase
    include RethinkORM::Timestamps

    table :ldap_strat

    attribute name : String, es_subfield: "keyword"
    belongs_to Authority, foreign_key: "authority_id", presence: true

    attribute port : Int32 = 636

    # Options are: plain, ssl, tls
    attribute auth_method : String = "ssl"
    attribute uid : String = "sAMAccountName"
    attribute host : String

    # BaseDN such as dc=intridea, dc=com
    attribute base : String

    # :bind_dn and :password is the default credentials to perform user lookup
    attribute bind_dn : String?
    attribute password : String?

    # LDAP filter like: (&(uid=%{username})(memberOf=cn=myapp-users,ou=groups,dc=example,dc=com))
    # Can be used instead of UID
    attribute filter : String?

    validates :name, presence: true
    validates :host, presence: true
    validates :base, presence: true

    def type
      "ldaps"
    end

    def type=(auth_type)
      raise "bad authentication type #{auth_type}" unless auth_type.to_s == "ldaps"
    end
  end
end
