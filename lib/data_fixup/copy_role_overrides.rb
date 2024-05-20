# frozen_string_literal: true

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

module DataFixup::CopyRoleOverrides
  def self.run(old_permission, new_permission)
    RoleOverride.where(permission: old_permission.to_s).find_in_batches do |old_role_overrides|
      possible_new_role_overrides = RoleOverride.where(permission: new_permission.to_s, context_id: old_role_overrides.map(&:context_id)).to_a

      old_role_overrides.each do |old_role_override|
        next if old_role_override.invalid? || possible_new_role_overrides.detect do |ro|
          ro.context_id == old_role_override.context_id &&
          ro.context_type == old_role_override.context_type &&
          ro.role_id == old_role_override.role_id
        end

        dup = RoleOverride.new
        old_role_override.attributes.except("id", "permission", "created_at", "updated_at").each do |key, val|
          dup.send(:"#{key}=", val)
        end
        dup.permission = new_permission.to_s
        dup.save!
      end
    end
  end
end
