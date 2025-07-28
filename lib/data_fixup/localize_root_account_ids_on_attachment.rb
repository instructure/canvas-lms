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

module DataFixup::LocalizeRootAccountIdsOnAttachment
  def self.run
    upper_bounds = Shard.current.id * Shard::IDS_PER_SHARD
    lower_bounds = (Shard.current.id + 1) * Shard::IDS_PER_SHARD
    Attachment.where(root_account_id: upper_bounds...lower_bounds).find_ids_in_batches do |batch|
      Attachment.where(id: batch).update_all("root_account_id=root_account_id%#{Shard::IDS_PER_SHARD}")
      sleep Setting.get("localize_data_fixup_sleep_time", "0.1").to_f
    end
  end
end
