# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module DataFixup::PopulateRootAccountIdsForCommunicationChannels
  def self.run
    if Account.root_accounts.size == 1
      CommunicationChannel
        .where(root_account_ids: nil)
        .or(CommunicationChannel.where(root_account_ids: []))
        .in_batches(of: 10_000)
        .update_all(root_account_ids: [Account.root_accounts.take.id])
    else
      CommunicationChannel.where(root_account_ids: nil)
                          .or(CommunicationChannel.where(root_account_ids: []))
                          .find_ids_in_batches do |ids|
        CommunicationChannel.where(id: ids)
                            .joins(:user)
                            .where.not(users: { root_account_ids: nil })
                            .where.not(users: { root_account_ids: [] })
                            .update_all("root_account_ids=users.root_account_ids")
      end
    end
  end
end
