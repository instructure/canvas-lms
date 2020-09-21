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

module DataFixup
  module ClearOldCommunicationChannelRootAccountIds
    # Gets rid of old filled root_account_ids so the backfill can fill them properly.
    # Loosely based on DataFixup::BackfillNulls
    def self.run
      CommunicationChannel.find_ids_in_ranges(batch_size: 1000) do |start_id, end_id|
        CommunicationChannel.where(id: start_id..end_id).
          where.not(root_account_ids: nil).
          update_all(root_account_ids: nil)
      end
    end
  end
end
