require "./helper"

module Engine::Model
  describe TriggerInstance do
    it "saves a TriggerInstance" do
      inst = TriggerInstance.create!
      id = TriggerInstance.find!(inst.id).id
      id.should eq inst.id
    end

    describe "index view" do
      it "#of finds TriggerInstance by parent Trigger" do
        trigger = Trigger.create!(name: "ree")
        inst = TriggerInstance.new
        inst.trigger = trigger
        inst.save!

        id = TriggerInstance.of(trigger.id).first?.try(&.id)
        id.should eq inst.id
      end

      it "#for finds TriggerInstance by parent ControlSystem" do
        cs = Generator.control_system.save!
        inst = TriggerInstance.new
        inst.control_system = cs
        inst.save!

        id = TriggerInstance.for(cs.id).first?.try(&.id)
        id.should eq inst.id
      end
    end
  end
end
