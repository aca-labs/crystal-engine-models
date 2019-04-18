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

    # index_view :modules, find_method: :using_module, validate: false
    # index_view :zones, find_method: :in_zone

    # FIXME: Mock
    #
    def self.by_zone_id(id)
      [] of ControlSystem
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

    # Allows us to lookup systems by names
    # after_save :expire_caches

    # def expire_cache(no_update = nil)
    #   System.expire(self.id || @old_id)
    #   remote = node

    #   # Only the active host should reload the modules
    #   if remote.host_active?
    #     ctrl = Control.instance

    #     # If not deleted and control is running
    #     # then we want to trigger updates on the logic modules
    #     if !@old_id && no_update.nil? && ctrl.ready
    #       # Start the triggers if not already running (must occur on the same thread)
    #       cs = self
    #       ctrl.nodes[cs.edge_id.to_sym].load_triggers_for(cs)

    #       # Reload the running modules
    #       Module.find_by_id(self.modules).each do |mod|
    #         if mod.control_system_id
    #           manager = ctrl.loaded? mod.id
    #           manager.reloaded(mod) if manager
    #         end
    #       end
    #     end
    #   end
    # end

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

    # We only want to run this callback if run within a rails console
    # before_destroy :cleanup_modules

    # This is called by the API directly for coordination purposes.
    # The callback is only used if running within a console.
    #
    # 1. Find systems that have each of the modules specified
    # 2. If this is the last system we remove the modules
    # def cleanup_modules
    #   self.modules.each do |mod_id|
    #     systems = ControlSystem.using_module(mod_id).to_a
    #     # We don't use the model's delete method as it looks up control systems
    #     Module.delete(mod_id) if systems.size <= 1
    #   end

    #   # delete all the trigger instances (remove directly as before_delete is not required)
    #   TriggerInstance.for(self.id).each do |trig|
    #     TriggerInstance.delete(trig.id)
    #   end

    #   # Prevents reload for the cache expiry
    #   @old_id = self.id
    # end

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

    # protected def expire_caches
    #   if control_running?
    #     Control.instance.expire_cache(self.id)
    #   end
    # end

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
