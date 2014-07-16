class MakeColumnsNotNull < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :postdeploy

  def self.mysql?
    %w{MySQL Mysql2}.include?(connection.adapter_name)
  end

  def self.change_fk_column_null_with_less_locking(table, column, foreign_table = column.to_s.sub(/_id$/, '').tableize.to_sym)
    remove_foreign_key table, column: column if mysql?
    change_column_null_with_less_locking table, column
    add_foreign_key table, foreign_table, column: column if mysql?
  end

  def self.up
    change_column_null_with_less_locking :abstract_courses, :workflow_state
    change_fk_column_null_with_less_locking :abstract_courses, :account_id
    change_fk_column_null_with_less_locking :abstract_courses, :root_account_id, :accounts
    AbstractCourse.where(enrollment_term_id: nil).find_each do |ac|
      AbstractCourse.where(id: ac).update_all(enrollment_term_id: ac.root_account.default_enrollment_term.id)
    end
    change_fk_column_null_with_less_locking :abstract_courses, :enrollment_term_id
    change_fk_column_null_with_less_locking :account_authorization_configs, :account_id
    change_column_null_with_less_locking :account_notifications, :start_at
    change_column_null_with_less_locking :account_notifications, :end_at
    change_fk_column_null_with_less_locking :account_notifications, :account_id
    change_fk_column_null_with_less_locking :account_users, :account_id
    change_column_null_with_less_locking :account_users, :user_id
    change_column_null_with_less_locking :account_users, :membership_type
    change_fk_column_null_with_less_locking :account_reports, :account_id
    change_column_null_with_less_locking :account_reports, :user_id
    change_column_null_with_less_locking :account_reports, :workflow_state
    change_column_null_with_less_locking :accounts, :workflow_state
    change_column_null_with_less_locking :alerts, :context_id
    change_column_null_with_less_locking :alerts, :context_type
    change_column_null_with_less_locking :alerts, :recipients
    change_column_null_with_less_locking :appointment_groups, :workflow_state
    change_column_null_with_less_locking :assessment_question_bank_users, :workflow_state
    change_column_null_with_less_locking :assessment_question_bank_users, :user_id
    change_column_null_with_less_locking :assessment_question_bank_users, :assessment_question_bank_id
    change_column_null_with_less_locking :assessment_question_banks, :workflow_state
    change_column_null_with_less_locking :assessment_requests, :workflow_state
    change_column_null_with_less_locking :assessment_requests, :user_id
    change_column_null_with_less_locking :assessment_requests, :asset_id
    change_column_null_with_less_locking :assessment_requests, :asset_type
    change_column_null_with_less_locking :assessment_requests, :assessor_asset_id
    change_column_null_with_less_locking :assessment_requests, :assessor_asset_type
    change_column_null_with_less_locking :assessment_requests, :assessor_id
    change_column_null_with_less_locking :assignments, :context_type
    change_column_null_with_less_locking :assignments, :context_id
    change_column_null_with_less_locking :assignments, :workflow_state
    change_column_null_with_less_locking :assignment_groups, :context_id
    change_column_null_with_less_locking :assignment_groups, :context_type
    change_column_null_with_less_locking :assignment_groups, :workflow_state
    change_column_null_with_less_locking :assignment_overrides, :title
    change_column_null_with_less_locking :calendar_events, :context_id
    change_column_null_with_less_locking :calendar_events, :context_type
    change_column_null_with_less_locking :calendar_events, :workflow_state
    change_column_null_with_less_locking :collaborations, :title
    change_column_null_with_less_locking :collaborations, :workflow_state
    change_column_null_with_less_locking :collections, :workflow_state
    change_column_null_with_less_locking :collections, :context_id
    change_column_null_with_less_locking :collections, :context_type
    change_fk_column_null_with_less_locking :collection_items, :collection_id
    change_column_null_with_less_locking :collection_items, :collection_item_data_id
    change_column_null_with_less_locking :collection_items, :user_id
    change_column_null_with_less_locking :collection_items, :workflow_state
    change_column_null_with_less_locking :collection_item_datas, :link_url
    change_column_null_with_less_locking :collection_item_upvotes, :collection_item_data_id
    change_column_null_with_less_locking :collection_item_upvotes, :user_id
    change_column_null_with_less_locking :communication_channels, :path
    change_column_null_with_less_locking :communication_channels, :path_type
    change_fk_column_null_with_less_locking :communication_channels, :user_id
    change_column_null_with_less_locking :communication_channels, :workflow_state
    change_column_null_with_less_locking :content_exports, :workflow_state
    change_fk_column_null_with_less_locking :content_exports, :course_id
    change_column_null_with_less_locking :content_migrations, :workflow_state
    change_column_null_with_less_locking :content_migrations, :context_id
    change_column_null_with_less_locking :content_participations, :workflow_state
    change_column_null_with_less_locking :content_participations, :content_id
    change_column_null_with_less_locking :content_participations, :content_type
    change_column_null_with_less_locking :content_participations, :user_id
    change_column_null_with_less_locking :content_tags, :context_type
    change_column_null_with_less_locking :content_tags, :context_id
    change_column_null_with_less_locking :content_tags, :workflow_state
    change_column_null_with_less_locking :context_external_tools, :name
    change_column_null_with_less_locking :context_external_tools, :consumer_key
    change_column_null_with_less_locking :context_external_tools, :shared_secret
    change_column_null_with_less_locking :context_external_tools, :workflow_state
    change_column_null_with_less_locking :context_module_progressions, :workflow_state
    change_column_null_with_less_locking :context_modules, :workflow_state
    change_column_null_with_less_locking :context_modules, :context_id
    change_column_null_with_less_locking :context_modules, :context_type
    change_column_null_with_less_locking :conversation_batches, :workflow_state
    change_column_null_with_less_locking :conversation_batches, :user_id
    ConversationBatch.where(root_conversation_message_id: nil).delete_all
    change_column_null_with_less_locking :conversation_batches, :root_conversation_message_id
    change_column_null_with_less_locking :conversation_participants, :workflow_state
    change_column_null_with_less_locking :conversation_participants, :conversation_id
    change_column_null_with_less_locking :conversation_participants, :user_id
    change_column_null_with_less_locking :course_account_associations, :depth
    change_column_null_with_less_locking :course_account_associations, :course_id
    change_column_null_with_less_locking :course_account_associations, :account_id
    change_column_null_with_less_locking :course_imports, :workflow_state
    change_fk_column_null_with_less_locking :course_imports, :course_id
    change_column_null_with_less_locking :course_imports, :import_type
    change_column_null_with_less_locking :course_imports, :workflow_state
    change_column_null_with_less_locking :course_sections, :course_id
    change_fk_column_null_with_less_locking :course_sections, :root_account_id, :accounts
    change_column_null_with_less_locking :course_sections, :workflow_state
    change_column_null_with_less_locking :courses, :workflow_state
    change_fk_column_null_with_less_locking :courses, :account_id
    change_fk_column_null_with_less_locking :courses, :root_account_id, :accounts
    change_fk_column_null_with_less_locking :courses, :enrollment_term_id
    change_column_null_with_less_locking :delayed_notifications, :workflow_state
    change_column_null_with_less_locking :delayed_notifications, :notification_id
    change_column_null_with_less_locking :delayed_notifications, :asset_id
    change_column_null_with_less_locking :delayed_notifications, :asset_type
    change_column_null_with_less_locking :discussion_entry_participants, :workflow_state
    change_column_null_with_less_locking :discussion_entry_participants, :user_id
    change_column_null_with_less_locking :discussion_entry_participants, :discussion_entry_id
    change_column_null_with_less_locking :discussion_topic_participants, :workflow_state
    change_column_null_with_less_locking :discussion_topic_participants, :user_id
    change_fk_column_null_with_less_locking :discussion_topic_participants, :discussion_topic_id
    change_column_null_with_less_locking :discussion_topic_participants, :unread_entry_count
    change_column_null_with_less_locking :discussion_topics, :context_type
    change_column_null_with_less_locking :discussion_topics, :context_id
    change_column_null_with_less_locking :discussion_topics, :workflow_state
    change_fk_column_null_with_less_locking :enrollment_terms, :root_account_id, :accounts
    change_column_null_with_less_locking :enrollment_terms, :workflow_state
    change_column_null_with_less_locking :enrollments, :user_id
    change_fk_column_null_with_less_locking :enrollments, :course_id
    change_column_null_with_less_locking :enrollments, :type
    change_fk_column_null_with_less_locking :enrollments, :root_account_id, :accounts
    Enrollment.where(course_section_id: nil).find_each do |e|
      Enrollment.where(id: e).update_all(course_section_id: e.course.default_section.id)
    end
    change_column_null_with_less_locking :enrollments, :course_section_id
    change_column_null_with_less_locking :enrollments, :workflow_state
    change_fk_column_null_with_less_locking :eportfolios, :user_id
    change_column_null_with_less_locking :eportfolios, :workflow_state
    change_fk_column_null_with_less_locking :eportfolio_categories, :eportfolio_id
    change_fk_column_null_with_less_locking :eportfolio_entries, :eportfolio_id
    change_fk_column_null_with_less_locking :eportfolio_entries, :eportfolio_category_id
    change_column_null_with_less_locking :external_feed_entries, :workflow_state
    change_column_null_with_less_locking :external_feed_entries, :external_feed_id
    change_column_null_with_less_locking :external_feeds, :url
    change_column_null_with_less_locking :external_feeds, :context_id
    change_column_null_with_less_locking :external_feeds, :context_type
    change_column_null_with_less_locking :folders, :context_type
    change_column_null_with_less_locking :folders, :context_id
    change_column_null_with_less_locking :folders, :workflow_state
    change_column_null_with_less_locking :grading_standards, :workflow_state
    change_column_null_with_less_locking :grading_standards, :context_id
    change_column_null_with_less_locking :grading_standards, :context_type
    change_fk_column_null_with_less_locking :group_memberships, :group_id
    change_column_null_with_less_locking :group_memberships, :user_id
    change_column_null_with_less_locking :group_memberships, :workflow_state
    change_column_null_with_less_locking :groups, :context_id
    change_column_null_with_less_locking :groups, :context_type
    change_fk_column_null_with_less_locking :groups, :account_id
    change_fk_column_null_with_less_locking :groups, :root_account_id, :accounts
    change_column_null_with_less_locking :groups, :workflow_state
    LearningOutcome.where(short_description: nil).update_all(short_description: '')
    change_column_null_with_less_locking :learning_outcomes, :short_description
    change_column_null_with_less_locking :learning_outcomes, :workflow_state
    LearningOutcomeGroup.where(title: nil).update_all(title: '')
    change_column_null_with_less_locking :learning_outcome_groups, :title
    change_column_null_with_less_locking :learning_outcome_groups, :workflow_state
    change_column_null_with_less_locking :media_objects, :workflow_state
    change_column_null_with_less_locking :media_objects, :media_id
    change_column_null_with_less_locking :media_tracks, :media_object_id
    change_column_null_with_less_locking :media_tracks, :content
    change_column_null_with_less_locking :migration_issues, :workflow_state
    change_column_null_with_less_locking :migration_issues, :content_migration_id
    change_column_null_with_less_locking :migration_issues, :issue_type
    change_column_null_with_less_locking :notification_policies, :communication_channel_id
    change_column_null_with_less_locking :notification_policies, :broadcast
    change_column_null_with_less_locking :notifications, :workflow_state
    change_column_null_with_less_locking :page_views, :user_id
    change_fk_column_null_with_less_locking :profiles, :root_account_id, :accounts
    change_column_null_with_less_locking :profiles, :context_id
    change_column_null_with_less_locking :profiles, :context_type
    change_column_null_with_less_locking :progresses, :context_id
    change_column_null_with_less_locking :progresses, :context_type
    change_column_null_with_less_locking :progresses, :workflow_state
    change_column_null_with_less_locking :pseudonyms, :workflow_state
    change_column_null_with_less_locking :pseudonyms, :account_id
    Pseudonym.where(user_id: nil).delete_all
    change_column_null_with_less_locking :pseudonyms, :user_id
    change_column_null_with_less_locking :quizzes, :context_id
    change_column_null_with_less_locking :quizzes, :context_type
    change_column_null_with_less_locking :quizzes, :workflow_state
    change_column_null_with_less_locking :quiz_groups, :quiz_id
    change_column_null_with_less_locking :quiz_submissions, :workflow_state
    change_column_null_with_less_locking :quiz_submissions, :quiz_id
    change_column_null_with_less_locking :roles, :workflow_state
    change_column_null_with_less_locking :rubric_assessments, :assessment_type
    change_fk_column_null_with_less_locking :rubric_assessments, :rubric_id
    change_column_null_with_less_locking :rubric_assessments, :artifact_id
    change_column_null_with_less_locking :rubric_assessments, :artifact_type
    change_column_null_with_less_locking :rubric_associations, :purpose
    change_fk_column_null_with_less_locking :rubric_associations, :rubric_id
    change_column_null_with_less_locking :rubric_associations, :association_id
    change_column_null_with_less_locking :rubric_associations, :association_type
    change_column_null_with_less_locking :rubric_associations, :context_id
    change_column_null_with_less_locking :rubric_associations, :context_type
    change_column_null_with_less_locking :rubrics, :workflow_state
    change_column_null_with_less_locking :rubrics, :context_id
    change_column_null_with_less_locking :rubrics, :context_type
    change_column_null_with_less_locking :session_persistence_tokens, :crypted_token
    change_fk_column_null_with_less_locking :session_persistence_tokens, :pseudonym_id
    change_column_null_with_less_locking :session_persistence_tokens, :token_salt
    change_column_null_with_less_locking :sis_batches, :workflow_state
    change_column_null_with_less_locking :sis_batches, :account_id
    change_column_null_with_less_locking :stream_items, :data
    change_column_null_with_less_locking :stream_items, :asset_type
    change_column_null_with_less_locking :stream_item_instances, :user_id
    change_column_null_with_less_locking :stream_item_instances, :stream_item_id
    change_column_null_with_less_locking :submissions, :assignment_id
    change_column_null_with_less_locking :submissions, :user_id
    change_column_null_with_less_locking :submissions, :workflow_state
    change_column_null_with_less_locking :thumbnails, :size
    change_column_null_with_less_locking :thumbnails, :content_type
    change_column_null_with_less_locking :thumbnails, :filename
    change_column_null_with_less_locking :user_account_associations, :user_id
    change_column_null_with_less_locking :user_account_associations, :account_id
    change_column_null_with_less_locking :user_follows, :following_user_id
    change_column_null_with_less_locking :user_follows, :followed_item_id
    change_column_null_with_less_locking :user_notes, :workflow_state
    change_column_null_with_less_locking :user_services, :user_id
    change_column_null_with_less_locking :user_services, :service
    UserService.where(service_user_id: nil).delete_all
    change_column_null_with_less_locking :user_services, :service_user_id
    change_column_null_with_less_locking :user_services, :workflow_state
    change_column_null_with_less_locking :users, :workflow_state
    change_column_null_with_less_locking :web_conferences, :conference_type
    change_column_null_with_less_locking :web_conferences, :title
    change_column_null_with_less_locking :web_conferences, :context_id
    change_column_null_with_less_locking :web_conferences, :context_type
    change_column_null_with_less_locking :web_conferences, :user_id
    change_column_null_with_less_locking :wiki_pages, :workflow_state
    change_column_null_with_less_locking :wiki_pages, :wiki_id
    change_column_null_with_less_locking :zip_file_imports, :context_id
    change_column_null_with_less_locking :zip_file_imports, :context_type
    change_column_null_with_less_locking :zip_file_imports, :workflow_state
  end

  def self.down
    change_column_null :abstract_courses, :workflow_state, true
    change_column_null :abstract_courses, :account_id, true
    change_column_null :abstract_courses, :root_account_id, true
    change_column_null :abstract_courses, :enrollment_term_id, true
    change_column_null :account_authorization_configs, :account_id, true
    change_column_null :account_notifications, :start_at, true
    change_column_null :account_notifications, :end_at, true
    change_column_null :account_notifications, :account_id, true
    change_column_null :account_users, :account_id, true
    change_column_null :account_users, :user_id, true
    change_column_null :account_users, :membership_type, true
    change_column_null :account_reports, :account_id, true
    change_column_null :account_reports, :user_id, true
    change_column_null :account_reports, :workflow_state, true
    change_column_null :accounts, :workflow_state, true
    change_column_null :alerts, :context_id, true
    change_column_null :alerts, :context_type, true
    change_column_null :alerts, :recipients, true
    change_column_null :appointment_groups, :workflow_state, true
    change_column_null :assessment_question_bank_users, :workflow_state, true
    change_column_null :assessment_question_bank_users, :user_id, true
    change_column_null :assessment_question_bank_users, :assessment_question_bank_id, true
    change_column_null :assessment_question_banks, :workflow_state, true
    change_column_null :assessment_requests, :workflow_state, true
    change_column_null :assessment_requests, :user_id, true
    change_column_null :assessment_requests, :asset_id, true
    change_column_null :assessment_requests, :asset_type, true
    change_column_null :assessment_requests, :assessor_asset_id, true
    change_column_null :assessment_requests, :assessor_asset_type, true
    change_column_null :assessment_requests, :assessor_id, true
    change_column_null :assignments, :context_type, true
    change_column_null :assignments, :context_id, true
    change_column_null :assignments, :workflow_state, true
    change_column_null :assignment_groups, :context_id, true
    change_column_null :assignment_groups, :context_type, true
    change_column_null :assignment_groups, :workflow_state, true
    change_column_null :assignment_overrides, :title, true
    change_column_null :calendar_events, :context_id, true
    change_column_null :calendar_events, :context_type, true
    change_column_null :calendar_events, :workflow_state, true
    change_column_null :collaborations, :title, true
    change_column_null :collaborations, :workflow_state, true
    change_column_null :collections, :workflow_state, true
    change_column_null :collections, :context_id, true
    change_column_null :collections, :context_type, true
    change_column_null :collection_items, :collection_id, true
    change_column_null :collection_items, :collection_item_data_id, true
    change_column_null :collection_items, :user_id, true
    change_column_null :collection_items, :workflow_state, true
    change_column_null :collection_item_datas, :link_url, true
    change_column_null :collection_item_upvotes, :collection_item_data_id, true
    change_column_null :collection_item_upvotes, :user_id, true
    change_column_null :communication_channels, :path, true
    change_column_null :communication_channels, :path_type, true
    change_column_null :communication_channels, :user_id, true
    change_column_null :communication_channels, :workflow_state, true
    change_column_null :content_exports, :workflow_state, true
    change_column_null :content_exports, :course_id, true
    change_column_null :content_migrations, :workflow_state, true
    change_column_null :content_migrations, :context_id, true
    change_column_null :content_participations, :workflow_state, true
    change_column_null :content_participations, :content_id, true
    change_column_null :content_participations, :content_type, true
    change_column_null :content_participations, :user_id, true
    change_column_null :content_tags, :context_type, true
    change_column_null :content_tags, :context_id, true
    change_column_null :content_tags, :workflow_state, true
    change_column_null :context_external_tools, :name, true
    change_column_null :context_external_tools, :consumer_key, true
    change_column_null :context_external_tools, :shared_secret, true
    change_column_null :context_external_tools, :workflow_state, true
    change_column_null :context_module_progressions, :workflow_state, true
    change_column_null :context_modules, :workflow_state, true
    change_column_null :context_modules, :context_id, true
    change_column_null :context_modules, :context_type, true
    change_column_null :conversation_batches, :workflow_state, true
    change_column_null :conversation_batches, :user_id, true
    change_column_null :conversation_batches, :root_conversation_message_id, true
    change_column_null :conversation_participants, :workflow_state, true
    change_column_null :conversation_participants, :conversation_id, true
    change_column_null :conversation_participants, :user_id, true
    change_column_null :course_account_associations, :depth, true
    change_column_null :course_account_associations, :course_id, true
    change_column_null :course_account_associations, :account_id, true
    change_column_null :course_imports, :workflow_state, true
    change_column_null :course_imports, :course_id, true
    change_column_null :course_imports, :import_type, true
    change_column_null :course_imports, :workflow_state, true
    change_column_null :course_sections, :course_id, true
    change_column_null :course_sections, :root_account_id, true
    change_column_null :course_sections, :workflow_state, true
    change_column_null :courses, :workflow_state, true
    change_column_null :courses, :account_id, true
    change_column_null :courses, :root_account_id, true
    change_column_null :courses, :enrollment_term_id, true
    change_column_null :delayed_notifications, :workflow_state, true
    change_column_null :delayed_notifications, :notification_id, true
    change_column_null :delayed_notifications, :asset_id, true
    change_column_null :delayed_notifications, :asset_type, true
    change_column_null :discussion_entry_participants, :workflow_state, true
    change_column_null :discussion_entry_participants, :user_id, true
    change_column_null :discussion_entry_participants, :discussion_entry_id, true
    change_column_null :discussion_topic_participants, :workflow_state, true
    change_column_null :discussion_topic_participants, :user_id, true
    change_column_null :discussion_topic_participants, :discussion_topic_id, true
    change_column_null :discussion_topic_participants, :unread_entry_count, true
    change_column_null :discussion_topics, :context_type, true
    change_column_null :discussion_topics, :context_id, true
    change_column_null :discussion_topics, :workflow_state, true
    change_column_null :enrollment_terms, :root_account_id, true
    change_column_null :enrollment_terms, :workflow_state, true
    change_column_null :enrollments, :user_id, true
    change_column_null :enrollments, :course_id, true
    change_column_null :enrollments, :type, true
    change_column_null :enrollments, :root_account_id, true
    change_column_null :enrollments, :course_section_id, true
    change_column_null :enrollments, :workflow_state, true
    change_column_null :eportfolios, :user_id, true
    change_column_null :eportfolios, :workflow_state, true
    change_column_null :eportfolio_categories, :eportfolio_id, true
    change_column_null :eportfolio_entries, :eportfolio_id, true
    change_column_null :eportfolio_entries, :eportfolio_category_id, true
    change_column_null :external_feed_entries, :workflow_state, true
    change_column_null :external_feed_entries, :external_feed_id, true
    change_column_null :external_feeds, :url, true
    change_column_null :external_feeds, :context_id, true
    change_column_null :external_feeds, :context_type, true
    change_column_null :folders, :context_type, true
    change_column_null :folders, :context_id, true
    change_column_null :folders, :workflow_state, true
    change_column_null :grading_standards, :workflow_state, true
    change_column_null :grading_standards, :context_id, true
    change_column_null :grading_standards, :context_type, true
    change_column_null :group_memberships, :group_id, true
    change_column_null :group_memberships, :user_id, true
    change_column_null :group_memberships, :workflow_state, true
    change_column_null :groups, :context_id, true
    change_column_null :groups, :context_type, true
    change_column_null :groups, :account_id, true
    change_column_null :groups, :root_account_id, true
    change_column_null :groups, :workflow_state, true
    change_column_null :learning_outcomes, :short_description, true
    change_column_null :learning_outcomes, :workflow_state, true
    change_column_null :learning_outcome_groups, :title, true
    change_column_null :learning_outcome_groups, :workflow_state, true
    change_column_null :media_objects, :workflow_state, true
    change_column_null :media_objects, :media_id, true
    change_column_null :media_tracks, :media_object_id, true
    change_column_null :media_tracks, :content, true
    change_column_null :migration_issues, :workflow_state, true
    change_column_null :migration_issues, :content_migration_id, true
    change_column_null :migration_issues, :issue_type, true
    change_column_null :notification_policies, :communication_channel_id, true
    change_column_null :notification_policies, :broadcast, true
    change_column_null :notifications, :workflow_state, true
    change_column_null :page_views, :user_id, true
    change_column_null :profiles, :root_account_id, true
    change_column_null :profiles, :context_id, true
    change_column_null :profiles, :context_type, true
    change_column_null :progresses, :context_id, true
    change_column_null :progresses, :context_type, true
    change_column_null :progresses, :workflow_state, true
    change_column_null :pseudonyms, :workflow_state, true
    change_column_null :pseudonyms, :account_id, true
    change_column_null :pseudonyms, :user_id, true
    change_column_null :quizzes, :context_id, true
    change_column_null :quizzes, :context_type, true
    change_column_null :quizzes, :workflow_state, true
    change_column_null :quiz_groups, :quiz_id, true
    change_column_null :quiz_submissions, :workflow_state, true
    change_column_null :quiz_submissions, :quiz_id, true
    change_column_null :roles, :workflow_state, true
    change_column_null :rubric_assessments, :assessment_type, true
    change_column_null :rubric_assessments, :rubric_id, true
    change_column_null :rubric_assessments, :rubric_association_id, true
    change_column_null :rubric_assessments, :artifact_id, true
    change_column_null :rubric_assessments, :artifact_type, true
    change_column_null :rubric_associations, :purpose, true
    change_column_null :rubric_associations, :rubric_id, true
    change_column_null :rubric_associations, :association_id, true
    change_column_null :rubric_associations, :association_type, true
    change_column_null :rubric_associations, :context_id, true
    change_column_null :rubric_associations, :context_type, true
    change_column_null :rubrics, :workflow_state, true
    change_column_null :rubrics, :context_id, true
    change_column_null :rubrics, :context_type, true
    change_column_null :session_persistence_tokens, :crypted_token, true
    change_column_null :session_persistence_tokens, :pseudonym_id, true
    change_column_null :session_persistence_tokens, :token_salt, true
    change_column_null :sis_batches, :workflow_state, true
    change_column_null :sis_batches, :account_id, true
    change_column_null :stream_items, :data, true
    change_column_null :stream_items, :asset_type, true
    change_column_null :stream_item_instances, :user_id, true
    change_column_null :stream_item_instances, :stream_item_id, true
    change_column_null :submissions, :assignment_id, true
    change_column_null :submissions, :user_id, true
    change_column_null :submissions, :workflow_state, true
    change_column_null :thumbnails, :size, true
    change_column_null :thumbnails, :content_type, true
    change_column_null :thumbnails, :filename, true
    change_column_null :user_account_associations, :user_id, true
    change_column_null :user_account_associations, :account_id, true
    change_column_null :user_follows, :following_user_id, true
    change_column_null :user_follows, :followed_item_id, true
    change_column_null :user_notes, :workflow_state, true
    change_column_null :user_services, :user_id, true
    change_column_null :user_services, :service, true
    change_column_null :user_services, :service_user_id, true
    change_column_null :user_services, :workflow_state, true
    change_column_null :users, :workflow_state, true
    change_column_null :web_conferences, :conference_type, true
    change_column_null :web_conferences, :title, true
    change_column_null :web_conferences, :context_id, true
    change_column_null :web_conferences, :context_type, true
    change_column_null :web_conferences, :user_id, true
    change_column_null :wiki_pages, :workflow_state, true
    change_column_null :wiki_pages, :wiki_id, true
    change_column_null :zip_file_imports, :context_id, true
    change_column_null :zip_file_imports, :context_type, true
    change_column_null :zip_file_imports, :workflow_state, true
  end
end
