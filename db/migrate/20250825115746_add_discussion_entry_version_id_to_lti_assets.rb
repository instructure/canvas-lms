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

class AddDiscussionEntryVersionIdToLtiAssets < ActiveRecord::Migration[7.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_reference :lti_assets,
                  :discussion_entry_version,
                  foreign_key: { on_delete: :nullify },
                  if_not_exists: true,
                  null: true,
                  index: {
                    unique: true,
                    where: "discussion_entry_version_id IS NOT NULL",
                    name: "index_lti_assets_unique_discussion_entry_version_id",
                    algorithm: :concurrently,
                    if_not_exists: true
                  }
  end

  def down
    remove_reference :lti_assets,
                     :discussion_entry_version,
                     foreign_key: true,
                     index: { name: "index_lti_assets_unique_discussion_entry_version_id", if_exists: true },
                     if_exists: true
  end
end
