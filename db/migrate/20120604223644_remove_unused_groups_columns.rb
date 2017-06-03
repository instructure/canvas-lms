#
# Copyright (C) 2012 - present Instructure, Inc.
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

class RemoveUnusedGroupsColumns < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    remove_column :groups, :type
    remove_column :groups, :groupable_id
    remove_column :groups, :groupable_type
  end

  def self.down
    add_column :groups, :type, :string
    add_column :groups, :groupable_id, :integer, :limit => 8
    add_column :groups, :groupable_type, :string
  end
end
