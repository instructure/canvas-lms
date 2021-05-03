# frozen_string_literal: true

# Copyright (C) 2021 - present Instructure, Inc.
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

class CreateMentions < ActiveRecord::Migration[6.0]
  tag :predeploy

  def up
    create_table :mentions do |t|
      t.references :discussion_entry, foreign_key: true, index: true, null: false
      t.references :user, foreign_key: true, index: true, null: false
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.string :workflow_state, default: "active", null: false, limit: 255
      t.timestamps
    end
    set_replica_identity(:microsoft_sync_groups, :index_microsoft_sync_groups_replica_identity)
  end

  def down
    drop_table :mentions
  end

end
