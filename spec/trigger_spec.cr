require "./helper"

module Engine::Model
  describe Trigger do
    it "saves a trigger" do
      inst = Generator.trigger.save!
      Trigger.find!(inst.id).id.should eq inst.id
    end

    pending Trigger::Actions
    pending Trigger::Conditions
  end
end
