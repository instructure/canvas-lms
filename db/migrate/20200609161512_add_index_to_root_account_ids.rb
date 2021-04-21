# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

class AddIndexToRootAccountIds < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  # I know this is a lot of indexes in one migration, but since they are itempotent
  # this simplifies their addition
  def up
    add_index :wikis, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :wiki_pages, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :rubrics, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :rubric_associations, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :rubric_assessments, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :master_courses_migration_results, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :master_courses_master_templates, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :master_courses_master_content_tags, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :quizzes, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :quiz_questions, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :quiz_groups, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :quiz_submissions, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :assessment_question_banks, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :assessment_questions, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :master_courses_child_subscriptions, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :content_tags, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :developer_key_account_bindings, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :developer_keys, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :lti_resource_links, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :lti_results, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :originality_reports, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :master_courses_child_content_tags, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :discussion_topic_participants, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :course_account_associations, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :context_modules, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :context_module_progressions, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :content_participations, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :content_participation_counts, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :lti_line_items, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :content_migrations, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :attachment_associations, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :assignment_override_students, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :assignment_overrides, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :assignment_groups, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :submission_versions, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :submission_comments, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :score_statistics, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :scores, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :grading_periods, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :post_policies, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :late_policies, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :grading_standards, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :custom_gradebook_columns, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :learning_outcome_groups, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :custom_gradebook_column_data, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :master_courses_master_migrations, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :learning_outcomes, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :learning_outcome_question_results, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :learning_outcome_results, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :outcome_proficiencies, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :outcome_proficiency_ratings, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :account_users, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :enrollment_states, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :group_memberships, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :role_overrides, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :access_tokens, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :user_account_associations, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :discussion_entries, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :asset_user_accesses, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :attachments, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :content_shares, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :user_notes, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :calendar_events, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :folders, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :communication_channels, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :favorites, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :discussion_topics, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :discussion_entry_participants, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :web_conference_participants, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :web_conferences, :root_account_id, algorithm: :concurrently, if_not_exists: true
  end
end
