require "./helper"

module Engine::Model
  # Transmogrified from the Ruby Engine spec
  describe ControlSystem do
    it "saves a control system" do
      cs = new_control_system
      begin
        cs.save!
      rescue e : RethinkORM::Error::DocumentInvalid
        pp! e.model.errors
        raise e
      end

      cs.should_not be_nil
      id = cs.id
      id.should start_with "sys-" if id
      cs.persisted?.should be_true
    end

    it "should create triggers when added and removed from a zone" do
      begin
        zone2 = new_zone.save!

        cs = new_control_system
        zone2_id = zone2.id
        if zone2_id
          cs.zones = [zone2_id]
        end

        cs.save!

        trigger = Trigger.create!(name: "trigger test")
        zone = new_zone
        trigger_id = trigger.id
        if trigger_id
          zone.triggers = [trigger_id]
        end
        zone.save!
        zone_id = zone.id
      rescue e : RethinkORM::Error::DocumentInvalid
        pp! e.class
        pp! e.model.errors
        raise e
      end

      cs.triggers.to_a.size.should eq 0

      # Set zones on the ControlSystem
      cs.zones = [zone_id, zone2_id] if zone_id && zone2_id
      cs.save!

      cs = ControlSystem.find! cs.id
      cs.triggers.to_a.size.should eq 1
      cs.triggers.to_a[0].zone_id.should eq zone.id

      cs.zones = [zone2_id] if zone2_id
      cs.save!

      cs = ControlSystem.find! cs.id
      cs.triggers.to_a.size.should eq 0
      zone.trigger_instances.to_a.size.should eq 0

      {cs, zone, zone2, trigger}.each do |m|
        begin
          m.destroy
        rescue
        end
      end
    end
  end
end
