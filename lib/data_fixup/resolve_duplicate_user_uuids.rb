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

module DataFixup::ResolveDuplicateUserUuids
  # the first user in this order will keep their UUID
  # prefer non-deleted, non-shadow, and then most recently updated
  ORDER_SQL = <<~SQL.squish.freeze
    CASE WHEN workflow_state<>'deleted' THEN 0 ELSE 1 END,
    CASE WHEN id<#{::Switchman::Shard::IDS_PER_SHARD} THEN 0 ELSE 1 END,
    updated_at DESC
  SQL

  def self.run(modify_non_deleted_users: false, column: :uuid)
    dup_uuids = User.where.not(column => nil).group(column).having("count(*)>1").pluck(column)
    dup_uuids.each do |uuid|
      canonical_user_id = User.where(column => uuid).order(Arel.sql(ORDER_SQL)).pick(:id)
      update_scope = User.where(column => uuid).where("id<>?", canonical_user_id) # intentionally avoiding switchman magic
      update_scope = update_scope.where(workflow_state: "deleted") unless modify_non_deleted_users
      update_scope.in_batches.update_all(column => nil) # will be regenerated on demand if/when user is undeleted
    end
  end
end
