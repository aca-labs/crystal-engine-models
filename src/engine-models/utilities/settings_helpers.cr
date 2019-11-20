require "rethinkdb-orm"

require "../settings"

module ACAEngine::Model
  module SettingsHelpers
    abstract def settings_collection

    macro settings_helper(type)
      def settings_collection
        RethinkORM::AssociationCollection({{ type }}, Settings).new(self)
      end
    end

    # Get the settings at a particular encryption level
    #
    def settings_at(encryption_level : Encryption::Level)
      settings_collection.where(encryption: encryption_level.to_i, settings_id: nil).to_a.first
    end

    # Decrypts and merges all settings for the model
    #
    def all_settings : Hash(YAML::Any, YAML::Any)
      settings_collection.where(settings_id: nil).reduce({} of YAML::Any => YAML::Any) do |acc, settings|
        # Parse and merge into accumulated settings hash
        acc.merge!(settings.any)
      end
    end

    # Decrypted JSON object for configuring drivers
    #
    def settings_json
      all_settings.to_json
    end
  end
end
