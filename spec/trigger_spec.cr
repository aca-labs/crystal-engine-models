require "./helper"

module Engine::Model
  describe Trigger do
    it "saves a trigger" do
      inst = Generator.trigger.save!
      Trigger.find!(inst.id).id.should eq inst.id
    end

    describe Trigger::Actions do
      it "validates function action" do
        model = Generator.trigger

        valid = Trigger::Actions::Function.new(
          mod: "anthropocene",
          method: "start"
        )
        invalid = Trigger::Actions::Function.new(
          mod: "anthropocene",
        )
        model.actions.try &.functions = [valid, invalid]

        model.valid?.should be_false
        model.errors.first.to_s.should end_with "method is required"
      end

      it "validates email action" do
        model = Generator.trigger

        valid = Trigger::Actions::Email.new(
          emails: [Faker::Internet.email],
          content: "Hi"
        )
        invalid = Trigger::Actions::Email.new(
          content: "No email, whodis"
        )
        model.actions.try &.mailers = [valid, invalid]

        model.valid?.should be_false
        model.errors.size.should eq 1
        model.errors.first.to_s.should end_with "emails is required"
      end
    end

    describe Trigger::Conditions do
      it "validates dependent condition" do
        model = Generator.trigger

        valid = Trigger::Conditions::Dependent.new(
          type: "at",
          time: Time.now,
        )
        invalid = Trigger::Conditions::Dependent.new(
          type: "maybe a cron",
          value: "5 * * * *",
        )
        model.conditions.try &.dependents = [valid, invalid]

        model.valid?.should be_false
        model.errors.size.should eq 1
        model.errors.first.to_s.should end_with "type is not included in the list"
      end

      it "validates comparison condition" do
        model = Generator.trigger

        valid = Trigger::Conditions::Comparison.new(
          left: true,
          operator: "and",
          right: {
            mod:    "anthropocene",
            status: "{on: true}",
            keys:   ["on"],
          }
        )
        invalid = Trigger::Conditions::Comparison.new(
          left: false,
          operator: "asldkgjbn",
          right: {
            mod:    "anthropocene",
            status: "{on: true}",
            keys:   ["on"],
          }
        )
        model.conditions.try &.comparisons = [valid, invalid]

        model.valid?.should be_false
        model.errors.size.should eq 1
        model.errors.first.to_s.should end_with "operator is not included in the list"
      end
    end
  end
end
