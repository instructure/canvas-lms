#
# Copyright (C) 2017 - present Instructure, Inc.
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
#

class AddForeignKeyIndexes10 < ActiveRecord::Migration[5.0]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :account_notifications, :user_id, algorithm: :concurrently
    add_index :account_reports, :user_id, algorithm: :concurrently
    add_index :content_exports, :user_id, where: "user_id IS NOT NULL", algorithm: :concurrently
    add_index :content_migrations, :user_id, where: "user_id IS NOT NULL", algorithm: :concurrently
    add_index :content_participations, :user_id, algorithm: :concurrently
    add_index :custom_gradebook_column_data, :user_id, algorithm: :concurrently
    add_index :discussion_entries, :editor_id, where: "editor_id IS NOT NULL", algorithm: :concurrently
    add_index :discussion_entry_participants, :user_id, algorithm: :concurrently
    add_index :discussion_topic_participants, :user_id, algorithm: :concurrently
    add_index :discussion_topics, :editor_id, where: "editor_id IS NOT NULL", algorithm: :concurrently
    add_index :external_feed_entries, :user_id, where: "user_id IS NOT NULL", algorithm: :concurrently
    add_index :external_feeds, :user_id, where: "user_id IS NOT NULL", algorithm: :concurrently
    add_index :gradebook_uploads, :user_id, algorithm: :concurrently
    add_index :grading_standards, :user_id, where: "user_id IS NOT NULL", algorithm: :concurrently
    add_index :groups, :leader_id, where: "leader_id IS NOT NULL", algorithm: :concurrently
    add_index :ignores, :user_id, algorithm: :concurrently
    add_index :live_assessments_results, :user_id, algorithm: :concurrently
    add_index :live_assessments_submissions, :user_id, algorithm: :concurrently
    add_index :media_objects, :user_id, where: "user_id IS NOT NULL", algorithm: :concurrently
    add_index :moderated_grading_provisional_grades, :scorer_id, algorithm: :concurrently
    add_index :oauth_requests, :user_id, where: "user_id IS NOT NULL", algorithm: :concurrently
    add_index :page_views, :real_user_id, where: "real_user_id IS NOT NULL", algorithm: :concurrently
    add_index :planner_overrides, :user_id, algorithm: :concurrently
    add_index :purgatories, :deleted_by_user_id, algorithm: :concurrently
    add_index :quiz_regrades, :user_id, algorithm: :concurrently
    add_index :sis_batches, :user_id, where: "user_id IS NOT NULL", algorithm: :concurrently
    add_index :user_notes, :created_by_id, algorithm: :concurrently
    add_index :user_profiles, :user_id, algorithm: :concurrently
  end
end
