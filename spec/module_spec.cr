require "./helper"

describe Engine::Model::Module do
  describe "persistence" do
    it "saves a Service module" do
      name = Faker::Hacker.noun
      mod = Engine::Model::Module.new(
        custom_name: name,
        uri: Faker::Internet.url,
      )

      service_dep = new_dependency(
        module_name: name,
        role: Engine::Model::Dependency::Role::Service,
      ).save!
      mod.dependency = service_dep

      begin
        mod.save!
        mod.persisted?.should be_true
      rescue e : RethinkORM::Error::DocumentInvalid
        inspect_error(e)
        raise e
      end
    end

    pending "saves a Logic module" do
      name = Faker::Hacker.noun
      mod = Engine::Model::Module.new(
        custom_name: name,
        uri: Faker::Internet.url,
      )

      service_dep = new_dependency(
        module_name: name,
        role: Engine::Model::Dependency::Role::Logic,
      ).save!

      mod.dependency = service_dep
      mod.control_system = new_control_system.save!

      begin
        mod.save!
        mod.persisted?.should be_true
      rescue e : RethinkORM::Error::DocumentInvalid
        inspect_error(e)
        raise e
      end
    end

    it "saves a Device module" do
      name = Faker::Hacker.noun
      mod = Engine::Model::Module.new(
        custom_name: name,
        uri: Faker::Internet.url,
        ip: Faker::Internet.ip_v4_address,
        port: Random.rand((1..6555)),
      )

      service_dep = new_dependency(
        module_name: name,
        role: Engine::Model::Dependency::Role::Device,
      ).save!

      mod.dependency = service_dep

      begin
        mod.save!
        mod.persisted?.should be_true
      rescue e : RethinkORM::Error::DocumentInvalid
        inspect_error(e)
        raise e
      end
    end

    it "saves a SSH module" do
      name = Faker::Hacker.noun
      mod = Engine::Model::Module.new(
        custom_name: name,
        uri: Faker::Internet.url,
        ip: Faker::Internet.ip_v4_address,
        port: Random.rand((1..65_535)),
      )

      service_dep = new_dependency(
        module_name: name,
        role: Engine::Model::Dependency::Role::SSH,
      ).save!

      mod.dependency = service_dep

      begin
        mod.save!
        mod.persisted?.should be_true
      rescue e : RethinkORM::Error::DocumentInvalid
        inspect_error(e)
        raise e
      end
    end
  end
end
