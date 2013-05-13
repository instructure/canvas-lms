def in_memory_database?
  Rails.env.test? and
    ENV["IN_MEMORY_DB"] and
    Rails::Configuration.new.database_configuration.has_key?('test-in-memory') and
    Rails::Configuration.new.database_configuration['test-in-memory']['database'] == ':memory:'
end

if in_memory_database?
  ActiveRecord::Base.establish_connection(Rails::Configuration.new.database_configuration['test-in-memory'])
  load "#{Rails.root}/db/schema.rb"
end
