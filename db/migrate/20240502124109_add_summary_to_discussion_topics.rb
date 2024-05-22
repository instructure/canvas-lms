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

class AddSummaryToDiscussionTopics < ActiveRecord::Migration[7.0]
  tag :predeploy

  def change
    create_table :discussion_topic_summaries do |t|
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.replica_identity_index
      t.references :discussion_topic, null: false, foreign_key: true, index: { name: "index_summaries_on_topic_id" }
      t.string :llm_config_version, null: false, limit: 255
      t.string :dynamic_content_hash, null: false, limit: 255
      t.timestamps
      t.text :summary
      t.integer :input_tokens
      t.integer :output_tokens
      t.float :generation_time

      t.index %i[discussion_topic_id llm_config_version dynamic_content_hash], name: "index_summaries_on_topic_id_and_llm_config_version_and_hash"
      t.index %i[discussion_topic_id created_at], name: "index_summaries_on_topic_id_and_created_at", order: { created_at: :desc }
    end

    create_table :discussion_topic_summary_feedback do |t|
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.replica_identity_index
      t.references :discussion_topic_summary, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true
      t.boolean :liked, default: false, null: false
      t.boolean :disliked, default: false, null: false
      t.boolean :regenerated, null: false, default: false
      t.boolean :summary_disabled, null: false, default: false
      t.timestamps

      t.index %i[discussion_topic_summary_id user_id], unique: true, name: "index_feedback_on_summary_id_and_user_id"

      t.check_constraint "NOT (liked AND disliked)"
    end
  end
end
