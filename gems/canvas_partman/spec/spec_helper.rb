#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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
require 'fixtures/trail'
require 'fixtures/week_event'

require 'byebug'

RSpec.configure do |config|
  Zoo = CanvasPartmanTest::Zoo
  Animal = CanvasPartmanTest::Animal
  Trail = CanvasPartmanTest::Trail
  WeekEvent = CanvasPartmanTest::WeekEvent

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
    [ Zoo, Animal, Trail, WeekEvent ].each(&:create_schema)
  end

  config.after :all do
    [ Animal, Trail, Zoo, WeekEvent ].each(&:drop_schema)
  end

  config.after :each do
    connection.tables.grep(/^partman_(?:animals|trails)_/).each do |partition_table_name|
      begin
        SchemaHelper.drop_table(partition_table_name)
      rescue StandardError => e
        puts "[WARN] Partition table dropping failed: #{e.message}"
      end
    end
  end
end
