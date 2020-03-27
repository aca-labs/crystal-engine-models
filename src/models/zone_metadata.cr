require "rethinkdb-orm"
require "time"

require "./base/model"
require "./zone"

module PlaceOS::Model
  class Zone::Metadata < ModelBase
    include RethinkORM::Timestamps

    table :metadata

    attribute name : String, es_type: "keyword"
    attribute description : String
    attribute details : JSON::Any

    belongs_to Zone, foreign_key: "zone_id", association_name: "zone"

    validates :zone, presence: true
    validates :name, presence: true

    ensure_unique :name, scope: [:zone_id, :name] do |zone_id, name|
      {zone_id, name.strip.downcase}
    end
  end
end
