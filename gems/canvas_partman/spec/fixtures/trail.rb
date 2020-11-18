# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

class CanvasPartmanTest::Trail < ActiveRecord::Base
  include CanvasPartman::Concerns::Partitioned
  self.partitioning_strategy = :by_id
  self.partitioning_field = 'zoo_id'
  self.partition_size = 5

  self.table_name = 'partman_trails'

  belongs_to :zoo, class_name: 'CanvasPartmanTest::Zoo'

  def self.create_schema
    self.drop_schema

    CanvasPartmanTest::SchemaHelper.create_table :partman_trails do |t|
      t.string :name
      t.references :zoo
      t.foreign_key :partman_zoos, column: :zoo_id
    end
  end

  def self.drop_schema
    CanvasPartmanTest::SchemaHelper.drop_table :partman_trails, cascade: true
  end
end
