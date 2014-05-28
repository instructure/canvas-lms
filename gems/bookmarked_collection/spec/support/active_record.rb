require 'active_record'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define(version: 1) do
  create_table :examples, force: true do |t|
    t.string :state
    t.string :name
  end

  create_table :users, force: true do |t|
    t.string :name
  end
end