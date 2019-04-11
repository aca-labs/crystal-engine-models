require "./helper"

describe Engine::Model::Dependency do
  it "creates a dependency" do
    dep = Engine::Model::Dependency.create!(
      name: "whatever",
      role: Engine::Model::Dependency::Role::Service,
      commit: "cbf1337",
      version: SemanticVersion.parse("1.1.1"),
      module_name: "some_module",
    )

    dep.should_not be_nil

    id = dep.id
    id.should start_with "dep-" if id
    dep.role.should eq Engine::Model::Dependency::Role::Service
    dep.persisted?.should be_true
  end
end
