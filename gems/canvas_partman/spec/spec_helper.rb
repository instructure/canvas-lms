begin
  require '../../spec/coverage_tool.rb'
  CoverageTool.start('canvas-partman-gem')
rescue LoadError => e
  puts "Error: #{e} "
end

module CanvasPartmanTest
end

require 'active_record'
require 'canvas_partman'
require 'support/active_record'
require 'support/schema_helper'
require 'fixtures/zoo'
require 'fixtures/animal'

if RUBY_VERSION =~ /^1.9/
  require 'debugger'
elsif RUBY_VERSION =~ /^2/
  require 'byebug'
end

RSpec.configure do |config|
  Zoo = CanvasPartmanTest::Zoo
  Animal = CanvasPartmanTest::Animal

  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.color = true
  config.order = 'random'

  def connection
    ActiveRecord::Base.connection
  end

  def count_records(table_name)
    pg_result = ActiveRecord::Base.connection.select_value <<-SQL
      SELECT  COUNT(*)
        FROM  #{table_name}
    SQL

    pg_result.to_i
  end

  config.before :all do
    [ Zoo, Animal ].each(&:create_schema)
  end

  config.after :all do
    [ Zoo, Animal ].each(&:drop_schema)
  end

  config.after :each do
    connection.tables.grep(/^partman_animals_/).each do |partition_table_name|
      begin
        SchemaHelper.drop_table(partition_table_name)
      rescue Exception => e
        puts "[WARN] Partition table dropping failed: #{e.message}"
      end
    end
  end
end