#
# Copyright (C) 2013 - present Instructure, Inc.
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

class DropCustomFieldTables < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    # these tables may not have ever been created
    drop_table "custom_fields" if table_exists?("custom_fields")
    drop_table "custom_field_values" if table_exists?("custom_field_values")
  end

  def self.down
  end
end
