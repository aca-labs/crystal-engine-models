require "rethinkdb-orm"
require "time"

require "./base/model"
require "./control_system"
require "./zone"

module PlaceOS::Model
  class Metadata < ModelBase
    include RethinkORM::Timestamps

    table :metadata

    attribute name : String, es_type: "keyword"
    attribute description : String
    attribute details : JSON::Any

    attribute parent_id : String, es_keyword: "keyword"

    secondary_index :parent_id

    belongs_to Zone, foreign_key: "parent_id", association_name: "zone"
    belongs_to ControlSystem, foreign_key: "parent_id", association_name: "control_system"

    validates :name, presence: true
    validates :parent_id, presence: true

    ensure_unique :name, scope: [:parent_id, :name] do |parent_id, name|
      {parent_id, name.strip.downcase}
    end

    record Response, name : String, description : String?, details : JSON::Any?, parent_id : String

    def self.build_metadata(parent, name : String? = nil) : Hash(String, Response)
      for(parent, name).each_with_object({} of String => Response) do |data, results|
        unless (data_name = data.name).nil? || (parent_id = data.parent_id).nil?
          results[data_name] = Response.new(
            name: data_name,
            description: data.description,
            details: data.details,
            zone_id: parent_id,
          )
        end
      end
    end

    def self.for(parent : String | Zone | ControlSystem, name : String? = nil)
      parent_id = case parent
                  in String
                    parent
                  in Zone, ControlSystem
                    parent.id.as(String)
                  end

      Metadata.table_query do |q|
        query = q.get_all(parent_id, index: :parent_id)
        if name && !name.empty?
          query.filter({name: name})
        else
          query
        end
      end
    end
  end
end
