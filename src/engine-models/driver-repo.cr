require "../engine-models"

module Engine::Model
  # Class that pins engine's drivers to a specifc repository state
  # Allows external driver management from a VCS
  class DriverRepo < ModelBase
    table :repo

    # Repository metadata
    attribute name : String, es_type: "keyword"
    attribute description : String
    attribute uri : String
    attribute commit_hash : String
    attribute branch : String

    # Validations
    validates :name, presence: true
    validates :uri, presence: true
    validates :commit_hash, presence: true
    validates :branch, presence: true

    # Authentication
    attribute username : String
    attribute password : String
    attribute key : String

    has_many Driver, collection_name: "drivers"
  end
end
