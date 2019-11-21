require "rethinkdb-orm"

require "../settings"

module ACAEngine::Model
  module SettingsHelper
    abstract def settings_collection

    macro settings_helper(type)
      def settings_collection
        RethinkORM::AssociationCollection({{ type }}, Settings).new(self)
      end
    end

    # Get the settings at a particular encryption level
    #
    def settings_at(encryption_level : Encryption::Level)
      Settings.raw_query do |q|
        q.table(Settings.table_name).filter({parent_id: self.id.as(String)}).filter { |r|
          r.has_fields(:settings_id).not
        }
      end.to_a.first
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
