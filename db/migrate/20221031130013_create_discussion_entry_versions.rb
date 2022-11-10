# frozen_string_literal: true

# Copyright (C) 2022 - present Instructure, Inc.
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

class CreateDiscussionEntryVersions < ActiveRecord::Migration[6.1]
  tag :predeploy

  def change
    create_table :discussion_entry_versions do |t|
      t.references :discussion_entry, null: false, foreign_key: true, index: false
      t.references :root_account, foreign_key: { to_table: :accounts }, null: false, index: false
      t.references :user, null: true, foreign_key: true, index: true
      t.integer :version, limit: 8
      t.text :message
      t.timestamps
    end

    reversible do |dir|
      dir.up { add_replica_identity "DiscussionEntryVersion", :root_account_id }
      dir.down { remove_replica_identity "DiscussionEntryVersion" }
    end
  end
end
