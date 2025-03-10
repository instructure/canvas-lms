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
    Attachment.where(root_account_id: Shard::IDS_PER_SHARD..).in_batches(strategy: :pluck_ids) do |batch|
      update_me = Hash.new { |h, k| h[k] = Set.new }

      batch.each do |attachment|
        root_id = attachment.attributes["root_account_id"]
        local_id, shard = Shard.local_id_for(root_id)
        update_me[local_id] << attachment.id if shard == Shard.current
      end

      update_me.each do |local_id, attachment_ids|
        Attachment.where(id: attachment_ids).update_all("root_account_id=#{local_id}")
      end
    end
  end
end
