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

class CreateCustomData < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :custom_data do |t|
      t.text :data
      t.string :namespace
      t.references :user, :limit => 8
      t.timestamps null: true
    end
  end

  def self.down
    drop_table :custom_data
  end
end
