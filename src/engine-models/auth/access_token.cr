require "../../engine-models"

module Engine::Model
  class AccessToken < ModelBase
    table :doorkeeper_access_tokens
  end
end
