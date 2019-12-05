require "rethinkdb-orm"
require "time"

require "./base/model"
require "./error"
require "./utilities/encryption"

module ACAEngine::Model
  # TODO: Statically ensure a single parent id exists on the table
  class Settings < ModelBase
    include RethinkORM::Timestamps

    table :sets

    attribute parent_id : String, es_keyword: "keyword"
    secondary_index :parent_id

    enum_attribute encryption_level : Encryption::Level
    attribute settings_string : String = "{}"
    attribute keys : Array(String) = [] of String, es_keyword: "text"

    attribute settings_id : String = nil
    secondary_index :settings_id

    # Settings self-referential entity relationship acts as a 2-level tree
    has_many(
      child_class: Settings,
      collection_name: "settings",
      foreign_key: "settings_id",
      dependent: :destroy
    )

    belongs_to ControlSystem, foreign_key: "parent_id"
    belongs_to Driver, foreign_key: "parent_id"
    belongs_to Module, foreign_key: "parent_id", association_name: "mod"
    belongs_to Zone, foreign_key: "parent_id"

    validates :encryption_level, prescence: true
    validates :parent_id, prescence: true

    # Callbacks
    ###########################################################################

    before_save :build_keys
    before_save :encrypt_settings
    before_update :create_version

    # Generate a version upon save of a master Settings
    #
    def create_version
      raise "Cannot update a Settings version" if is_version?
      old_settings = encrypt(settings_string_was || settings_string.as(String))
      attrs = attributes_tuple.merge({id: nil, created_at: nil, updated_at: nil, settings_string: old_settings})
      version = Settings.new(**attrs)
      version.settings_id = self.id
      version.save!
    end

    # Generate keys for settings object
    #
    def build_keys : Array(String)
      settings_string = @settings_string.as(String)
      unencrypted = Encryption.is_encrypted?(settings_string) ? decrypt : settings_string
      self.keys = YAML.parse(unencrypted).as_h.keys.map(&.to_s)
    end

    # Queries
    ###########################################################################

    # Get version history
    #
    # TODO: support ranges
    def history
      Settings.get_all([id], index: :settings_id).to_a.sort_by!(&.created_at.as(Time))
    end

    # Get settings for a given parent id
    #
    def self.for_parent(parent_id : String) : Array(Settings)
      for_parent([parent_id])
    end

    # Get settings for given parent ids
    #
    def self.for_parent(parent_ids : Array(String)) : Array(Settings)
      Settings.raw_query do |q|
        q.table(Settings.table_name).get_all(parent_ids, index: :parent_id).filter { |r|
          # Get documents where the settings_id does not exist, i.e. the masters
          r.has_fields(:settings_id).not
        }
      end.to_a
    end

    # Query on master settings associated with parent_id
    #
    def self.master_settings_query(parent_id : String)
      Settings.raw_query do |q|
        yield q.table(Settings.table_name).filter({parent_id: parent_id}).filter { |r|
          # Get documents where the settings_id does not exist, i.e. is the master
          r.has_fields(:settings_id).not
        }
      end.to_a
    end

    # Encryption methods
    ###########################################################################

    protected def encrypt(string : String)
      raise NoParentError.new unless (encryption_id = @parent_id)

      encryption = @encryption_level.as(Encryption::Level)
      Encryption.encrypt(string, level: encryption, id: encryption_id)
    end

    # Encrypts all settings.
    #
    def encrypt_settings
      settings_string = @settings_string.as(String)
      self.settings_string = encrypt(settings_string)
    end

    # Encrypt in place
    #
    def encrypt!
      encrypt_settings
      self
    end

    # Decrypts the model's setting string
    #
    def decrypt
      raise NoParentError.new unless (encryption_id = @parent_id)
      settings_string = @settings_string.as(String)
      level = @encryption_level.as(Encryption::Level)

      Encryption.decrypt(string: settings_string, level: level, id: encryption_id)
    end

    # Decrypts the model's settings string dependent on user privileges
    #
    def decrypt_for!(user)
      self.settings_string = decrypt_for(user)
      self
    end

    # Decrypts (if user has correct privilege) and returns the settings string
    #
    def decrypt_for(user) : String
      if encryption_level == Encryption::Level::Support && (user.is_support? || user.is_admin?)
        decrypt
      elsif encryption_level == Encryption::Level::Admin && user.is_admin?
        decrypt
      else
        settings_string.as(String)
      end
    end

    # Retrieve the parent relation
    #
    def parent
      [
        self.control_system,
        self.driver,
        self.mod,
        self.zone,
      ].compact.first?
    end

    def parent=(parent : Union(Zone, ControlSystem, Driver, Module))
      case parent
      when ControlSystem then self.control_system = parent
      when Driver        then self.driver = parent
      when Module        then self.mod = parent
      when Zone          then self.zone = parent
      end
    end

    # Helpers
    ###########################################################################

    def self.has_privilege?(user, encryption_level)
      case encryption_level
      when Encryption::Level::None    then true
      when Encryption::Level::Support then user.is_admin?
      when Encryption::Level::Admin   then user.is_admin?
      else                                 false
      end
    end

    # Look up a settings key, if it exists and the user has the correct privilege
    #
    def self.get_setting_for?(user : Model::User, key : String, settings : Array(Settings) = [] of Settings) : YAML::Any?
      # First check if key present, then deserialise
      if settings.any?(&.has_key_for?(user, key))
        settings
          # Sort on privilege
          .sort_by(&.encryption_level.as(Encryption::Level))
          # Attain (if exists) setting for given key
          .compact_map(&.any[key]?)
          # Get the highest privilege setting
          .last
      end
    end

    # Decrypt and pick off the setting
    #
    def get_setting_for?(user, setting) : YAML::Any?
      Settings.get_setting_for(user, setting, [self])
    end

    # Check if top-level settings key present for the supplied user
    #
    def has_key_for?(user, key)
      has_key = keys.try(&.includes?(key))
      has_privilege = Settings.has_privilege?(user, encryption_level)
      has_key && has_privilege
    end

    # If a Settings has a parent, it's a version
    #
    def is_version? : Bool
      !!(@settings_id)
    end

    # Determine if setting_string is encrypted
    #
    def is_encrypted? : Bool
      !!(@settings_string.try &->Encryption.is_encrypted?(String))
    end

    # Decrypts settings, encodes as a json object
    #
    def settings_json
      settings_any.to_json
    end

    # Decrypts settings for a user, merges into single JSON object
    #
    def any(user : User) : Hash(YAML::Any, YAML::Any)?
      decrypt_for(user).try(&->YAML.parse(String).as_h)
    end

    # Decrypts settings, merges into single JSON object
    #
    def any : Hash(YAML::Any, YAML::Any)
      YAML.parse(decrypt).as_h
    end
  end
end
