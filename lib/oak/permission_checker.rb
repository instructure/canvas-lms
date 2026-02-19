# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module Oak
  class PermissionChecker
    def self.user_permitted?(user, root_account)
      return false unless user && root_account

      # Legacy check, scheduled for removal after Ignite Agent is publicly released
      if root_account.feature_enabled?(:ignite_agent_enabled)
        return true if root_account.grants_right?(user, :manage_account_settings)
        return true if user.feature_enabled?(:ignite_agent_enabled_for_user)
      end
      # End legacy check

      return true if root_account.feature_enabled?(:oak_for_admins) &&
                     root_account.grants_right?(user, :access_oak)
      return true if root_account.feature_enabled?(:oak_for_teachers) &&
                     user.all_courses
                         .where(root_account:)
                         .first&.grants_right?(user, :access_oak_teacher)

      false
    end
  end
end
