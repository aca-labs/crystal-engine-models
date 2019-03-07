require "./helper"

describe Engine::Model::Dependency do
  it "creates a dependency" do
    dep = Engine::Model::Dependency.create!(
      name: "whatever",
      class_name: "hitachi",
      module_name: "some_module",
      role: Engine::Model::Dependency::Role::Service,
    )

    dep.should_not be_nil

    id = dep.id
    id.should start_with "dep-" if id
    dep.role.should eq Engine::Model::Dependency::Role::Service
    dep.persisted?.should be_true
  end
end
