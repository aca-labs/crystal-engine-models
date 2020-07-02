require "rethinkdb-orm"
require "time"

require "./base/model"
require "./settings"
require "./utilities/settings_helper"

module PlaceOS::Model
  class Zone < ModelBase
    include RethinkORM::Timestamps
    include SettingsHelper

    table :zone

    attribute name : String, es_type: "keyword"
    attribute description : String
    attribute tags : Set(String) = ->{ Set(String).new }

    # =============================
    # Additional top level metadata that is fairly common
    # =============================
    # Geo-location string (lat,long) or any other location
    attribute location : String
    # For display on staff app
    attribute display_name : String
    # Could be used as floor code
    attribute code : String
    # Could be used as floor type
    attribute type : String
    # Could be used as a desk count
    attribute count : Int32 = 0
    # Could be used as a people capacity
    attribute capacity : Int32 = 0
    # Map identifier, could be a URL or id
    attribute map_id : String
    # =============================

    belongs_to Zone, foreign_key: "parent_id", association_name: "parent"
    has_many(
      child_class: Zone,
      collection_name: "children",
      foreign_key: "parent_id",
      dependent: :destroy
    )

    attribute triggers : Array(String) = [] of String

    has_many(
      child_class: TriggerInstance,
      collection_name: "trigger_instances",
      foreign_key: "zone_id",
      dependent: :destroy,
    )

    # Metadata belonging to this zone
    has_many(
      child_class: Metadata,
      collection_name: "metadata",
      foreign_key: "parent_id",
      dependent: :destroy
    )

    # Encrypted yaml settings
    has_many(
      child_class: Settings,
      collection_name: "settings",
      foreign_key: "parent_id",
      dependent: :destroy
    )

    # Looks up the triggers attached to the zone
    def trigger_data : Array(Trigger)
      triggers = @triggers
      if !triggers || triggers.empty?
        [] of Trigger
      else
        Trigger.find_all(triggers).to_a
      end
    end

    validates :name, presence: true
    ensure_unique :name

    def systems
      ControlSystem.by_zone_id(self.id)
    end

    before_destroy :remove_zone

    # Removes self from ControlSystems
    protected def remove_zone
      self.systems.try &.each do |cs|
        zones = cs.zones
        if zones
          cs.zones = zones.reject(self.id)

          version = cs.version
          cs.version = version + 1 if version

          cs.save!
        end
      end
    end

    # Zone Trigger Management
    ###########################################################################

    @remove_triggers : Array(String) = [] of String
    @add_triggers : Array(String) = [] of String

    @update_systems = false

    before_save :check_triggers

    protected def check_triggers
      if self.triggers_changed?
        previous = self.triggers_was || [] of String
        current = self.triggers || [] of String

        @remove_triggers = previous - current
        @add_triggers = current - previous

        @update_systems = !@remove_triggers.empty? || !@add_triggers.empty?
      else
        @update_systems = false
      end
    end

    after_save :update_triggers

    protected def update_triggers
      return unless @update_systems

      # Remove TriggerInstances
      unless @remove_triggers.empty?
        self.trigger_instances.each do |trig|
          trig.destroy if @remove_triggers.includes?(trig.trigger_id)
        end
      end

      # Add TriggerInstances
      unless @add_triggers.empty?
        self.systems.try &.each do |sys|
          @add_triggers.each do |trig_id|
            inst = TriggerInstance.new(trigger_id: trig_id, zone_id: self.id)
            inst.control_system = sys
            inst.save
          end
        end
      end
    end
  end
end
