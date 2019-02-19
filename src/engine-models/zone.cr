require "rethinkdb-orm"

class Engine::Zone < RethinkORM::Base
  attribute name : String
  attribute description : String
  attribute tags : String
  attribute settings : Hash(String, String), default: {} of String => String

  # TODO:
  # attribute triggers : Array(Trigger),   default: [] of Trigger

  attribute created_at : Int64, default: ->{ Time.now }

  # TODO:
  # has_many TriggerInstance, collection_name: "trigger_instances", dependent: :destroy

  ensure_unique :name do |name|
    "#{name.to_s.strip.downcase}"
  end

  validates :name, presence: true

  def systems
    ControlSystem.in_zone(self.id)
  end

  # TODO:
  # def trigger_data
  #     if triggers.empty?
  #         []
  #     else
  #         Array(Trigger.find_by_id(triggers))
  #     end
  # end

  before_destroy :remove_zone

  protected def remove_zone
    zone_cache.delete(self.id)
    systems.each do |cs|
      cs.zones.delete(self.id)
      cs.version += 1
      cs.save!
    end
  end

  # Expire both the zone cache and any systems that use the zone
  after_save :expire_caches

  protected def expire_caches
    zone_cache[self.id] = self
    ctrl = Control.instance
    systems.each do |cs|
      ctrl.expire_cache cs.id
    end
  end

  protected def zone_cache
    Control.instance.zones
  end

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
