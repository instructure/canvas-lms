# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

###########################################################################################
###         This file is auto generated, any changes made directly will be lost.        ###
###              To regenerate this file run `bundle exec rake doc:api                  ###
###                                                                                     ###
###                   The template for this file is located here:                       ###
###                doc/api/fulldoc/html/api_scopes/scope_mapper_template.erb            ###
###########################################################################################

class ApiScopeMapper

  SCOPE_MAP = {
    scopes_api: {
      index: :api_token_scopes
    }.freeze,
    account_notifications: {
      user_index: :account_notifications,
      show: :account_notifications,
      user_close_notification: :account_notifications,
      create: :account_notifications,
      update: :account_notifications
    }.freeze,
    account_reports: {
      available_reports: :account_reports,
      create: :account_reports,
      index: :account_reports,
      show: :account_reports,
      destroy: :account_reports
    }.freeze,
    accounts: {
      index: :accounts,
      course_accounts: :accounts,
      show: :accounts,
      permissions: :accounts,
      sub_accounts: :accounts,
      terms_of_service: :accounts,
      help_links: :accounts,
      courses_api: :accounts,
      update: :accounts,
      remove_user: :accounts
    }.freeze,
    sub_accounts: {
      create: :accounts,
      destroy: :accounts
    }.freeze,
    account_lookup: {
      show: :accounts_lti
    }.freeze,
    admins: {
      create: :admins,
      destroy: :admins,
      index: :admins
    }.freeze,
    external_feeds: {
      index: :announcement_external_feeds,
      create: :announcement_external_feeds,
      destroy: :announcement_external_feeds
    }.freeze,
    announcements_api: {
      index: :announcements
    }.freeze,
    appointment_groups: {
      index: :appointment_groups,
      create: :appointment_groups,
      show: :appointment_groups,
      update: :appointment_groups,
      destroy: :appointment_groups,
      users: :appointment_groups,
      groups: :appointment_groups,
      next_appointment: :appointment_groups
    }.freeze,
    assignment_extensions: {
      create: :assignment_extensions
    }.freeze,
    assignment_groups: {
      index: :assignment_groups
    }.freeze,
    assignment_groups_api: {
      show: :assignment_groups,
      create: :assignment_groups,
      update: :assignment_groups,
      destroy: :assignment_groups
    }.freeze,
    assignments: {
      destroy: :assignments
    }.freeze,
    assignments_api: {
      index: :assignments,
      user_index: :assignments,
      show: :assignments,
      create: :assignments,
      update: :assignments,
      bulk_update: :assignments
    }.freeze,
    assignment_overrides: {
      index: :assignments,
      show: :assignments,
      group_alias: :assignments,
      section_alias: :assignments,
      create: :assignments,
      update: :assignments,
      destroy: :assignments,
      batch_retrieve: :assignments,
      batch_create: :assignments,
      batch_update: :assignments
    }.freeze,
    authentication_providers: {
      index: :authentication_providers,
      create: :authentication_providers,
      update: :authentication_providers,
      show: :authentication_providers,
      destroy: :authentication_providers,
      show_sso_settings: :authentication_providers,
      update_sso_settings: :authentication_providers
    }.freeze,
    authentication_audit_api: {
      for_login: :authentications_log,
      for_account: :authentications_log,
      for_user: :authentications_log
    }.freeze,
    master_templates: {
      show: :blueprint_courses,
      associated_courses: :blueprint_courses,
      update_associations: :blueprint_courses,
      queue_migration: :blueprint_courses,
      restrict_item: :blueprint_courses,
      unsynced_changes: :blueprint_courses,
      migrations_index: :blueprint_courses,
      migrations_show: :blueprint_courses,
      migration_details: :blueprint_courses,
      subscriptions_index: :blueprint_courses,
      imports_index: :blueprint_courses,
      imports_show: :blueprint_courses,
      import_details: :blueprint_courses
    }.freeze,
    bookmarks: {
      index: :bookmarks,
      create: :bookmarks,
      show: :bookmarks,
      update: :bookmarks,
      destroy: :bookmarks
    }.freeze,
    brand_configs_api: {
      show: :brand_configs
    }.freeze,
    calendar_events_api: {
      index: :calendar_events,
      user_index: :calendar_events,
      create: :calendar_events,
      show: :calendar_events,
      reserve: :calendar_events,
      update: :calendar_events,
      destroy: :calendar_events,
      set_course_timetable: :calendar_events,
      get_course_timetable: :calendar_events,
      set_course_timetable_events: :calendar_events
    }.freeze,
    collaborations: {
      api_index: :collaborations,
      members: :collaborations,
      potential_collaborators: :collaborations
    }.freeze,
    comm_messages_api: {
      index: :commmessages
    }.freeze,
    communication_channels: {
      index: :communication_channels,
      create: :communication_channels,
      destroy: :communication_channels,
      delete_push_token: :communication_channels
    }.freeze,
    conferences: {
      index: :conferences,
      for_user: :conferences
    }.freeze,
    content_exports_api: {
      index: :content_exports,
      show: :content_exports,
      create: :content_exports
    }.freeze,
    migration_issues: {
      index: :content_migrations,
      show: :content_migrations,
      update: :content_migrations
    }.freeze,
    content_migrations: {
      index: :content_migrations,
      show: :content_migrations,
      create: :content_migrations,
      update: :content_migrations,
      available_migrators: :content_migrations,
      content_list: :content_migrations
    }.freeze,
    csp_settings: {
      get_csp_settings: :content_security_policy_settings,
      set_csp_setting: :content_security_policy_settings,
      set_csp_lock: :content_security_policy_settings,
      add_domain: :content_security_policy_settings,
      add_multiple_domains: :content_security_policy_settings,
      csp_log: :content_security_policy_settings,
      remove_domain: :content_security_policy_settings
    }.freeze,
    content_shares: {
      create: :content_shares,
      index: :content_shares,
      unread_count: :content_shares,
      show: :content_shares,
      destroy: :content_shares,
      add_users: :content_shares,
      update: :content_shares
    }.freeze,
    conversations: {
      index: :conversations,
      create: :conversations,
      batches: :conversations,
      show: :conversations,
      update: :conversations,
      mark_all_as_read: :conversations,
      destroy: :conversations,
      add_recipients: :conversations,
      add_message: :conversations,
      remove_messages: :conversations,
      batch_update: :conversations,
      find_recipients: :conversations,
      unread_count: :conversations
    }.freeze,
    course_audit_api: {
      for_course: :course_audit_log,
      for_account: :course_audit_log
    }.freeze,
    course_quiz_extensions: {
      create: :course_quiz_extensions
    }.freeze,
    courses: {
      index: :courses,
      user_index: :courses,
      create: :courses,
      create_file: :courses,
      students: :courses,
      users: :courses,
      recent_students: :courses,
      user: :courses,
      content_share_users: :courses,
      preview_html: :courses,
      activity_stream: :courses,
      activity_stream_summary: :courses,
      todo_items: :courses,
      destroy: :courses,
      api_settings: :courses,
      update_settings: :courses,
      student_view_student: :courses,
      show: :courses,
      update: :courses,
      batch_update: :courses,
      reset_content: :courses,
      effective_due_dates: :courses,
      permissions: :courses
    }.freeze,
    content_imports: {
      copy_course_status: :courses,
      copy_course_content: :courses
    }.freeze,
    custom_gradebook_columns_api: {
      index: :custom_gradebook_columns,
      create: :custom_gradebook_columns,
      update: :custom_gradebook_columns,
      destroy: :custom_gradebook_columns,
      reorder: :custom_gradebook_columns
    }.freeze,
    custom_gradebook_column_data_api: {
      index: :custom_gradebook_columns,
      update: :custom_gradebook_columns,
      bulk_update: :custom_gradebook_columns
    }.freeze,
    discussion_topics: {
      index: :discussion_topics,
      create: :discussion_topics,
      update: :discussion_topics,
      destroy: :discussion_topics,
      reorder: :discussion_topics
    }.freeze,
    discussion_entries: {
      update: :discussion_topics,
      destroy: :discussion_topics
    }.freeze,
    discussion_topics_api: {
      show: :discussion_topics,
      view: :discussion_topics,
      add_entry: :discussion_topics,
      entries: :discussion_topics,
      add_reply: :discussion_topics,
      replies: :discussion_topics,
      entry_list: :discussion_topics,
      mark_topic_read: :discussion_topics,
      mark_topic_unread: :discussion_topics,
      mark_all_read: :discussion_topics,
      mark_all_unread: :discussion_topics,
      mark_entry_read: :discussion_topics,
      mark_entry_unread: :discussion_topics,
      rate_entry: :discussion_topics,
      subscribe_topic: :discussion_topics,
      unsubscribe_topic: :discussion_topics
    }.freeze,
    canvadoc_sessions: {
    }.freeze,
    terms: {
      create: :enrollment_terms,
      update: :enrollment_terms,
      destroy: :enrollment_terms
    }.freeze,
    terms_api: {
      index: :enrollment_terms,
      show: :enrollment_terms
    }.freeze,
    enrollments_api: {
      index: :enrollments,
      show: :enrollments,
      create: :enrollments,
      destroy: :enrollments,
      accept: :enrollments,
      reject: :enrollments,
      reactivate: :enrollments,
      last_attended: :enrollments
    }.freeze,
    errors: {
      create: :error_reports
    }.freeze,
    external_tools: {
      index: :external_tools,
      generate_sessionless_launch: :external_tools,
      show: :external_tools,
      create: :external_tools,
      update: :external_tools,
      destroy: :external_tools,
      add_rce_favorite: :external_tools,
      remove_rce_favorite: :external_tools
    }.freeze,
    favorites: {
      list_favorite_courses: :favorites,
      list_favorite_groups: :favorites,
      add_favorite_course: :favorites,
      add_favorite_groups: :favorites,
      remove_favorite_course: :favorites,
      remove_favorite_groups: :favorites,
      reset_course_favorites: :favorites,
      reset_groups_favorites: :favorites
    }.freeze,
    feature_flags: {
      index: :feature_flags,
      enabled_features: :feature_flags,
      show: :feature_flags,
      update: :feature_flags,
      delete: :feature_flags
    }.freeze,
    files: {
      api_quota: :files,
      api_index: :files,
      public_url: :files,
      api_show: :files,
      api_update: :files,
      destroy: :files,
      reset_verifier: :files
    }.freeze,
    folders: {
      api_index: :files,
      list_all_folders: :files,
      resolve_path: :files,
      show: :files,
      update: :files,
      create: :files,
      api_destroy: :files,
      create_file: :files,
      copy_file: :files,
      copy_folder: :files,
      media_folder: :files
    }.freeze,
    usage_rights: {
      set_usage_rights: :files,
      remove_usage_rights: :files,
      licenses: :files
    }.freeze,
    grade_change_audit_api: {
      for_assignment: :grade_change_log,
      for_course: :grade_change_log,
      for_student: :grade_change_log,
      for_grader: :grade_change_log,
      query: :grade_change_log
    }.freeze,
    gradebook_history_api: {
      days: :gradebook_history,
      day_details: :gradebook_history,
      submissions: :gradebook_history,
      feed: :gradebook_history
    }.freeze,
    grading_periods: {
      index: :grading_periods,
      show: :grading_periods,
      update: :grading_periods,
      destroy: :grading_periods
    }.freeze,
    grading_standards_api: {
      create: :grading_standards,
      context_index: :grading_standards,
      context_show: :grading_standards
    }.freeze,
    group_categories: {
      index: :group_categories,
      show: :group_categories,
      create: :group_categories,
      import: :group_categories,
      update: :group_categories,
      destroy: :group_categories,
      groups: :group_categories,
      export: :group_categories,
      users: :group_categories,
      assign_unassigned_members: :group_categories
    }.freeze,
    groups: {
      index: :groups,
      context_index: :groups,
      show: :groups,
      create: :groups,
      update: :groups,
      destroy: :groups,
      invite: :groups,
      users: :groups,
      create_file: :groups,
      preview_html: :groups,
      activity_stream: :groups,
      activity_stream_summary: :groups,
      permissions: :groups
    }.freeze,
    group_memberships: {
      index: :groups,
      show: :groups,
      create: :groups,
      update: :groups,
      destroy: :groups
    }.freeze,
    history: {
      index: :history
    }.freeze,
    internet_image: {
      image_search: :image_search,
      image_selection: :image_search
    }.freeze,
    immersive_reader: {
    }.freeze,
    jwts: {
      create: :jwts,
      refresh: :jwts
    }.freeze,
    late_policy: {
      show: :late_policy,
      create: :late_policy,
      update: :late_policy
    }.freeze,
    line_items: {
      create: :line_items,
      update: :line_items,
      show: :line_items,
      index: :line_items,
      destroy: :line_items
    }.freeze,
    results: {
      create: :liveassessments,
      index: :result,
      show: :result
    }.freeze,
    assessments: {
      create: :liveassessments,
      index: :liveassessments
    }.freeze,
    pseudonyms: {
      index: :logins,
      create: :logins,
      update: :logins,
      destroy: :logins
    }.freeze,
    media_tracks: {
      index: :media_objects,
      update: :media_objects
    }.freeze,
    media_objects: {
      index: :media_objects,
      update_media_object: :media_objects
    }.freeze,
    moderation_set: {
      index: :moderated_grading,
      create: :moderated_grading
    }.freeze,
    provisional_grades: {
      bulk_select: :moderated_grading,
      status: :moderated_grading,
      select: :moderated_grading,
      publish: :moderated_grading
    }.freeze,
    anonymous_provisional_grades: {
      status: :moderated_grading
    }.freeze,
    context_modules_api: {
      index: :modules,
      show: :modules,
      create: :modules,
      update: :modules,
      destroy: :modules,
      relock: :modules
    }.freeze,
    context_module_items_api: {
      index: :modules,
      show: :modules,
      create: :modules,
      update: :modules,
      select_mastery_path: :modules,
      destroy: :modules,
      mark_as_done: :modules,
      item_sequence: :modules,
      mark_item_read: :modules
    }.freeze,
    names_and_roles: {
      course_index: :names_and_role,
      group_index: :names_and_role
    }.freeze,
    notification_preferences: {
      index: :notification_preferences,
      category_index: :notification_preferences,
      show: :notification_preferences,
      update: :notification_preferences,
      update_preferences_by_category: :notification_preferences,
      update_all: :notification_preferences
    }.freeze,
    originality_reports_api: {
      create: :originality_reports,
      update: :originality_reports,
      show: :originality_reports
    }.freeze,
    outcome_groups_api: {
      redirect: :outcome_groups,
      index: :outcome_groups,
      link_index: :outcome_groups,
      show: :outcome_groups,
      update: :outcome_groups,
      destroy: :outcome_groups,
      outcomes: :outcome_groups,
      link: :outcome_groups,
      unlink: :outcome_groups,
      subgroups: :outcome_groups,
      create: :outcome_groups,
      import: :outcome_groups
    }.freeze,
    outcome_imports_api: {
      create: :outcome_imports,
      show: :outcome_imports
    }.freeze,
    outcome_results: {
      index: :outcome_results,
      rollups: :outcome_results
    }.freeze,
    outcomes_api: {
      show: :outcomes,
      update: :outcomes,
      outcome_alignments: :outcomes
    }.freeze,
    wiki_pages_api: {
      show_front_page: :pages,
      duplicate: :pages,
      update_front_page: :pages,
      index: :pages,
      create: :pages,
      show: :pages,
      update: :pages,
      destroy: :pages,
      revisions: :pages,
      show_revision: :pages,
      revert: :pages
    }.freeze,
    peer_reviews_api: {
      index: :peer_reviews,
      create: :peer_reviews,
      destroy: :peer_reviews
    }.freeze,
    plagiarism_assignments_api: {
      show: :plagiarism_detection_platform_assignments
    }.freeze,
    users_api: {
      show: :plagiarism_detection_platform_users,
      group_index: :plagiarism_detection_platform_users
    }.freeze,
    submissions_api: {
      show: :submissions,
      history: :plagiarism_detection_submissions,
      index: :submissions,
      for_students: :submissions,
      create_file: :submissions,
      update: :submissions,
      gradeable_students: :submissions,
      multiple_gradeable_students: :submissions,
      bulk_update: :submissions,
      mark_submission_read: :submissions,
      mark_submission_unread: :submissions,
      submission_summary: :submissions
    }.freeze,
    planner: {
      index: :planner
    }.freeze,
    planner_notes: {
      index: :planner,
      show: :planner,
      update: :planner,
      create: :planner,
      destroy: :planner
    }.freeze,
    planner_overrides: {
      index: :planner,
      show: :planner,
      update: :planner,
      create: :planner,
      destroy: :planner
    }.freeze,
    poll_sessions: {
      index: :poll_sessions,
      show: :poll_sessions,
      create: :poll_sessions,
      update: :poll_sessions,
      destroy: :poll_sessions,
      open: :poll_sessions,
      close: :poll_sessions,
      opened: :poll_sessions,
      closed: :poll_sessions
    }.freeze,
    poll_choices: {
      index: :pollchoices,
      show: :pollchoices,
      create: :pollchoices,
      update: :pollchoices,
      destroy: :pollchoices
    }.freeze,
    poll_submissions: {
      show: :pollsubmissions,
      create: :pollsubmissions
    }.freeze,
    polls: {
      index: :polls,
      show: :polls,
      create: :polls,
      update: :polls,
      destroy: :polls
    }.freeze,
    outcome_proficiency_api: {
      create: :proficiency_ratings,
      show: :proficiency_ratings
    }.freeze,
    progress: {
      show: :progress
    }.freeze,
    public_jwk: {
      update: :public_jwk
    }.freeze,
    quiz_assignment_overrides: {
      index: :quiz_assignment_overrides,
      new_quizzes: :quiz_assignment_overrides
    }.freeze,
    quiz_extensions: {
      create: :quiz_extensions
    }.freeze,
    quiz_ip_filters: {
      index: :quiz_ip_filters
    }.freeze,
    quiz_groups: {
      show: :quiz_question_groups,
      create: :quiz_question_groups,
      update: :quiz_question_groups,
      destroy: :quiz_question_groups,
      reorder: :quiz_question_groups
    }.freeze,
    quiz_questions: {
      index: :quiz_questions,
      show: :quiz_questions,
      create: :quiz_questions,
      update: :quiz_questions,
      destroy: :quiz_questions
    }.freeze,
    quiz_reports: {
      index: :quiz_reports,
      create: :quiz_reports,
      show: :quiz_reports,
      abort: :quiz_reports
    }.freeze,
    quiz_statistics: {
      index: :quiz_statistics
    }.freeze,
    quiz_submission_events_api: {
      create: :quiz_submission_events,
      index: :quiz_submission_events
    }.freeze,
    quiz_submission_files: {
      create: :quiz_submission_files
    }.freeze,
    quiz_submission_questions: {
      index: :quiz_submission_questions,
      answer: :quiz_submission_questions,
      flag: :quiz_submission_questions,
      unflag: :quiz_submission_questions
    }.freeze,
    quiz_submission_users: {
      message: :quiz_submission_user_list
    }.freeze,
    quiz_submissions_api: {
      index: :quiz_submissions,
      submission: :quiz_submissions,
      show: :quiz_submissions,
      create: :quiz_submissions,
      update: :quiz_submissions,
      complete: :quiz_submissions,
      time: :quiz_submissions
    }.freeze,
    quizzes_api: {
      index: :quizzes,
      show: :quizzes,
      create: :quizzes,
      update: :quizzes,
      destroy: :quizzes,
      reorder: :quizzes,
      validate_access_code: :quizzes
    }.freeze,
    role_overrides: {
      api_index: :roles,
      show: :roles,
      add_role: :roles,
      remove_role: :roles,
      activate_role: :roles,
      update: :roles
    }.freeze,
    rubrics: {
      create: :rubrics,
      update: :rubrics,
      destroy: :rubrics
    }.freeze,
    rubrics_api: {
      index: :rubrics,
      show: :rubrics
    }.freeze,
    rubric_assessments: {
      create: :rubrics,
      update: :rubrics,
      destroy: :rubrics
    }.freeze,
    rubric_associations: {
      create: :rubrics,
      update: :rubrics,
      destroy: :rubrics
    }.freeze,
    sis_import_errors_api: {
      index: :sis_import_errors
    }.freeze,
    sis_imports_api: {
      index: :sis_imports,
      importing: :sis_imports,
      create: :sis_imports,
      show: :sis_imports,
      restore_states: :sis_imports,
      abort: :sis_imports,
      abort_all_pending: :sis_imports
    }.freeze,
    sis_api: {
      sis_assignments: :sis_integration
    }.freeze,
    disable_post_to_sis_api: {
      disable_post_to_sis: :sis_integration
    }.freeze,
    scores: {
      create: :score
    }.freeze,
    search: {
      recipients: :search,
      all_courses: :search
    }.freeze,
    sections: {
      index: :sections,
      create: :sections,
      crosslist: :sections,
      uncrosslist: :sections,
      update: :sections,
      show: :sections,
      destroy: :sections
    }.freeze,
    services_api: {
      show_kaltura_config: :services,
      start_kaltura_session: :services
    }.freeze,
    shared_brand_configs: {
      create: :shared_brand_configs,
      update: :shared_brand_configs,
      destroy: :shared_brand_configs
    }.freeze,
    submission_comments_api: {
      update: :submission_comments,
      destroy: :submission_comments,
      create_file: :submission_comments
    }.freeze,
    submissions: {
      create: :submissions
    }.freeze,
    tabs: {
      index: :tabs,
      update: :tabs
    }.freeze,
    user_observees: {
      index: :user_observees,
      observers: :user_observees,
      create: :user_observees,
      show: :user_observees,
      show_observer: :user_observees,
      update: :user_observees,
      destroy: :user_observees
    }.freeze,
    observer_pairing_codes_api: {
      create: :user_observees
    }.freeze,
    users: {
      api_index: :users,
      activity_stream: :users,
      activity_stream_summary: :users,
      todo_items: :users,
      todo_item_count: :users,
      upcoming_events: :users,
      missing_submissions: :users,
      ignore_stream_item: :users,
      ignore_all_stream_items: :users,
      create_file: :users,
      api_show: :users,
      create: :users,
      create_self_registered_user: :users,
      settings: :users,
      get_custom_colors: :users,
      get_custom_color: :users,
      set_custom_color: :users,
      get_dashboard_positions: :users,
      set_dashboard_positions: :users,
      update: :users,
      merge_into: :users,
      split: :users,
      pandata_events_token: :users,
      user_graded_submissions: :users
    }.freeze,
    profile: {
      settings: :users,
      profile_pics: :users
    }.freeze,
    page_views: {
      index: :users
    }.freeze,
    custom_data: {
      set_data: :users,
      get_data: :users,
      delete_data: :users
    }.freeze,
    course_nicknames: {
      index: :users,
      show: :users,
      update: :users,
      delete: :users,
      clear: :users
    }.freeze,
    subscriptions_api: {
      create: :webhooks_subscriptions,
      destroy: :webhooks_subscriptions,
      show: :webhooks_subscriptions,
      update: :webhooks_subscriptions,
      index: :webhooks_subscriptions
    }.freeze,
    epub_exports: {
      index: :epub_exports,
      create: :epub_exports,
      show: :epub_exports
    }.freeze
  }.freeze

  RESOURCE_NAMES = {
    oauth2: -> {I18n.t('OAuth 2')},
    peer_services: -> {I18n.t('Peer Services')},
    api_token_scopes: -> {I18n.t('API Token Scopes')},
    account_notifications: -> {I18n.t('Account Notifications')},
    account_reports: -> {I18n.t('Account Reports')},
    accounts: -> {I18n.t('Accounts')},
    accounts_lti: -> {I18n.t('Accounts (LTI)')},
    admins: -> {I18n.t('Admins')},
    announcement_external_feeds: -> {I18n.t('Announcement External Feeds')},
    announcements: -> {I18n.t('Announcements')},
    appointment_groups: -> {I18n.t('Appointment Groups')},
    assignment_extensions: -> {I18n.t('Assignment Extensions')},
    assignment_groups: -> {I18n.t('Assignment Groups')},
    assignments: -> {I18n.t('Assignments')},
    authentication_providers: -> {I18n.t('Authentication Providers')},
    authentications_log: -> {I18n.t('Authentications Log')},
    blueprint_courses: -> {I18n.t('Blueprint Courses')},
    bookmarks: -> {I18n.t('Bookmarks')},
    brand_configs: -> {I18n.t('Brand Configs')},
    calendar_events: -> {I18n.t('Calendar Events')},
    collaborations: -> {I18n.t('Collaborations')},
    commmessages: -> {I18n.t('CommMessages')},
    communication_channels: -> {I18n.t('Communication Channels')},
    conferences: -> {I18n.t('Conferences')},
    content_exports: -> {I18n.t('Content Exports')},
    content_migrations: -> {I18n.t('Content Migrations')},
    content_security_policy_settings: -> {I18n.t('Content Security Policy Settings')},
    content_shares: -> {I18n.t('Content Shares')},
    conversations: -> {I18n.t('Conversations')},
    course_audit_log: -> {I18n.t('Course Audit log')},
    course_quiz_extensions: -> {I18n.t('Course Quiz Extensions')},
    courses: -> {I18n.t('Courses')},
    custom_gradebook_columns: -> {I18n.t('Custom Gradebook Columns')},
    discussion_topics: -> {I18n.t('Discussion Topics')},
    enrollment_terms: -> {I18n.t('Enrollment Terms')},
    enrollments: -> {I18n.t('Enrollments')},
    error_reports: -> {I18n.t('Error Reports')},
    external_tools: -> {I18n.t('External Tools')},
    favorites: -> {I18n.t('Favorites')},
    feature_flags: -> {I18n.t('Feature Flags')},
    files: -> {I18n.t('Files')},
    grade_change_log: -> {I18n.t('Grade Change Log')},
    gradebook_history: -> {I18n.t('Gradebook History')},
    grading_periods: -> {I18n.t('Grading Periods')},
    grading_standards: -> {I18n.t('Grading Standards')},
    group_categories: -> {I18n.t('Group Categories')},
    groups: -> {I18n.t('Groups')},
    history: -> {I18n.t('History')},
    image_search: -> {I18n.t('Image Search')},
    jwts: -> {I18n.t('JWTs')},
    late_policy: -> {I18n.t('Late Policy')},
    line_items: -> {I18n.t('Line Items')},
    liveassessments: -> {I18n.t('LiveAssessments')},
    logins: -> {I18n.t('Logins')},
    media_objects: -> {I18n.t('Media Objects')},
    moderated_grading: -> {I18n.t('Moderated Grading')},
    modules: -> {I18n.t('Modules')},
    names_and_role: -> {I18n.t('Names and Role')},
    notification_preferences: -> {I18n.t('Notification Preferences')},
    originality_reports: -> {I18n.t('Originality Reports')},
    outcome_groups: -> {I18n.t('Outcome Groups')},
    outcome_imports: -> {I18n.t('Outcome Imports')},
    outcome_results: -> {I18n.t('Outcome Results')},
    outcomes: -> {I18n.t('Outcomes')},
    pages: -> {I18n.t('Pages')},
    peer_reviews: -> {I18n.t('Peer Reviews')},
    plagiarism_detection_platform_assignments: -> {I18n.t('Plagiarism Detection Platform Assignments')},
    plagiarism_detection_platform_users: -> {I18n.t('Plagiarism Detection Platform Users')},
    plagiarism_detection_submissions: -> {I18n.t('Plagiarism Detection Submissions')},
    planner: -> {I18n.t('Planner')},
    poll_sessions: -> {I18n.t('Poll Sessions')},
    pollchoices: -> {I18n.t('PollChoices')},
    pollsubmissions: -> {I18n.t('PollSubmissions')},
    polls: -> {I18n.t('Polls')},
    proficiency_ratings: -> {I18n.t('Proficiency Ratings')},
    progress: -> {I18n.t('Progress')},
    public_jwk: -> {I18n.t('Public JWK')},
    quiz_assignment_overrides: -> {I18n.t('Quiz Assignment Overrides')},
    quiz_extensions: -> {I18n.t('Quiz Extensions')},
    quiz_ip_filters: -> {I18n.t('Quiz IP Filters')},
    quiz_question_groups: -> {I18n.t('Quiz Question Groups')},
    quiz_questions: -> {I18n.t('Quiz Questions')},
    quiz_reports: -> {I18n.t('Quiz Reports')},
    quiz_statistics: -> {I18n.t('Quiz Statistics')},
    quiz_submission_events: -> {I18n.t('Quiz Submission Events')},
    quiz_submission_files: -> {I18n.t('Quiz Submission Files')},
    quiz_submission_questions: -> {I18n.t('Quiz Submission Questions')},
    quiz_submission_user_list: -> {I18n.t('Quiz Submission User List')},
    quiz_submissions: -> {I18n.t('Quiz Submissions')},
    quizzes: -> {I18n.t('Quizzes')},
    result: -> {I18n.t('Result')},
    roles: -> {I18n.t('Roles')},
    rubrics: -> {I18n.t('Rubrics')},
    sis_import_errors: -> {I18n.t('SIS Import Errors')},
    sis_imports: -> {I18n.t('SIS Imports')},
    sis_integration: -> {I18n.t('SIS Integration')},
    score: -> {I18n.t('Score')},
    search: -> {I18n.t('Search')},
    sections: -> {I18n.t('Sections')},
    services: -> {I18n.t('Services')},
    shared_brand_configs: -> {I18n.t('Shared Brand Configs')},
    submission_comments: -> {I18n.t('Submission Comments')},
    submissions: -> {I18n.t('Submissions')},
    tabs: -> {I18n.t('Tabs')},
    user_observees: -> {I18n.t('User Observees')},
    users: -> {I18n.t('Users')},
    webhooks_subscriptions: -> {I18n.t('Webhooks Subscriptions')},
    epub_exports: -> {I18n.t('ePub Exports')}
  }.freeze

  def self.lookup_resource(controller, action)
    controller_class = controller.to_s.split('/').last.to_sym
    SCOPE_MAP.dig(controller_class, action)
  end

  def self.name_for_resource(resource)
    RESOURCE_NAMES[resource]&.call
  end

end
