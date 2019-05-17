require "faker"

require "../src/engine-models/*"
require "../src/engine-models/**"

RANDOM = Random.new

module Engine::Model
  # Defines generators for models
  module Generator
    def self.driver(role : Driver::Role? = nil, module_name : String? = nil, repo : DriverRepo? = nil)
      role = self.role unless role
      repo = self.driver_repo.save! unless repo
      module_name = Faker::Hacker.noun unless module_name

      driver = Driver.new(
        name: RANDOM.base64(10),
        commit: RANDOM.hex(7),
        version: SemanticVersion.parse("1.1.1"),
        module_name: module_name,
      )

      driver.role = role
      driver.driver_repo = repo
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

    def self.trigger(system : ControlSystem? = nil)
      trigger = Trigger.new(
        name: Faker::Hacker.noun,
      )
      trigger.control_system = system if system
      trigger
    end

    def self.trigger_instance(trigger = nil, zone = nil, control_system = nil)
      trigger = self.trigger.save! unless trigger
      instance = TriggerInstance.new
      instance.trigger = trigger

      instance.zone = zone if zone
      instance.control_system = control_system if control_system

      instance
    end

    def self.control_system
      ControlSystem.new(
        name: RANDOM.base64(10),
      )
    end

    def self.module(driver = nil, control_system = nil)
      mod_name = Faker::Hacker.noun

      driver = Generator.driver(module_name: mod_name) if driver.nil?
      driver.save! unless driver.persisted?

      mod = case driver.role
            when Driver::Role::Logic
              Module.new(custom_name: mod_name, uri: Faker::Internet.url)
            when Driver::Role::Device
              Module.new(
                custom_name: mod_name,
                uri: Faker::Internet.url,
                ip: Faker::Internet.ip_v4_address,
                port: Random.rand((1..6555)),
              )
            when Driver::Role::SSH
              Module.new(
                custom_name: mod_name,
                uri: Faker::Internet.url,
                ip: Faker::Internet.ip_v4_address,
                port: Random.rand((1..65_535)),
              )
            else
              # Driver::Role::Service
              Module.new(custom_name: mod_name, uri: Faker::Internet.url)
            end

      # Set driver
      mod.driver = driver

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
