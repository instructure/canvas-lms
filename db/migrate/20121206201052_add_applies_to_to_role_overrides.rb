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

class AddAppliesToToRoleOverrides < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :role_overrides, :applies_to_self, :boolean, :default => true, :null => false
    add_column :role_overrides, :applies_to_descendants, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :role_overrides, :applies_to_self, :applies_to_descendants
  end
end
