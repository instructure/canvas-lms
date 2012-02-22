#
# Copyright (C) 2011 Instructure, Inc.
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

class InstallCustomFields < ActiveRecord::Migration
  def self.up
    create_table :custom_fields, :force => true do |t|
      t.string  :name
      t.string  :description

      t.string  :field_type
      t.string  :default_value

      t.string  :scoper_type
      t.integer :scoper_id, :limit => 8

      t.string  :target_type

      t.timestamps
    end
    add_index :custom_fields, %w(scoper_type scoper_id target_type name), :name => "custom_field_lookup"

    create_table :custom_field_values, :force => true do |t|
      t.integer :custom_field_id, :limit => 8
      t.string  :value

      t.string  :customized_type
      t.integer :customized_id, :limit => 8

      t.timestamps
    end
  end

  def self.down
    drop_table :custom_field_values
    drop_table :custom_fields
  end
end
