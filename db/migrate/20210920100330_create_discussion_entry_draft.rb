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

class CreateDiscussionEntryDraft < ActiveRecord::Migration[6.0]
  tag :predeploy

  def change
    create_table :discussion_entry_drafts do |t|
      t.references :discussion_topic, null: false, foreign_key: true, index: true
      t.references :discussion_entry, null: true, foreign_key: true, index: false
      t.references :root_entry, foreign_key: { to_table: 'discussion_entries' }, null: true, index: true
      t.references :parent, foreign_key: { to_table: 'discussion_entries' }, null: true, index: true
      t.references :attachment, null: true, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.text :message
      t.boolean :include_reply_preview, null: false, default: false
      t.timestamps
      t.index %i(discussion_topic_id user_id),
              name: 'unique_index_on_topic_and_user',
              where: 'discussion_entry_id IS NULL AND root_entry_id IS NULL',
              unique: true
      t.index %i(root_entry_id user_id),
              name: 'unique_index_on_root_entry_and_user',
              where: 'discussion_entry_id IS NULL',
              unique: true
      t.index %i(discussion_entry_id user_id),
              name: 'unique_index_on_entry_and_user',
              unique: true
    end
  end
end
