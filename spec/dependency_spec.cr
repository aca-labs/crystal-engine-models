require "./helper"

module Engine::Model
  describe Dependency do
    it "creates a dependency" do
      dep = Generator.dependency(role: Dependency::Role::Service)
      dep.version = SemanticVersion.parse("1.1.1")
      dep.save!

      dep.persisted?.should be_true

      dep.id.try &.should start_with "dep-"
      dep.role.should eq Dependency::Role::Service
      dep.version.should eq SemanticVersion.parse("1.1.1")
    end

    it "finds modules by dependency" do
      dep = Generator.dependency(role: Dependency::Role::Device).save!
      mod = Generator.module(dependency_role: dep.role)
      mod.dependency = dep
      mod.save!

      dep.persisted?.should be_true
      mod.persisted?.should be_true

      Module.by_dependency_id(dep.id).to_a.first.id.should eq mod.id
    end

    describe "callbacks" do
      it "#cleanup_modules removes dependency modules" do
        dep = Generator.dependency(role: Dependency::Role::Device).save!
        mod = Generator.module(dependency_role: dep.role)
        mod.dependency = dep
        mod.save!

        dep.persisted?.should be_true
        mod.persisted?.should be_true

        Module.by_dependency_id(dep.id).to_a.first.id.should eq mod.id
        dep.destroy
        Module.find(mod.id).should be_nil
      end

      it "#update_modules updates dependent modules dependency metadata" do
        dep = Generator.dependency(role: Dependency::Role::Device).save!
        mod = Generator.module(dependency_role: dep.role)

        mod.dependency = dep
        mod.save!

        dep.persisted?.should be_true
        mod.persisted?.should be_true

        dep.role = Dependency::Role::SSH
        dep.save!

        Module.find!(mod.id).role.should eq Dependency::Role::SSH
      end
    end
  end
end
