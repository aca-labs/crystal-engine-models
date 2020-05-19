require "./helper"

module PlaceOS::Model
  # Transmogrified from the Ruby Engine spec
  describe Zone do
    it "saves a zone" do
      zone = Generator.zone

      begin
        zone.save!
      rescue e : RethinkORM::Error::DocumentInvalid
        inspect_error(e)
        raise e
      end

      zone.should_not be_nil
      id = zone.id
      id.should start_with "zone-" if id
      zone.persisted?.should be_true
    end

    it "supports zone hierarchies" do
      zone = Generator.zone

      begin
        zone.save!
      rescue e : RethinkORM::Error::DocumentInvalid
        inspect_error(e)
        raise e
      end

      zone.should_not be_nil
      id = zone.id.not_nil!
      id.should start_with "zone-"
      zone.persisted?.should be_true

      zone2 = Generator.zone
      zone2.parent_id = id
      begin
        zone2.save!
      rescue e : RethinkORM::Error::DocumentInvalid
        inspect_error(e)
        raise e
      end

      id2 = zone2.id.not_nil!
      id2.should start_with "zone-"

      zone.children.to_a.map(&.id).should eq [id2]
      zone2.parent.not_nil!.id.should eq id

      # show that deleting the parent deletes the children
      Zone.find!(id2.as(String)).id.should eq id2
      zone.destroy
      Zone.find(id2.as(String)).should be_nil
    end

    it "should create triggers when added and removed from a zone" do
      # Set up
      zone = Generator.zone.save!
      cs = Generator.control_system

      id = zone.id
      cs.zones = [id] if id

      cs.save!

      trigger = Trigger.create!(name: "trigger test")

      # No trigger_instances associated with zone
      zone.trigger_instances.to_a.size.should eq 0
      cs.triggers.to_a.size.should eq 0

      id = trigger.id
      zone.triggers = [id] if id
      zone.triggers_changed?.should be_true
      zone.save

      trigs = cs.triggers.to_a
      trigs.size.should eq 1
      trigs.first.zone_id.should eq zone.id

      # Reload the relationships
      zone = Zone.find!(zone.id.as(String))

      zone.trigger_instances.to_a.size.should eq 1
      zone.triggers = [] of String
      zone.save

      zone = Zone.find!(zone.id.as(String))
      zone.trigger_instances.to_a.size.should eq 0

      {cs, zone, trigger}.each &.destroy
    end

    it "has a #tag_list helper" do
      expected = ["building", "area-51"]
      zone = Zone.new(name: "el zono", tags: expected.join(' '))
      zone.tag_list.should eq expected
    end
  end
end
