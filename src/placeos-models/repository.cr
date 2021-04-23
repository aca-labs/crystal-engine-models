require "rethinkdb"
require "rethinkdb-orm"
require "time"

require "./base/model"

module PlaceOS::Model
  # Pins engine's driver sources to a specific repository state.
  # Enables external driver management from a VCS.
  class Repository < ModelBase
    include RethinkORM::Timestamps

    table :repo

    attribute name : String, es_subfield: "keyword"
    attribute description : String = ""

    # `folder_name` may only contain valid path characters
    attribute folder_name : String

    attribute uri : String
    attribute commit_hash : String = "HEAD"
    attribute branch : String = "master"

    # Authentication

    attribute username : String?
    attribute password : String?
    attribute key : String?

    enum Type
      Driver
      Interface

      def to_reql
        JSON::Any.new(to_s.downcase)
      end
    end

    attribute repo_type : Type = Type::Driver, es_type: "text"

    # Association
    ###############################################################################################

    has_many(
      child_class: Driver,
      collection_name: "drivers",
      foreign_key: "repository_id",
      dependent: :destroy
    )

    # Validation
    ###############################################################################################

    validates :name, presence: true
    validates :folder_name, presence: true, format: {with: /^[a-zA-Z0-9_+\-\(\)\.]*$/}
    validates :repo_type, presence: true
    validates :uri, presence: true
    validates :commit_hash, presence: true

    validate ->(this : Model::Repository) {
      this.validation_error(:uri, "is an invalid URI") unless Validation.valid_uri?(this.uri)
    }

    ensure_unique :folder_name, scope: [:repo_type, :folder_name] do |repo_type, folder_name|
      {repo_type, folder_name.strip.downcase}
    end

    # Cloning Management
    ###############################################################################################

    def pull!
      commit_hash_will_change!
      self.commit_hash = self.class.pull_commit(self)
      save!
    end

    def should_pull?
      self.commit_hash == self.class.pull_commit(self)
    end

    def self.pull_commit(repo : Repository)
      repo.repo_type.driver? ? "HEAD" : "PULL"
    end
  end
end
