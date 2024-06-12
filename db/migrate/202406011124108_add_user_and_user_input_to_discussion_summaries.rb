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

class AddUserAndUserInputToDiscussionSummaries < ActiveRecord::Migration[7.0]
  tag :predeploy
  disable_ddl_transaction!

  def up
    change_table :discussion_topic_summaries, bulk: true do |t|
      t.references :user, foreign_key: true, index: { algorithm: :concurrently, if_not_exists: true }, if_not_exists: true
      t.string :user_input, if_not_exists: true, limit: 255
      t.remove_index name: "index_summaries_for_lookup", if_exists: true
      t.index %i[discussion_topic_id llm_config_version dynamic_content_hash parent_id created_at], name: "index_summaries_for_lookup", algorithm: :concurrently, if_not_exists: true, order: { created_at: :desc }
    end
  end

  def down
    change_table :discussion_topic_summaries, bulk: true do |t|
      t.remove_references :user
      t.remove :user_input
      t.remove_index name: "index_summaries_for_lookup", if_exists: true
      t.index %i[discussion_topic_id llm_config_version dynamic_content_hash parent_id locale created_at], name: "index_summaries_for_lookup", algorithm: :concurrently, if_not_exists: true, order: { created_at: :desc }
    end
  end
end
