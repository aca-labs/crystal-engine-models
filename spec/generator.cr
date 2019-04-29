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
      role_value = Dependency::Role.values.sample(1).first
      Dependency::Role.from_value(role_value)
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

    def self.control_system
      ControlSystem.new(
        name: RANDOM.base64(10),
      )
    end

    def self.zone
      Zone.new(
        name: RANDOM.base64(10),
      )
    end
  end
end
