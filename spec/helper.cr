require "spec"
require "faker"
require "random"
require "rethinkdb-orm"

require "./generator"

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

# Pretty prints document errors
def inspect_error(error : RethinkORM::Error::DocumentInvalid)
  errors = error.model.errors.map do |e|
    {
      field:   e.field,
      message: e.message,
    }
  end
  pp! errors
end
