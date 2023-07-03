# frozen_string_literal: true

# Copyright (C) 2023 - present Instructure, Inc.
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

class AddMissingFkIndexes4 < ActiveRecord::Migration[7.0]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    # rubocop:disable Migration/Predeploy
    add_index :abstract_courses, :account_id, algorithm: :concurrently, if_not_exists: true
    # We have a poorly named index (index_account_notification_roles_on_role_id) that is actually on (account_notification_id, role_id)
    add_index :account_notification_roles, :role_id, name: "index_account_notification_roles_only_on_role_id", where: "role_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :account_users, :role_id, algorithm: :concurrently, if_not_exists: true
    add_index :accounts, :latest_outcome_import_id, where: "latest_outcome_import_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :alert_criteria, :alert_id, where: "alert_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :anonymous_or_moderation_events, :context_external_tool_id, name: "index_ame_on_context_external_tool_id", where: "context_external_tool_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :assignment_groups, :cloned_item_id, where: "cloned_item_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :assignments, :cloned_item_id, where: "cloned_item_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :attachments, :usage_rights_id, where: "usage_rights_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :auditor_grade_change_records, :grading_period_id, where: "grading_period_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :calendar_events, :cloned_item_id, where: "cloned_item_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :conditional_release_assignment_set_associations, :assignment_id, name: "index_crasa_on_assignment_id", where: "assignment_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :conditional_release_assignment_set_associations, :assignment_set_id, name: "index_crasa_on_assignment_set_id", where: "assignment_set_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :conditional_release_assignment_sets, :scoring_range_id, name: "index_conditional_release_assignment_sets_on_scoring_range_id", algorithm: :concurrently, if_not_exists: true
    add_index :conditional_release_scoring_ranges, :rule_id, name: "index_conditional_release_scoring_ranges_on_rule_id", algorithm: :concurrently, if_not_exists: true
    add_index :content_migrations, :asset_map_attachment_id, where: "asset_map_attachment_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :content_shares, :sender_id, where: "sender_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :content_tags, :cloned_item_id, where: "cloned_item_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :context_external_tools, :cloned_item_id, where: "cloned_item_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :context_modules, :cloned_item_id, where: "cloned_item_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :courses, :latest_outcome_import_id, where: "latest_outcome_import_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :discussion_topics, :cloned_item_id, where: "cloned_item_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :grading_period_groups, :root_account_id, where: "root_account_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :group_and_membership_importers, :attachment_id, where: "attachment_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :live_assessments_results, :assessor_id, algorithm: :concurrently, if_not_exists: true
    add_index :lti_product_families, :root_account_id, algorithm: :concurrently, if_not_exists: true
    add_index :lti_resource_placements, :message_handler_id, where: "message_handler_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :lti_tool_proxies, :product_family_id, algorithm: :concurrently, if_not_exists: true
    add_index :lti_tool_proxy_bindings, :tool_proxy_id, algorithm: :concurrently, if_not_exists: true
    add_index :polling_poll_submissions, :poll_id, algorithm: :concurrently, if_not_exists: true
    add_index :quiz_regrade_runs, :quiz_regrade_id, algorithm: :concurrently, if_not_exists: true
    add_index :quizzes, :cloned_item_id, where: "cloned_item_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :report_snapshots, :account_id, where: "account_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :role_overrides, :role_id, algorithm: :concurrently, if_not_exists: true
    add_index :rubrics, :rubric_id, where: "rubric_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :scores, :grading_period_id, where: "grading_period_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :submissions, :media_object_id, where: "media_object_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :switchman_shards, :delayed_jobs_shard_id, where: "delayed_jobs_shard_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :user_profile_links, :user_profile_id, where: "user_profile_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    add_index :wiki_pages, :cloned_item_id, where: "cloned_item_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true
    # rubocop:enable Migration/Predeploy
  end
end
