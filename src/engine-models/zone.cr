require "time"

require "../engine-models"

# TODO:
# - zone cache
# - triggers

module Engine::Model
  class Zone < ModelBase
    table :zone

    attribute name : String
    attribute description : String
    attribute tags : String
    attribute settings : String = "{}"

    attribute created_at : Time = ->{ Time.utc_now }, converter: Time::EpochConverter

    attribute triggers : Array(String) = [] of String

    has_many TriggerInstance, collection_name: "trigger_instances", dependent: :destroy

    # Looks up the triggers attached to the zone
    def trigger_data : Array(Trigger)
      if @triggers.empty?
        [] of Trigger
      else
        Trigger.find(@triggers).to_a
      end
    end

    ensure_unique :name
    validates :name, presence: true

    def systems
      ControlSystem.by_zone_id(self.id)
    end

    before_destroy :remove_zone

    protected def remove_zone
      # zone_cache.delete(self.id)
      systems.each do |cs|
        zones = cs.zones
        if zones
          cs.zones = zones.reject(self.id)

          version = cs.version
          cs.version = version + 1 if version

          cs.save!
        end
      end
    end

    # Expire both the zone cache and any systems that use the zone
    # after_save :expire_caches
    # protected def expire_caches
    #   zone_cache[self.id] = self
    #   ctrl = Control.instance
    #   systems.each do |cs|
    #     ctrl.expire_cache cs.id
    #   end
    # end

    # protected def zone_cache
    #   Control.instance.zones
    # end

    # TODO:
    # =======================
    # Zone Trigger Management
    # =======================
    # before_save :check_triggers
    # protected def check_triggers
    #     if self.triggers_changed?
    #         previous = Array(self.triggers_was)
    #         current  = self.triggers

    #         @remove_triggers = previous - current
    #         @add_triggers = current - previous

    #         @update_systems = @remove_triggers.present? || @add_triggers.present?
    #     else
    #         @update_systems = false
    #     end
    #     nil
    # end

    # after_save :update_triggers
    # protected def update_triggers
    #     return unless @update_systems
    #     if @remove_triggers.present?
    #         self.trigger_instances.stream do |trig|
    #             trig.destroy if @remove_triggers.include?(trig.trigger_id)
    #         end
    #     end
    #
    #     if @add_triggers.present?
    #         systems.stream do |sys|
    #             @add_triggers.each do |trig_id|
    #                 inst = TriggerInstance.new
    #                 inst.control_system = sys
    #                 inst.trigger_id = trig_id
    #                 inst.zone_id = self.id
    #                 inst.save
    #             end
    #         end
    #     end
    #     nil
    # end
  end
end
