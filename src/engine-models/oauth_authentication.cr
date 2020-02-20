require "uri"
require "json"
require "./base/model"

module ACAEngine::Model
  # See: https://github.com/omniauth/omniauth-oauth2
  # https://github.com/oauth-xx/oauth2
  class OAuthAuthentication < ModelBase
    include RethinkORM::Timestamps

    table :oauth_strat

    attribute name : String, es_type: "keyword"
    belongs_to Authority, foreign_key: "authority_id"

    # The client ID and secret configured for this application
    attribute client_id : String
    attribute client_secret : String

    # Maps an expected key to a provided key i.e. {used_in_engine => used_by_remote}
    attribute info_mappings : Hash(String, String) = {} of String => String

    # The HTTP URL of the SSO provider
    attribute site : String

    # The SSO providers URL for authorization, defaults to: `oauth/authorize`
    # Google is `/o/oauth2/auth`
    attribute authorize_url : String

    # If not set it defaults to "post"
    attribute token_method : String

    # If not set it defaults to "request_body", others include "basic_auth"
    attribute auth_scheme : String

    # defaults to: `oauth/token` however google is: `/o/oauth2/token`
    attribute token_url : String

    # Space seperated scope strings
    # i.e. `https://www.googleapis.com/auth/devstorage.readonly https://www.googleapis.com/auth/prediction`
    attribute scope : String

    # URL to call with a valid token to obtain the users profile data (name, email etc)
    attribute raw_info_url : String

    validates :name, presence: true
    validates :authority_id, presence: true

    def type
      "oauths"
    end

    def type=(auth_type)
      raise "bad authentication type #{auth_type}" unless auth_type.to_s == "oauths"
    end
  end
end
