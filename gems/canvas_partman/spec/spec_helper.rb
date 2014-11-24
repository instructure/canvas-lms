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

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.color = true
  config.order = 'random'

  def find_table_constraints(table_name)
    pg_result = ActiveRecord::Base.connection.execute <<-SQL
      SELECT  *
      FROM    information_schema.table_constraints
      WHERE   table_name='#{table_name}'
    SQL

    pg_result.to_a
  end

  def find_index(opts)
    pg_result = ActiveRecord::Base.connection.execute <<-SQL
      SELECT  *
      FROM    pg_indexes
      WHERE   tablename='#{opts[:table]}' AND indexname='#{opts[:name]}'
    SQL

    pg_result.to_a.first
  end

  def find_records(opts)
    pg_result = ActiveRecord::Base.connection.execute <<-SQL
      SELECT  *
      FROM    #{opts[:table]}
    SQL

    pg_result.to_a
  end

  def find_tables(prefix)
    pg_result = ActiveRecord::Base.connection.execute <<-SQL
      SELECT  table_name FROM information_schema.tables
        WHERE table_schema='public'
        AND   table_name LIKE '#{prefix}%'
    SQL

    pg_result.to_a.map(&:values).flatten
  end

  config.after :each do
    find_tables('partman_animals_').each do |partition_table_name|
      begin
        SchemaHelper.drop_table(partition_table_name)
      rescue Exception => e
        puts "[WARN] Partition table dropping failed: #{e.message}"
      end
    end
  end
end