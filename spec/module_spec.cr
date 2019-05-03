require "./helper"

def spec_module_persistence(role)
  it "saves a #{role} module" do
    mod = Engine::Model::Generator.module(role)
    begin
      mod.save!
      mod.persisted?.should be_true
    rescue e : RethinkORM::Error::DocumentInvalid
      inspect_error(e)
      raise e
    end
  end
end

module Engine::Model
  describe Module do
    describe "persistence" do
      Dependency::Role.values.each do |role|
        spec_module_persistence(role)
      end
    end
  end
end
