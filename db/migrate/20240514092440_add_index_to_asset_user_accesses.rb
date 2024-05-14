# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

class AddIndexToAssetUserAccesses < ActiveRecord::Migration[7.0]
  # required when adding an index to an existing table
  disable_ddl_transaction!
  # indexes are typically added in Predeploy; however, to avoid blocking
  # deployments on a large table, we’re using a Postdeploy migration
  tag :postdeploy

  def change
    # add a partial index on the updated_at column for rows where context_type
    # is 'Group', optimizing queries filtering by this context
    # rubocop:disable Migration/Predeploy
    add_index :asset_user_accesses,
              :updated_at,
              name: "index_on_updated_at_for_group_context",
              where: "context_type = 'Group'",
              algorithm: :concurrently,
              # make the migration idempotent
              if_not_exists: true
    # rubocop:enable Migration/Predeploy
  end
end
