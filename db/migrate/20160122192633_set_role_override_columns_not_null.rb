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

class SetRoleOverrideColumnsNotNull < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    RoleOverride.where(enabled: nil).preload(:context, :role).find_each do |ro|
      # can't simply set to false, since it was conflated with being for inheritance
      # in RoleOverride.permission_for
      ro.enabled = RoleOverride.enabled_for?(ro.context, ro.permission.to_sym, ro.role).include?(:self)
      ro.save!
    end

    RoleOverride.where(locked: nil).update_all(locked: false)

    change_column :role_overrides, :enabled, :bool, default: true, null: false
    change_column :role_overrides, :locked, :bool, default: false, null: false
  end

  def self.down
    change_column :role_overrides, :enabled, :bool, default: nil, null: true
    change_column :role_overrides, :locked, :bool, default: nil, null: true
  end
end
