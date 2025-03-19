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

class CreateDiscussionTopicInsightEntries < ActiveRecord::Migration[7.1]
  tag :predeploy

  def change
    create_table :discussion_topic_insight_entries do |t|
      t.references :discussion_topic_insight, foreign_key: true, null: false
      t.references :discussion_topic, foreign_key: true, index: false, null: false
      t.references :discussion_entry, foreign_key: true, null: false
      t.references :discussion_entry_version, foreign_key: true, null: false
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false

      t.string :locale, null: false, limit: 255
      t.string :dynamic_content_hash, null: false, limit: 64

      t.jsonb :ai_evaluation, null: false, default: {}

      t.references :ai_evaluation_human_reviewer, foreign_key: { to_table: :users }
      t.boolean :ai_evaluation_human_feedback_liked, null: false, default: false
      t.boolean :ai_evaluation_human_feedback_disliked, null: false, default: false
      t.string :ai_evaluation_human_feedback_notes, null: false, default: "", limit: 1024

      t.replica_identity_index
      t.timestamps

      t.index %i[discussion_topic_id discussion_entry_id dynamic_content_hash], unique: true, name: "index_discussion_topic_insight_entries_lookup"
      t.index %i[discussion_topic_id locale discussion_entry_id created_at], order: { created_at: :desc }, name: "index_discussion_topic_insight_entries_latest"
    end
  end
end
