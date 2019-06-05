require "uri"
require "rethinkdb-orm"

require "../../engine-models"

module Engine::Model
  class OauthStrat < ModelBase
    include RethinkORM::Timestamps

    table :oauth_strat
    belongs_to Authority

    attribute name : String, es_type: "keyword"
    attribute client_id : String
    attribute client_secret : String

    attribute info_mappings : Hash(String, String)

    attribute site : String
    attribute authorize_url : String
    attribute token_method : String
    attribute auth_scheme : String
    attribute token_url : String
    attribute scope : String
    attribute raw_info_url : String

    validates :authority_id, presence: true
    validates :name, presence: true
  end
end
