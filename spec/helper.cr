require "spec"
require "faker"
require "random"

require "rethinkdb-orm"

DB_NAME = "test_#{Time.now.to_unix}_#{rand(10000)}"
RethinkORM::Connection.configure do |settings|
  settings.db = DB_NAME
end

# Tear down the test database
at_exit do
  RethinkORM::Connection.raw do |q|
    q.db_drop(DB_NAME)
  end
end

require "../src/engine-models/*"
require "../src/engine-models/**"

RANDOM = Random.new(9966)

def new_dependency(module_name : String, role : Engine::Model::Dependency::Role)
  dep = Engine::Model::Dependency.new(
    name: Faker::Hacker.noun,
    commit: RANDOM.hex(7),
    version: SemanticVersion.parse("1.1.1"),
    module_name: module_name,
  )
  dep.role = role
  dep
end

def inspect_error(error : RethinkORM::Error::DocumentInvalid)
  errors = error.model.errors.map do |e|
    {
      field:   e.field,
      message: e.message,
    }
  end
  pp! errors
end

def new_control_system
  Engine::Model::ControlSystem.new(
    name: Faker::Hacker.noun,
  )
end

def new_zone
  Engine::Model::Zone.new(
    name: Faker::Hacker.noun,
  )
end

def fake_dependency
  random_role_value = Engine::Model::Dependency::Role.values.sample(1).first
  random_role = Engine::Model::Dependency::Role.from_value(random_role_value)
  new_dependency(module_name: Faker::Hacker.noun, role: random_role)
end
