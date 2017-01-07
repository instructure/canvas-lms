class AddBackDefaultStringLimitsP2 < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    add_string_limit_if_missing :delayed_messages, :context_type
    add_string_limit_if_missing :delayed_messages, :frequency
    add_string_limit_if_missing :delayed_messages, :workflow_state

    add_string_limit_if_missing :delayed_notifications, :asset_type
    add_string_limit_if_missing :delayed_notifications, :workflow_state
    add_string_limit_if_missing :delayed_notifications, :asset_context_type

    add_string_limit_if_missing :developer_keys, :api_key
    add_string_limit_if_missing :developer_keys, :email
    add_string_limit_if_missing :developer_keys, :user_name

    add_string_limit_if_missing :developer_keys, :name
    add_string_limit_if_missing :developer_keys, :redirect_uri
    add_string_limit_if_missing :developer_keys, :icon_url
    add_string_limit_if_missing :developer_keys, :sns_arn
    add_string_limit_if_missing :developer_keys, :workflow_state
    # without specifying the array, rails added a limit but removed the array
    unless column_exists?(:developer_keys, :redirect_uris, :string, limit: 255, array: true)
      change_column :developer_keys, :redirect_uris, :string, limit: 255, array: true
    end

    add_string_limit_if_missing :discussion_entries, :workflow_state
    add_string_limit_if_missing :discussion_entries, :migration_id

    add_string_limit_if_missing :discussion_entry_participants, :workflow_state

    add_string_limit_if_missing :discussion_topic_participants, :workflow_state

    add_string_limit_if_missing :discussion_topics, :title
    add_string_limit_if_missing :discussion_topics, :context_type
    add_string_limit_if_missing :discussion_topics, :type
    add_string_limit_if_missing :discussion_topics, :workflow_state
    add_string_limit_if_missing :discussion_topics, :context_code
    add_string_limit_if_missing :discussion_topics, :migration_id
    add_string_limit_if_missing :discussion_topics, :discussion_type

    add_string_limit_if_missing :enrollment_dates_overrides, :enrollment_type
    add_string_limit_if_missing :enrollment_dates_overrides, :context_type

    add_string_limit_if_missing :enrollment_states, :state

    add_string_limit_if_missing :enrollment_terms, :name
    add_string_limit_if_missing :enrollment_terms, :term_code
    add_string_limit_if_missing :enrollment_terms, :sis_source_id
    add_string_limit_if_missing :enrollment_terms, :workflow_state
    add_string_limit_if_missing :enrollment_terms, :integration_id

    add_string_limit_if_missing :eportfolio_categories, :name
    add_string_limit_if_missing :eportfolio_categories, :slug

    add_string_limit_if_missing :eportfolio_entries, :name
    add_string_limit_if_missing :eportfolio_entries, :slug

    add_string_limit_if_missing :eportfolios, :name
    add_string_limit_if_missing :eportfolios, :uuid
    add_string_limit_if_missing :eportfolios, :workflow_state

    add_string_limit_if_missing :epub_exports, :workflow_state

    add_string_limit_if_missing :error_reports, :email
    add_string_limit_if_missing :error_reports, :request_method
    add_string_limit_if_missing :error_reports, :subject
    add_string_limit_if_missing :error_reports, :request_context_id
    add_string_limit_if_missing :error_reports, :category

    add_string_limit_if_missing :event_stream_failures, :operation
    add_string_limit_if_missing :event_stream_failures, :event_stream
    add_string_limit_if_missing :event_stream_failures, :record_id

    add_string_limit_if_missing :external_feed_entries, :source_name
    add_string_limit_if_missing :external_feed_entries, :workflow_state
    add_string_limit_if_missing :external_feed_entries, :author_name
    add_string_limit_if_missing :external_feed_entries, :author_email
    add_string_limit_if_missing :external_feed_entries, :asset_type
    add_string_limit_if_missing :external_feed_entries, :uuid

    add_string_limit_if_missing :external_feeds, :context_type
    add_string_limit_if_missing :external_feeds, :title
    add_string_limit_if_missing :external_feeds, :url
    add_string_limit_if_missing :external_feeds, :header_match
    add_string_limit_if_missing :external_feeds, :verbosity
    add_string_limit_if_missing :external_feeds, :migration_id

    add_string_limit_if_missing :external_integration_keys, :context_type
    add_string_limit_if_missing :external_integration_keys, :key_value
    add_string_limit_if_missing :external_integration_keys, :key_type

    add_string_limit_if_missing :favorites, :context_type

    add_string_limit_if_missing :feature_flags, :context_type
    add_string_limit_if_missing :feature_flags, :feature
    add_string_limit_if_missing :feature_flags, :state

    add_string_limit_if_missing :folders, :name
    add_string_limit_if_missing :folders, :context_type
    add_string_limit_if_missing :folders, :workflow_state
    add_string_limit_if_missing :folders, :submission_context_code

    add_string_limit_if_missing :grading_period_grades, :workflow_state

    add_string_limit_if_missing :grading_period_groups, :workflow_state
    add_string_limit_if_missing :grading_period_groups, :title

    add_string_limit_if_missing :grading_periods, :title
    add_string_limit_if_missing :grading_periods, :workflow_state

    add_string_limit_if_missing :grading_standards, :title
    add_string_limit_if_missing :grading_standards, :context_type
    add_string_limit_if_missing :grading_standards, :context_code
    add_string_limit_if_missing :grading_standards, :workflow_state
    add_string_limit_if_missing :grading_standards, :migration_id

    add_string_limit_if_missing :group_categories, :context_type
    add_string_limit_if_missing :group_categories, :name
    add_string_limit_if_missing :group_categories, :role
    add_string_limit_if_missing :group_categories, :self_signup
    add_string_limit_if_missing :group_categories, :auto_leader

    add_string_limit_if_missing :ignores, :asset_type
    add_string_limit_if_missing :ignores, :purpose

    add_string_limit_if_missing :learning_outcome_groups, :context_type
    add_string_limit_if_missing :learning_outcome_groups, :title
    add_string_limit_if_missing :learning_outcome_groups, :workflow_state
    add_string_limit_if_missing :learning_outcome_groups, :migration_id
    add_string_limit_if_missing :learning_outcome_groups, :vendor_guid
    add_string_limit_if_missing :learning_outcome_groups, :low_grade
    add_string_limit_if_missing :learning_outcome_groups, :high_grade

    add_string_limit_if_missing :learning_outcome_question_results, :associated_asset_type

    add_string_limit_if_missing :learning_outcome_results, :context_type
    add_string_limit_if_missing :learning_outcome_results, :context_code
    add_string_limit_if_missing :learning_outcome_results, :association_type
    add_string_limit_if_missing :learning_outcome_results, :artifact_type
    add_string_limit_if_missing :learning_outcome_results, :title
    add_string_limit_if_missing :learning_outcome_results, :associated_asset_type

    add_string_limit_if_missing :learning_outcomes, :context_type
    add_string_limit_if_missing :learning_outcomes, :short_description
    add_string_limit_if_missing :learning_outcomes, :context_code
    add_string_limit_if_missing :learning_outcomes, :workflow_state
    add_string_limit_if_missing :learning_outcomes, :migration_id
    add_string_limit_if_missing :learning_outcomes, :vendor_guid
    add_string_limit_if_missing :learning_outcomes, :low_grade
    add_string_limit_if_missing :learning_outcomes, :high_grade
    add_string_limit_if_missing :learning_outcomes, :display_name
    add_string_limit_if_missing :learning_outcomes, :calculation_method

    add_string_limit_if_missing :live_assessments_assessments, :key
    add_string_limit_if_missing :live_assessments_assessments, :title
    add_string_limit_if_missing :live_assessments_assessments, :context_type

    add_string_limit_if_missing :lti_message_handlers, :message_type
    add_string_limit_if_missing :lti_message_handlers, :launch_path

    add_string_limit_if_missing :lti_product_families, :vendor_code
    add_string_limit_if_missing :lti_product_families, :product_code
    add_string_limit_if_missing :lti_product_families, :vendor_name
    add_string_limit_if_missing :lti_product_families, :website
    add_string_limit_if_missing :lti_product_families, :vendor_email

    add_string_limit_if_missing :lti_resource_handlers, :resource_type_code
    add_string_limit_if_missing :lti_resource_handlers, :placements
    add_string_limit_if_missing :lti_resource_handlers, :name

    add_string_limit_if_missing :lti_resource_placements, :placement

    add_string_limit_if_missing :lti_tool_proxies, :guid
    add_string_limit_if_missing :lti_tool_proxies, :product_version
    add_string_limit_if_missing :lti_tool_proxies, :lti_version
    add_string_limit_if_missing :lti_tool_proxies, :workflow_state
    add_string_limit_if_missing :lti_tool_proxies, :context_type
    add_string_limit_if_missing :lti_tool_proxies, :name
    add_string_limit_if_missing :lti_tool_proxies, :description

    add_string_limit_if_missing :lti_tool_proxy_bindings, :context_type

    add_string_limit_if_missing :lti_tool_settings, :context_type

    add_string_limit_if_missing :master_courses_child_content_tags, :content_type

    add_string_limit_if_missing :master_courses_child_subscriptions, :workflow_state

    add_string_limit_if_missing :master_courses_master_content_tags, :content_type

    add_string_limit_if_missing :master_courses_master_migrations, :workflow_state

    add_string_limit_if_missing :master_courses_master_templates, :workflow_state

    add_string_limit_if_missing :media_objects, :context_type
    add_string_limit_if_missing :media_objects, :workflow_state
    add_string_limit_if_missing :media_objects, :user_type
    add_string_limit_if_missing :media_objects, :title
    add_string_limit_if_missing :media_objects, :user_entered_title
    add_string_limit_if_missing :media_objects, :media_id
    add_string_limit_if_missing :media_objects, :media_type
    add_string_limit_if_missing :media_objects, :old_media_id

    add_string_limit_if_missing :media_tracks, :kind
    add_string_limit_if_missing :media_tracks, :locale

    add_string_limit_if_missing :messages, :workflow_state
    add_string_limit_if_missing :messages, :context_type
    add_string_limit_if_missing :messages, :asset_context_type
    add_string_limit_if_missing :messages, :notification_name
    add_string_limit_if_missing :messages, :path_type
    add_string_limit_if_missing :messages, :asset_context_code
    add_string_limit_if_missing :messages, :reply_to_name

    add_string_limit_if_missing :migration_issues, :workflow_state
    add_string_limit_if_missing :migration_issues, :issue_type

    add_string_limit_if_missing :moderated_grading_provisional_grades, :grade

    add_string_limit_if_missing :notification_endpoints, :token
    add_string_limit_if_missing :notification_endpoints, :arn

    add_string_limit_if_missing :notification_policies, :frequency

    add_string_limit_if_missing :notifications, :workflow_state
    add_string_limit_if_missing :notifications, :name
    add_string_limit_if_missing :notifications, :subject
    add_string_limit_if_missing :notifications, :category
    add_string_limit_if_missing :notifications, :main_link

    add_string_limit_if_missing :oauth_requests, :token
    add_string_limit_if_missing :oauth_requests, :secret
    add_string_limit_if_missing :oauth_requests, :user_secret
    add_string_limit_if_missing :oauth_requests, :workflow_state
    add_string_limit_if_missing :oauth_requests, :original_host_with_port
    add_string_limit_if_missing :oauth_requests, :service

    add_string_limit_if_missing :page_comments, :page_type

    add_string_limit_if_missing :page_views, :request_id
    add_string_limit_if_missing :page_views, :session_id
    add_string_limit_if_missing :page_views, :context_type
    add_string_limit_if_missing :page_views, :asset_type
    add_string_limit_if_missing :page_views, :controller
    add_string_limit_if_missing :page_views, :action
    add_string_limit_if_missing :page_views, :http_method
    add_string_limit_if_missing :page_views, :remote_ip

    add_string_limit_if_missing :plugin_settings, :name

    add_string_limit_if_missing :polling_poll_choices, :text

    add_string_limit_if_missing :polling_polls, :question
    add_string_limit_if_missing :polling_polls, :description

    add_string_limit_if_missing :profiles, :context_type
    add_string_limit_if_missing :profiles, :title
    add_string_limit_if_missing :profiles, :path
    add_string_limit_if_missing :profiles, :visibility

    add_string_limit_if_missing :progresses, :context_type
    add_string_limit_if_missing :progresses, :tag
    add_string_limit_if_missing :progresses, :delayed_job_id
    add_string_limit_if_missing :progresses, :workflow_state
    add_string_limit_if_missing :progresses, :cache_key_context

    add_string_limit_if_missing :pseudonyms, :workflow_state
    add_string_limit_if_missing :pseudonyms, :unique_id
    add_string_limit_if_missing :pseudonyms, :crypted_password
    add_string_limit_if_missing :pseudonyms, :password_salt
    add_string_limit_if_missing :pseudonyms, :persistence_token
    add_string_limit_if_missing :pseudonyms, :single_access_token
    add_string_limit_if_missing :pseudonyms, :perishable_token
    add_string_limit_if_missing :pseudonyms, :last_login_ip
    add_string_limit_if_missing :pseudonyms, :current_login_ip
    add_string_limit_if_missing :pseudonyms, :reset_password_token
    add_string_limit_if_missing :pseudonyms, :sis_user_id
    add_string_limit_if_missing :pseudonyms, :sis_ssha
    add_string_limit_if_missing :pseudonyms, :integration_id
  end

  def add_string_limit_if_missing(table, column)
    return if column_exists?(table, column, :string, limit: 255)
    change_column table, column, :string, limit: 255
  end
end
