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

class AddParentAndLocaleToDiscussionSummaries < ActiveRecord::Migration[7.0]
  tag :predeploy
  disable_ddl_transaction!

  def up
    change_table :discussion_topic_summaries, bulk: true do |t|
      t.references :parent, foreign_key: { to_table: :discussion_topic_summaries }, index: { algorithm: :concurrently, if_not_exists: true }, if_not_exists: true
      t.string :locale, if_not_exists: true
      t.index %i[discussion_topic_id llm_config_version dynamic_content_hash parent_id locale created_at], name: "index_summaries_for_lookup", algorithm: :concurrently, if_not_exists: true, order: { created_at: :desc }
      t.remove_index name: "index_summaries_on_topic_id_and_llm_config_version_and_hash", if_exists: true
      t.remove_index name: "index_summaries_on_topic_id_and_created_at", if_exists: true
    end
  end

  def down
    change_table :discussion_topic_summaries, bulk: true do |t|
      t.remove_index name: "index_summaries_for_lookup", if_exists: true
      t.remove_references :parent
      t.remove :locale
      t.index %i[discussion_topic_id llm_config_version dynamic_content_hash], name: "index_summaries_on_topic_id_and_llm_config_version_and_hash", algorithm: :concurrently, if_not_exists: true
      t.index [:discussion_topic_id, :created_at], name: "index_summaries_on_topic_id_and_created_at", order: { created_at: :desc }, algorithm: :concurrently, if_not_exists: true
    end
  end
end
