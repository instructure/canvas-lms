# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module DataFixup::PopulateRootAccountIdsOnStudentViewUsers
  def self.run
    User.where(root_account_ids: []).where("preferences like ?", "%fake_student%").find_in_batches do |group|
      # In theory preferences could have fake_student = false, so do the actual check on the rails side to
      # look at what we want
      group.select(&:fake_student?).each do |user|
        user.delay_if_production(max_attempts: User::MAX_ROOT_ACCOUNT_ID_SYNC_ATTEMPTS).update_root_account_ids
      end
    end
  end
end
