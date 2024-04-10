# frozen_string_literal: true

#
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

class SetReplicaIdentities < ActiveRecord::Migration[7.0]
  tag :predeploy

  def up
    return if connection.index_exists?(:content_tags, replica_identity: true)

    set_replica_identity :access_tokens
    set_replica_identity :account_users
    set_replica_identity :accounts
    set_replica_identity :asset_user_accesses
    set_replica_identity :blackout_dates
    set_replica_identity :comment_bank_items
    set_replica_identity :content_tags
    set_replica_identity :context_external_tools
    set_replica_identity :course_account_associations
    set_replica_identity :course_pace_module_items
    set_replica_identity :course_paces
    set_replica_identity :course_sections
    set_replica_identity :courses
    set_replica_identity :custom_grade_statuses
    set_replica_identity :developer_key_account_bindings
    set_replica_identity :developer_keys
    set_replica_identity :discussion_entries
    set_replica_identity :discussion_entry_versions
    set_replica_identity :discussion_entry_participants
    set_replica_identity :discussion_topic_participants
    set_replica_identity :discussion_topics
    set_replica_identity :enrollment_dates_overrides
    set_replica_identity :enrollment_states
    set_replica_identity :enrollment_terms
    set_replica_identity :enrollments
    set_replica_identity :favorites
    set_replica_identity :folders
    set_replica_identity :group_categories
    set_replica_identity :group_memberships
    set_replica_identity :groups
    set_replica_identity :lti_ims_registrations
    set_replica_identity :lti_line_items
    set_replica_identity :lti_resource_links
    set_replica_identity :lti_results
    set_replica_identity :mentions
    set_replica_identity :microsoft_sync_groups
    set_replica_identity :microsoft_sync_partial_sync_changes
    set_replica_identity :microsoft_sync_user_mappings
    set_replica_identity :originality_reports
    set_replica_identity :pseudonyms
    set_replica_identity :role_overrides
    set_replica_identity :roles
    set_replica_identity :rubric_criteria
    set_replica_identity :standard_grade_statuses
    set_replica_identity :temporary_enrollment_pairings
    set_replica_identity :user_account_associations
    set_replica_identity :user_lmgb_outcome_orderings
    set_replica_identity :user_notes
    set_replica_identity :users
    set_replica_identity :web_conference_participants
    set_replica_identity :web_conferences
    set_replica_identity :wiki_page_lookups
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
