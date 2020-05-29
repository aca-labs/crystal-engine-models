require "rethinkdb-orm"
require "./base/model"
require "./authority"
require "./user"

module PlaceOS::Model
  class UserAuthLookup < ModelBase
    include RethinkORM::Timestamps
    table :authentication

    attribute uid : String
    attribute provider : String
    belongs_to User
    belongs_to Authority

    before_create :generate_id

    def generate_id
      self.id = "auth-#{self.authority_id}-#{self.provider}-#{self.uid}"
    end
  end
end
