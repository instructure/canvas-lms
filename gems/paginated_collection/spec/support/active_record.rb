require 'active_record'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define(version: 1) do
  create_table :examples, force: true
end