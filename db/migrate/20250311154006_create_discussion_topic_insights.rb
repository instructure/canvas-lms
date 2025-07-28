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

class CreateDiscussionTopicInsights < ActiveRecord::Migration[7.1]
  tag :predeploy

  def change
    create_table :discussion_topic_insights do |t|
      t.references :discussion_topic, foreign_key: true, index: false, null: false
      t.references :user, foreign_key: true, null: false
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.string :workflow_state, null: false, default: "created"
      t.timestamps
      t.replica_identity_index

      t.index %i[discussion_topic_id created_at], order: { created_at: :desc }, name: "index_discussion_topic_insights_latest"
    end
  end
end
