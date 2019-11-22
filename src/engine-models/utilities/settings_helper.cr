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
      master_settings_query do |q|
        q.filter({encryption_level: encryption_level.to_i})
      end.first
    end

    # Decrypts and merges all settings for the model
    #
    def all_settings : Hash(YAML::Any, YAML::Any)
      master_settings.reduce({} of YAML::Any => YAML::Any) do |acc, settings|
        # Parse and merge into accumulated settings hash
        acc.merge!(settings.any)
      end
    end

    # Decrypted JSON object for configuring drivers
    #
    def settings_json : String
      all_settings.to_json
    end

    # Query the master settings attached to a model
    #
    def master_settings : Array(Settings)
      master_settings_query { |q| q }
    end

    # Query for all master settings associated with a model
    #
    protected def master_settings_query
      Settings.raw_query do |q|
        yield q.table(Settings.table_name).filter({parent_id: self.id.as(String)}).filter { |r|
          # Get documents where the settings_id does not exist, i.e. is the master
          r.has_fields(:settings_id).not
        }
      end.to_a
    end
  end
end
