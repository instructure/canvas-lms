# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

class CreateTranslationFeedback < ActiveRecord::Migration[8.0]
  tag :predeploy

  def change
    create_table :translation_feedback do |t|
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.references :user, null: false, foreign_key: true
      t.references :context, polymorphic: %i[course], null: false, foreign_key: true
      t.references :content, polymorphic: %i[discussion_topic discussion_entry], null: false, foreign_key: true, index: false
      t.string :target_language, null: false, limit: 16
      t.boolean :liked, default: false, null: false
      t.boolean :disliked, default: false, null: false
      t.text :feedback_notes
      t.string :feature_slug, limit: 255
      t.timestamps

      t.replica_identity_index
      t.index %i[discussion_topic_id target_language user_id],
              unique: true,
              where: "discussion_topic_id IS NOT NULL",
              name: "index_translation_feedback_topic_uniqueness"
      t.index %i[discussion_entry_id target_language user_id],
              unique: true,
              where: "discussion_entry_id IS NOT NULL",
              name: "index_translation_feedback_entry_uniqueness"
      t.check_constraint "NOT (liked AND disliked)", name: "chk_translation_feedback_liked_disliked"
    end
  end
end
