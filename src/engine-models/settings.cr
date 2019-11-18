require "rethinkdb-orm"
require "time"

require "./base/model"
require "./error"
require "./utilities/encryption"


# Could you parameterise on the parent model?
# It sould be generic on the model...
# So then you would have Settings(T), not sure that would work
module ACAEngine::Model
  # Settings mode
  #
  # TODO: statically ensure a single parent id exists on the table
  class Settings < ModelBase
    include RethinkORM::Timestamps

    table :sets

    attribute parent_id : String
    attribute encryption : Encryption
    attribute settings : String
    attribute keys : Array(String) = [] of String

    # Settings acts a 2-level tree
    has_many Settings, collection_name: "settings", dependent: :destroy

    belongs_to Zone, dependent: :destroy
    belongs_to ControlSystem, dependent: :destroy
    belongs_to Driver, dependent: :destroy
    belongs_to Module, dependent: :destroy

    validates :parent_id, prescence: true
    validate ->single_parent(Setting)

    before_save :build_keys

    def build_keys : Array(String)
      raise NoParentError unless (encryption_id = @parent_id)

      settings = @settings.as(String)
      encryption = @encryption.as(Encryption::Level)
      parent_id = @parent_id.as(String)
      decrypted = Encryption.decrypt(string: settings, level: encryption, id: encryption_id)

      self.keys = YAML.parse(decrypted).to_h.keys.map(&.to_s)
    end

    # Queries
    ###########################################################################

    # Get version history
    #
    # TODO: ranges
    def history
      Settings.get_all([id], index: :settings_id).as_a.sort_by!(&.created_at)
    end

    # Validators
    ###########################################################################

    protected def single_parent(settings : Setting)
      parent_ids = {settings.zone_id, settings.control_system_id, settings.driver_id, settings.module_id}
      unless parent_ids.one?
        this.validation_error(:parent_id, "there can only be a single parent id #{parent_ids.inspect}")
      end
    end

    # Parent accessors set the model id, used for encryption
    ###########################################################################

    macro finished
      {% for parent in {Zone, ControlSystem, Driver, Module} %}
        def {{parent.id.downcase}}=(model : {{parent}})
          parent_id = model.id
          previous_def(model)
        end
      {% end %}
    end

    # Helpers
    ###########################################################################

    # If a Settings has a parent, it's a version
    #
    def is_version? : Bool
      !!(@settings_id)
    end6

    # Encrypts all settings.
    #
    # We want encryption of unpersisted models, so we set the id if not present
    # Setting of id here will not intefer with `persisted?` unless call made in a before_save
    def encrypt_settings(settings : Array(Setting))
      raise NoParentError unless (encryption_id = @parent_id)

      settings.map do |setting|
        level, setting_string = setting
        {level, Encryption.encrypt(string: setting_string, level: level, id: encryption_id)}
      end
    end

    # Decrypts settings dependent on user privileges
    #
    def decrypt_for!(user)
      self.settings = decrypt_for(user)
      self
    end

    def decrypt_for(user) : String
      raise NoParentError unless (encryption_id = @parent_id)

      settings = @settings.as(String)
      encryption = @encryption.as(Encryption::Level)

      case encryption
      when Encryption::Level::Support && (user.is_support? || user.is_admin?)
        Encryption.decrypt(string: settings, level: level, id: encryption_id)
      when Encryption::Level::Admin && user.is_admin?
        Encryption.decrypt(string: settings, level: level, id: encryption_id)
      else
        settings
      end
    end

    # Decrypt and pick off the setting
    #
    def get_setting_for(user, setting) : YAML::Any?
      return unless @id

      decrypted_settings = decrypt_for(user)
      YAML.parse(decrypted)[setting]? unless Encryption.is_encrypted?(decrypted_settings)
    end

    # Decrypts settings, merges into single JSON object
    #
    def settings_json
      raise NoParentError unless (encryption_id = @parent_id)

      @settings.as(Array(Setting)).reduce({} of YAML::Any => YAML::Any) { |acc, (level, settings_string)|
        # Decrypt String
        decrypted = ACAEngine::Encryption.decrypt(string: settings_string, level: level, id: encryption_id)
        # Parse and merge into accumulated settings hash
        acc.merge!(YAML.parse(decrypted).as_h)
      }.to_json
    end
  end
end
