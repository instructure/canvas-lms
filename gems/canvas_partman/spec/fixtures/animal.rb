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

class CanvasPartmanTest::Animal < ActiveRecord::Base
  include CanvasPartman::Concerns::Partitioned

  self.table_name = 'partman_animals'

  belongs_to :zoo, class_name: 'CanvasPartmanTest::Zoo'

  def self.create_schema
    self.drop_schema

    CanvasPartmanTest::SchemaHelper.create_table :partman_animals do |t|
      t.string :race
      t.datetime :created_at
      t.references :zoo
      t.foreign_key :partman_zoos, column: :zoo_id
    end
  end

  def self.drop_schema
    CanvasPartmanTest::SchemaHelper.drop_table :partman_animals, cascade: true
  end
end
