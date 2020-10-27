require "rethinkdb-orm"
require "time"
require "json"

require "./utilities/json_string_converter"

require "./base/model"
require "./control_system"
require "./zone"

module PlaceOS::Model
  class Metadata < ModelBase
    include RethinkORM::Timestamps

    table :metadata

    attribute name : String, es_subfield: "keyword"
    attribute description : String = ""
    attribute details : JSON::Any, converter: JSON::Any::StringConverter
    attribute editors : Set(String) = ->{ Set(String).new }

    attribute parent_id : String, es_keyword: "keyword"

    secondary_index :parent_id

    belongs_to Zone, foreign_key: "parent_id", association_name: "zone"
    belongs_to ControlSystem, foreign_key: "parent_id", association_name: "control_system"
    belongs_to User, foreign_key: "parent_id", association_name: "user"

    validates :details, presence: true
    validates :name, presence: true
    validates :parent_id, presence: true

    ensure_unique :name, scope: [:parent_id, :name] do |parent_id, name|
      {parent_id, name.strip.downcase}
    end

    record Interface, name : String, description : String, details : JSON::Any, parent_id : String? {
      include JSON::Serializable
    }

    def self.interface(model : Metadata)
      Interface.new(
        name: model.name,
        description: model.description,
        details: model.details,
        parent_id: model.parent_id,
      )
    end

    def self.build_metadata(parent, name : String? = nil) : Hash(String, Interface)
      for(parent, name).each_with_object({} of String => Interface) do |data, results|
        results[data.name] = self.interface(data)
      end
    end

    def self.for(parent : String | Zone | ControlSystem | User, name : String? = nil)
      parent_id = case parent
                  in String
                    parent
                  in Zone, ControlSystem, User
                    parent.id.as(String)
                  end

      Metadata.raw_query do |q|
        query = q.table(Model::Metadata.table_name).get_all(parent_id, index: :parent_id)
        if name && !name.empty?
          query.filter({name: name})
        else
          query
        end
      end
    end
  end
end
