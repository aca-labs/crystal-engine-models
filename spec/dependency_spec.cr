require "./helper"

module Engine::Model
  describe Dependency do
    it "creates a dependency" do
      dep = Dependency.create!(
        name: "whatever",
        role: Dependency::Role::Service,
        commit: "cbf1337",
        version: SemanticVersion.parse("1.1.1"),
        module_name: "some_module",
      )

      dep.should_not be_nil

      id = dep.id
      id.should start_with "dep-" if id
      dep.role.should eq Dependency::Role::Service
      dep.version.should eq SemanticVersion.parse("1.1.1")
      dep.persisted?.should be_true
    end
  end
end
