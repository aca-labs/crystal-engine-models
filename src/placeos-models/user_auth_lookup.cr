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

    # Association
    ###############################################################################################

    belongs_to User
    belongs_to Authority

    # Callbacks
    ###############################################################################################

    before_create :generate_id

    protected def generate_id
      self._new_flag = true
      self.id = "auth-#{self.authority_id}-#{self.provider}-#{self.uid}"
    end
  end
end
