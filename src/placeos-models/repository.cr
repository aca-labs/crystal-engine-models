require "rethinkdb"
require "rethinkdb-orm"
require "time"

require "./base/model"

module PlaceOS::Model
  # Class that pins engine's drivers to a specific repository state
  # Allows external driver management from a VCS
  class Repository < ModelBase
    include RethinkORM::Timestamps
    table :repo

    enum Type
      Driver
      Interface

      def to_reql
        JSON::Any.new(to_s)
      end
    end

    # Repository metadata
    attribute name : String, es_subfield: "keyword"
    attribute description : String = ""

    # folder_name may only contain valid path characters
    attribute folder_name : String

    attribute uri : String
    attribute commit_hash : String = "HEAD"
    attribute branch : String = "master"

    enum_attribute repo_type : Type = Type::Driver, column_type: String, es_type: "text"

    # Validations
    validates :name, presence: true
    validates :folder_name, presence: true, format: {with: /^[a-zA-Z0-9_+\-\(\)\.]*$/}
    validates :repo_type, presence: true
    validates :uri, presence: true
    validates :commit_hash, presence: true

    ensure_unique :folder_name, scope: [:repo_type, :folder_name] do |repo_type, folder_name|
      {repo_type, folder_name.strip.downcase}
    end

    # Authentication
    attribute username : String?
    attribute password : String?
    attribute key : String?

    has_many(
      child_class: Driver,
      collection_name: "drivers",
      foreign_key: "repository_id",
      dependent: :destroy
    )

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
