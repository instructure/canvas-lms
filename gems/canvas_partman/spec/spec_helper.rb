# frozen_string_literal: true

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
#

begin
  require "debug"
rescue LoadError
  # do nothing if its not available
end

begin
  require "../../spec/coverage_tool"
  CoverageTool.start("canvas-partman-gem")
rescue LoadError => e
  puts "Error: #{e} "
end

module CanvasPartmanTest
end

require "active_record"
require "rails/version"
require "canvas_partman"

require "uri"
ActiveRecord::Base.establish_connection(ENV.fetch("DATABASE_URL", nil))
# we need to ensure this callback is called for active_record-pg_extensions,
# which isn't running because we're not using Rails to setup the database
ActiveRecord::PGExtensions::Railtie.run_initializers
require "support/schema_helper"
require "fixtures/zoo"
require "fixtures/animal"
require "fixtures/trail"
require "fixtures/week_event"

Zoo = CanvasPartmanTest::Zoo
Animal = CanvasPartmanTest::Animal
Trail = CanvasPartmanTest::Trail
WeekEvent = CanvasPartmanTest::WeekEvent

RSpec.configure do |config|
  config.color = true
  config.order = :random

  def connection
    ActiveRecord::Base.connection
  end

  def count_records(table_name)
    pg_result = ActiveRecord::Base.connection.select_value <<~SQL.squish
      SELECT  COUNT(*)
        FROM  #{table_name}
    SQL

    pg_result.to_i
  end

  config.before :all do
    [Zoo, Animal, Trail, WeekEvent].each(&:create_schema)
  end

  config.after :all do
    [Animal, Trail, Zoo, WeekEvent].each(&:drop_schema)
  end

  config.after do
    connection.tables.grep(/^partman_(?:animals|trails)_/).each do |partition_table_name|
      SchemaHelper.drop_table(partition_table_name)
    rescue => e
      puts "[WARN] Partition table dropping failed: #{e.message}"
    end
  end
end
