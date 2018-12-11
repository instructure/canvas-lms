#
# Copyright (C) 2018 - present Instructure, Inc.
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

class CanvasPartmanTest::WeekEvent < ActiveRecord::Base
  include CanvasPartman::Concerns::Partitioned
  self.partitioning_strategy = :by_date
  self.partitioning_interval = :weeks

  self.table_name = 'partman_week_events'

  def self.create_schema
    self.drop_schema

    CanvasPartmanTest::SchemaHelper.create_table(self.table_name.to_sym) do |t|
      t.datetime :created_at
    end
  end

  def self.drop_schema
    CanvasPartmanTest::SchemaHelper.drop_table(self.table_name.to_sym, cascade: true)
  end
end
