require "../src/engine-models/*"
require "../src/engine-models/**"

RANDOM = Random.new

module Engine::Model
  # Defines generators for models
  module Generator
    def self.dependency(module_name : String? = nil, role : Dependency::Role? = nil)
      role = Generator.role unless role
      module_name = Faker::Hacker.noun unless module_name

      dep = Dependency.new(
        name: RANDOM.base64(10),
        commit: RANDOM.hex(7),
        version: SemanticVersion.parse("1.1.1"),
        module_name: module_name,
      )
      dep.role = role
      dep
    end

    def self.role
      role_value = Dependency::Role.names.sample(1).first
      Dependency::Role.parse(role_value)
    end

    def self.driver_repo
      DriverRepo.new(
        name: Faker::Hacker.noun,
        description: Faker::Hacker.noun,
        uri: Faker::Internet.url,
        commit_hash: RANDOM.hex(4),
        branch: Faker::Hacker.noun,
      )
    end

    def self.trigger
      Trigger.new(
        name: Faker::Hacker.noun
      )
    end

    def self.control_system
      ControlSystem.new(
        name: RANDOM.base64(10),
      )
    end

    def self.module(dependency_role, control_system = nil)
      mod_name = Faker::Hacker.noun
      mod, dep = case dependency_role
                 when Dependency::Role::Logic
                   logic_mod = Module.new(custom_name: mod_name, uri: Faker::Internet.url)
                   logic_dep = Generator.dependency(module_name: mod_name, role: dependency_role)

                   {logic_mod, logic_dep}
                 when Dependency::Role::Device
                   device_mod = Module.new(
                     custom_name: mod_name,
                     uri: Faker::Internet.url,
                     ip: Faker::Internet.ip_v4_address,
                     port: Random.rand((1..6555)),
                   )
                   device_dep = Generator.dependency(module_name: mod_name, role: dependency_role)

                   {device_mod, device_dep}
                 when Dependency::Role::SSH
                   ssh_mod = Module.new(
                     custom_name: mod_name,
                     uri: Faker::Internet.url,
                     ip: Faker::Internet.ip_v4_address,
                     port: Random.rand((1..65_535)),
                   )
                   ssh_dep = Generator.dependency(module_name: mod_name, role: dependency_role)

                   {ssh_mod, ssh_dep}
                 else
                   # Dependency::Role::Service
                   service_mod = Module.new(custom_name: mod_name, uri: Faker::Internet.url)
                   service_dep = Generator.dependency(module_name: mod_name, role: dependency_role)

                   {service_mod, service_dep}
                 end

      # Set dep
      mod.dependency = dep.save!

      # Set cs
      mod.control_system = !control_system ? Generator.control_system.save! : control_system

      mod
    end

    def self.zone
      Zone.new(
        name: RANDOM.base64(10),
      )
    end
  end
end
