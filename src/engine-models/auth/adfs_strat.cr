require "rethinkdb-orm"

require "../../engine-models"

module Engine::Model
  class AdfsStrat < ModelBase
    include RethinkORM::Timestamps

    table :adfs_strat

    attribute name : String
    belongs_to Authority

    attribute issuer : String = "aca"
    attribute idp_sso_target_url_runtime_params : Hash(String, String)
    attribute name_identifier_format : String = ->{ "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified" }
    attribute uid_attribute : String

    attribute assertion_consumer_service_url : String
    attribute idp_sso_target_url : String

    attribute idp_cert : String
    attribute idp_cert_fingerprint : String

    attribute attribute_service_name : String
    attribute attribute_statements : Hash(String, Array(String)) = ->{
      {
        "name"       => ["name"],
        "email":        ["email", "mail"],
        "first_name" => ["first_name", "firstname", "firstName", "givenname"],
        "last_name"  => ["last_name", "lastname", "lastName", "surname"],
      }
    }

    attribute request_attributes : Array(NamedTuple(name: String, name_format: String, friendly_name: String)) = ->{
      [
        {name: "ImmutableID", name_format: "urn:oasis:names:tc:SAML:2.0:attrname-format:basic", friendly_name: "Login Name"},
        {name: "email", name_format: "urn:oasis:names:tc:SAML:2.0:attrname-format:basic", friendly_name: "Email address"},
        {name: "name", name_format: "urn:oasis:names:tc:SAML:2.0:attrname-format:basic", friendly_name: "Full name"},
        {name: "first_name", name_format: "urn:oasis:names:tc:SAML:2.0:attrname-format:basic", friendly_name: "Given name"},
        {name: "last_name", name_format: "urn:oasis:names:tc:SAML:2.0:attrname-format:basic", friendly_name: "Family name"},
      ]
    }

    attribute idp_slo_target_url : String
    attribute slo_default_relay_state : String

    validates :authority_id, presence: true
    validates :name, presence: true

    validates :issuer, presence: true
    validates :idp_sso_target_url, presence: true
    validates :name_identifier_format, presence: true
    validates :assertion_consumer_service_url, presence: true
    validates :request_attributes, presence: true
  end
end
