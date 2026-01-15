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

module DataFixup
  module BackfillGranularProfileAccountSettings
    def self.run
      Account.root_accounts.active.non_shadow.find_each do |account|
        next if account.settings.key?(:users_can_edit_bio) || account.settings.key?(:users_can_edit_profile_links) || account.settings.key?(:users_can_edit_title)

        can_edit_profile = account.settings[:users_can_edit_profile]
        can_edit_name = account.settings[:users_can_edit_name]
        account.settings[:users_can_edit_bio] = can_edit_profile
        account.settings[:users_can_edit_profile_links] = can_edit_profile
        # original permission check was for editing names
        # via both API and UI, the field "title" is only accessible if the user can edit profile
        # which is why we check both fields before assigning the default here
        account.settings[:users_can_edit_title] = can_edit_profile && can_edit_name
        account.save!
      end
    end
  end
end
