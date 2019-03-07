require "spec"
require "faker"
require "random"

require "../src/engine-models/*"
require "../src/engine-models/**"

def fake_dependency
  random_role_value = Engine::Model::Dependency::Role.values.sample(1).first
  random_role = Engine::Model::Dependency::Role.from_value(random_role_value)
  Engine::Model::Dependency.new(
    name: Faker::Hacker.noun,
    class_name: Faker::Hacker.noun,
    module_name: Faker::Hacker.noun,
    role: random_role,
  )
end

def fake_module
  mod = Engine::Model::Module.new(
    ip: Faker::Internet.ip_v4_address,
    port: Random.rand(65535),
  )
  mod.dependency = fake_dependency
  mod.control_system = fake_control_system
  mod
end

def fake_control_system
  Engine::Model::ControlSystem.new(
    name: Faker::Hacker.noun
  )
end
