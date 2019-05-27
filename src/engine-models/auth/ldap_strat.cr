require "rethinkdb-orm"

require "../../engine-models"

module Engine::Model
  class LdapStrat < ModelBase
    include RethinkORM::Timestamps
    table :ldap_strat

    belongs_to Authority

    attribute name : String

    attribute port : Int32 = 636, numericality: {greater_than: 0, less_than_or_equal_to: 65_535}
    attribute auth_method : String = "ssl"
    attribute uid : String = ->{ "sAMAccountName" }
    attribute host : String
    attribute base : String
    attribute bind_dn : String
    attribute password : String # This should not be plain text

    attribute filter : String

    validates :authority_id, presence: true
    validates :name, presence: true
    validates :host, presence: true
    validates :port, presence: true
    validates :base, presence: true
  end
end
