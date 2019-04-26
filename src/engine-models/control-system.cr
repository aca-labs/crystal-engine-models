require "uri"
require "time"

require "../engine-models"

module Engine::Model
  class ControlSystem < ModelBase
    table :sys

    before_save :update_features

    attribute name : String
    attribute description : String

    # Room search meta-data
    # Building + Level are both filtered using zones
    attribute email : String
    attribute capacity : Int32 = 0
    attribute features : String
    attribute bookable : Bool = false
    attribute map_id : String

    # Provide a email lookup helpers
    secondary_index :email

    # The number of UI devices that are always available in the room
    # i.e. the number of iPads mounted on the wall
    attribute installed_ui_devices : Int32 = 0

    # IDs of associated models
    attribute zones : Array(String) = [] of String
    attribute modules : Array(String) = [] of String

    def self.by_zone_id(id)
      ControlSystem.raw_query do |q|
        q.table(ControlSystem.table_name).filter do |doc|
          doc["zones"].contains(id)
        end
      end
    end

    def self.in_zone(id)
      self.by_zone_id(id)
    end

    def self.by_module_id(id)
      ControlSystem.raw_query do |q|
        q.table(ControlSystem.table_name).filter do |doc|
          doc["modules"].contains(id)
        end
      end
    end

    def self.using_module(id)
      self.by_module_id(id)
    end

    # YAML settings
    attribute settings : String = "{}"

    attribute created_at : Time = ->{ Time.utc_now }, converter: Time::EpochConverter

    # Provide a field for simplifying support
    attribute support_url : String
    attribute version : Int32 = 0

    ensure_unique :name do |name|
      "#{name.to_s.strip.downcase}"
    end

    # Obtains the control system's modules as json
    def module_data
      Module.get_all(modules).to_a.map do |mod|
        object = mod.attributes[:dependency].try(&.select({:name, :module_name}))
        object.to_json
      end
    end

    # Obtains the control system's zones as json
    def zone_data
      Zone.get_all(zones).to_a.map(&.to_json)
    end

    # Triggers
    def triggers
      TriggerInstance.for(self.id)
    end

    # Zones and settings are only required for confident coding
    validates :name, presence: true

    # Validate support URI
    validate ->(this : ControlSystem) {
      support_url = this.support_url
      if support_url.nil? || support_url.empty?
        this.support_url = nil
      else
        url = URI.parse(support_url)
        url_parsed = !!(url && url.scheme && url.host)
        this.validation_error(:support_url, "is an invalid URI") unless url_parsed
      end
    }

    # Adds modules to the features field,
    # Extends features with extra_features field in settings if present
    protected def update_features
      if self.id
        system = ControlSystem.find(self.id)
        if system
          mods = system.modules || [] of String
          mods.reject! "__Triggers__"
          self.features = mods.join " "
        end
      end

      settings = self.settings
      if settings
        extra_features = JSON.parse(settings)["extra_features"]?
        if extra_features
          self.features = "#{self.features} #{extra_features}"
        end
      end
    end

    # =======================
    # Zone Trigger Management
    # =======================

    @remove_zones : Array(String) = [] of String
    @add_zones : Array(String) = [] of String

    @update_triggers = false

    before_save :check_zones

    # Update the zones on the model
    protected def check_zones
      if self.zones_changed?
        previous = self.zones_was || [] of String
        current = self.zones || [] of String

        @remove_zones = previous - current
        @add_zones = current - previous

        @update_triggers = !@remove_zones.empty? || !@add_zones.empty?
      else
        @update_triggers = false
      end
    end

    after_save :update_triggers

    # Updates triggers after save
    #
    # * Destroy Triggers from removed zones
    # * Adds TriggerInstances to added zones
    protected def update_triggers
      return unless @update_triggers

      unless @remove_zones.empty?
        trigs = self.triggers.to_a

        # Remove ControlSystem's triggers associated with the removed zone
        Zone.find_all(@remove_zones).each do |zone|
          # Destroy the associated triggers
          triggers = zone.triggers || [] of String
          triggers.each do |trig_id|
            trigs.each do |trig|
              if trig.trigger_id == trig_id && trig.zone_id == zone.id
                trig.destroy
              end
            end
          end
        end
      end

      # Add trigger instances to zones
      Zone.find_all(@add_zones).each do |zone|
        triggers = zone.triggers || [] of String
        triggers.each do |trig_id|
          inst = TriggerInstance.new(trigger_id: trig_id, zone_id: zone.id)
          inst.control_system = self
          inst.save
        end
      end
    end
  end
end
