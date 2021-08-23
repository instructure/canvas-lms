# frozen_string_literal: true

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

class MakeTimestampsNotNull < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  TABLES = [
    :access_tokens,
    :account_notifications,
    :alerts,
    :appointment_group_contexts,
    :appointment_group_sub_contexts,
    :assignment_override_students,
    :assignment_overrides,
    :canvadocs,
    :content_exports,
    :content_participation_counts,
    :context_external_tools,
    :conversation_batches,
    :custom_data,
    :custom_gradebook_columns,
    :delayed_jobs,
    :discussion_topic_materialized_views,
    :epub_exports,
    :event_stream_failures,
    :external_integration_keys,
    :favorites,
    :feature_flags,
    :grading_period_groups,
    :grading_periods,
    :ignores,
    :live_assessments_assessments,
    :live_assessments_submissions,
    :lti_message_handlers,
    :lti_product_families,
    :lti_resource_handlers,
    :lti_resource_placements,
    :lti_tool_proxies,
    :lti_tool_proxy_bindings,
    :lti_tool_settings,
    :media_tracks,
    :migration_issues,
    :moderated_grading_provisional_grades,
    :notification_endpoints,
    :polling_poll_choices,
    :polling_poll_sessions,
    :polling_poll_submissions,
    :polling_polls,
    :quiz_question_regrades,
    :quiz_regrade_runs,
    :quiz_regrades,
    :quiz_statistics,
    :session_persistence_tokens,
    :sis_post_grades_statuses,
    :user_profile_links
  ].freeze

  def change
    TABLES.each do |table|
      change_column_null(table, :created_at, false)
      change_column_null(table, :updated_at, false)
    end
  end
end
