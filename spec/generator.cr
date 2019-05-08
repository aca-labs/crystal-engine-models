require "faker"

require "../src/engine-models/*"
require "../src/engine-models/**"

RANDOM = Random.new

module Engine::Model
  # Defines generators for models
  module Generator
    def self.driver(module_name : String? = nil, role : Driver::Role? = nil)
      role = Generator.role unless role
      module_name = Faker::Hacker.noun unless module_name

      driver = Driver.new(
        name: RANDOM.base64(10),
        commit: RANDOM.hex(7),
        version: SemanticVersion.parse("1.1.1"),
        module_name: module_name,
      )
      driver.role = role
      driver
    end

    def self.role
      role_value = Driver::Role.names.sample(1).first
      Driver::Role.parse(role_value)
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

    def self.module(driver_role = nil, control_system = nil)
      driver_role = self.role if driver_role.nil?

      mod_name = Faker::Hacker.noun
      mod, driver = case driver_role
                    when Driver::Role::Logic
                      logic_mod = Module.new(custom_name: mod_name, uri: Faker::Internet.url)
                      logic_driver = Generator.driver(module_name: mod_name, role: driver_role)

                      {logic_mod, logic_driver}
                    when Driver::Role::Device
                      device_mod = Module.new(
                        custom_name: mod_name,
                        uri: Faker::Internet.url,
                        ip: Faker::Internet.ip_v4_address,
                        port: Random.rand((1..6555)),
                      )
                      device_driver = Generator.driver(module_name: mod_name, role: driver_role)

                      {device_mod, device_driver}
                    when Driver::Role::SSH
                      ssh_mod = Module.new(
                        custom_name: mod_name,
                        uri: Faker::Internet.url,
                        ip: Faker::Internet.ip_v4_address,
                        port: Random.rand((1..65_535)),
                      )
                      ssh_driver = Generator.driver(module_name: mod_name, role: driver_role)

                      {ssh_mod, ssh_driver}
                    else
                      # Driver::Role::Service
                      service_mod = Module.new(custom_name: mod_name, uri: Faker::Internet.url)
                      service_driver = Generator.driver(module_name: mod_name, role: driver_role)

                      {service_mod, service_driver}
                    end

      # Set driver
      mod.driver = driver.save!

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
