require "./helper"

describe Engine::Model::ControlSystem do
  pending "saves a control system" do
    cs = Engine::Model::ControlSystem.create!(
      name: Faker::Hacker.noun
    )

    cs.save!
    cs.should_not be_nil
    id = cs.id
    id.should start_with "sys-" if id
    cs.persisted?.should be_true
  end
end
