# frozen_string_literal: true

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

class RemoveDiscussionEntryDrafts < ActiveRecord::Migration[8.0]
  tag :postdeploy

  def up
    drop_table :discussion_entry_drafts, if_exists: true
  end

  def down
    create_table :discussion_entry_drafts do |t|
      t.references :discussion_topic, null: false, foreign_key: true
      t.references :discussion_entry, foreign_key: true, index: false
      t.references :root_entry, foreign_key: { to_table: :discussion_entries }
      t.references :parent, foreign_key: { to_table: :discussion_entries }
      t.references :attachment, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :message
      t.boolean :include_reply_preview, null: false, default: false
      t.timestamps precision: 6

      t.index %i[discussion_topic_id user_id],
              name: "unique_index_on_topic_and_user",
              where: "discussion_entry_id IS NULL AND root_entry_id IS NULL",
              unique: true
      t.index %i[root_entry_id user_id],
              name: "unique_index_on_root_entry_and_user",
              where: "discussion_entry_id IS NULL",
              unique: true
      t.index %i[discussion_entry_id user_id],
              name: "unique_index_on_entry_and_user",
              unique: true
    end
  end
end
