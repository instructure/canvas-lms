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
#

module DataFixup
  class DeleteOrphanedFeatureFlags
    def self.run
      FeatureFlag.joins("LEFT JOIN #{User.quoted_table_name} ON users.id = feature_flags.context_id AND feature_flags.context_type = 'User'")
                 .where(context_type: "User", users: { id: nil })
                 .in_batches
                 .delete_all

      FeatureFlag.joins("LEFT JOIN #{Course.quoted_table_name} ON courses.id = feature_flags.context_id AND feature_flags.context_type = 'Course'")
                 .where(context_type: "Course", courses: { id: nil })
                 .in_batches
                 .delete_all

      FeatureFlag.joins("LEFT JOIN #{Account.quoted_table_name} ON accounts.id = feature_flags.context_id AND feature_flags.context_type = 'Account'")
                 .where(context_type: "Account", accounts: { id: nil })
                 .in_batches
                 .delete_all
    end
  end
end
