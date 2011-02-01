$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'spec'
require 'active_record'
require 'delayed_job'

logger = Logger.new('/tmp/dj.log')
ActiveRecord::Base.logger = logger
Delayed::Worker.logger = logger
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do

  create_table :delayed_jobs, :force => true do |table|
    table.integer  :priority, :default => 0
    table.integer  :attempts, :default => 0
    table.text     :handler
    table.text     :queue, :default => nil
    table.string   :last_error
    table.datetime :run_at
    table.datetime :locked_at
    table.string   :locked_by
    table.datetime :failed_at
    table.timestamps
  end

  create_table :stories, :force => true do |table|
    table.string :text
  end

end

# Purely useful for test cases...
class Story < ActiveRecord::Base
  def tell; text; end       
  def whatever(n, _); tell*n; end
  def whatever_else(n, _); tell*n; end
  
  handle_asynchronously :whatever
  handle_asynchronously_with_queue :whatever_else, "testqueue"
end

Delayed::Worker.cant_fork = true

require 'sample_jobs'
require 'shared_backend_spec'
