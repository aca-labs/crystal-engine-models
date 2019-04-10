require "../engine-models"

module Engine::Model
  # Class that pins engine's drivers to a specifc repository state
  # Allows external driver management from a VCS
  class DriverRepo < ModelBase
    # Repo metadata
    attribute name : String
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

    # has_many Dependency
  end
end