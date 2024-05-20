# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module DataFixup::PopulateRootAccountIdsOnCommunicationChannels
  def self.populate(min, max)
    CommunicationChannel.find_ids_in_ranges(start_at: min, end_at: max) do |batch_min, batch_max|
      scope = CommunicationChannel.where(id: batch_min..batch_max, root_account_ids: nil)

      # First handle non-cross-shard users (code adapted from
      # PopulateRootAccountIdOnModels.populate_root_account_ids())
      scope.non_shadow
           .joins(:user)
           .update_all("root_account_ids = users.root_account_ids")

      # the root account ids
      scope.shadow.joins(:user).find_each do |cc|
        cc.user.delay_if_production(max_attempts: User::MAX_ROOT_ACCOUNT_ID_SYNC_ATTEMPTS).update_root_account_ids
      end
    end
  end
end
