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

module DataFixup::BackfillHorizonAccountIds
  def self.run
    Account.non_shadow.where("settings LIKE ?", "%horizon_account:%").find_each do |account|
      if account.settings.dig(:horizon_account, :value)
        root_account = account.root_account.reload
        horizon_account_ids = Set.new(root_account.settings[:horizon_account_ids] || [])
        horizon_account_ids.add(account.id)
        root_account.settings[:horizon_account_ids] = horizon_account_ids.to_a
        root_account.save!
      end
    end
  end
end
