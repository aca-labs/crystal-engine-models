require "./helper"

module Engine::Model
  describe Module do
    describe "persistence" do
      it "saves a Service module" do
        name = Faker::Hacker.noun
        mod = Module.new(
          custom_name: name,
          uri: Faker::Internet.url,
        )

        service_dep = Generator.dependency(
          module_name: name,
          role: Dependency::Role::Service,
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

      it "saves a Logic module" do
        name = Faker::Hacker.noun
        mod = Module.new(
          custom_name: name,
          uri: Faker::Internet.url,
        )

        service_dep = Generator.dependency(
          module_name: name,
          role: Dependency::Role::Logic,
        ).save!

        mod.dependency = service_dep
        mod.control_system = Generator.control_system.save!

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
        mod = Module.new(
          custom_name: name,
          uri: Faker::Internet.url,
          ip: Faker::Internet.ip_v4_address,
          port: Random.rand((1..6555)),
        )

        service_dep = Generator.dependency(
          module_name: name,
          role: Dependency::Role::Device,
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
        mod = Module.new(
          custom_name: name,
          uri: Faker::Internet.url,
          ip: Faker::Internet.ip_v4_address,
          port: Random.rand((1..65_535)),
        )

        service_dep = Generator.dependency(
          module_name: name,
          role: Dependency::Role::SSH,
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
end
