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
    :migration_systems,
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
    :user_profile_links,
    :webhooks
  ].freeze

  def change
    TABLES.each do |table|
      change_column_null(table, :created_at, false)
      change_column_null(table, :updated_at, false)
    end
  end
end
