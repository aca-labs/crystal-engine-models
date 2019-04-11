require "random"
require "time"

require "../engine-models"

module Engine::Model
  class TriggerInstance < ModelBase
    table :trig

    belongs_to ControlSystem
    belongs_to Trigger
    belongs_to Zone

    attribute created_at : Time = ->{ Time.utc_now }, converter: Time::EpochConverter
    attribute updated_at : Time = ->{ Time.utc_now }, converter: Time::EpochConverter

    attribute enabled : Bool = true
    attribute triggered : Bool = false
    attribute important : Bool = false

    attribute webhook_secret : String = ->{ Random::Secure.hex(32) }
    attribute trigger_count : Int32 = 0

    before_destroy :unload
    after_save :load

    # ----------------
    # PARENT ACCESSORS
    # ----------------
    def name
      self.trigger.name
    end

    def description
      self.trigger.description
    end

    def conditions
      self.trigger.conditions
    end

    def actions
      self.trigger.actions
    end

    def debounce_period
      self.trigger.debounce_period
    end

    def binding
      self.id
    end

    # # ------------
    # # VIEWS ACCESS
    # # ------------
    # # Helper method: for(sys_id)
    # index_view :control_system_id, find_method: :for

    # # Finds all the instances belonging to a particular trigger
    # # Helper method: of(trig_id)
    # index_view :trigger_id, find_method: :of

    # Override to_json, set method fields
    def to_json
      self.attributes.merge({
        :name        => name,
        :description => description,
        :conditions  => conditions,
        :actions     => actions,
        :binding     => binding,
      }).to_json
    end

    # --------------------
    # START / STOP HELPERS
    # --------------------

    # Loads trigger instance into module
    def load
      # FIXME: Stub
      # if @ignore_update
      #     @ignore_update = false
      # else
      #     mod_man = get_module_manager
      #     mod = mod_man.instance if mod_man

      #     if mod_man && mod
      #         trig = self
      #         mod_man.thread.schedule do
      #             mod.reload trig
      #         end
      #     end
      # end
    end

    # Ignore updates to trigger
    def ignore_update
      @ignore_update = true
    end

    # Unloads trigger instance from module
    def unload
      # FIXME: Stub
      #     mod_man = get_module_manager
      #     mod = mod_man.instance if mod_man

      #     if mod_man && mod
      #         trig = self
      #         old_id = trig.id # This is removed once delete has completed
      #         mod_man.thread.schedule do
      #             mod.remove old_id
      #         end
      #     end
    end

    # FIXME: Discuss migration
    # protected def get_module_manager
    #     ::Orchestrator::Control.instance.loaded?(self.control_system_id)
    # end

    before_create :set_importance

    protected def set_importance
      self.important = self.trigger.important
    end

    # -----------
    # VALIDATIONS
    # -----------

    # Ensure the models exist in the database
    # validates :control_system, presence: true
    # validates :trigger, presence: true
  end
end
