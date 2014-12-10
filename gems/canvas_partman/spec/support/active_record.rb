require 'yaml'

YAML.load_file('../../config/database.yml')['test'].tap do |creds|
  ActiveRecord::Base.establish_connection(creds)
end