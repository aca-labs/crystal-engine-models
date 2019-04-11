require "./helper"

# Transmogrified from the Ruby Engine spec
describe Engine::Model::Zone do
  pending "should save a zone" do
    zone = new_zone

    begin
      zone.save!
    rescue e : RethinkORM::Error::DocumentInvalid
      pp! e.model.errors
      raise e
    end

    zone.should_not be_nil
    id = zone.id
    id.should start_with "zone-" if id
    zone.persisted?.should be_true
  end

  pending "should create triggers when added and removed from a zone" do
    begin
      zone2 = new_zone.save!
      cs = new_control_system

      id = zone2.id
      unless id.nil?
        cs.zones = [id]
      end
      cs.save!

      trigger = Engine::Model::Trigger.create!(name: "trigger test")

      zone = Engine::Model::Zone.new(name: "trig zone")
      id = trigger.id
      unless id.nil?
        zone.triggers = [id]
      end
      zone.save!
    rescue e : RethinkORM::Error::DocumentInvalid
      raise e
    end

    zone.trigger_instances.to_a.size.should eq 0
    cs.triggers.to_a.size.should eq 0

    # zone.triggers = [trigger.id]
    # zone.triggers_changed?.should be_true
    zone.save

    # cs.triggers.to_a.size.should eq 1
    # cs.triggers.to_a[0].zone_id.should eq zone.id

    # Reload the relationships
    zone = Engine::Model::Zone.find! zone.id
    zone.trigger_instances.to_a.size.should eq 1
    # zone.triggers = [] of String
    zone.save

    zone = Engine::Model::Zone.find! zone.id
    zone.trigger_instances.to_a.size.should eq 0

    {cs, zone, zone2, trigger}.each do |m|
      begin
        m.destroy
      rescue
      end
    end
  end
end
