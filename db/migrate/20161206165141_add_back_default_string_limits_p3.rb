class AddBackDefaultStringLimitsP3 < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    add_string_limit_if_missing :quiz_groups, :name
    add_string_limit_if_missing :quiz_groups, :migration_id

    add_string_limit_if_missing :quiz_question_regrades, :regrade_option

    add_string_limit_if_missing :quiz_questions, :migration_id
    add_string_limit_if_missing :quiz_questions, :workflow_state

    add_string_limit_if_missing :quiz_statistics, :report_type

    add_string_limit_if_missing :quizzes, :title
    add_string_limit_if_missing :quizzes, :scoring_policy
    add_string_limit_if_missing :quizzes, :quiz_type
    add_string_limit_if_missing :quizzes, :access_code
    add_string_limit_if_missing :quizzes, :migration_id
    add_string_limit_if_missing :quizzes, :hide_results
    add_string_limit_if_missing :quizzes, :ip_filter

    add_string_limit_if_missing :quiz_submission_events, :event_type

    add_string_limit_if_missing :quiz_submissions, :workflow_state
    add_string_limit_if_missing :quiz_submissions, :temporary_user_code
    add_string_limit_if_missing :quiz_submissions, :validation_token

    add_string_limit_if_missing :report_snapshots, :report_type

    add_string_limit_if_missing :role_overrides, :permission
    add_string_limit_if_missing :role_overrides, :context_type

    add_string_limit_if_missing :roles, :name
    add_string_limit_if_missing :roles, :base_role_type
    add_string_limit_if_missing :roles, :workflow_state

    add_string_limit_if_missing :rubric_assessments, :artifact_type
    add_string_limit_if_missing :rubric_assessments, :assessment_type

    add_string_limit_if_missing :rubric_associations, :association_type
    add_string_limit_if_missing :rubric_associations, :title
    add_string_limit_if_missing :rubric_associations, :purpose
    add_string_limit_if_missing :rubric_associations, :url
    add_string_limit_if_missing :rubric_associations, :context_type
    add_string_limit_if_missing :rubric_associations, :context_code

    add_string_limit_if_missing :rubrics, :context_type
    add_string_limit_if_missing :rubrics, :title
    add_string_limit_if_missing :rubrics, :context_code
    add_string_limit_if_missing :rubrics, :migration_id
    add_string_limit_if_missing :rubrics, :workflow_state

    add_string_limit_if_missing :schema_migrations, :version

    add_string_limit_if_missing :scribd_mime_types, :extension
    add_string_limit_if_missing :scribd_mime_types, :name

    add_string_limit_if_missing :session_persistence_tokens, :token_salt
    add_string_limit_if_missing :session_persistence_tokens, :crypted_token

    add_string_limit_if_missing :sessions, :session_id

    add_string_limit_if_missing :settings, :name

    add_string_limit_if_missing :shared_brand_configs, :name

    add_string_limit_if_missing :sis_batches, :workflow_state
    add_string_limit_if_missing :sis_batches, :diffing_data_set_identifier

    add_string_limit_if_missing :sis_post_grades_statuses, :status
    add_string_limit_if_missing :sis_post_grades_statuses, :message

    add_string_limit_if_missing :stream_item_instances, :workflow_state
    add_string_limit_if_missing :stream_item_instances, :context_type

    add_string_limit_if_missing :stream_items, :context_type
    add_string_limit_if_missing :stream_items, :asset_type
    add_string_limit_if_missing :stream_items, :notification_category

    add_string_limit_if_missing :submission_comment_participants, :participation_type

    add_string_limit_if_missing :submission_comments, :author_name
    add_string_limit_if_missing :submission_comments, :group_comment_id
    add_string_limit_if_missing :submission_comments, :media_comment_id
    add_string_limit_if_missing :submission_comments, :media_comment_type
    add_string_limit_if_missing :submission_comments, :context_type

    add_string_limit_if_missing :submission_versions, :context_type

    add_string_limit_if_missing :thumbnails, :content_type
    add_string_limit_if_missing :thumbnails, :filename
    add_string_limit_if_missing :thumbnails, :thumbnail
    add_string_limit_if_missing :thumbnails, :uuid
    add_string_limit_if_missing :thumbnails, :namespace

    add_string_limit_if_missing :usage_rights, :context_type
    add_string_limit_if_missing :usage_rights, :use_justification
    add_string_limit_if_missing :usage_rights, :license

    add_string_limit_if_missing :user_merge_data, :workflow_state

    add_string_limit_if_missing :user_merge_data_records, :context_type
    add_string_limit_if_missing :user_merge_data_records, :previous_workflow_state

    add_string_limit_if_missing :user_notes, :title
    add_string_limit_if_missing :user_notes, :workflow_state

    add_string_limit_if_missing :user_observers, :workflow_state

    add_string_limit_if_missing :user_profile_links, :title

    add_string_limit_if_missing :user_profiles, :title

    add_string_limit_if_missing :user_services, :secret
    add_string_limit_if_missing :user_services, :protocol
    add_string_limit_if_missing :user_services, :service
    add_string_limit_if_missing :user_services, :service_user_url
    add_string_limit_if_missing :user_services, :service_user_id
    add_string_limit_if_missing :user_services, :service_user_name
    add_string_limit_if_missing :user_services, :service_domain
    add_string_limit_if_missing :user_services, :crypted_password
    add_string_limit_if_missing :user_services, :password_salt
    add_string_limit_if_missing :user_services, :type
    add_string_limit_if_missing :user_services, :workflow_state
    add_string_limit_if_missing :user_services, :last_result_id

    add_string_limit_if_missing :users, :name
    add_string_limit_if_missing :users, :sortable_name
    add_string_limit_if_missing :users, :workflow_state
    add_string_limit_if_missing :users, :time_zone
    add_string_limit_if_missing :users, :uuid
    add_string_limit_if_missing :users, :avatar_image_url
    add_string_limit_if_missing :users, :avatar_image_source
    add_string_limit_if_missing :users, :phone
    add_string_limit_if_missing :users, :school_name
    add_string_limit_if_missing :users, :school_position
    add_string_limit_if_missing :users, :short_name
    add_string_limit_if_missing :users, :gender
    add_string_limit_if_missing :users, :visible_inbox_types
    add_string_limit_if_missing :users, :avatar_state
    add_string_limit_if_missing :users, :locale
    add_string_limit_if_missing :users, :browser_locale
    add_string_limit_if_missing :users, :otp_secret_key_enc
    add_string_limit_if_missing :users, :otp_secret_key_salt
    add_string_limit_if_missing :users, :initial_enrollment_type
    add_string_limit_if_missing :users, :lti_context_id

    add_string_limit_if_missing :versions, :versionable_type

    add_string_limit_if_missing :web_conference_participants, :participation_type

    add_string_limit_if_missing :web_conferences, :title
    add_string_limit_if_missing :web_conferences, :conference_type
    add_string_limit_if_missing :web_conferences, :conference_key
    add_string_limit_if_missing :web_conferences, :context_type
    add_string_limit_if_missing :web_conferences, :user_ids
    add_string_limit_if_missing :web_conferences, :added_user_ids
    add_string_limit_if_missing :web_conferences, :uuid
    add_string_limit_if_missing :web_conferences, :invited_user_ids
    add_string_limit_if_missing :web_conferences, :context_code
    add_string_limit_if_missing :web_conferences, :type

    add_string_limit_if_missing :wiki_pages, :title
    add_string_limit_if_missing :wiki_pages, :workflow_state
    add_string_limit_if_missing :wiki_pages, :editing_roles
    add_string_limit_if_missing :wiki_pages, :migration_id

    add_string_limit_if_missing :wikis, :title
  end

  def add_string_limit_if_missing(table, column)
    return if column_exists?(table, column, :string, limit: 255)
    change_column table, column, :string, limit: 255
  end
end
