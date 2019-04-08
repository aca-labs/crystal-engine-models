require "./helper"

describe Engine::Model::Zone do

    @cs : Engine::Model::ControlSystem?
    @edge : Engine::Model::EdgeControl?
    @zone : Engine::Model::Zone?
    @zone2 : Engine::Model::Zone?
    @trigger : Engine::Model::Trigger?

    Spec.before_each do
        begin
            @zone2 = Engine::Model::Zone.new
            @zone2.name = "trig zone2"
            @zone2.save!

            @edge = Engine::Model::EdgeControl.new
            @edge.name = "edge test"
            @edge.save!

            @cs = Engine::Model::ControlSystem.new
            @cs.name = "trig sys"
            @cs.zones << @zone2.id
            @cs.edge = @edge
            @cs.save!

            @trigger = Engine::Model::Trigger.new
            @trigger.name = "trigger test"
            @trigger.save!

            @zone = Engine::Model::Zone.new
            @zone.name = "trig zone"
            @zone.triggers = [@trigger.id]
            @zone.save!
        rescue e : RethinkORM::Error::RecordInvalid
            puts "#{e.record.errors.inspect}"
            raise e
        end
    end

    Spec.after_each do
        begin
            @cs.destroy
        rescue
        end
        begin
            @edge.destroy
        rescue
        end
        begin
            @zone.destroy
        rescue
        end
        begin
            @zone2.destroy
        rescue
        end
        begin
            @trigger.destroy
        rescue
        end

        @zone = @zone2 = @cs = @trigger = nil
    end

    it "should create triggers when added and removed from a zone" do
        @zone.trigger_instances.to_a.count.should eq 0
        @cs.triggers.to_a.count.should eq 0

        @zone.triggers = [@trigger.id]
        @zone.triggers_changed?.should be_true
        @zone.save

        @cs.triggers.to_a.count.should eq 1
        @cs.triggers.to_a[0].zone_id.should eq @zone.id

        # Reload the relationships
        @zone = Engine::Model::Zone.find @zone.id
        @zone.trigger_instances.to_a.count.should eq 1
        @zone.triggers = []
        @zone.save

        @zone = Engine::Model::Zone.find @zone.id
        @zone.trigger_instances.to_a.count.should eq 0
    end
end
