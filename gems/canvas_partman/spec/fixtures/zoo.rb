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

class CanvasPartmanTest::Zoo < ActiveRecord::Base
  self.table_name = 'partman_zoos'

  has_many :animals,
    class_name: 'CanvasPartmanTest::Animal',
    dependent: :destroy

  has_many :trails,
           class_name: 'CanvasPartmanTest::Trail',
           dependent: :destroy

  def self.create_schema
    self.drop_schema

    SchemaHelper.create_table :partman_zoos do |t|
      t.timestamps null: false
    end
  end

  def self.drop_schema
    SchemaHelper.drop_table :partman_zoos
  end
end
