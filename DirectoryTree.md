```
.
├── CONTRIBUTING.md
├── COPYRIGHT
├── Dockerfile
├── Dockerfile.githook
├── Dockerfile.jenkins
├── Dockerfile.jenkins-cache
├── Dockerfile.jenkins.final
├── Dockerfile.jenkins.js
├── Dockerfile.jenkins.linters
├── Dockerfile.jenkins.ruby-runner
├── Dockerfile.jenkins.webpack-assets
├── Dockerfile.jenkins.webpack-builder
├── Dockerfile.jenkins.webpack-cache
├── Dockerfile.jenkins.webpack-runner
├── Dockerfile.jenkins.yarn-runner
├── Dockerfile.master-bouncer
├── Dockerfile.package-translations
├── Dockerfile.production
├── Dockerfile.puma
├── Gemfile
├── Gemfile.d
│   ├── _before.rb
│   ├── app.rb
│   ├── assets.rb
│   ├── development.rb
│   ├── i18n_tools_and_rake_tasks.rb
│   ├── icu.rb
│   ├── plugins.rb
│   ├── postgres.rb
│   ├── redis.rb
│   ├── rubocop.rb
│   ├── rubocop.rb.lock
│   ├── test.rb
│   └── ~after.rb
├── Gemfile.lock
├── Jenkinsfile
├── Jenkinsfile.axe
├── Jenkinsfile.contract-tests
├── Jenkinsfile.coverage
├── Jenkinsfile.coverage-js
├── Jenkinsfile.crystalball
├── Jenkinsfile.dive
├── Jenkinsfile.docker-smoke
├── Jenkinsfile.docker-sync
├── Jenkinsfile.dynamodb
├── Jenkinsfile.js
├── Jenkinsfile.junit-uploader
├── Jenkinsfile.master-bouncer-check-all
├── Jenkinsfile.package-translations
├── Jenkinsfile.postgres
├── Jenkinsfile.redis
├── Jenkinsfile.rspecq
├── Jenkinsfile.selenium.flakey_spec_catcher
├── Jenkinsfile.selenium.performance.chrome
├── Jenkinsfile.test-subbuild
├── Jenkinsfile.vendored-gems
├── Jenkinsfile.xbrowser
├── LICENSE
├── README.md
├── Rakefile
├── SECURITY.md
├── app
│   ├── controllers
│   │   ├── accessibility_controller.rb
│   │   ├── account_calendars_api_controller.rb
│   │   ├── account_grading_settings_controller.rb
│   │   ├── account_notifications_controller.rb
│   │   ├── account_reports_controller.rb
│   │   ├── accounts_controller.rb
│   │   ├── admins_controller.rb
│   │   ├── alerts_controller.rb
│   │   ├── analytics_hub_controller.rb
│   │   ├── announcements_api_controller.rb
│   │   ├── announcements_controller.rb
│   │   ├── anonymous_provisional_grades_controller.rb
│   │   ├── anonymous_submissions_controller.rb
│   │   ├── app_center_controller.rb
│   │   ├── application_controller.rb
│   │   ├── appointment_groups_controller.rb
│   │   ├── assessment_questions_controller.rb
│   │   ├── assignment_extensions_controller.rb
│   │   ├── assignment_groups_api_controller.rb
│   │   ├── assignment_groups_controller.rb
│   │   ├── assignment_overrides_controller.rb
│   │   ├── assignments_api_controller.rb
│   │   ├── assignments_controller.rb
│   │   ├── auditor_api_controller.rb
│   │   ├── authentication_audit_api_controller.rb
│   │   ├── authentication_providers_controller.rb
│   │   ├── blackout_dates_controller.rb
│   │   ├── block_editor_templates_api_controller.rb
│   │   ├── block_editors_controller.rb
│   │   ├── bookmarks
│   │   │   └── bookmarks_controller.rb
│   │   ├── brand_configs_api_controller.rb
│   │   ├── brand_configs_controller.rb
│   │   ├── calendar_events_api_controller.rb
│   │   ├── calendar_events_controller.rb
│   │   ├── calendars_controller.rb
│   │   ├── canvadoc_sessions_controller.rb
│   │   ├── career_controller.rb
│   │   ├── collaborations_controller.rb
│   │   ├── comm_messages_api_controller.rb
│   │   ├── communication_channels_controller.rb
│   │   ├── concerns
│   │   │   ├── captcha_validation.rb
│   │   │   ├── grading_scheme_serializer.rb
│   │   │   ├── granular_permission_enforcement.rb
│   │   │   ├── horizon_mode.rb
│   │   │   └── k5_mode.rb
│   │   ├── conditional_release
│   │   │   ├── concerns
│   │   │   │   ├── api_to_nested_attributes.rb
│   │   │   │   └── permitted_api_parameters.rb
│   │   │   ├── rules_controller.rb
│   │   │   └── stats_controller.rb
│   │   ├── conferences_controller.rb
│   │   ├── content_exports_api_controller.rb
│   │   ├── content_exports_controller.rb
│   │   ├── content_imports_controller.rb
│   │   ├── content_migrations_controller.rb
│   │   ├── content_shares_controller.rb
│   │   ├── context_controller.rb
│   │   ├── context_module_items_api_controller.rb
│   │   ├── context_modules_api_controller.rb
│   │   ├── context_modules_controller.rb
│   │   ├── conversations_controller.rb
│   │   ├── course_audit_api_controller.rb
│   │   ├── course_nicknames_controller.rb
│   │   ├── course_paces_controller.rb
│   │   ├── course_pacing
│   │   │   ├── bulk_student_enrollment_paces_api_controller.rb
│   │   │   ├── pace_contexts_api_controller.rb
│   │   │   ├── paces_api_controller.rb
│   │   │   ├── section_paces_api_controller.rb
│   │   │   └── student_enrollment_paces_api_controller.rb
│   │   ├── course_reports_controller.rb
│   │   ├── courses_controller.rb
│   │   ├── crocodoc_sessions_controller.rb
│   │   ├── csp_settings_controller.rb
│   │   ├── custom_data_controller.rb
│   │   ├── custom_gradebook_column_data_api_controller.rb
│   │   ├── custom_gradebook_columns_api_controller.rb
│   │   ├── developer_key_account_bindings_controller.rb
│   │   ├── developer_keys_controller.rb
│   │   ├── disable_post_to_sis_api_controller.rb
│   │   ├── discussion_entries_controller.rb
│   │   ├── discussion_topic_users_controller.rb
│   │   ├── discussion_topics_api_controller.rb
│   │   ├── discussion_topics_controller.rb
│   │   ├── docviewer_audit_events_controller.rb
│   │   ├── enrollments_api_controller.rb
│   │   ├── eportfolio_categories_controller.rb
│   │   ├── eportfolio_entries_controller.rb
│   │   ├── eportfolios_api_controller.rb
│   │   ├── eportfolios_controller.rb
│   │   ├── epub_exports_controller.rb
│   │   ├── equation_images_controller.rb
│   │   ├── errors_controller.rb
│   │   ├── external_content_controller.rb
│   │   ├── external_feeds_controller.rb
│   │   ├── external_tools_controller.rb
│   │   ├── favorites_controller.rb
│   │   ├── feature_flags_controller.rb
│   │   ├── file_previews_controller.rb
│   │   ├── files_controller.rb
│   │   ├── filters
│   │   │   ├── live_assessments.rb
│   │   │   ├── polling.rb
│   │   │   ├── quiz_submissions.rb
│   │   │   └── quizzes.rb
│   │   ├── folders_controller.rb
│   │   ├── grade_change_audit_api_controller.rb
│   │   ├── gradebook_csvs_controller.rb
│   │   ├── gradebook_filters_api_controller.rb
│   │   ├── gradebook_history_api_controller.rb
│   │   ├── gradebook_settings_controller.rb
│   │   ├── gradebook_uploads_controller.rb
│   │   ├── gradebooks_controller.rb
│   │   ├── grading_period_sets_controller.rb
│   │   ├── grading_periods_controller.rb
│   │   ├── grading_schemes_json_controller.rb
│   │   ├── grading_standards_api_controller.rb
│   │   ├── grading_standards_controller.rb
│   │   ├── graphql_controller.rb
│   │   ├── group_categories_controller.rb
│   │   ├── group_memberships_controller.rb
│   │   ├── groups_controller.rb
│   │   ├── history_controller.rb
│   │   ├── horizon_controller.rb
│   │   ├── immersive_reader_controller.rb
│   │   ├── info_controller.rb
│   │   ├── inst_access_tokens_controller.rb
│   │   ├── jobs_controller.rb
│   │   ├── jobs_v2_controller.rb
│   │   ├── jwts_controller.rb
│   │   ├── late_policy_controller.rb
│   │   ├── learn_platform_controller.rb
│   │   ├── learning_object_dates_controller.rb
│   │   ├── legal_information_controller.rb
│   │   ├── live_assessments
│   │   │   ├── assessments_controller.rb
│   │   │   └── results_controller.rb
│   │   ├── login
│   │   │   ├── apple_controller.rb
│   │   │   ├── canvas_controller.rb
│   │   │   ├── cas_controller.rb
│   │   │   ├── clever_controller.rb
│   │   │   ├── email_verify_controller.rb
│   │   │   ├── external_auth_observers_controller.rb
│   │   │   ├── facebook_controller.rb
│   │   │   ├── github_controller.rb
│   │   │   ├── google_controller.rb
│   │   │   ├── ldap_controller.rb
│   │   │   ├── linkedin_controller.rb
│   │   │   ├── microsoft_controller.rb
│   │   │   ├── oauth2_controller.rb
│   │   │   ├── oauth_base_controller.rb
│   │   │   ├── oauth_controller.rb
│   │   │   ├── openid_connect_controller.rb
│   │   │   ├── otp_controller.rb
│   │   │   ├── saml_controller.rb
│   │   │   ├── saml_idp_discovery_controller.rb
│   │   │   └── shared.rb
│   │   ├── login_controller.rb
│   │   ├── lti
│   │   │   ├── account_external_tools_controller.rb
│   │   │   ├── account_lookup_controller.rb
│   │   │   ├── asset_processor_launch_controller.rb
│   │   │   ├── concerns
│   │   │   │   ├── oembed.rb
│   │   │   │   ├── parent_frame.rb
│   │   │   │   └── sessionless_launches.rb
│   │   │   ├── context_controls_controller.rb
│   │   │   ├── data_services_controller.rb
│   │   │   ├── deployments_controller.rb
│   │   │   ├── eula_launch_controller.rb
│   │   │   ├── feature_flags_controller.rb
│   │   │   ├── ims
│   │   │   │   ├── access_token_helper.rb
│   │   │   │   ├── asset_processor_controller.rb
│   │   │   │   ├── asset_processor_eula_controller.rb
│   │   │   │   ├── authentication_controller.rb
│   │   │   │   ├── authorization_controller.rb
│   │   │   │   ├── concerns
│   │   │   │   │   ├── advantage_services.rb
│   │   │   │   │   ├── deep_linking_modules.rb
│   │   │   │   │   ├── deep_linking_services.rb
│   │   │   │   │   ├── gradebook_services.rb
│   │   │   │   │   └── lti_services.rb
│   │   │   │   ├── deep_linking_controller.rb
│   │   │   │   ├── dynamic_registration_controller.rb
│   │   │   │   ├── line_items_controller.rb
│   │   │   │   ├── names_and_roles_controller.rb
│   │   │   │   ├── notice_handlers_controller.rb
│   │   │   │   ├── progress_controller.rb
│   │   │   │   ├── providers
│   │   │   │   │   ├── course_memberships_provider.rb
│   │   │   │   │   ├── group_memberships_provider.rb
│   │   │   │   │   └── memberships_provider.rb
│   │   │   │   ├── results_controller.rb
│   │   │   │   ├── scores_controller.rb
│   │   │   │   ├── tool_consumer_profile_controller.rb
│   │   │   │   ├── tool_proxy_controller.rb
│   │   │   │   └── tool_setting_controller.rb
│   │   │   ├── launch_services.rb
│   │   │   ├── lti_apps_controller.rb
│   │   │   ├── membership_service_controller.rb
│   │   │   ├── message_controller.rb
│   │   │   ├── originality_reports_api_controller.rb
│   │   │   ├── plagiarism_assignments_api_controller.rb
│   │   │   ├── platform_storage_controller.rb
│   │   │   ├── public_jwk_controller.rb
│   │   │   ├── registrations_controller.rb
│   │   │   ├── resource_links_controller.rb
│   │   │   ├── submissions_api_controller.rb
│   │   │   ├── subscriptions_api_controller.rb
│   │   │   ├── subscriptions_validator.rb
│   │   │   ├── token_controller.rb
│   │   │   ├── tool_configurations_api_controller.rb
│   │   │   ├── tool_default_icon_controller.rb
│   │   │   ├── tool_proxy_controller.rb
│   │   │   └── users_api_controller.rb
│   │   ├── lti_api_controller.rb
│   │   ├── master_courses
│   │   │   └── master_templates_controller.rb
│   │   ├── media_objects_controller.rb
│   │   ├── media_tracks_controller.rb
│   │   ├── messages_controller.rb
│   │   ├── microsoft_sync
│   │   │   └── groups_controller.rb
│   │   ├── migration_issues_controller.rb
│   │   ├── moderation_set_controller.rb
│   │   ├── module_assignment_overrides_controller.rb
│   │   ├── notification_preferences_controller.rb
│   │   ├── oauth2_provider_controller.rb
│   │   ├── oauth_proxy_controller.rb
│   │   ├── observer_alert_thresholds_api_controller.rb
│   │   ├── observer_alerts_api_controller.rb
│   │   ├── observer_pairing_codes_api_controller.rb
│   │   ├── one_time_passwords_controller.rb
│   │   ├── outcome_groups_api_controller.rb
│   │   ├── outcome_groups_controller.rb
│   │   ├── outcome_imports_api_controller.rb
│   │   ├── outcome_proficiency_api_controller.rb
│   │   ├── outcome_results_controller.rb
│   │   ├── outcomes_academic_benchmark_import_api_controller.rb
│   │   ├── outcomes_api_controller.rb
│   │   ├── outcomes_controller.rb
│   │   ├── page_comments_controller.rb
│   │   ├── page_views_controller.rb
│   │   ├── peer_reviews_api_controller.rb
│   │   ├── planner_controller.rb
│   │   ├── planner_notes_controller.rb
│   │   ├── planner_overrides_controller.rb
│   │   ├── plugins_controller.rb
│   │   ├── polling
│   │   │   ├── poll_choices_controller.rb
│   │   │   ├── poll_sessions_controller.rb
│   │   │   ├── poll_submissions_controller.rb
│   │   │   └── polls_controller.rb
│   │   ├── profile_controller.rb
│   │   ├── progress_controller.rb
│   │   ├── provisional_grades_base_controller.rb
│   │   ├── provisional_grades_controller.rb
│   │   ├── pseudonym_sessions_controller.rb
│   │   ├── pseudonyms_controller.rb
│   │   ├── question_banks_controller.rb
│   │   ├── quizzes
│   │   │   ├── course_quiz_extensions_controller.rb
│   │   │   ├── outstanding_quiz_submissions_controller.rb
│   │   │   ├── quiz_assignment_overrides_controller.rb
│   │   │   ├── quiz_extensions_controller.rb
│   │   │   ├── quiz_groups_controller.rb
│   │   │   ├── quiz_ip_filters_controller.rb
│   │   │   ├── quiz_questions_controller.rb
│   │   │   ├── quiz_reports_controller.rb
│   │   │   ├── quiz_statistics_controller.rb
│   │   │   ├── quiz_submission_events_api_controller.rb
│   │   │   ├── quiz_submission_events_controller.rb
│   │   │   ├── quiz_submission_files_controller.rb
│   │   │   ├── quiz_submission_questions_controller.rb
│   │   │   ├── quiz_submission_users_controller.rb
│   │   │   ├── quiz_submissions_api_controller.rb
│   │   │   ├── quiz_submissions_controller.rb
│   │   │   ├── quizzes_api_controller.rb
│   │   │   └── quizzes_controller.rb
│   │   ├── quizzes_next
│   │   │   └── quizzes_api_controller.rb
│   │   ├── release_notes_controller.rb
│   │   ├── rich_content_api_controller.rb
│   │   ├── role_overrides_controller.rb
│   │   ├── rubric_assessment_imports_controller.rb
│   │   ├── rubric_assessments_controller.rb
│   │   ├── rubric_associations_controller.rb
│   │   ├── rubrics_api_controller.rb
│   │   ├── rubrics_controller.rb
│   │   ├── scopes_api_controller.rb
│   │   ├── search_controller.rb
│   │   ├── sections_controller.rb
│   │   ├── security_controller.rb
│   │   ├── self_enrollments_controller.rb
│   │   ├── services_api_controller.rb
│   │   ├── shared_brand_configs_controller.rb
│   │   ├── sis_api_controller.rb
│   │   ├── sis_import_errors_api_controller.rb
│   │   ├── sis_imports_api_controller.rb
│   │   ├── smart_search_controller.rb
│   │   ├── sub_accounts_controller.rb
│   │   ├── submission_comments_api_controller.rb
│   │   ├── submission_comments_controller.rb
│   │   ├── submissions
│   │   │   ├── abstract_submission_for_show.rb
│   │   │   ├── anonymous_downloads_controller.rb
│   │   │   ├── anonymous_previews_controller.rb
│   │   │   ├── anonymous_submission_for_show.rb
│   │   │   ├── attachment_for_submission_download.rb
│   │   │   ├── downloads_base_controller.rb
│   │   │   ├── downloads_controller.rb
│   │   │   ├── previews_base_controller.rb
│   │   │   ├── previews_controller.rb
│   │   │   ├── show_helper.rb
│   │   │   └── submission_for_show.rb
│   │   ├── submissions_api_controller.rb
│   │   ├── submissions_base_controller.rb
│   │   ├── submissions_controller.rb
│   │   ├── support_helpers
│   │   │   ├── crocodoc_controller.rb
│   │   │   ├── plagiarism_platform_controller.rb
│   │   │   ├── submission_lifecycle_manage_controller.rb
│   │   │   └── turnitin_controller.rb
│   │   ├── tabs_controller.rb
│   │   ├── temporary_enrollment_pairings_api_controller.rb
│   │   ├── terms_api_controller.rb
│   │   ├── terms_controller.rb
│   │   ├── tokens_controller.rb
│   │   ├── translation_controller.rb
│   │   ├── usage_rights_controller.rb
│   │   ├── user_lists_controller.rb
│   │   ├── user_observees_controller.rb
│   │   ├── users_controller.rb
│   │   ├── web_zip_exports_controller.rb
│   │   ├── what_if_grades_api_controller.rb
│   │   ├── wiki_pages_api_controller.rb
│   │   └── wiki_pages_controller.rb
│   ├── graphql
│   │   ├── audit_log_field_extension.rb
│   │   ├── canvas_antiabuse_analyzer.rb
│   │   ├── canvas_schema.rb
│   │   ├── collection_connection.rb
│   │   ├── dynamo_connection.rb
│   │   ├── dynamo_query.rb
│   │   ├── graphql_helpers
│   │   │   ├── anonymous_grading.rb
│   │   │   ├── auto_grade_eligibility_helper.rb
│   │   │   ├── context_fetcher.rb
│   │   │   └── user_content.rb
│   │   ├── graphql_helpers.rb
│   │   ├── graphql_node_loader.rb
│   │   ├── graphql_postgres_timeout.rb
│   │   ├── graphql_tuning.rb
│   │   ├── interfaces
│   │   │   ├── asset_string_interface.rb
│   │   │   ├── assignments_connection_interface.rb
│   │   │   ├── base_interface.rb
│   │   │   ├── discussions_connection_interface.rb
│   │   │   ├── files_connection_interface.rb
│   │   │   ├── legacy_id_interface.rb
│   │   │   ├── module_item_interface.rb
│   │   │   ├── pages_connection_interface.rb
│   │   │   ├── quizzes_connection_interface.rb
│   │   │   ├── submission_interface.rb
│   │   │   └── timestamp_interface.rb
│   │   ├── loaders
│   │   │   ├── README.md
│   │   │   ├── activity_stream_summary_loader.rb
│   │   │   ├── api_content_attachment_loader.rb
│   │   │   ├── assessment_request_loader.rb
│   │   │   ├── asset_string_loader.rb
│   │   │   ├── assignment_rubric_assessments_count_loader.rb
│   │   │   ├── association_count_loader.rb
│   │   │   ├── association_loader.rb
│   │   │   ├── audit_events_loader.rb
│   │   │   ├── course_outcome_alignment_stats_loader.rb
│   │   │   ├── course_role_loader.rb
│   │   │   ├── course_student_analytics_loader.rb
│   │   │   ├── current_grading_period_loader.rb
│   │   │   ├── discussion_entry_counts_loader.rb
│   │   │   ├── discussion_entry_draft_loader.rb
│   │   │   ├── discussion_entry_loader.rb
│   │   │   ├── discussion_entry_user_loader.rb
│   │   │   ├── discussion_topic_participant_loader.rb
│   │   │   ├── entry_participant_loader.rb
│   │   │   ├── foreign_key_loader.rb
│   │   │   ├── has_postable_comments_loader.rb
│   │   │   ├── id_loader.rb
│   │   │   ├── last_commented_by_user_at_loader.rb
│   │   │   ├── media_object_loader.rb
│   │   │   ├── mentionable_user_loader.rb
│   │   │   ├── outcome_alignment_loader.rb
│   │   │   ├── outcome_friendly_description_loader.rb
│   │   │   ├── override_assignment_loader.rb
│   │   │   ├── permissions_loader.rb
│   │   │   ├── rubric_associations_loader.rb
│   │   │   ├── section_grade_posted_state.rb
│   │   │   ├── sisid_loader.rb
│   │   │   ├── submission_group_id_loader.rb
│   │   │   └── unsharded_id_loader.rb
│   │   ├── log_query_complexity.rb
│   │   ├── mutations
│   │   │   ├── HOWTO Add Mutations.md
│   │   │   ├── add_conversation_message.rb
│   │   │   ├── assignment_base.rb
│   │   │   ├── auto_grade_submission.rb
│   │   │   ├── base_learning_outcome_mutation.rb
│   │   │   ├── base_mutation.rb
│   │   │   ├── create_assignment.rb
│   │   │   ├── create_comment_bank_item.rb
│   │   │   ├── create_conversation.rb
│   │   │   ├── create_discussion_entry.rb
│   │   │   ├── create_discussion_entry_draft.rb
│   │   │   ├── create_discussion_topic.rb
│   │   │   ├── create_group_in_set.rb
│   │   │   ├── create_group_set.rb
│   │   │   ├── create_internal_setting.rb
│   │   │   ├── create_learning_outcome.rb
│   │   │   ├── create_learning_outcome_group.rb
│   │   │   ├── create_module.rb
│   │   │   ├── create_outcome_calculation_method.rb
│   │   │   ├── create_outcome_proficiency.rb
│   │   │   ├── create_submission.rb
│   │   │   ├── create_submission_comment.rb
│   │   │   ├── create_submission_draft.rb
│   │   │   ├── create_user_inbox_label.rb
│   │   │   ├── delete_comment_bank_item.rb
│   │   │   ├── delete_conversation_messages.rb
│   │   │   ├── delete_conversations.rb
│   │   │   ├── delete_custom_grade_status.rb
│   │   │   ├── delete_discussion_entry.rb
│   │   │   ├── delete_discussion_topic.rb
│   │   │   ├── delete_internal_setting.rb
│   │   │   ├── delete_outcome_calculation_method.rb
│   │   │   ├── delete_outcome_links.rb
│   │   │   ├── delete_outcome_proficiency.rb
│   │   │   ├── delete_submission_comment.rb
│   │   │   ├── delete_submission_draft.rb
│   │   │   ├── delete_user_inbox_label.rb
│   │   │   ├── discussion_base.rb
│   │   │   ├── group_set_base.rb
│   │   │   ├── hide_assignment_grades.rb
│   │   │   ├── hide_assignment_grades_for_sections.rb
│   │   │   ├── import_outcomes.rb
│   │   │   ├── mark_submission_comments_read.rb
│   │   │   ├── move_outcome_links.rb
│   │   │   ├── outcome_calculation_method_base.rb
│   │   │   ├── outcome_proficiency_base.rb
│   │   │   ├── post_assignment_grades.rb
│   │   │   ├── post_assignment_grades_for_sections.rb
│   │   │   ├── post_draft_submission_comment.rb
│   │   │   ├── save_rubric_assessment.rb
│   │   │   ├── set_assignment_post_policy.rb
│   │   │   ├── set_course_post_policy.rb
│   │   │   ├── set_friendly_description.rb
│   │   │   ├── set_module_item_completion.rb
│   │   │   ├── set_override_score.rb
│   │   │   ├── set_override_status.rb
│   │   │   ├── set_rubric_self_assessment.rb
│   │   │   ├── subscribe_to_discussion_topic.rb
│   │   │   ├── update_assignment.rb
│   │   │   ├── update_comment_bank_item.rb
│   │   │   ├── update_conversation_participants.rb
│   │   │   ├── update_discussion_entries_read_state.rb
│   │   │   ├── update_discussion_entry.rb
│   │   │   ├── update_discussion_entry_participant.rb
│   │   │   ├── update_discussion_expanded.rb
│   │   │   ├── update_discussion_read_state.rb
│   │   │   ├── update_discussion_sort_order.rb
│   │   │   ├── update_discussion_thread_read_state.rb
│   │   │   ├── update_discussion_topic.rb
│   │   │   ├── update_discussion_topic_participant.rb
│   │   │   ├── update_gradebook_group_filter.rb
│   │   │   ├── update_internal_setting.rb
│   │   │   ├── update_learning_outcome.rb
│   │   │   ├── update_learning_outcome_group.rb
│   │   │   ├── update_my_inbox_settings.rb
│   │   │   ├── update_notification_preferences.rb
│   │   │   ├── update_outcome_calculation_method.rb
│   │   │   ├── update_outcome_proficiency.rb
│   │   │   ├── update_rubric_archived_state.rb
│   │   │   ├── update_rubric_assessment_read_state.rb
│   │   │   ├── update_speed_grader_settings.rb
│   │   │   ├── update_split_screen_view_deeply_nested_alert.rb
│   │   │   ├── update_submission_grade.rb
│   │   │   ├── update_submission_grade_status.rb
│   │   │   ├── update_submission_sticker.rb
│   │   │   ├── update_submission_student_entered_score.rb
│   │   │   ├── update_submissions_read_state.rb
│   │   │   ├── update_user_discussions_splitscreen_view.rb
│   │   │   ├── upsert_custom_grade_status.rb
│   │   │   └── upsert_standard_grade_status.rb
│   │   ├── patched_array_connection.rb
│   │   ├── tracers
│   │   │   └── datadog_tracer.rb
│   │   ├── types
│   │   │   ├── HOWTO Add Fields.md
│   │   │   ├── HOWTO Add Types.md
│   │   │   ├── account_type.rb
│   │   │   ├── activity_stream_type.rb
│   │   │   ├── anonymous_user_type.rb
│   │   │   ├── application_object_type.rb
│   │   │   ├── assessment_request_type.rb
│   │   │   ├── assignment_group_rules_type.rb
│   │   │   ├── assignment_group_type.rb
│   │   │   ├── assignment_override_type.rb
│   │   │   ├── assignment_submission_type.rb
│   │   │   ├── assignment_target_sort_order_input_type.rb
│   │   │   ├── assignment_type.rb
│   │   │   ├── audit_event_type.rb
│   │   │   ├── audit_logs_type.rb
│   │   │   ├── base_enum.rb
│   │   │   ├── base_field.rb
│   │   │   ├── base_input_object.rb
│   │   │   ├── base_scalar.rb
│   │   │   ├── base_union.rb
│   │   │   ├── checkpoint_type.rb
│   │   │   ├── comment_bank_item_type.rb
│   │   │   ├── communication_channel_type.rb
│   │   │   ├── content_tag_connection.rb
│   │   │   ├── content_tag_content_type.rb
│   │   │   ├── content_tag_type.rb
│   │   │   ├── conversation_message_type.rb
│   │   │   ├── conversation_participant_type.rb
│   │   │   ├── conversation_type.rb
│   │   │   ├── course_dashboard_card_type.rb
│   │   │   ├── course_outcome_alignment_stats_type.rb
│   │   │   ├── course_permissions_type.rb
│   │   │   ├── course_progression_type.rb
│   │   │   ├── course_type.rb
│   │   │   ├── course_users_sort_input_type.rb
│   │   │   ├── custom_grade_status_type.rb
│   │   │   ├── date_time_range_type.rb
│   │   │   ├── date_time_type.rb
│   │   │   ├── discussion_entry_counts_type.rb
│   │   │   ├── discussion_entry_draft_type.rb
│   │   │   ├── discussion_entry_permissions_type.rb
│   │   │   ├── discussion_entry_report_type_counts_type.rb
│   │   │   ├── discussion_entry_type.rb
│   │   │   ├── discussion_entry_version_type.rb
│   │   │   ├── discussion_participant_type.rb
│   │   │   ├── discussion_permissions_type.rb
│   │   │   ├── discussion_sort_order_type.rb
│   │   │   ├── discussion_type.rb
│   │   │   ├── draftable_submission_type.rb
│   │   │   ├── enrollment_type.rb
│   │   │   ├── enrollments_sort_input_type.rb
│   │   │   ├── entry_participant_type.rb
│   │   │   ├── external_tool_placements_type.rb
│   │   │   ├── external_tool_settings_type.rb
│   │   │   ├── external_tool_type.rb
│   │   │   ├── external_url_type.rb
│   │   │   ├── file_type.rb
│   │   │   ├── folder_type.rb
│   │   │   ├── grades_type.rb
│   │   │   ├── grading_period_group_type.rb
│   │   │   ├── grading_period_type.rb
│   │   │   ├── grading_standard_type.rb
│   │   │   ├── group_membership_type.rb
│   │   │   ├── group_set_type.rb
│   │   │   ├── group_type.rb
│   │   │   ├── html_encoded_string_type.rb
│   │   │   ├── inbox_settings_type.rb
│   │   │   ├── internal_setting_type.rb
│   │   │   ├── learning_outcome_group_type.rb
│   │   │   ├── learning_outcome_type.rb
│   │   │   ├── legacy_node_type.rb
│   │   │   ├── lock_info_type.rb
│   │   │   ├── media_object_type.rb
│   │   │   ├── media_source_type.rb
│   │   │   ├── media_track_type.rb
│   │   │   ├── message_permissions_type.rb
│   │   │   ├── messageable_context_type.rb
│   │   │   ├── messageable_user_type.rb
│   │   │   ├── module_external_tool_type.rb
│   │   │   ├── module_item_type.rb
│   │   │   ├── module_progression_type.rb
│   │   │   ├── module_sub_header_type.rb
│   │   │   ├── module_type.rb
│   │   │   ├── mutation_log_type.rb
│   │   │   ├── mutation_type.rb
│   │   │   ├── notification_policy_type.rb
│   │   │   ├── notification_preferences_context_type.rb
│   │   │   ├── notification_preferences_type.rb
│   │   │   ├── notification_type.rb
│   │   │   ├── order_direction_type.rb
│   │   │   ├── outcome_alignment_type.rb
│   │   │   ├── outcome_calculation_method_type.rb
│   │   │   ├── outcome_friendly_description_type.rb
│   │   │   ├── outcome_proficiency_type.rb
│   │   │   ├── page_type.rb
│   │   │   ├── post_policy_type.rb
│   │   │   ├── proficiency_rating_input_type.rb
│   │   │   ├── proficiency_rating_type.rb
│   │   │   ├── progress_type.rb
│   │   │   ├── query_type.rb
│   │   │   ├── quiz_item_type.rb
│   │   │   ├── quiz_type.rb
│   │   │   ├── recipients_type.rb
│   │   │   ├── rubric_assessment_rating_type.rb
│   │   │   ├── rubric_assessment_type.rb
│   │   │   ├── rubric_association_type.rb
│   │   │   ├── rubric_criterion_type.rb
│   │   │   ├── rubric_rating_type.rb
│   │   │   ├── rubric_type.rb
│   │   │   ├── section_type.rb
│   │   │   ├── speed_grader_settings_type.rb
│   │   │   ├── standard_grade_status_type.rb
│   │   │   ├── sticker_type.rb
│   │   │   ├── student_summary_analytics_type.rb
│   │   │   ├── sub_assignment_submission_type.rb
│   │   │   ├── submission_comment_filter_input_type.rb
│   │   │   ├── submission_comment_type.rb
│   │   │   ├── submission_draft_type.rb
│   │   │   ├── submission_filter_input_type.rb
│   │   │   ├── submission_grading_status_type.rb
│   │   │   ├── submission_history_order_input_type.rb
│   │   │   ├── submission_history_type.rb
│   │   │   ├── submission_search_filter_input_type.rb
│   │   │   ├── submission_search_order_input_type.rb
│   │   │   ├── submission_state_type.rb
│   │   │   ├── submission_status_tag_type.rb
│   │   │   ├── submission_type.rb
│   │   │   ├── term_type.rb
│   │   │   ├── turnitin_context_type.rb
│   │   │   ├── turnitin_data_type.rb
│   │   │   ├── url_type.rb
│   │   │   ├── usage_rights_type.rb
│   │   │   ├── user_type.rb
│   │   │   └── validation_error_type.rb
│   │   └── types.rb
│   ├── helpers
│   │   ├── accessibility_controller_helper.rb
│   │   ├── account_notification_helper.rb
│   │   ├── accounts_helper.rb
│   │   ├── alignments_helper.rb
│   │   ├── application_helper.rb
│   │   ├── assessment_request_helper.rb
│   │   ├── assignments_helper.rb
│   │   ├── attachment_helper.rb
│   │   ├── avatar_helper.rb
│   │   ├── broken_link_helper.rb
│   │   ├── calendar_conferences_helper.rb
│   │   ├── calendar_events_helper.rb
│   │   ├── canvadocs_helper.rb
│   │   ├── canvas_outcomes_helper.rb
│   │   ├── collaborations_helper.rb
│   │   ├── communication_channels_helper.rb
│   │   ├── content_export_api_helper.rb
│   │   ├── content_export_assignment_helper.rb
│   │   ├── content_imports_helper.rb
│   │   ├── context_external_tools_helper.rb
│   │   ├── context_modules_helper.rb
│   │   ├── conversations_helper.rb
│   │   ├── courses_helper.rb
│   │   ├── custom_color_helper.rb
│   │   ├── custom_sidebar_links_helper.rb
│   │   ├── cyoe_helper.rb
│   │   ├── dashboard_helper.rb
│   │   ├── datadog_rum_helper.rb
│   │   ├── default_due_time_helper.rb
│   │   ├── discussion_topics_helper.rb
│   │   ├── eportfolios_helper.rb
│   │   ├── global_navigation_helper.rb
│   │   ├── gradebooks_helper.rb
│   │   ├── grading_periods_helper.rb
│   │   ├── group_permission_helper.rb
│   │   ├── groups_helper.rb
│   │   ├── hmac_helper.rb
│   │   ├── inst_llm_helper.rb
│   │   ├── kaltura_helper.rb
│   │   ├── launch_iframe_helper.rb
│   │   ├── legal_information_helper.rb
│   │   ├── login
│   │   │   ├── canvas_helper.rb
│   │   │   └── otp_helper.rb
│   │   ├── messages
│   │   │   ├── peer_reviews_helper.rb
│   │   │   └── send_student_names_helper.rb
│   │   ├── new_quizzes_features_helper.rb
│   │   ├── observer_enrollments_helper.rb
│   │   ├── outcome_result_resolver_helper.rb
│   │   ├── outcomes_features_helper.rb
│   │   ├── outcomes_request_batcher.rb
│   │   ├── outcomes_service_alignments_helper.rb
│   │   ├── outcomes_service_authoritative_results_helper.rb
│   │   ├── profile_helper.rb
│   │   ├── quizzes_helper.rb
│   │   ├── rollup_score_aggregator_helper.rb
│   │   ├── rrule_helper.rb
│   │   ├── search_helper.rb
│   │   ├── section_tab_helper.rb
│   │   ├── self_enrollments_helper.rb
│   │   ├── stream_items_helper.rb
│   │   ├── submission_comments_helper.rb
│   │   ├── submissions_helper.rb
│   │   ├── submittable_helper.rb
│   │   ├── syllabus_helper.rb
│   │   ├── url_helper.rb
│   │   ├── usage_metrics_helper.rb
│   │   ├── users_helper.rb
│   │   ├── visibility_sql_helper.rb
│   │   ├── web_zip_export_helper.rb
│   │   └── will_paginate_helper.rb
│   ├── messages
│   │   ├── 2fa.email.erb
│   │   ├── 2fa.email.html.erb
│   │   ├── _email_footer.email.erb
│   │   ├── _layout.email.html.erb
│   │   ├── _notes.txt
│   │   ├── access_token_created_on_behalf_of_user.email.erb
│   │   ├── access_token_created_on_behalf_of_user.email.html.erb
│   │   ├── access_token_created_on_behalf_of_user.sms.erb
│   │   ├── access_token_created_on_behalf_of_user.summary.erb
│   │   ├── access_token_deleted.email.erb
│   │   ├── access_token_deleted.email.html.erb
│   │   ├── access_token_deleted.sms.erb
│   │   ├── access_token_deleted.summary.erb
│   │   ├── account_notification.email.erb
│   │   ├── account_notification.email.html.erb
│   │   ├── account_user_notification.email.erb
│   │   ├── account_user_notification.email.html.erb
│   │   ├── account_user_registration.email.erb
│   │   ├── account_user_registration.email.html.erb
│   │   ├── account_verification.email.erb
│   │   ├── account_verification.email.html.erb
│   │   ├── added_to_conversation.email.erb
│   │   ├── added_to_conversation.email.html.erb
│   │   ├── added_to_conversation.sms.erb
│   │   ├── added_to_conversation.summary.erb
│   │   ├── alert.email.erb
│   │   ├── alert.email.html.erb
│   │   ├── alert.sms.erb
│   │   ├── alert.summary.erb
│   │   ├── annotation_notification.email.erb
│   │   ├── annotation_notification.email.html.erb
│   │   ├── annotation_notification.summary.erb
│   │   ├── annotation_teacher_notification.email.erb
│   │   ├── annotation_teacher_notification.email.html.erb
│   │   ├── annotation_teacher_notification.summary.erb
│   │   ├── announcement_created_by_you.email.erb
│   │   ├── announcement_created_by_you.email.html.erb
│   │   ├── announcement_created_by_you.sms.erb
│   │   ├── announcement_created_by_you.summary.erb
│   │   ├── announcement_reply.email.erb
│   │   ├── announcement_reply.email.html.erb
│   │   ├── announcement_reply.sms.erb
│   │   ├── announcement_reply.summary.erb
│   │   ├── appointment_canceled_by_user.email.erb
│   │   ├── appointment_canceled_by_user.email.html.erb
│   │   ├── appointment_canceled_by_user.sms.erb
│   │   ├── appointment_deleted_for_user.email.erb
│   │   ├── appointment_deleted_for_user.email.html.erb
│   │   ├── appointment_deleted_for_user.sms.erb
│   │   ├── appointment_group_deleted.email.erb
│   │   ├── appointment_group_deleted.email.html.erb
│   │   ├── appointment_group_deleted.sms.erb
│   │   ├── appointment_group_published.email.erb
│   │   ├── appointment_group_published.email.html.erb
│   │   ├── appointment_group_published.sms.erb
│   │   ├── appointment_group_published.summary.erb
│   │   ├── appointment_group_updated.email.erb
│   │   ├── appointment_group_updated.email.html.erb
│   │   ├── appointment_group_updated.sms.erb
│   │   ├── appointment_group_updated.summary.erb
│   │   ├── appointment_reserved_by_user.email.erb
│   │   ├── appointment_reserved_by_user.email.html.erb
│   │   ├── appointment_reserved_by_user.sms.erb
│   │   ├── appointment_reserved_for_user.email.erb
│   │   ├── appointment_reserved_for_user.email.html.erb
│   │   ├── appointment_reserved_for_user.sms.erb
│   │   ├── appointment_reserved_for_user.summary.erb
│   │   ├── assignment_changed.email.erb
│   │   ├── assignment_changed.email.html.erb
│   │   ├── assignment_changed.sms.erb
│   │   ├── assignment_changed.summary.erb
│   │   ├── assignment_created.email.erb
│   │   ├── assignment_created.email.html.erb
│   │   ├── assignment_created.sms.erb
│   │   ├── assignment_created.summary.erb
│   │   ├── assignment_due_date_changed.email.erb
│   │   ├── assignment_due_date_changed.email.html.erb
│   │   ├── assignment_due_date_changed.sms.erb
│   │   ├── assignment_due_date_changed.summary.erb
│   │   ├── assignment_due_date_override_changed.email.erb
│   │   ├── assignment_due_date_override_changed.email.html.erb
│   │   ├── assignment_due_date_override_changed.sms.erb
│   │   ├── assignment_due_date_override_changed.summary.erb
│   │   ├── assignment_graded.email.erb
│   │   ├── assignment_graded.email.html.erb
│   │   ├── assignment_graded.sms.erb
│   │   ├── assignment_graded.summary.erb
│   │   ├── assignment_resubmitted.email.erb
│   │   ├── assignment_resubmitted.email.html.erb
│   │   ├── assignment_resubmitted.sms.erb
│   │   ├── assignment_resubmitted.summary.erb
│   │   ├── assignment_submitted.email.erb
│   │   ├── assignment_submitted.email.html.erb
│   │   ├── assignment_submitted.sms.erb
│   │   ├── assignment_submitted.summary.erb
│   │   ├── assignment_submitted_late.email.erb
│   │   ├── assignment_submitted_late.email.html.erb
│   │   ├── assignment_submitted_late.sms.erb
│   │   ├── assignment_submitted_late.summary.erb
│   │   ├── blueprint_content_added.email.erb
│   │   ├── blueprint_content_added.email.html.erb
│   │   ├── blueprint_content_added.sms.erb
│   │   ├── blueprint_content_added.summary.erb
│   │   ├── blueprint_sync_complete.email.erb
│   │   ├── blueprint_sync_complete.email.html.erb
│   │   ├── blueprint_sync_complete.sms.erb
│   │   ├── blueprint_sync_complete.summary.erb
│   │   ├── checkpoints_created.email.erb
│   │   ├── checkpoints_created.email.html.erb
│   │   ├── collaboration_invitation.email.erb
│   │   ├── collaboration_invitation.email.html.erb
│   │   ├── collaboration_invitation.sms.erb
│   │   ├── collaboration_invitation.summary.erb
│   │   ├── confirm_email_communication_channel.email.erb
│   │   ├── confirm_email_communication_channel.email.html.erb
│   │   ├── confirm_registration.email.erb
│   │   ├── confirm_registration.email.html.erb
│   │   ├── confirm_sms_communication_channel.sms.erb
│   │   ├── content_export_failed.email.erb
│   │   ├── content_export_failed.email.html.erb
│   │   ├── content_export_finished.email.erb
│   │   ├── content_export_finished.email.html.erb
│   │   ├── content_link_error.email.erb
│   │   ├── content_link_error.email.html.erb
│   │   ├── content_link_error.sms.erb
│   │   ├── content_link_error.summary.erb
│   │   ├── conversation_created.email.erb
│   │   ├── conversation_created.email.html.erb
│   │   ├── conversation_created.sms.erb
│   │   ├── conversation_created.summary.erb
│   │   ├── conversation_message.email.erb
│   │   ├── conversation_message.email.html.erb
│   │   ├── conversation_message.sms.erb
│   │   ├── conversation_message.summary.erb
│   │   ├── discussion_mention.email.erb
│   │   ├── discussion_mention.email.html.erb
│   │   ├── discussion_mention.sms.erb
│   │   ├── discussion_mention.summary.erb
│   │   ├── dsr_request.email.erb
│   │   ├── dsr_request.html.erb
│   │   ├── enrollment_accepted.email.erb
│   │   ├── enrollment_accepted.email.html.erb
│   │   ├── enrollment_accepted.sms.erb
│   │   ├── enrollment_accepted.summary.erb
│   │   ├── enrollment_invitation.email.erb
│   │   ├── enrollment_invitation.email.html.erb
│   │   ├── enrollment_invitation.sms.erb
│   │   ├── enrollment_invitation.summary.erb
│   │   ├── enrollment_notification.email.erb
│   │   ├── enrollment_notification.email.html.erb
│   │   ├── enrollment_notification.sms.erb
│   │   ├── enrollment_notification.summary.erb
│   │   ├── enrollment_registration.email.erb
│   │   ├── enrollment_registration.email.html.erb
│   │   ├── enrollment_registration.sms.erb
│   │   ├── enrollment_registration.summary.erb
│   │   ├── event_date_changed.email.erb
│   │   ├── event_date_changed.email.html.erb
│   │   ├── event_date_changed.sms.erb
│   │   ├── event_date_changed.summary.erb
│   │   ├── forgot_password.email.erb
│   │   ├── forgot_password.email.html.erb
│   │   ├── grade_weight_changed.email.erb
│   │   ├── grade_weight_changed.email.html.erb
│   │   ├── grade_weight_changed.sms.erb
│   │   ├── grade_weight_changed.summary.erb
│   │   ├── group_assignment_submitted_late.email.erb
│   │   ├── group_assignment_submitted_late.email.html.erb
│   │   ├── group_assignment_submitted_late.sms.erb
│   │   ├── group_assignment_submitted_late.summary.erb
│   │   ├── group_membership_accepted.email.erb
│   │   ├── group_membership_accepted.email.html.erb
│   │   ├── group_membership_accepted.sms.erb
│   │   ├── group_membership_accepted.summary.erb
│   │   ├── group_membership_rejected.email.erb
│   │   ├── group_membership_rejected.email.html.erb
│   │   ├── group_membership_rejected.sms.erb
│   │   ├── group_membership_rejected.summary.erb
│   │   ├── manually_created_access_token_created.email.erb
│   │   ├── manually_created_access_token_created.email.html.erb
│   │   ├── manually_created_access_token_created.sms.erb
│   │   ├── manually_created_access_token_created.summary.erb
│   │   ├── merge_email_communication_channel.email.erb
│   │   ├── merge_email_communication_channel.email.html.erb
│   │   ├── new_account_user.email.erb
│   │   ├── new_account_user.email.html.erb
│   │   ├── new_account_user.sms.erb
│   │   ├── new_account_user.summary.erb
│   │   ├── new_announcement.email.erb
│   │   ├── new_announcement.email.html.erb
│   │   ├── new_announcement.sms.erb
│   │   ├── new_announcement.summary.erb
│   │   ├── new_context_group_membership.email.erb
│   │   ├── new_context_group_membership.email.html.erb
│   │   ├── new_context_group_membership.sms.erb
│   │   ├── new_context_group_membership.summary.erb
│   │   ├── new_context_group_membership_invitation.email.erb
│   │   ├── new_context_group_membership_invitation.email.html.erb
│   │   ├── new_context_group_membership_invitation.sms.erb
│   │   ├── new_context_group_membership_invitation.summary.erb
│   │   ├── new_course.email.erb
│   │   ├── new_course.email.html.erb
│   │   ├── new_course.sms.erb
│   │   ├── new_course.summary.erb
│   │   ├── new_discussion_entry.email.erb
│   │   ├── new_discussion_entry.email.html.erb
│   │   ├── new_discussion_entry.sms.erb
│   │   ├── new_discussion_entry.summary.erb
│   │   ├── new_discussion_topic.email.erb
│   │   ├── new_discussion_topic.email.html.erb
│   │   ├── new_discussion_topic.sms.erb
│   │   ├── new_discussion_topic.summary.erb
│   │   ├── new_event_created.email.erb
│   │   ├── new_event_created.email.html.erb
│   │   ├── new_event_created.sms.erb
│   │   ├── new_event_created.summary.erb
│   │   ├── new_file_added.email.erb
│   │   ├── new_file_added.email.html.erb
│   │   ├── new_file_added.sms.erb
│   │   ├── new_file_added.summary.erb
│   │   ├── new_files_added.email.erb
│   │   ├── new_files_added.email.html.erb
│   │   ├── new_files_added.sms.erb
│   │   ├── new_files_added.summary.erb
│   │   ├── new_student_organized_group.email.erb
│   │   ├── new_student_organized_group.email.html.erb
│   │   ├── new_student_organized_group.sms.erb
│   │   ├── new_student_organized_group.summary.erb
│   │   ├── new_user.email.erb
│   │   ├── new_user.email.html.erb
│   │   ├── new_user.sms.erb
│   │   ├── new_user.summary.erb
│   │   ├── notification_types.yml
│   │   ├── peer_review_invitation.email.erb
│   │   ├── peer_review_invitation.email.html.erb
│   │   ├── peer_review_invitation.sms.erb
│   │   ├── peer_review_invitation.summary.erb
│   │   ├── pseudonym_registration.email.erb
│   │   ├── pseudonym_registration.email.html.erb
│   │   ├── pseudonym_registration.sms.erb
│   │   ├── pseudonym_registration.summary.erb
│   │   ├── pseudonym_registration_done.email.erb
│   │   ├── pseudonym_registration_done.email.html.erb
│   │   ├── pseudonym_registration_done.sms.erb
│   │   ├── pseudonym_registration_done.summary.erb
│   │   ├── quiz_regrade_finished.email.erb
│   │   ├── quiz_regrade_finished.email.html.erb
│   │   ├── quiz_regrade_finished.sms.erb
│   │   ├── quiz_regrade_finished.summary.erb
│   │   ├── report_generated.email.erb
│   │   ├── report_generated.email.html.erb
│   │   ├── report_generation_failed.email.erb
│   │   ├── report_generation_failed.email.html.erb
│   │   ├── reported_reply.email.erb
│   │   ├── reported_reply.email.html.erb
│   │   ├── reported_reply.summary.erb
│   │   ├── rubric_assessment_submission_reminder.email.erb
│   │   ├── rubric_assessment_submission_reminder.email.html.erb
│   │   ├── rubric_assessment_submission_reminder.sms.erb
│   │   ├── rubric_assessment_submission_reminder.summary.erb
│   │   ├── rubric_association_created.email.erb
│   │   ├── rubric_association_created.email.html.erb
│   │   ├── rubric_association_created.sms.erb
│   │   ├── rubric_association_created.summary.erb
│   │   ├── submission_comment.email.erb
│   │   ├── submission_comment.email.html.erb
│   │   ├── submission_comment.sms.erb
│   │   ├── submission_comment.summary.erb
│   │   ├── submission_comment_for_teacher.email.erb
│   │   ├── submission_comment_for_teacher.email.html.erb
│   │   ├── submission_comment_for_teacher.sms.erb
│   │   ├── submission_comment_for_teacher.summary.erb
│   │   ├── submission_grade_changed.email.erb
│   │   ├── submission_grade_changed.email.html.erb
│   │   ├── submission_grade_changed.sms.erb
│   │   ├── submission_grade_changed.summary.erb
│   │   ├── submission_graded.email.erb
│   │   ├── submission_graded.email.html.erb
│   │   ├── submission_graded.sms.erb
│   │   ├── submission_graded.summary.erb
│   │   ├── submission_needs_grading.email.erb
│   │   ├── submission_needs_grading.email.html.erb
│   │   ├── submission_needs_grading.sms.erb
│   │   ├── submission_needs_grading.summary.erb
│   │   ├── submission_posted.email.erb
│   │   ├── submission_posted.email.html.erb
│   │   ├── submission_posted.sms.erb
│   │   ├── submission_posted.summary.erb
│   │   ├── submissions_posted.email.erb
│   │   ├── submissions_posted.email.html.erb
│   │   ├── submissions_posted.sms.erb
│   │   ├── submissions_posted.summary.erb
│   │   ├── summaries.email.erb
│   │   ├── summaries.email.html.erb
│   │   ├── summaries.sms.erb
│   │   ├── upcoming_assignment_alert.email.erb
│   │   ├── upcoming_assignment_alert.email.html.erb
│   │   ├── upcoming_assignment_alert.sms.erb
│   │   ├── updated_wiki_page.email.erb
│   │   ├── updated_wiki_page.email.html.erb
│   │   ├── updated_wiki_page.sms.erb
│   │   ├── updated_wiki_page.summary.erb
│   │   ├── web_conference_invitation.email.erb
│   │   ├── web_conference_invitation.email.html.erb
│   │   ├── web_conference_invitation.sms.erb
│   │   ├── web_conference_invitation.summary.erb
│   │   ├── web_conference_recording_ready.email.erb
│   │   ├── web_conference_recording_ready.email.html.erb
│   │   ├── web_conference_recording_ready.sms.erb
│   │   └── web_conference_recording_ready.summary.erb
│   ├── middleware
│   │   ├── load_account.rb
│   │   ├── prevent_non_multipart_parse.rb
│   │   ├── request_context_generator.rb
│   │   ├── request_context_session.rb
│   │   ├── request_throttle
│   │   │   └── increment_bucket.lua
│   │   ├── request_throttle.rb
│   │   ├── samesite_transition_cookie_store.rb
│   │   ├── sentry_trace_scrubber.rb
│   │   └── sessions_timeout.rb
│   ├── models
│   │   ├── abstract_assignment.rb
│   │   ├── abstract_course.rb
│   │   ├── access_token.rb
│   │   ├── accessibility
│   │   │   ├── form_field.rb
│   │   │   ├── rule.rb
│   │   │   └── rules
│   │   │       ├── adjacent_links_rule.rb
│   │   │       ├── headings_sequence_rule.rb
│   │   │       ├── headings_start_at_h2_rule.rb
│   │   │       ├── img_alt_filename_rule.rb
│   │   │       ├── img_alt_length_rule.rb
│   │   │       ├── img_alt_rule.rb
│   │   │       ├── large_text_contrast_rule.rb
│   │   │       ├── list_structure_rule.rb
│   │   │       ├── paragraphs_for_headings_rule.rb
│   │   │       ├── small_text_contrast_rule.rb
│   │   │       ├── table_caption_rule.rb
│   │   │       ├── table_header_rule.rb
│   │   │       └── table_header_scope_rule.rb
│   │   ├── account
│   │   │   ├── help_links.rb
│   │   │   ├── settings.rb
│   │   │   └── settings_wrapper.rb
│   │   ├── account.rb
│   │   ├── account_notification.rb
│   │   ├── account_notification_role.rb
│   │   ├── account_report.rb
│   │   ├── account_report_row.rb
│   │   ├── account_report_runner.rb
│   │   ├── account_user.rb
│   │   ├── alert.rb
│   │   ├── alert_criterion.rb
│   │   ├── alerts
│   │   │   ├── delayed_alert_sender.rb
│   │   │   ├── interaction.rb
│   │   │   ├── ungraded_count.rb
│   │   │   └── ungraded_timespan.rb
│   │   ├── announcement.rb
│   │   ├── announcement_embedding.rb
│   │   ├── anonymous_or_moderation_event.rb
│   │   ├── application_record.rb
│   │   ├── appointment_group.rb
│   │   ├── appointment_group_context.rb
│   │   ├── appointment_group_sub_context.rb
│   │   ├── assessment_question.rb
│   │   ├── assessment_question_bank.rb
│   │   ├── assessment_question_bank_user.rb
│   │   ├── assessment_request.rb
│   │   ├── asset_user_access.rb
│   │   ├── asset_user_access_log.rb
│   │   ├── assignment
│   │   │   ├── bulk_update.rb
│   │   │   ├── grade_error.rb
│   │   │   ├── hard_coded.rb
│   │   │   └── max_graders_reached_error.rb
│   │   ├── assignment.rb
│   │   ├── assignment_configuration_tool_lookup.rb
│   │   ├── assignment_embedding.rb
│   │   ├── assignment_group.rb
│   │   ├── assignment_override.rb
│   │   ├── assignment_override_student.rb
│   │   ├── assignments
│   │   │   ├── needs_grading_count_query.rb
│   │   │   └── scoped_to_user.rb
│   │   ├── attachment.rb
│   │   ├── attachment_association.rb
│   │   ├── attachment_upload_status.rb
│   │   ├── attachments
│   │   │   ├── garbage_collector.rb
│   │   │   ├── local_storage.rb
│   │   │   ├── s3_storage.rb
│   │   │   ├── scoped_to_user.rb
│   │   │   ├── storage.rb
│   │   │   └── verification.rb
│   │   ├── audit_event_service.rb
│   │   ├── auditors
│   │   │   ├── active_record
│   │   │   │   ├── attributes.rb
│   │   │   │   ├── authentication_record.rb
│   │   │   │   ├── course_record.rb
│   │   │   │   ├── feature_flag_record.rb
│   │   │   │   ├── grade_change_record.rb
│   │   │   │   ├── model.rb
│   │   │   │   ├── partitioner.rb
│   │   │   │   └── pseudonym_record.rb
│   │   │   ├── authentication.rb
│   │   │   ├── course.rb
│   │   │   ├── feature_flag.rb
│   │   │   ├── grade_change.rb
│   │   │   ├── pseudonym.rb
│   │   │   └── record.rb
│   │   ├── auditors.rb
│   │   ├── authentication_provider
│   │   │   ├── apple.rb
│   │   │   ├── canvas.rb
│   │   │   ├── cas.rb
│   │   │   ├── clever.rb
│   │   │   ├── delegated.rb
│   │   │   ├── facebook.rb
│   │   │   ├── git_hub.rb
│   │   │   ├── google.rb
│   │   │   ├── ldap.rb
│   │   │   ├── linked_in.rb
│   │   │   ├── microsoft.rb
│   │   │   ├── oauth.rb
│   │   │   ├── oauth2.rb
│   │   │   ├── open_id_connect
│   │   │   │   ├── discovery_refresher.rb
│   │   │   │   └── jwks_refresher.rb
│   │   │   ├── open_id_connect.rb
│   │   │   ├── plugin_settings.rb
│   │   │   ├── provider_refresher.rb
│   │   │   ├── saml
│   │   │   │   ├── federation.rb
│   │   │   │   ├── in_common.rb
│   │   │   │   ├── metadata_refresher.rb
│   │   │   │   └── uk_federation.rb
│   │   │   ├── saml.rb
│   │   │   └── saml_idp_discovery.rb
│   │   ├── authentication_provider.rb
│   │   ├── auto_grade_result.rb
│   │   ├── big_blue_button_conference.rb
│   │   ├── blackout_date.rb
│   │   ├── block_editor.rb
│   │   ├── block_editor_template.rb
│   │   ├── bookmark_service.rb
│   │   ├── bookmarks
│   │   │   └── bookmark.rb
│   │   ├── bookmarks.rb
│   │   ├── bounce_notification_processor.rb
│   │   ├── brand_config.rb
│   │   ├── broadcast_policies
│   │   │   ├── assignment_participants.rb
│   │   │   ├── assignment_policy.rb
│   │   │   ├── quiz_submission_policy.rb
│   │   │   ├── submission_policy.rb
│   │   │   └── wiki_page_policy.rb
│   │   ├── calendar_event.rb
│   │   ├── canvadoc.rb
│   │   ├── canvadocs_annotation_context.rb
│   │   ├── canvadocs_submission.rb
│   │   ├── canvas_metadatum.rb
│   │   ├── cloned_item.rb
│   │   ├── collaboration.rb
│   │   ├── collaborator.rb
│   │   ├── comment_bank_item.rb
│   │   ├── communication_channel
│   │   │   └── bulk_actions.rb
│   │   ├── communication_channel.rb
│   │   ├── conditional_release
│   │   │   ├── assignment_set.rb
│   │   │   ├── assignment_set_action.rb
│   │   │   ├── assignment_set_association.rb
│   │   │   ├── bounds_validations.rb
│   │   │   ├── deletion.rb
│   │   │   ├── migration_service.rb
│   │   │   ├── override_handler.rb
│   │   │   ├── rule.rb
│   │   │   ├── scoring_range.rb
│   │   │   ├── service.rb
│   │   │   └── stats.rb
│   │   ├── conditional_release.rb
│   │   ├── content_export.rb
│   │   ├── content_migration.rb
│   │   ├── content_participation.rb
│   │   ├── content_participation_count.rb
│   │   ├── content_share.rb
│   │   ├── content_tag.rb
│   │   ├── context.rb
│   │   ├── context_external_tool.rb
│   │   ├── context_external_tool_placement.rb
│   │   ├── context_module.rb
│   │   ├── context_module_item.rb
│   │   ├── context_module_progression.rb
│   │   ├── context_module_progressions
│   │   │   └── finder.rb
│   │   ├── conversation.rb
│   │   ├── conversation_batch.rb
│   │   ├── conversation_message.rb
│   │   ├── conversation_message_participant.rb
│   │   ├── conversation_participant.rb
│   │   ├── course.rb
│   │   ├── course_account_association.rb
│   │   ├── course_date_range.rb
│   │   ├── course_pace.rb
│   │   ├── course_pace_module_item.rb
│   │   ├── course_profile.rb
│   │   ├── course_progress.rb
│   │   ├── course_report.rb
│   │   ├── course_score_statistic.rb
│   │   ├── course_section.rb
│   │   ├── courses
│   │   │   ├── export_warnings.rb
│   │   │   ├── item_visibility_helper.rb
│   │   │   ├── teacher_student_mapper.rb
│   │   │   └── timetable_event_builder.rb
│   │   ├── crocodoc_document.rb
│   │   ├── csp
│   │   │   ├── account_helper.rb
│   │   │   ├── course_helper.rb
│   │   │   └── domain.rb
│   │   ├── custom_data.rb
│   │   ├── custom_grade_status.rb
│   │   ├── custom_gradebook_column.rb
│   │   ├── custom_gradebook_column_datum.rb
│   │   ├── delayed_message.rb
│   │   ├── delayed_notification.rb
│   │   ├── designer_enrollment.rb
│   │   ├── developer_key.rb
│   │   ├── developer_key_account_binding.rb
│   │   ├── developer_keys
│   │   │   └── access_verifier.rb
│   │   ├── discussion_entry.rb
│   │   ├── discussion_entry_draft.rb
│   │   ├── discussion_entry_participant.rb
│   │   ├── discussion_entry_version.rb
│   │   ├── discussion_topic
│   │   │   ├── materialized_view.rb
│   │   │   ├── prompt_presenter.rb
│   │   │   ├── scoped_to_sections.rb
│   │   │   └── scoped_to_user.rb
│   │   ├── discussion_topic.rb
│   │   ├── discussion_topic_embedding.rb
│   │   ├── discussion_topic_insight
│   │   │   └── entry.rb
│   │   ├── discussion_topic_insight.rb
│   │   ├── discussion_topic_participant.rb
│   │   ├── discussion_topic_section_visibility.rb
│   │   ├── discussion_topic_summary
│   │   │   └── feedback.rb
│   │   ├── discussion_topic_summary.rb
│   │   ├── document_service.rb
│   │   ├── enrollment
│   │   │   ├── batch_state_updater.rb
│   │   │   ├── query_builder.rb
│   │   │   └── recent_activity.rb
│   │   ├── enrollment.rb
│   │   ├── enrollment_dates_override.rb
│   │   ├── enrollment_state.rb
│   │   ├── enrollment_term.rb
│   │   ├── eportfolio.rb
│   │   ├── eportfolio_category.rb
│   │   ├── eportfolio_entry.rb
│   │   ├── epub_export.rb
│   │   ├── epub_exports
│   │   │   ├── course_epub_exports_presenter.rb
│   │   │   └── create_service.rb
│   │   ├── error_report.rb
│   │   ├── estimated_duration.rb
│   │   ├── etherpad_collaboration.rb
│   │   ├── exporters
│   │   │   ├── exporter_helper.rb
│   │   │   ├── quizzes2_exporter.rb
│   │   │   ├── submission_exporter.rb
│   │   │   ├── user_data_exporter.rb
│   │   │   └── zip_exporter.rb
│   │   ├── external_feed.rb
│   │   ├── external_feed_entry.rb
│   │   ├── external_integration_key.rb
│   │   ├── external_tool_collaboration.rb
│   │   ├── favorite.rb
│   │   ├── feature_flag.rb
│   │   ├── folder.rb
│   │   ├── google_docs_collaboration.rb
│   │   ├── gradebook_csv.rb
│   │   ├── gradebook_filter.rb
│   │   ├── gradebook_upload.rb
│   │   ├── grading_period.rb
│   │   ├── grading_period_group.rb
│   │   ├── grading_standard.rb
│   │   ├── group.rb
│   │   ├── group_and_membership_importer.rb
│   │   ├── group_categories
│   │   │   ├── params.rb
│   │   │   └── params_policy.rb
│   │   ├── group_category.rb
│   │   ├── group_leadership.rb
│   │   ├── group_membership.rb
│   │   ├── horizon_validators.rb
│   │   ├── ignore.rb
│   │   ├── importers
│   │   │   ├── account_content_importer.rb
│   │   │   ├── assessment_question_bank_importer.rb
│   │   │   ├── assessment_question_importer.rb
│   │   │   ├── assignment_group_importer.rb
│   │   │   ├── assignment_importer.rb
│   │   │   ├── attachment_importer.rb
│   │   │   ├── blueprint_settings_importer.rb
│   │   │   ├── calendar_event_importer.rb
│   │   │   ├── content_importer_helper.rb
│   │   │   ├── context_external_tool_importer.rb
│   │   │   ├── context_module_importer.rb
│   │   │   ├── course_content_importer.rb
│   │   │   ├── course_pace_importer.rb
│   │   │   ├── db_migration_query_service.rb
│   │   │   ├── discussion_topic_importer.rb
│   │   │   ├── external_feed_importer.rb
│   │   │   ├── grading_standard_importer.rb
│   │   │   ├── group_importer.rb
│   │   │   ├── late_policy_importer.rb
│   │   │   ├── learning_outcome_group_importer.rb
│   │   │   ├── learning_outcome_importer.rb
│   │   │   ├── lti_resource_link_importer.rb
│   │   │   ├── media_track_importer.rb
│   │   │   ├── quiz_group_importer.rb
│   │   │   ├── quiz_importer.rb
│   │   │   ├── quiz_question_importer.rb
│   │   │   ├── rubric_importer.rb
│   │   │   ├── tool_profile_importer.rb
│   │   │   └── wiki_page_importer.rb
│   │   ├── importers.rb
│   │   ├── incoming_mail
│   │   │   ├── errors.rb
│   │   │   ├── message_handler.rb
│   │   │   └── reply_to_address.rb
│   │   ├── kaltura_media_file_handler.rb
│   │   ├── late_policy.rb
│   │   ├── learning_outcome.rb
│   │   ├── learning_outcome_group.rb
│   │   ├── learning_outcome_question_result.rb
│   │   ├── learning_outcome_result.rb
│   │   ├── live_assessments
│   │   │   ├── assessment.rb
│   │   │   ├── result.rb
│   │   │   └── submission.rb
│   │   ├── live_assessments.rb
│   │   ├── llm_config.rb
│   │   ├── lti
│   │   │   ├── analytics_service.rb
│   │   │   ├── asset.rb
│   │   │   ├── asset_processor.rb
│   │   │   ├── asset_processor_eula_acceptance.rb
│   │   │   ├── asset_report.rb
│   │   │   ├── caliper_service.rb
│   │   │   ├── content_migration_service
│   │   │   │   ├── exporter.rb
│   │   │   │   ├── importer.rb
│   │   │   │   └── migrator.rb
│   │   │   ├── content_migration_service.rb
│   │   │   ├── context_control.rb
│   │   │   ├── context_external_tool_errors.rb
│   │   │   ├── ims
│   │   │   │   └── registration.rb
│   │   │   ├── launch.rb
│   │   │   ├── line_item.rb
│   │   │   ├── link.rb
│   │   │   ├── logout_service.rb
│   │   │   ├── lti_account_creator.rb
│   │   │   ├── lti_advantage_adapter.rb
│   │   │   ├── lti_assignment_creator.rb
│   │   │   ├── lti_context_creator.rb
│   │   │   ├── lti_outbound_adapter.rb
│   │   │   ├── lti_tool_creator.rb
│   │   │   ├── lti_user_creator.rb
│   │   │   ├── message_handler.rb
│   │   │   ├── migratable.rb
│   │   │   ├── navigation_cache.rb
│   │   │   ├── notice_handler.rb
│   │   │   ├── overlay.rb
│   │   │   ├── overlay_version.rb
│   │   │   ├── pns
│   │   │   │   ├── lti_asset_processor_submission_notice_builder.rb
│   │   │   │   ├── lti_context_copy_notice_builder.rb
│   │   │   │   ├── lti_hello_world_notice_builder.rb
│   │   │   │   ├── notice_builder.rb
│   │   │   │   └── notice_types.rb
│   │   │   ├── product_family.rb
│   │   │   ├── registration.rb
│   │   │   ├── registration_account_binding.rb
│   │   │   ├── registration_request_service.rb
│   │   │   ├── resource_handler.rb
│   │   │   ├── resource_link.rb
│   │   │   ├── resource_placement.rb
│   │   │   ├── result.rb
│   │   │   ├── tool_configuration.rb
│   │   │   ├── tool_consumer_profile.rb
│   │   │   ├── tool_consumer_profile_creator.rb
│   │   │   ├── tool_proxy.rb
│   │   │   ├── tool_proxy_binding.rb
│   │   │   ├── tool_proxy_service.rb
│   │   │   ├── tool_setting.rb
│   │   │   └── xapi_service.rb
│   │   ├── lti.rb
│   │   ├── lti_conference.rb
│   │   ├── mailer.rb
│   │   ├── many_root_accounts.rb
│   │   ├── master_courses
│   │   │   ├── child_content_tag.rb
│   │   │   ├── child_subscription.rb
│   │   │   ├── collection_restrictor.rb
│   │   │   ├── folder_helper.rb
│   │   │   ├── master_content_tag.rb
│   │   │   ├── master_migration.rb
│   │   │   ├── master_template.rb
│   │   │   ├── migration_result.rb
│   │   │   ├── restrictor.rb
│   │   │   ├── tag_helper.rb
│   │   │   └── tag_validator.rb
│   │   ├── master_courses.rb
│   │   ├── media_object.rb
│   │   ├── media_source_fetcher.rb
│   │   ├── media_track.rb
│   │   ├── mention.rb
│   │   ├── message.rb
│   │   ├── messages
│   │   │   ├── assignment_resubmitted
│   │   │   │   ├── email_presenter.rb
│   │   │   │   ├── presenter.rb
│   │   │   │   ├── sms_presenter.rb
│   │   │   │   └── summary_presenter.rb
│   │   │   ├── assignment_submitted
│   │   │   │   ├── email_presenter.rb
│   │   │   │   ├── presenter.rb
│   │   │   │   ├── sms_presenter.rb
│   │   │   │   └── summary_presenter.rb
│   │   │   ├── assignment_submitted_late
│   │   │   │   ├── email_presenter.rb
│   │   │   │   ├── presenter.rb
│   │   │   │   ├── sms_presenter.rb
│   │   │   │   └── summary_presenter.rb
│   │   │   ├── name_helper.rb
│   │   │   ├── partitioner.rb
│   │   │   └── submission_comment_for_teacher
│   │   │       ├── annotation_presenter.rb
│   │   │       ├── email_presenter.rb
│   │   │       ├── presenter.rb
│   │   │       ├── sms_presenter.rb
│   │   │       └── summary_presenter.rb
│   │   ├── microsoft_sync
│   │   │   ├── group.rb
│   │   │   ├── partial_sync_change.rb
│   │   │   └── user_mapping.rb
│   │   ├── microsoft_sync.rb
│   │   ├── migration_issue.rb
│   │   ├── moderated_grading
│   │   │   ├── null_provisional_grade.rb
│   │   │   ├── provisional_grade.rb
│   │   │   └── selection.rb
│   │   ├── moderated_grading.rb
│   │   ├── moderation_grader.rb
│   │   ├── notification.rb
│   │   ├── notification_endpoint.rb
│   │   ├── notification_failure_processor.rb
│   │   ├── notification_finder.rb
│   │   ├── notification_policy.rb
│   │   ├── notification_policy_override.rb
│   │   ├── notification_preloader.rb
│   │   ├── notifier.rb
│   │   ├── oauth_request.rb
│   │   ├── observer_alert.rb
│   │   ├── observer_alert_threshold.rb
│   │   ├── observer_enrollment.rb
│   │   ├── observer_pairing_code.rb
│   │   ├── one_time_password.rb
│   │   ├── originality_report.rb
│   │   ├── outcome_calculation_method.rb
│   │   ├── outcome_friendly_description.rb
│   │   ├── outcome_import.rb
│   │   ├── outcome_import_context.rb
│   │   ├── outcome_import_error.rb
│   │   ├── outcome_proficiency.rb
│   │   ├── outcome_proficiency_rating.rb
│   │   ├── outcomes_service
│   │   │   ├── migration_extractor.rb
│   │   │   ├── migration_service.rb
│   │   │   └── service.rb
│   │   ├── page_comment.rb
│   │   ├── page_view
│   │   │   ├── account_filter.rb
│   │   │   ├── csv_report.rb
│   │   │   └── pv4_client.rb
│   │   ├── page_view.rb
│   │   ├── parallel_importer.rb
│   │   ├── planner_note.rb
│   │   ├── planner_override.rb
│   │   ├── plugin_setting.rb
│   │   ├── polling
│   │   │   ├── poll.rb
│   │   │   ├── poll_choice.rb
│   │   │   ├── poll_session.rb
│   │   │   └── poll_submission.rb
│   │   ├── polling.rb
│   │   ├── post_policy.rb
│   │   ├── profile.rb
│   │   ├── progress.rb
│   │   ├── pseudonym.rb
│   │   ├── pseudonym_session.rb
│   │   ├── purgatory.rb
│   │   ├── quiz_migration_alert.rb
│   │   ├── quizzes
│   │   │   ├── log_auditing
│   │   │   │   ├── event_aggregator.rb
│   │   │   │   ├── question_answered_event_extractor.rb
│   │   │   │   ├── question_answered_event_optimizer.rb
│   │   │   │   └── snapshot_scraper.rb
│   │   │   ├── outstanding_quiz_submission_manager.rb
│   │   │   ├── preloader.rb
│   │   │   ├── quiz.rb
│   │   │   ├── quiz_eligibility.rb
│   │   │   ├── quiz_extension.rb
│   │   │   ├── quiz_group.rb
│   │   │   ├── quiz_outcome_result_builder.rb
│   │   │   ├── quiz_participant.rb
│   │   │   ├── quiz_question
│   │   │   │   ├── answer_group.rb
│   │   │   │   ├── answer_parsers
│   │   │   │   │   ├── answer_parser.rb
│   │   │   │   │   ├── calculated.rb
│   │   │   │   │   ├── essay.rb
│   │   │   │   │   ├── fill_in_multiple_blanks.rb
│   │   │   │   │   ├── matching.rb
│   │   │   │   │   ├── missing_word.rb
│   │   │   │   │   ├── multiple_answers.rb
│   │   │   │   │   ├── multiple_choice.rb
│   │   │   │   │   ├── multiple_dropdowns.rb
│   │   │   │   │   ├── numerical.rb
│   │   │   │   │   ├── short_answer.rb
│   │   │   │   │   ├── text_only.rb
│   │   │   │   │   └── true_false.rb
│   │   │   │   ├── answer_serializers
│   │   │   │   │   ├── answer_serializer.rb
│   │   │   │   │   ├── calculated.rb
│   │   │   │   │   ├── essay.rb
│   │   │   │   │   ├── file_upload.rb
│   │   │   │   │   ├── fill_in_multiple_blanks.rb
│   │   │   │   │   ├── matching.rb
│   │   │   │   │   ├── multiple_answers.rb
│   │   │   │   │   ├── multiple_choice.rb
│   │   │   │   │   ├── multiple_dropdowns.rb
│   │   │   │   │   ├── numerical.rb
│   │   │   │   │   ├── serialized_answer.rb
│   │   │   │   │   ├── short_answer.rb
│   │   │   │   │   ├── text_only.rb
│   │   │   │   │   ├── true_false.rb
│   │   │   │   │   ├── unknown.rb
│   │   │   │   │   └── util.rb
│   │   │   │   ├── answer_serializers.rb
│   │   │   │   ├── base.rb
│   │   │   │   ├── calculated_question.rb
│   │   │   │   ├── essay_question.rb
│   │   │   │   ├── file_upload_answer.rb
│   │   │   │   ├── file_upload_question.rb
│   │   │   │   ├── fill_in_multiple_blanks_question.rb
│   │   │   │   ├── match_group.rb
│   │   │   │   ├── matching_question.rb
│   │   │   │   ├── multiple_answers_question.rb
│   │   │   │   ├── multiple_choice_question.rb
│   │   │   │   ├── multiple_dropdowns_question.rb
│   │   │   │   ├── numerical_question.rb
│   │   │   │   ├── question_data.rb
│   │   │   │   ├── raw_fields.rb
│   │   │   │   ├── short_answer_question.rb
│   │   │   │   ├── text_only_question.rb
│   │   │   │   ├── unknown_question.rb
│   │   │   │   └── user_answer.rb
│   │   │   ├── quiz_question.rb
│   │   │   ├── quiz_question_builder
│   │   │   │   ├── bank_pool.rb
│   │   │   │   └── group_pool.rb
│   │   │   ├── quiz_question_builder.rb
│   │   │   ├── quiz_question_regrade.rb
│   │   │   ├── quiz_regrade.rb
│   │   │   ├── quiz_regrade_run.rb
│   │   │   ├── quiz_regrader
│   │   │   │   ├── answer.rb
│   │   │   │   ├── attempt_version.rb
│   │   │   │   ├── regrader.rb
│   │   │   │   └── submission.rb
│   │   │   ├── quiz_sortables.rb
│   │   │   ├── quiz_statistics
│   │   │   │   ├── item_analysis
│   │   │   │   │   ├── item.rb
│   │   │   │   │   └── summary.rb
│   │   │   │   ├── item_analysis.rb
│   │   │   │   ├── report.rb
│   │   │   │   └── student_analysis.rb
│   │   │   ├── quiz_statistics.rb
│   │   │   ├── quiz_statistics_service.rb
│   │   │   ├── quiz_submission
│   │   │   │   └── question_reference_data_fixer.rb
│   │   │   ├── quiz_submission.rb
│   │   │   ├── quiz_submission_attempt.rb
│   │   │   ├── quiz_submission_event.rb
│   │   │   ├── quiz_submission_event_partitioner.rb
│   │   │   ├── quiz_submission_history.rb
│   │   │   ├── quiz_submission_service.rb
│   │   │   ├── quiz_submission_snapshot.rb
│   │   │   ├── quiz_submission_zipper.rb
│   │   │   ├── quiz_user_finder.rb
│   │   │   ├── quiz_user_messager.rb
│   │   │   ├── scoped_to_user.rb
│   │   │   ├── submission_grader.rb
│   │   │   └── submission_manager.rb
│   │   ├── quizzes.rb
│   │   ├── quizzes_next
│   │   │   ├── export_service.rb
│   │   │   ├── importers
│   │   │   │   └── course_content_importer.rb
│   │   │   └── service.rb
│   │   ├── received_content_share.rb
│   │   ├── release_note.rb
│   │   ├── release_notes
│   │   │   └── dev_utils.rb
│   │   ├── report_snapshot.rb
│   │   ├── role.rb
│   │   ├── role_override.rb
│   │   ├── rollup_score.rb
│   │   ├── root_account_resolver.rb
│   │   ├── rubric
│   │   │   └── trackable.rb
│   │   ├── rubric.rb
│   │   ├── rubric_assessment
│   │   │   └── trackable.rb
│   │   ├── rubric_assessment.rb
│   │   ├── rubric_assessment_export.rb
│   │   ├── rubric_assessment_import.rb
│   │   ├── rubric_association.rb
│   │   ├── rubric_criterion
│   │   │   └── trackable.rb
│   │   ├── rubric_criterion.rb
│   │   ├── rubric_import.rb
│   │   ├── scheduled_publication.rb
│   │   ├── scheduled_smart_alert.rb
│   │   ├── score.rb
│   │   ├── score_metadata.rb
│   │   ├── score_statistic.rb
│   │   ├── sent_content_share.rb
│   │   ├── session_persistence_token.rb
│   │   ├── setting.rb
│   │   ├── sharded_bookmarked_collection.rb
│   │   ├── shared_brand_config.rb
│   │   ├── simply_versioned
│   │   │   └── partitioner.rb
│   │   ├── sis_batch.rb
│   │   ├── sis_batch_error.rb
│   │   ├── sis_batch_roll_back_data.rb
│   │   ├── sis_post_grades_status.rb
│   │   ├── sis_pseudonym.rb
│   │   ├── speed_grader
│   │   │   ├── assignment.rb
│   │   │   └── student_group_selection.rb
│   │   ├── split_users.rb
│   │   ├── standard_grade_status.rb
│   │   ├── stream_item.rb
│   │   ├── stream_item_instance.rb
│   │   ├── student_enrollment.rb
│   │   ├── student_view_enrollment.rb
│   │   ├── sub_assignment.rb
│   │   ├── submission.rb
│   │   ├── submission_comment.rb
│   │   ├── submission_comment_interaction.rb
│   │   ├── submission_draft.rb
│   │   ├── submission_draft_attachment.rb
│   │   ├── submission_version.rb
│   │   ├── ta_enrollment.rb
│   │   ├── teacher_enrollment.rb
│   │   ├── temporary_enrollment_pairing.rb
│   │   ├── terms_of_service.rb
│   │   ├── terms_of_service_content.rb
│   │   ├── thumbnail.rb
│   │   ├── usage_rights.rb
│   │   ├── user.rb
│   │   ├── user_account_association.rb
│   │   ├── user_learning_object_scopes.rb
│   │   ├── user_lmgb_outcome_orderings.rb
│   │   ├── user_merge_data.rb
│   │   ├── user_merge_data_item.rb
│   │   ├── user_merge_data_record.rb
│   │   ├── user_observation_link.rb
│   │   ├── user_observer.rb
│   │   ├── user_past_lti_id.rb
│   │   ├── user_preference_value.rb
│   │   ├── user_profile.rb
│   │   ├── user_profile_link.rb
│   │   ├── user_service.rb
│   │   ├── users
│   │   │   ├── access_verifier.rb
│   │   │   └── creation_notify_policy.rb
│   │   ├── version.rb
│   │   ├── viewed_submission_comment.rb
│   │   ├── web_conference.rb
│   │   ├── web_conference_participant.rb
│   │   ├── web_zip_export.rb
│   │   ├── wiki.rb
│   │   ├── wiki_page.rb
│   │   ├── wiki_page_embedding.rb
│   │   ├── wiki_page_lookup.rb
│   │   ├── wiki_pages
│   │   │   └── scoped_to_user.rb
│   │   └── wimba_conference.rb
│   ├── observers
│   │   ├── cacher.rb
│   │   ├── live_events_observer.rb
│   │   └── stream_item_cache.rb
│   ├── presenters
│   │   ├── assignment_presenter.rb
│   │   ├── authentication_providers_presenter.rb
│   │   ├── communication_channel_presenter.rb
│   │   ├── course_for_menu_presenter.rb
│   │   ├── course_pace_presenter.rb
│   │   ├── course_pacing
│   │   │   ├── pace_contexts_presenter.rb
│   │   │   ├── pace_presenter.rb
│   │   │   ├── section_pace_presenter.rb
│   │   │   ├── student_enrollment_pace_presenter.rb
│   │   │   └── templates
│   │   │       ├── DefaultCoursePace.docx
│   │   │       ├── IndividualCoursePace.docx
│   │   │       └── SectionCoursePace.docx
│   │   ├── discussion_topic_presenter.rb
│   │   ├── grade_summary_assignment_presenter.rb
│   │   ├── grade_summary_presenter.rb
│   │   ├── grades_presenter.rb
│   │   ├── grading_period_grade_summary_presenter.rb
│   │   ├── mark_done_presenter.rb
│   │   ├── override_list_presenter.rb
│   │   ├── override_tooltip_presenter.rb
│   │   ├── quizzes
│   │   │   └── take_quiz_presenter.rb
│   │   ├── section_tab_presenter.rb
│   │   ├── submission
│   │   │   ├── anonymous_upload_presenter.rb
│   │   │   ├── show_presenter.rb
│   │   │   └── upload_presenter.rb
│   │   └── to_do_list_presenter.rb
│   ├── serializers
│   │   ├── attachment_serializer.rb
│   │   ├── canvas
│   │   │   ├── api_array_serializer.rb
│   │   │   ├── api_serialization.rb
│   │   │   └── api_serializer.rb
│   │   ├── developer_key_account_binding_serializer.rb
│   │   ├── grading_period_serializer.rb
│   │   ├── grading_period_set_serializer.rb
│   │   ├── late_policy_serializer.rb
│   │   ├── live_assessments
│   │   │   ├── assessment_serializer.rb
│   │   │   └── result_serializer.rb
│   │   ├── live_events
│   │   │   ├── attachment_serializer.rb
│   │   │   ├── event_serializer_provider.rb
│   │   │   └── external_tool_serializer.rb
│   │   ├── locked_serializer.rb
│   │   ├── lti
│   │   │   ├── ims
│   │   │   │   ├── line_items_serializer.rb
│   │   │   │   ├── names_and_roles_serializer.rb
│   │   │   │   └── results_serializer.rb
│   │   │   └── tool_configuration_serializer.rb
│   │   ├── permissions_serializer.rb
│   │   ├── polling
│   │   │   ├── poll_choice_serializer.rb
│   │   │   ├── poll_serializer.rb
│   │   │   ├── poll_session_serializer.rb
│   │   │   └── poll_submission_serializer.rb
│   │   ├── progress_serializer.rb
│   │   ├── quizzes
│   │   │   ├── quiz_api_serializer.rb
│   │   │   ├── quiz_extension_serializer.rb
│   │   │   ├── quiz_report_serializer.rb
│   │   │   ├── quiz_serializer.rb
│   │   │   ├── quiz_statistics_serializer.rb
│   │   │   ├── quiz_submission_serializer.rb
│   │   │   └── quiz_submission_user_serializer.rb
│   │   └── quizzes_next
│   │       └── quiz_serializer.rb
│   ├── services
│   │   ├── application_service.rb
│   │   ├── assignment_visibility
│   │   │   ├── assignment_visibility_service.rb
│   │   │   ├── entities
│   │   │   │   └── assignment_visible_to_student.rb
│   │   │   └── repositories
│   │   │       └── assignment_visible_to_student_repository.rb
│   │   ├── auto_grade_comments_service.rb
│   │   ├── auto_grade_service.rb
│   │   ├── checkpoints
│   │   │   ├── adhoc_override_common_service.rb
│   │   │   ├── adhoc_override_creator_service.rb
│   │   │   ├── adhoc_override_updater_service.rb
│   │   │   ├── aggregator_service.rb
│   │   │   ├── assignment_aggregator_service.rb
│   │   │   ├── course_override_creator_service.rb
│   │   │   ├── course_override_updater_service.rb
│   │   │   ├── date_override_common_service.rb
│   │   │   ├── date_override_creator_service.rb
│   │   │   ├── date_override_updater_service.rb
│   │   │   ├── date_overrider.rb
│   │   │   ├── discussion_checkpoint_common_service.rb
│   │   │   ├── discussion_checkpoint_creator_service.rb
│   │   │   ├── discussion_checkpoint_deleter_service.rb
│   │   │   ├── discussion_checkpoint_error.rb
│   │   │   ├── discussion_checkpoint_updater_service.rb
│   │   │   ├── group_override_common.rb
│   │   │   ├── group_override_creator_service.rb
│   │   │   ├── group_override_updater_service.rb
│   │   │   ├── section_override_creator_service.rb
│   │   │   ├── section_override_updater_service.rb
│   │   │   └── submission_aggregator_service.rb
│   │   ├── course_pacing
│   │   │   ├── course_pace_service.rb
│   │   │   ├── pace_contexts_service.rb
│   │   │   ├── pace_service.rb
│   │   │   ├── section_pace_service.rb
│   │   │   └── student_enrollment_pace_service.rb
│   │   ├── courses
│   │   │   ├── horizon_service.rb
│   │   │   └── off_pace
│   │   │       └── students
│   │   │           ├── reporter.rb
│   │   │           └── validator.rb
│   │   ├── differentiation_tag
│   │   │   ├── adhoc_override_creator_service.rb
│   │   │   ├── converters
│   │   │   │   ├── context_module_override_converter.rb
│   │   │   │   ├── general_assignment_override_converter.rb
│   │   │   │   └── tag_override_converter.rb
│   │   │   └── override_converter_service.rb
│   │   ├── differentiation_tag.rb
│   │   ├── flamegraphs
│   │   │   └── flamegraph_service.rb
│   │   ├── inbox
│   │   │   ├── entities
│   │   │   │   └── inbox_settings.rb
│   │   │   ├── inbox_service.rb
│   │   │   └── repositories
│   │   │       └── inbox_settings_repository.rb
│   │   ├── k5
│   │   │   ├── enablement_service.rb
│   │   │   └── user_service.rb
│   │   ├── login
│   │   │   └── login_brand_config_filter.rb
│   │   ├── lti
│   │   │   ├── account_binding_service.rb
│   │   │   ├── asset_processor_notifier.rb
│   │   │   ├── create_registration_service.rb
│   │   │   ├── list_registration_service.rb
│   │   │   ├── log_service.rb
│   │   │   ├── platform_notification_service.rb
│   │   │   ├── tool_finder.rb
│   │   │   └── update_registration_service.rb
│   │   ├── module_visibility
│   │   │   ├── entities
│   │   │   │   └── module_visible_to_student.rb
│   │   │   ├── module_visibility_service.rb
│   │   │   └── repositories
│   │   │       └── module_visible_to_student_repository.rb
│   │   ├── quiz_visibility
│   │   │   ├── entities
│   │   │   │   └── quiz_visible_to_student.rb
│   │   │   ├── quiz_visibility_service.rb
│   │   │   └── repositories
│   │   │       └── quiz_visible_to_student_repository.rb
│   │   ├── submissions
│   │   │   └── what_if_grades_service.rb
│   │   ├── ungraded_discussion_visibility
│   │   │   ├── entities
│   │   │   │   └── ungraded_discussion_visible_to_student.rb
│   │   │   ├── repositories
│   │   │   │   └── ungraded_discussion_visible_to_student_repository.rb
│   │   │   └── ungraded_discussion_visibility_service.rb
│   │   ├── video_caption_service.rb
│   │   ├── visibility_helpers
│   │   │   ├── cache_settings.rb
│   │   │   └── common.rb
│   │   └── wiki_page_visibility
│   │       ├── entities
│   │       │   └── wiki_page_visible_to_student.rb
│   │       ├── repositories
│   │       │   └── wiki_page_visible_to_student_repository.rb
│   │       └── wiki_page_visibility_service.rb
│   ├── stylesheets
│   │   ├── base
│   │   │   ├── _SideNav.scss
│   │   │   ├── _custom_bootstrap.scss
│   │   │   ├── _custom_mediaelementplayer.css
│   │   │   ├── _environment.scss
│   │   │   ├── _ic_app_header.scss
│   │   │   ├── _ic_app_layout.scss
│   │   │   ├── _ic_mixins.scss
│   │   │   ├── _ic_utilities.scss
│   │   │   ├── _layout.scss
│   │   │   ├── _left-side.scss
│   │   │   ├── _module_sequence_footer.scss
│   │   │   ├── _print.scss
│   │   │   ├── _right-side.scss
│   │   │   ├── _shared.scss
│   │   │   ├── _variables.scss
│   │   │   └── mixins
│   │   │       ├── _blue.scss
│   │   │       ├── _breakpoints.scss
│   │   │       ├── _bubbles.scss
│   │   │       ├── _compile_mixins.scss
│   │   │       ├── _misc.scss
│   │   │       └── _typography.scss
│   │   ├── brandable_variables.json
│   │   ├── bundles
│   │   │   ├── account_admin_tools.scss
│   │   │   ├── account_calendar_settings.scss
│   │   │   ├── account_settings.scss
│   │   │   ├── act_as_modal.scss
│   │   │   ├── addpeople.scss
│   │   │   ├── agenda_view.scss
│   │   │   ├── aligned_outcomes.scss
│   │   │   ├── all_courses.scss
│   │   │   ├── announcements_index.scss
│   │   │   ├── assignment_enhancements_teacher_view.scss
│   │   │   ├── assignment_grade_summary.scss
│   │   │   ├── assignments.scss
│   │   │   ├── assignments_2_student.scss
│   │   │   ├── assignments_2_teacher.scss
│   │   │   ├── assignments_edit.scss
│   │   │   ├── assignments_peer_review.scss
│   │   │   ├── blueprint_courses.scss
│   │   │   ├── brand_config_index.scss
│   │   │   ├── calendar2.scss
│   │   │   ├── calendar_appointment_group_edit.scss
│   │   │   ├── canvas_inbox.scss
│   │   │   ├── canvas_quizzes.scss
│   │   │   ├── choose_mastery_path.scss
│   │   │   ├── common.scss
│   │   │   ├── conditional_release_editor.scss
│   │   │   ├── conferences.scss
│   │   │   ├── content_migrations.scss
│   │   │   ├── content_next.scss
│   │   │   ├── content_shares.scss
│   │   │   ├── context_cards.scss
│   │   │   ├── context_list.scss
│   │   │   ├── context_module_progressions.scss
│   │   │   ├── context_modules.scss
│   │   │   ├── context_modules2.scss
│   │   │   ├── conversations_new.scss
│   │   │   ├── course_link_validator.scss
│   │   │   ├── course_list.scss
│   │   │   ├── course_paces.scss
│   │   │   ├── course_settings.scss
│   │   │   ├── course_show.scss
│   │   │   ├── course_show_secondary.scss
│   │   │   ├── course_wizard.scss
│   │   │   ├── dashboard.scss
│   │   │   ├── dashboard_card.scss
│   │   │   ├── developer_keys.scss
│   │   │   ├── disable_transitions.scss
│   │   │   ├── discussions.scss
│   │   │   ├── discussions_edit.scss
│   │   │   ├── discussions_index.scss
│   │   │   ├── edit_calendar_event_full.scss
│   │   │   ├── enhanced_individual_gradebook.scss
│   │   │   ├── enhanced_rubrics.scss
│   │   │   ├── enrollment_terms.scss
│   │   │   ├── eportfolio_moderation.scss
│   │   │   ├── epub_exports.scss
│   │   │   ├── external_tool_full_width.scss
│   │   │   ├── external_tool_full_width_in_context.scss
│   │   │   ├── external_tool_full_width_with_nav.scss
│   │   │   ├── federated_attributes.scss
│   │   │   ├── fonts.scss
│   │   │   ├── grade_summary.scss
│   │   │   ├── gradebook.scss
│   │   │   ├── gradebook_uploads.scss
│   │   │   ├── grading_period_sets.scss
│   │   │   ├── grading_periods.scss
│   │   │   ├── grading_standards.scss
│   │   │   ├── improved_outcomes_management.scss
│   │   │   ├── instructure_eportfolio.scss
│   │   │   ├── jobs_v2.scss
│   │   │   ├── k5_common.scss
│   │   │   ├── k5_course.scss
│   │   │   ├── k5_dashboard.scss
│   │   │   ├── k5_font.scss
│   │   │   ├── k5_theme.scss
│   │   │   ├── k6_theme.scss
│   │   │   ├── learning_mastery.scss
│   │   │   ├── learning_outcomes.scss
│   │   │   ├── license_help.scss
│   │   │   ├── locale.scss
│   │   │   ├── login.scss
│   │   │   ├── login_confirm.scss
│   │   │   ├── media_player.scss
│   │   │   ├── messages.scss
│   │   │   ├── mobile_auth.scss
│   │   │   ├── moderate_quiz.scss
│   │   │   ├── new_assignments.scss
│   │   │   ├── new_user_tutorials.scss
│   │   │   ├── not_found_index.scss
│   │   │   ├── otp_login.scss
│   │   │   ├── pairing_code.scss
│   │   │   ├── permissions.scss
│   │   │   ├── prior_users.scss
│   │   │   ├── proficiency_table.scss
│   │   │   ├── profile_edit.scss
│   │   │   ├── profile_show.scss
│   │   │   ├── question_bank.scss
│   │   │   ├── quizzes.scss
│   │   │   ├── rce.scss
│   │   │   ├── react_collaborations.scss
│   │   │   ├── react_files.scss
│   │   │   ├── react_todo_sidebar.scss
│   │   │   ├── registration.scss
│   │   │   ├── reminder_course_setup.scss
│   │   │   ├── reports.scss
│   │   │   ├── roster.scss
│   │   │   ├── roster_user.scss
│   │   │   ├── roster_user_usage.scss
│   │   │   ├── saml_fields.scss
│   │   │   ├── search.scss
│   │   │   ├── select_content_dialog.scss
│   │   │   ├── self_enrollment.scss
│   │   │   ├── settings_sidebar.scss
│   │   │   ├── show_submissions_upload.scss
│   │   │   ├── side_tabs_table.scss
│   │   │   ├── slickgrid.scss
│   │   │   ├── speed_grader.scss
│   │   │   ├── statistics.scss
│   │   │   ├── styleguide.scss
│   │   │   ├── submission.scss
│   │   │   ├── syllabus.scss
│   │   │   ├── terms.scss
│   │   │   ├── theme_editor.scss
│   │   │   ├── theme_preview.scss
│   │   │   ├── tinymce.scss
│   │   │   ├── trophy_case.scss
│   │   │   ├── ui_listview.scss
│   │   │   ├── unauthorized_message.scss
│   │   │   ├── user_grades.scss
│   │   │   ├── user_list_boxes.scss
│   │   │   ├── user_logins.scss
│   │   │   ├── ways_to_contact.scss
│   │   │   ├── webzip_export.scss
│   │   │   ├── what_gets_loaded_inside_the_tinymce_editor.scss
│   │   │   └── wiki_page.scss
│   │   ├── components
│   │   │   ├── _MimeClassIcons.scss
│   │   │   ├── _ProgressBar.scss
│   │   │   ├── _aacs.scss
│   │   │   ├── _admin_links.scss
│   │   │   ├── _alerts.scss
│   │   │   ├── _alignment.scss
│   │   │   ├── _announcement-rss-tray.scss
│   │   │   ├── _autocomplete.scss
│   │   │   ├── _avatars.scss
│   │   │   ├── _borders.scss
│   │   │   ├── _breadcrumbs.scss
│   │   │   ├── _broken-images.scss
│   │   │   ├── _buttons.scss
│   │   │   ├── _canvas-icons.scss
│   │   │   ├── _carousel.scss
│   │   │   ├── _centered-block.scss
│   │   │   ├── _components.scss
│   │   │   ├── _conditional_release.scss
│   │   │   ├── _conditional_release_stats.scss
│   │   │   ├── _context_search.scss
│   │   │   ├── _element-toggler.scss
│   │   │   ├── _emoji.scss
│   │   │   ├── _empty-state.scss
│   │   │   ├── _external_link.scss
│   │   │   ├── _flickrSearch.scss
│   │   │   ├── _forms.scss
│   │   │   ├── _g_assignments.scss
│   │   │   ├── _g_collaborations.scss
│   │   │   ├── _g_conference.scss
│   │   │   ├── _g_context_modules.scss
│   │   │   ├── _g_groups.scss
│   │   │   ├── _g_instructure.scss
│   │   │   ├── _g_media_comments.scss
│   │   │   ├── _g_mini_calendar.scss
│   │   │   ├── _g_rubrics.scss
│   │   │   ├── _g_wiki.scss
│   │   │   ├── _grade_detail_tray.scss
│   │   │   ├── _gutters.scss
│   │   │   ├── _header_bar.scss
│   │   │   ├── _helpDialog.scss
│   │   │   ├── _ic-badge.scss
│   │   │   ├── _ic-code.scss
│   │   │   ├── _ic-color-picker.scss
│   │   │   ├── _ic-content-rows.scss
│   │   │   ├── _ic-expand-link.scss
│   │   │   ├── _ic-forms.scss
│   │   │   ├── _ic-icon-header.scss
│   │   │   ├── _ic-image-text-combo.scss
│   │   │   ├── _ic-range-input.scss
│   │   │   ├── _ic-reset.scss
│   │   │   ├── _ic-sortable-list.scss
│   │   │   ├── _ic-super-toggle.scss
│   │   │   ├── _ic-theme-card.scss
│   │   │   ├── _ic-typography.scss
│   │   │   ├── _ic-unread-badge.scss
│   │   │   ├── _inst_tree.scss
│   │   │   ├── _item-groups-condensed.scss
│   │   │   ├── _item-groups.scss
│   │   │   ├── _lock-state.scss
│   │   │   ├── _master-course-state.scss
│   │   │   ├── _media_recorder.scss
│   │   │   ├── _message_students.scss
│   │   │   ├── _misc.scss
│   │   │   ├── _new-and-total-badge.scss
│   │   │   ├── _pill.scss
│   │   │   ├── _post-to-sis-state.scss
│   │   │   ├── _publish-state.scss
│   │   │   ├── _react_modal.scss
│   │   │   ├── _rubric.scss
│   │   │   ├── _show_hide_opacity.scss
│   │   │   ├── _spacing.scss
│   │   │   ├── _spinner.scss
│   │   │   ├── _submission_stickers.scss
│   │   │   ├── _tables.scss
│   │   │   ├── _tabs.scss
│   │   │   ├── _token_input.scss
│   │   │   ├── _token_selector.scss
│   │   │   ├── _typography.scss
│   │   │   ├── _ui.selectmenu.scss
│   │   │   ├── _webcam_modal.scss
│   │   │   └── deprecated
│   │   │       ├── _fancy_links.scss
│   │   │       ├── _legacy_buttons.scss
│   │   │       ├── _misc.scss
│   │   │       └── _tooltip.scss
│   │   ├── deprecated
│   │   │   └── bootstrap
│   │   │       ├── _close.scss
│   │   │       ├── _labels-badges.scss
│   │   │       ├── _mixins.scss
│   │   │       ├── _navs.scss
│   │   │       ├── _progress-bars.scss
│   │   │       ├── _responsive-1200px-min.scss
│   │   │       └── _responsive-768px-979px.scss
│   │   ├── eportfolio_static.css
│   │   ├── jst
│   │   │   ├── AssignmentDetailsDialog.scss
│   │   │   ├── FindFlickrImageView.scss
│   │   │   ├── MoveOutcomeDialog.scss
│   │   │   ├── PaginatedView.scss
│   │   │   ├── SubmissionDetailsDialog.scss
│   │   │   ├── TreeBrowser.scss
│   │   │   ├── assignments
│   │   │   │   ├── AssignmentGroupListItem.scss
│   │   │   │   └── DueDateOverride.scss
│   │   │   ├── calendar
│   │   │   │   └── calendarApp.scss
│   │   │   ├── courses
│   │   │   │   └── Syllabus.scss
│   │   │   ├── editor
│   │   │   │   └── KeyboardShortcuts.scss
│   │   │   ├── groups
│   │   │   │   └── manage
│   │   │   │       ├── addUnassignedMenu.scss
│   │   │   │       ├── assignToGroupMenu.scss
│   │   │   │       ├── group.scss
│   │   │   │       ├── groupCategories.scss
│   │   │   │       ├── groupCategory.scss
│   │   │   │       ├── groupCategoryCreate.scss
│   │   │   │       └── groupUsers.scss
│   │   │   ├── messageStudentsDialog.scss
│   │   │   ├── outcomes
│   │   │   │   └── outcomePopover.scss
│   │   │   ├── quizzes
│   │   │   │   ├── LDBLoginPopup.scss
│   │   │   │   └── fileUploadQuestionState.scss
│   │   │   └── widget
│   │   │       └── UploadMediaTrackForm.scss
│   │   ├── our_custom_tiny_mce_stuff
│   │   │   ├── _tiny_like_ck_with_external_tools.scss
│   │   │   └── _tinymce.editor_box.scss
│   │   ├── pages
│   │   │   ├── _rubrics.scss
│   │   │   ├── _turnitin.scss
│   │   │   ├── _wiki_animations.scss
│   │   │   ├── account_settings
│   │   │   │   └── _account_settings.scss
│   │   │   ├── agenda
│   │   │   │   └── _agenda_view_minical.scss
│   │   │   ├── assignment_enhancements_teacher_view
│   │   │   │   └── _teacher_view.scss
│   │   │   ├── assignments
│   │   │   │   └── _assignments.scss
│   │   │   ├── assignments2_student
│   │   │   │   ├── _file_select_items.scss
│   │   │   │   ├── _step_items.scss
│   │   │   │   ├── _steps.scss
│   │   │   │   ├── _student_header.scss
│   │   │   │   └── _students_comments.scss
│   │   │   ├── assignments_2_teacher
│   │   │   │   └── _teacher_view.scss
│   │   │   ├── calendar
│   │   │   │   ├── _appointment_group_edit.scss
│   │   │   │   ├── _calendar2.scss
│   │   │   │   ├── _calendarHeader.scss
│   │   │   │   ├── _mini_calendar.scss
│   │   │   │   ├── _scheduler.scss
│   │   │   │   └── _sidebar.scss
│   │   │   ├── canvas_inbox
│   │   │   │   └── _canvas_inbox.scss
│   │   │   ├── conditional_release_editor
│   │   │   │   ├── _assignment-card.scss
│   │   │   │   ├── _assignment-modal.scss
│   │   │   │   ├── _assignment-picker.scss
│   │   │   │   ├── _assignment-set.scss
│   │   │   │   ├── _condition-toggle.scss
│   │   │   │   ├── _editor-view.scss
│   │   │   │   ├── _percent-input.scss
│   │   │   │   ├── _score-label.scss
│   │   │   │   └── _scoring-range.scss
│   │   │   ├── conversations
│   │   │   │   ├── _compose_message_dialog.scss
│   │   │   │   └── _conversations_new.scss
│   │   │   ├── course_settings
│   │   │   │   ├── _CourseImageSelector.scss
│   │   │   │   ├── _blueprint_settings.scss
│   │   │   │   └── _course_settings.scss
│   │   │   ├── dashboard
│   │   │   │   └── _dashboard_activity.scss
│   │   │   ├── eportfolio_moderation
│   │   │   │   └── _eportfolio_moderation.scss
│   │   │   ├── gradebook
│   │   │   │   ├── _grade_passback.scss
│   │   │   │   ├── _gradebook.scss
│   │   │   │   ├── _gradebook_settings.scss
│   │   │   │   └── _learning_outcome_gradebook.scss
│   │   │   ├── learning_mastery
│   │   │   │   ├── _grade_passback.scss
│   │   │   │   ├── _gradebook.scss
│   │   │   │   └── _learning_outcome_gradebook.scss
│   │   │   ├── login
│   │   │   │   ├── _ic-login-sso.scss
│   │   │   │   ├── _ic-login.scss
│   │   │   │   ├── _login_otp.scss
│   │   │   │   └── _registration_dialog.scss
│   │   │   ├── quiz_log_auditing
│   │   │   │   ├── _main.scss
│   │   │   │   ├── _variables.scss
│   │   │   │   ├── blocks
│   │   │   │   │   ├── _event_stream.scss
│   │   │   │   │   ├── _question_anchors.scss
│   │   │   │   │   └── event_stream
│   │   │   │   │       └── _action_log.scss
│   │   │   │   └── components
│   │   │   │       ├── _ic_quiz_inspector.scss
│   │   │   │       └── ic_quiz_inspector
│   │   │   │           ├── _answer_matrix.scss
│   │   │   │           ├── _question_inspector.scss
│   │   │   │           ├── _question_listing.scss
│   │   │   │           └── _session.scss
│   │   │   ├── quiz_statistics
│   │   │   │   ├── _main.scss
│   │   │   │   ├── _question_statistics.scss
│   │   │   │   ├── _summary_statistics.scss
│   │   │   │   ├── _variables.scss
│   │   │   │   ├── components
│   │   │   │   │   └── _ic_spinner.scss
│   │   │   │   └── ext
│   │   │   │       └── _qtip.scss
│   │   │   ├── quizzes
│   │   │   │   ├── _quizzes-mobile.scss
│   │   │   │   └── _quizzes.scss
│   │   │   ├── react_collaborations
│   │   │   │   ├── _Collaboration.scss
│   │   │   │   ├── _CollaborationsApp.scss
│   │   │   │   ├── _DeleteConfirmation.scss
│   │   │   │   └── _LoadingSpinner.scss
│   │   │   ├── react_files
│   │   │   │   ├── _DialogPreview.scss
│   │   │   │   ├── _FilePreview.scss
│   │   │   │   ├── _FileUpload.scss
│   │   │   │   ├── _FolderTree.scss
│   │   │   │   ├── _MoveDialog.scss
│   │   │   │   ├── _RestrictedDialogForm.scss
│   │   │   │   ├── _RestrictedRadioButtons.scss
│   │   │   │   ├── _Toolbar.scss
│   │   │   │   ├── _UsageRightsDialog.scss
│   │   │   │   ├── _UsageRightsIndicator.scss
│   │   │   │   ├── _UsageRightsSelectBox.scss
│   │   │   │   └── _react_files.scss
│   │   │   ├── screenreader_gradebook
│   │   │   │   └── _screenreader_gradebook.scss
│   │   │   ├── shared
│   │   │   │   ├── _external_tools.scss
│   │   │   │   ├── _feature_flags.scss
│   │   │   │   ├── _grading_standards.scss
│   │   │   │   ├── _mark_as_done.scss
│   │   │   │   ├── _menu_tools.scss
│   │   │   │   ├── _message_students.scss
│   │   │   │   ├── _move_dialog.scss
│   │   │   │   └── _outcome_colors.scss
│   │   │   └── styleguide
│   │   │       ├── _styleguide_app.scss
│   │   │       ├── _styleguide_layout.scss
│   │   │       ├── _styleguide_setup.scss
│   │   │       └── _styleguide_syntax.scss
│   │   ├── variants
│   │   │   ├── new_styles_high_contrast
│   │   │   │   └── _variant_variables.scss
│   │   │   ├── new_styles_high_contrast_dyslexic
│   │   │   │   └── _variant_variables.scss
│   │   │   ├── new_styles_high_contrast_rtl
│   │   │   │   └── _variant_variables.scss
│   │   │   ├── new_styles_normal_contrast
│   │   │   │   └── _variant_variables.scss
│   │   │   ├── new_styles_normal_contrast_dyslexic
│   │   │   │   └── _variant_variables.scss
│   │   │   └── new_styles_normal_contrast_rtl
│   │   │       └── _variant_variables.scss
│   │   └── vendor
│   │       ├── _embed_content.scss
│   │       ├── _flexboxgrid.scss
│   │       ├── _slick.grid.scss
│   │       ├── _xflex.scss
│   │       ├── bootstrap
│   │       │   ├── _button-groups.scss
│   │       │   ├── _dropdowns.scss
│   │       │   ├── _forms.scss
│   │       │   ├── _grid.scss
│   │       │   ├── _layouts.scss
│   │       │   ├── _media.scss
│   │       │   ├── _pagination.scss
│   │       │   ├── _popovers.scss
│   │       │   ├── _responsive-navbar.scss
│   │       │   ├── _tables.scss
│   │       │   ├── _thumbnails.scss
│   │       │   └── _variables.scss
│   │       ├── jquery.qtip.scss
│   │       └── jqueryui
│   │           ├── _jquery.ui.all.scss
│   │           ├── _jquery.ui.autocomplete.scss
│   │           ├── _jquery.ui.button.scss
│   │           ├── _jquery.ui.core.scss
│   │           ├── _jquery.ui.datepicker.scss
│   │           ├── _jquery.ui.dialog.scss
│   │           ├── _jquery.ui.menu.scss
│   │           ├── _jquery.ui.progressbar.scss
│   │           ├── _jquery.ui.resizable.scss
│   │           ├── _jquery.ui.selectable.scss
│   │           ├── _jquery.ui.tabs.scss
│   │           ├── _jquery.ui.theme.scss
│   │           ├── _jquery.ui.tooltip.scss
│   │           ├── _overrides.scss
│   │           └── _variables.scss
│   └── views
│       ├── accounts
│       │   ├── _account_user.html.erb
│       │   ├── _additional_settings.html.erb
│       │   ├── _additional_settings_right_side.html.erb
│       │   ├── _course.html.erb
│       │   ├── _edit_account_notification.html.erb
│       │   ├── _external_integration_keys.html.erb
│       │   ├── _sis_agent_token_auth.html.erb
│       │   ├── _sis_batch_counts.html.erb
│       │   ├── _sis_batch_messages.html.erb
│       │   ├── _sis_integration_settings.html.erb
│       │   ├── _sis_integration_settings_old.html.erb
│       │   ├── admin_tools.html.erb
│       │   ├── avatars.html.erb
│       │   ├── confirm_delete_user.html.erb
│       │   ├── eportfolio_moderation.html.erb
│       │   ├── index.html.erb
│       │   ├── reports_tab.html.erb
│       │   ├── settings.html.erb
│       │   ├── sis_import.html.erb
│       │   └── statistics.html.erb
│       ├── announcements
│       │   └── index.html.erb
│       ├── assignments
│       │   ├── _assignment_details.html.erb
│       │   ├── _assignment_sidebar.html.erb
│       │   ├── _assignments_list_right_side.html.erb
│       │   ├── _confetti.html.erb
│       │   ├── _eula_checkbox.html.erb
│       │   ├── _grade_assignment.html.erb
│       │   ├── _group_comment.html.erb
│       │   ├── _group_submission_reminder.html.erb
│       │   ├── _lti_header.html.erb
│       │   ├── _peer_review_assignment.html.erb
│       │   ├── _student_assignment_overview.html.erb
│       │   ├── _submission_sidebar.html.erb
│       │   ├── _submit_assignment.html.erb
│       │   ├── _submit_online_text_entry.html.erb
│       │   ├── _submit_online_upload.html.erb
│       │   ├── _syllabus_content.html.erb
│       │   ├── _syllabus_right_side.html.erb
│       │   ├── _turnitin.html.erb
│       │   ├── _vericite.html.erb
│       │   ├── edit.html.erb
│       │   ├── new_index.html.erb
│       │   ├── peer_reviews.html.erb
│       │   ├── redirect_page.html.erb
│       │   ├── show.html.erb
│       │   ├── syllabus.html.erb
│       │   └── text_entry_page.html.erb
│       ├── authentication_providers
│       │   ├── _aac_settings.html.erb
│       │   ├── _additional_settings.html.erb
│       │   ├── _apple_fields.html.erb
│       │   ├── _canvas_fields.html.erb
│       │   ├── _cas_fields.html.erb
│       │   ├── _clever_fields.html.erb
│       │   ├── _debug_data.html.erb
│       │   ├── _debugging.html.erb
│       │   ├── _facebook_fields.html.erb
│       │   ├── _federated_attributes.html.erb
│       │   ├── _github_fields.html.erb
│       │   ├── _google_fields.html.erb
│       │   ├── _jit_provisioning_field.html.erb
│       │   ├── _ldap_fields.html.erb
│       │   ├── _ldap_settings_test.html.erb
│       │   ├── _linkedin_fields.html.erb
│       │   ├── _login_attribute_dropdown.html.erb
│       │   ├── _microsoft_fields.html.erb
│       │   ├── _oauth2_fields.html.erb
│       │   ├── _openid_connect_fields.html.erb
│       │   ├── _saml_fields.html.erb
│       │   ├── _saml_idp_discovery_fields.html.erb
│       │   ├── _sso_settings_form.html.erb
│       │   └── index.html.erb
│       ├── blackout_dates
│       │   └── index.html.erb
│       ├── brand_configs
│       │   └── show.html.erb
│       ├── calendar_events
│       │   ├── _full_calendar_event.html.erb
│       │   ├── new.html.erb
│       │   └── show.html.erb
│       ├── calendars
│       │   ├── _event.html.erb
│       │   ├── _mini_calendar.html.erb
│       │   └── show.html.erb
│       ├── collaborations
│       │   ├── _auth_google_drive.html.erb
│       │   ├── _collaboration.html.erb
│       │   ├── _collaboration_footer.html.erb
│       │   ├── _collaboration_links.html.erb
│       │   ├── _delete_button.html.erb
│       │   ├── _edit_button.html.erb
│       │   ├── _forms.html.erb
│       │   ├── index.html.erb
│       │   └── show.erb
│       ├── communication_channels
│       │   ├── confirm.html.erb
│       │   └── confirm_failed.html.erb
│       ├── conferences
│       │   └── index.html.erb
│       ├── content_exports
│       │   ├── _quiz_export_checklist.html.erb
│       │   └── index.html.erb
│       ├── content_migrations
│       │   └── index.html.erb
│       ├── context
│       │   ├── _deleted_item.html.erb
│       │   ├── _roster_right_side.html.erb
│       │   ├── media_object_inline.html.erb
│       │   ├── new_roster_user.html.erb
│       │   ├── object_snippet.html.erb
│       │   ├── prior_users.html.erb
│       │   ├── roster.html.erb
│       │   ├── roster_user.html.erb
│       │   ├── roster_user_services.html.erb
│       │   ├── roster_user_usage.html.erb
│       │   └── undelete_index.html.erb
│       ├── context_modules
│       │   ├── _asessment_request.html.erb
│       │   ├── _content_next.html.erb
│       │   ├── _context_module_next.html.erb
│       │   ├── _keyboard_navigation.html.erb
│       │   ├── _module_item_conditional_next.html.erb
│       │   ├── _module_item_next.html.erb
│       │   ├── _prerequisites_message.html.erb
│       │   ├── _tool_sequence_footer.html.erb
│       │   ├── index.html.erb
│       │   ├── items_html.html.erb
│       │   ├── lock_explanation.html.erb
│       │   ├── module_html.html.erb
│       │   ├── progressions.html.erb
│       │   └── url_show.html.erb
│       ├── conversations
│       │   └── index_new.html.erb
│       ├── course_paces
│       │   └── index.html.erb
│       ├── courses
│       │   ├── _course_show_secondary.html.erb
│       │   ├── _group_list.html.erb
│       │   ├── _recent_event.html.erb
│       │   ├── _recent_feedback.html.erb
│       │   ├── _settings_sidebar.html.erb
│       │   ├── _sidebar_periods_weighting.html.erb
│       │   ├── _sidebar_weighting.html.erb
│       │   ├── _to_do_list.html.erb
│       │   ├── confirm_action.html.erb
│       │   ├── copy.html.erb
│       │   ├── description.html.erb
│       │   ├── index.html.erb
│       │   ├── link_validator.html.erb
│       │   ├── settings.html.erb
│       │   ├── show.html.erb
│       │   └── statistics.html.erb
│       ├── developer_keys
│       │   └── index.html.erb
│       ├── discussion_topics
│       │   ├── _assignment_details.html.erb
│       │   ├── _assignment_todo.html.erb
│       │   ├── _entry.html.erb
│       │   ├── _group_discussion.html.erb
│       │   ├── _new_and_total_badge.html.erb
│       │   ├── _peer_reviews.html.erb
│       │   ├── _sub_entry.html.erb
│       │   ├── edit.html.erb
│       │   └── show.html.erb
│       ├── eportfolios
│       │   ├── _eportfolio.html.erb
│       │   ├── _page_comment.html.erb
│       │   ├── _page_section.html.erb
│       │   ├── _page_section_static.html.erb
│       │   ├── _page_settings.html.erb
│       │   ├── _section_settings.html.erb
│       │   ├── _static_page.html.erb
│       │   ├── _wizard_box.html.erb
│       │   ├── show.html.erb
│       │   └── user_index.html.erb
│       ├── epub_exports
│       │   └── index.html.erb
│       ├── errors
│       │   └── index.html.erb
│       ├── external_content
│       │   ├── cancel.html.erb
│       │   ├── selection_test.html.erb
│       │   └── success.html.erb
│       ├── external_tools
│       │   ├── _external_tools.html.erb
│       │   ├── _global_nav_menu_items.html.erb
│       │   ├── finished.html.erb
│       │   └── helpers
│       │       └── _icon.html.erb
│       ├── file_previews
│       │   ├── img_preview.html.erb
│       │   ├── lock_explanation.html.erb
│       │   ├── media_preview.html.erb
│       │   └── no_preview.html.erb
│       ├── files
│       │   ├── _nested_content.html.erb
│       │   └── show.html.erb
│       ├── gradebook_uploads
│       │   ├── new.html.erb
│       │   └── show.html.erb
│       ├── gradebooks
│       │   ├── _grading_box.html.erb
│       │   ├── _grading_box_extended.html.erb
│       │   ├── blank_submission.html.erb
│       │   ├── grade_summary.html.erb
│       │   ├── grade_summary_list.html.erb
│       │   ├── gradebook.html.erb
│       │   ├── learning_mastery.html.erb
│       │   ├── show_submissions_upload.html.erb
│       │   ├── speed_grader.html.erb
│       │   └── submissions_zip_upload.html.erb
│       ├── grading_standards
│       │   ├── account_index.html.erb
│       │   └── course_index.html.erb
│       ├── graphql
│       │   └── graphiql.html.erb
│       ├── groups
│       │   ├── _user_pagination.erb
│       │   ├── context_groups.html.erb
│       │   ├── context_manage_groups.html.erb
│       │   ├── index.html.erb
│       │   ├── membership_pending.html.erb
│       │   └── show.html.erb
│       ├── info
│       │   └── browserconfig.xml.builder
│       ├── jobs
│       │   └── index.html.erb
│       ├── jst
│       │   └── profiles
│       │       └── notifications
│       │           ├── privacyNotice.handlebars
│       │           └── privacyNotice.handlebars.json
│       ├── layouts
│       │   ├── _fixed_bottom.html.erb
│       │   ├── _foot.html.erb
│       │   ├── _head.html.erb
│       │   ├── application.html.erb
│       │   ├── bare.html.erb
│       │   ├── borderless_lti.html.erb
│       │   ├── mobile_auth.html.erb
│       │   ├── mobile_embed.html.erb
│       │   └── styleguide.html.erb
│       ├── login
│       │   ├── canvas
│       │   │   ├── _forgot_password_link.html.erb
│       │   │   ├── _instructure_logo.svg
│       │   │   ├── _login_banner.html.erb
│       │   │   ├── _new_login_content.html.erb
│       │   │   ├── _sso_buttons.html.erb
│       │   │   ├── mobile_login.html.erb
│       │   │   ├── new.html.erb
│       │   │   └── new_login.html.erb
│       │   ├── email_verify
│       │   │   └── show.html.erb
│       │   ├── logout_confirm.html.erb
│       │   ├── logout_landing.html.erb
│       │   ├── new.html.erb
│       │   ├── otp
│       │   │   └── new.html.erb
│       │   └── shared
│       │       └── _header_logo.html.erb
│       ├── lti
│       │   ├── _conditional_submission_sidebar.html.erb
│       │   ├── _launch_iframe.html.erb
│       │   ├── _lti_message.html.erb
│       │   ├── _lti_message_quizzes_next.erb
│       │   ├── framed_launch.html.erb
│       │   ├── full_width_in_context.html.erb
│       │   ├── full_width_launch.html.erb
│       │   ├── full_width_with_nav.html.erb
│       │   ├── ims
│       │   │   ├── authentication
│       │   │   │   ├── authorize.html.erb
│       │   │   │   ├── login_required_error_screen.html.erb
│       │   │   │   └── missing_cookie_fix.html.erb
│       │   │   ├── deep_linking
│       │   │   │   └── deep_linking_response.html.erb
│       │   │   └── dynamic_registration
│       │   │       └── dr_iframe.html.erb
│       │   ├── in_rce_launch.html.erb
│       │   ├── message
│       │   │   └── registration_return.html.erb
│       │   ├── platform_storage
│       │   │   ├── _forwarding_frame.html.erb
│       │   │   └── post_message_forwarding.html.erb
│       │   ├── registrations
│       │   │   └── index.erb
│       │   ├── tool_default_icon
│       │   │   └── show.html.erb
│       │   └── unframed_launch.html.erb
│       ├── messages
│       │   ├── _message.html.erb
│       │   ├── html_message.html.erb
│       │   ├── index.html.erb
│       │   └── show.html.erb
│       ├── oauth2_provider
│       │   ├── _confirm_form.html.erb
│       │   ├── auth.html.erb
│       │   ├── confirm.html.erb
│       │   └── confirm_mobile.html.erb
│       ├── one_time_passwords
│       │   └── index.html.erb
│       ├── outcomes
│       │   ├── _outcome_alignment.html.erb
│       │   ├── _outcome_result.html.erb
│       │   ├── index.html.erb
│       │   ├── show.html.erb
│       │   └── user_outcome_results.html.erb
│       ├── plugins
│       │   ├── _account_report_settings.html.erb
│       │   ├── _app_center_settings.html.erb
│       │   ├── _apple_settings.html.erb
│       │   ├── _assignment_freezer_settings.html.erb
│       │   ├── _big_blue_button_fallback_settings.html.erb
│       │   ├── _big_blue_button_settings.html.erb
│       │   ├── _byots_docs.html.erb
│       │   ├── _canvadocs_settings.html.erb
│       │   ├── _clever_settings.html.erb
│       │   ├── _crocodoc_settings.html.erb
│       │   ├── _custom_ticketing_email_settings.html.erb
│       │   ├── _custom_ticketing_web_post_settings.html.erb
│       │   ├── _diigo_settings.html.erb
│       │   ├── _dim_dim_settings.html.erb
│       │   ├── _embedded_chat_settings.html.erb
│       │   ├── _etherpad_settings.html.erb
│       │   ├── _facebook_settings.html.erb
│       │   ├── _github_settings.html.erb
│       │   ├── _google_drive_settings.html.erb
│       │   ├── _grade_export_settings.html.erb
│       │   ├── _i18n_settings.html.erb
│       │   ├── _inst_fs_settings.html.erb
│       │   ├── _kaltura_settings.html.erb
│       │   ├── _learn_platform_settings.html.erb
│       │   ├── _linked_in_settings.html.erb
│       │   ├── _mathman_settings.html.erb
│       │   ├── _microsoft_settings.html.erb
│       │   ├── _panda_pub_settings.html.erb
│       │   ├── _sessions_timeout.html.erb
│       │   ├── _settings_header.html.erb
│       │   ├── _sis_import_settings.html.erb
│       │   ├── _ticketing_system_settings.html.erb
│       │   ├── _vericite_settings.html.erb
│       │   ├── _wimba_settings.html.erb
│       │   ├── index.html.erb
│       │   └── show.html.erb
│       ├── profile
│       │   ├── _access_token.html.erb
│       │   ├── _email_select.html.erb
│       │   ├── _sms_select.html.erb
│       │   ├── _ways_to_contact.html.erb
│       │   ├── content_shares.erb
│       │   ├── profile.html.erb
│       │   ├── show.html.erb
│       │   └── unauthorized.html.erb
│       ├── pseudonyms
│       │   └── confirm_change_password.html.erb
│       ├── question_banks
│       │   ├── _question_bank.html.erb
│       │   ├── _question_teaser.html.erb
│       │   ├── index.html.erb
│       │   └── show.html.erb
│       ├── quizzes
│       │   ├── quiz_submission_events
│       │   │   └── index.html.erb
│       │   ├── quiz_submissions
│       │   │   ├── close_quiz_popup_window.html.erb
│       │   │   └── show.html.erb
│       │   └── quizzes
│       │       ├── _cant_go_back_warning.html.erb
│       │       ├── _direct_share_buttons.html.erb
│       │       ├── _display_answer.html.erb
│       │       ├── _display_question.html.erb
│       │       ├── _download_file_upload_submissions.html.erb
│       │       ├── _equations_help.html.erb
│       │       ├── _find_question_from_bank.html.erb
│       │       ├── _form_answer.html.erb
│       │       ├── _form_question.html.erb
│       │       ├── _move_handle.html.erb
│       │       ├── _move_question.html.erb
│       │       ├── _multi_answer.html.erb
│       │       ├── _muted.html.erb
│       │       ├── _question_group.html.erb
│       │       ├── _question_list_right_side.html.erb
│       │       ├── _question_teaser.html.erb
│       │       ├── _quiz_details.html.erb
│       │       ├── _quiz_edit.erb
│       │       ├── _quiz_edit_conditional_release.erb
│       │       ├── _quiz_edit_details.erb
│       │       ├── _quiz_edit_form_actions.erb
│       │       ├── _quiz_edit_header.erb
│       │       ├── _quiz_edit_questions.erb
│       │       ├── _quiz_right_side.html.erb
│       │       ├── _quiz_show_student.html.erb
│       │       ├── _quiz_show_teacher.html.erb
│       │       ├── _quiz_submission.html.erb
│       │       ├── _quiz_submission_results.html.erb
│       │       ├── _single_answer.html.erb
│       │       ├── _submission_version.html.erb
│       │       ├── _submission_version_score.html.erb
│       │       ├── _take_quiz_right_side.html.erb
│       │       ├── access_code.html.erb
│       │       ├── history.html.erb
│       │       ├── index.html.erb
│       │       ├── invalid_ip.html.erb
│       │       ├── lockdown_browser_required.html.erb
│       │       ├── managed_quiz_data.html.erb
│       │       ├── moderate.html.erb
│       │       ├── new.html.erb
│       │       ├── read_only.html.erb
│       │       ├── refresh_quiz_after_popup.html.erb
│       │       ├── show.html.erb
│       │       ├── statistics_cqs.html.erb
│       │       ├── submission_html.html.erb
│       │       ├── submission_versions.html.erb
│       │       ├── take_quiz.html.erb
│       │       └── take_quiz_in_popup.html.erb
│       ├── role_overrides
│       │   └── index.html.erb
│       ├── rubrics
│       │   ├── index.html.erb
│       │   ├── show.html.erb
│       │   └── user_index.html.erb
│       ├── search
│       │   ├── _all_courses_inner.html.erb
│       │   └── all_courses.html.erb
│       ├── sections
│       │   └── show.html.erb
│       ├── self_enrollments
│       │   ├── _already_enrolled.html.erb
│       │   ├── _authenticate.html.erb
│       │   ├── _authenticate_or_register.html.erb
│       │   ├── _confirm_enrollments.html.erb
│       │   ├── _course_full.html.erb
│       │   ├── _enrollment_closed.html.erb
│       │   ├── _successfully_enrolled.html.erb
│       │   └── new.html.erb
│       ├── shared
│       │   ├── _account_notification.html.erb
│       │   ├── _account_options.html.erb
│       │   ├── _accounts_right_side_shared.html.erb
│       │   ├── _additional_footer_scripts.erb
│       │   ├── _assignment_rubric_dialog.html.erb
│       │   ├── _auth_type_icon.html.erb
│       │   ├── _available_dates.html.erb
│       │   ├── _blank.html.erb
│       │   ├── _canvas-primary-nav.erb
│       │   ├── _canvas-user-nav.erb
│       │   ├── _canvas_footer.erb
│       │   ├── _content_notices.html.erb
│       │   ├── _current_enrollment.html.erb
│       │   ├── _dashboard_card.html.erb
│       │   ├── _dashboard_invitation.html.erb
│       │   ├── _dashboard_messages.html.erb
│       │   ├── _datadog_rum_js.html.erb
│       │   ├── _discussion_entry.html.erb
│       │   ├── _embedded_chat.html.erb
│       │   ├── _enrollment_term_select.html.erb
│       │   ├── _event_list.html.erb
│       │   ├── _find_outcome.html.erb
│       │   ├── _flash_notices.html.erb
│       │   ├── _footer_epilogue.html.erb
│       │   ├── _footer_links.html.erb
│       │   ├── _global_dialogs.html.erb
│       │   ├── _grading_periods_selector.html.erb
│       │   ├── _grading_standard.html.erb
│       │   ├── _ignore_option_list.erb
│       │   ├── _inline_preview.html.erb
│       │   ├── _invitation.html.erb
│       │   ├── _javascript_init.html.erb
│       │   ├── _locale_warning.html.erb
│       │   ├── _login_fft_helper.html.erb
│       │   ├── _maintenance_window.html.erb
│       │   ├── _mark_as_done.html.erb
│       │   ├── _message_students.html.erb
│       │   ├── _new_course_form.html.erb
│       │   ├── _new_nav_header.html.erb
│       │   ├── _no_recent_activity.html.erb
│       │   ├── _originality_score_icon.html.erb
│       │   ├── _outcome_alignments.html.erb
│       │   ├── _override_list.html.erb
│       │   ├── _pending_enrollment.html.erb
│       │   ├── _profile_form.html.erb
│       │   ├── _profile_main.html.erb
│       │   ├── _recent_activity.html.erb
│       │   ├── _recent_activity_item.html.erb
│       │   ├── _report_error.html.erb
│       │   ├── _right_side.html.erb
│       │   ├── _rubric.html.erb
│       │   ├── _rubric_criterion.html.erb
│       │   ├── _rubric_criterion_dialog.html.erb
│       │   ├── _rubric_dialog.html.erb
│       │   ├── _rubric_summary.html.erb
│       │   ├── _rubric_summary_criterion.html.erb
│       │   ├── _rubrics_component.html.erb
│       │   ├── _select_content_dialog.html.erb
│       │   ├── _sequence_footer.html.erb
│       │   ├── _static_notices.html.erb
│       │   ├── _sub_account_options.html.erb
│       │   ├── _user_lists.html.erb
│       │   ├── _vdd_tooltip.html.erb
│       │   ├── _wiki_image.html.erb
│       │   ├── errors
│       │   │   ├── 400_message.html.erb
│       │   │   ├── 403_message.html.erb
│       │   │   ├── 404_message.html.erb
│       │   │   ├── 500_message.html.erb
│       │   │   ├── AUT_message.html.erb
│       │   │   ├── _error_form.html.erb
│       │   │   ├── error_with_details.html.erb
│       │   │   └── file_not_found.html.erb
│       │   ├── registration_incomplete.html.erb
│       │   ├── svg
│       │   │   ├── _svg_canvas_logo.svg
│       │   │   ├── _svg_canvas_logomark_only.svg
│       │   │   ├── _svg_default_lti_new_styles.svg
│       │   │   ├── _svg_icon_accounts_new_styles.svg
│       │   │   ├── _svg_icon_apple.svg
│       │   │   ├── _svg_icon_apps.svg
│       │   │   ├── _svg_icon_arrow_right.svg
│       │   │   ├── _svg_icon_calendar.svg
│       │   │   ├── _svg_icon_calendar_new_styles.svg
│       │   │   ├── _svg_icon_canvas.svg
│       │   │   ├── _svg_icon_clever.svg
│       │   │   ├── _svg_icon_cog.svg
│       │   │   ├── _svg_icon_courses.svg
│       │   │   ├── _svg_icon_courses_new_styles.svg
│       │   │   ├── _svg_icon_dashboard.svg
│       │   │   ├── _svg_icon_facebook.svg
│       │   │   ├── _svg_icon_folder.svg
│       │   │   ├── _svg_icon_github.svg
│       │   │   ├── _svg_icon_google.svg
│       │   │   ├── _svg_icon_grades.svg
│       │   │   ├── _svg_icon_grades_new_styles.svg
│       │   │   ├── _svg_icon_groups_new_styles.svg
│       │   │   ├── _svg_icon_help.svg
│       │   │   ├── _svg_icon_history.svg
│       │   │   ├── _svg_icon_home.svg
│       │   │   ├── _svg_icon_inbox.svg
│       │   │   ├── _svg_icon_information.svg
│       │   │   ├── _svg_icon_lifepreserver.svg
│       │   │   ├── _svg_icon_linkedin.svg
│       │   │   ├── _svg_icon_magnify.svg
│       │   │   ├── _svg_icon_mail.svg
│       │   │   ├── _svg_icon_microsoft.svg
│       │   │   ├── _svg_icon_navtoggle.svg
│       │   │   ├── _svg_icon_passport.svg
│       │   │   ├── _svg_login_new_styles.svg
│       │   │   └── k12
│       │   │       ├── _svg_icon_calendar_new_styles.svg
│       │   │       ├── _svg_icon_courses.svg
│       │   │       ├── _svg_icon_courses_new_styles.svg
│       │   │       ├── _svg_icon_dashboard.svg
│       │   │       ├── _svg_icon_grades_new_styles.svg
│       │   │       └── _svg_icon_inbox.svg
│       │   ├── terms_required.html.erb
│       │   ├── unauthorized.html.erb
│       │   └── unauthorized_feed.html.erb
│       ├── smart_search
│       │   └── show.html.erb
│       ├── sub_accounts
│       │   └── index.html.erb
│       ├── submission_comments
│       │   ├── fonts
│       │   │   ├── DejaVuSans.ttf
│       │   │   ├── NotoEmoji-Regular.ttf
│       │   │   └── noto_sans
│       │   │       ├── NotoSansArabic-Regular.ttf
│       │   │       ├── NotoSansArmenian-Regular.ttf
│       │   │       ├── NotoSansHebrew-Regular.ttf
│       │   │       ├── NotoSansJP-Regular.ttf
│       │   │       ├── NotoSansKR-Regular.ttf
│       │   │       ├── NotoSansSC-Regular.ttf
│       │   │       ├── NotoSansTC-Regular.ttf
│       │   │       └── NotoSansThai-Regular.ttf
│       │   └── index.pdf.prawn
│       ├── submissions
│       │   ├── _grade_values_can_grade.html.erb
│       │   ├── _grade_values_can_read.html.erb
│       │   ├── _originality_score.html.erb
│       │   ├── _submission_download.html.erb
│       │   ├── show.html.erb
│       │   └── show_preview.html.erb
│       ├── terms_api
│       │   ├── _term.html.erb
│       │   ├── _timespan.html.erb
│       │   └── index.html.erb
│       ├── users
│       │   ├── _cc_prefs.html.erb
│       │   ├── _current_conference.html.erb
│       │   ├── _enrollment.html.erb
│       │   ├── _group.html.erb
│       │   ├── _last_login.html.erb
│       │   ├── _logins.html.erb
│       │   ├── _name.html.erb
│       │   ├── _scheduled_conference.html.erb
│       │   ├── _welcome.html.erb
│       │   ├── admin_split.html.erb
│       │   ├── dashboard_sidebar.html.erb
│       │   ├── grades.html.erb
│       │   ├── new.html.erb
│       │   ├── show.html.erb
│       │   ├── teacher_activity.html.erb
│       │   └── user_dashboard.html.erb
│       └── wiki_pages
│           ├── edit.html.erb
│           ├── index.html.erb
│           ├── revisions.html.erb
│           └── show.html.erb
├── bin
│   ├── brakeman
│   ├── contracts-generate
│   ├── contracts-publish-api
│   ├── contracts-tag-prod
│   ├── contracts-verify-api
│   ├── contracts-verify-live-events
│   ├── dress_code
│   ├── flakey_spec_catcher
│   ├── lint
│   ├── rails
│   ├── rake
│   ├── rdbg
│   ├── rdbg-spring
│   ├── rspec
│   ├── rubocop
│   ├── spring
│   └── wip_open_source_lint.sh
├── biome.json
├── build
│   ├── Dockerfile.puma.template
│   ├── Dockerfile.template
│   ├── README.md
│   ├── docker-compose
│   │   ├── data_loader
│   │   │   ├── Dockerfile
│   │   │   ├── fetch-volumes
│   │   │   ├── push-volumes
│   │   │   └── wait-for-it
│   │   └── dynamodb
│   │       └── Dockerfile
│   ├── docker_utils.rb
│   ├── dockerfile_writer.rb
│   ├── gergich
│   │   ├── biome.rb
│   │   └── xsslint.rb
│   ├── new-jenkins
│   │   ├── consumer-smoke-test.sh
│   │   ├── crystalball_map_smoke_test.rb
│   │   ├── crystalball_merge_coverage.rb
│   │   ├── dive.sh
│   │   ├── docker-build-helpers.sh
│   │   ├── docker-build.sh
│   │   ├── docker-compose-build-up.sh
│   │   ├── docker-compose-pull.sh
│   │   ├── docker-compose-setup-databases.sh
│   │   ├── docker-with-flakey-network-protection.sh
│   │   ├── iterscores.lua
│   │   ├── js
│   │   │   ├── cleanup-coverage.js
│   │   │   ├── coverage-report.sh
│   │   │   └── docker-build.sh
│   │   ├── js-changes.sh
│   │   ├── library
│   │   │   ├── README.md
│   │   │   ├── build.gradle.kts
│   │   │   ├── resources
│   │   │   │   └── js
│   │   │   │       └── docker-provision.sh
│   │   │   ├── test
│   │   │   │   └── integration
│   │   │   │       └── groovy
│   │   │   │           └── BaseTest.groovy
│   │   │   └── vars
│   │   │       ├── buildDockerImageStage.groovy
│   │   │       ├── buildSummaryReportHooks.groovy
│   │   │       ├── commitMessageFlagDefaults.groovy
│   │   │       ├── contractTestsStage.groovy
│   │   │       ├── dependencyCheckStage.groovy
│   │   │       ├── distribution.groovy
│   │   │       ├── filesChangedStage.groovy
│   │   │       ├── jsStage.groovy
│   │   │       ├── lintersStage.groovy
│   │   │       ├── nodeLabel.groovy
│   │   │       ├── rebaseStage.groovy
│   │   │       ├── rspecStage.groovy
│   │   │       ├── runMigrationsStage.groovy
│   │   │       ├── setupStage.groovy
│   │   │       ├── slackHelpers.groovy
│   │   │       ├── vendoredGemsStage.groovy
│   │   │       └── webpackStage.groovy
│   │   ├── linters
│   │   │   ├── docker-build.sh
│   │   │   ├── run-and-collect-output.sh
│   │   │   ├── run-eslint.sh
│   │   │   ├── run-gergich-biome.sh
│   │   │   ├── run-gergich-bundle.sh
│   │   │   ├── run-gergich-linters.sh
│   │   │   ├── run-gergich-publish.sh
│   │   │   ├── run-gergich-yarn.sh
│   │   │   ├── run-gergich.sh
│   │   │   ├── run-master-bouncer.sh
│   │   │   ├── run-misc-js-checks.sh
│   │   │   ├── run-snyk.sh
│   │   │   └── run-ts-type-check.sh
│   │   ├── locales-changes.sh
│   │   ├── migrate-md5sum.sh
│   │   ├── package-translations
│   │   │   ├── README.md
│   │   │   ├── merge-strings.sh
│   │   │   ├── sync-config-crowd.json
│   │   │   ├── sync-config.json
│   │   │   ├── sync-strings.sh
│   │   │   └── sync-translations.sh
│   │   ├── pact
│   │   │   └── contracts-generate-api.sh
│   │   ├── record-webpack-sizes.sh
│   │   ├── rspec-combine-coverage-results.py
│   │   ├── rspec-coverage-report.sh
│   │   ├── rspec-flakey-spec-catcher-parallel.sh
│   │   ├── rspec-flakey-spec-catcher.sh
│   │   ├── rspec-with-retries.sh
│   │   ├── rspecq-tests.sh
│   │   ├── run-migrations.sh
│   │   ├── skipped_specs_manager.rb
│   │   ├── spec-changes.sh
│   │   ├── test-gems.sh
│   │   ├── wait-for-file.sh
│   │   ├── wait-for-it
│   │   └── xbrowser-test.sh
│   └── vendor
│       └── woff-code-latest.zip
├── code_of_conduct.md
├── config
│   ├── amazon_s3.yml.example
│   ├── application.rb
│   ├── boot.rb
│   ├── bounce_notifications.yml.example
│   ├── brakeman.ignore
│   ├── brakeman.yml
│   ├── brandable_css.yml
│   ├── browsers.yml
│   ├── cache_store.yml.example
│   ├── canvas_cdn.yml.example
│   ├── canvas_rails_switcher.rb
│   ├── code_ownership.yml
│   ├── consul.yml.example
│   ├── copyright-template.js
│   ├── credentials.test.yml
│   ├── crystalball.yml
│   ├── cutycapt.yml.example
│   ├── database.yml.example
│   ├── delayed_jobs.yml.example
│   ├── docker-compose.override.yml.example
│   ├── domain.yml.example
│   ├── dynamic_settings.yml.example
│   ├── dynamodb.yml.example
│   ├── environment.rb
│   ├── environments
│   │   ├── development.rb
│   │   ├── production.rb
│   │   └── test.rb
│   ├── external_migration.yml.example
│   ├── feature_flags
│   │   ├── 00_standard.yml
│   │   ├── 01_quiz_submission_logs.yml
│   │   ├── 02_anonymous_moderated_marking.yml
│   │   ├── 03_moderated_grading.yml
│   │   ├── 04_mutation_audit_log.yml
│   │   ├── 05_immersive_reader.yml
│   │   ├── 06_k6_canvas_theme.yml
│   │   ├── accessibility_report_tab.yml
│   │   ├── analytics_feature_flags.yml
│   │   ├── apogee_release_flags.yml
│   │   ├── app_fundamentals_release_flags.yml
│   │   ├── appex_release_flags.yml
│   │   ├── clx_feature_flags.yml
│   │   ├── commons_feature_flags.yml
│   │   ├── content_share_flags.yml
│   │   ├── course_pace_feature_flags.yml
│   │   ├── covid.yml
│   │   ├── custom_reports.yml
│   │   ├── discussion_summary.yml
│   │   ├── engage_release_flags.yml
│   │   ├── interop_release_flags.yml
│   │   ├── learning_foundations_release_flags.yml
│   │   ├── mastery_paths_flags.yml
│   │   ├── mobile_feature_flags.yml
│   │   ├── outcomes_feature_flags.yml
│   │   ├── proserve_release_flags.yml
│   │   ├── quizzes_release_flags.yml
│   │   ├── rich_content_experience_release_flags.yml
│   │   ├── smart_search.yml
│   │   ├── tiger_team_release_flags.yml
│   │   ├── translation.yml
│   │   ├── verifiers.yml
│   │   └── vice_release_flags.yml
│   ├── file_store.yml.example
│   ├── incoming_mail.yml.example
│   ├── initializers
│   │   ├── action_pack.rb
│   │   ├── action_view.rb
│   │   ├── active_model_errors.rb
│   │   ├── active_record.rb
│   │   ├── active_record_query_trace.rb
│   │   ├── active_support.rb
│   │   ├── adheres_to_policy.rb
│   │   ├── api_scope_mapper_initializer.rb
│   │   ├── authlogic_mods.rb
│   │   ├── backtrace_silencers.rb
│   │   ├── bookmarked_collection.rb
│   │   ├── broadcast_policy.rb
│   │   ├── cache_store.rb
│   │   ├── canvas_ai.rb
│   │   ├── canvas_cache.rb
│   │   ├── canvas_crummy.rb
│   │   ├── canvas_http.rb
│   │   ├── canvas_kaltura.rb
│   │   ├── canvas_panda_pub.rb
│   │   ├── canvas_partman.rb
│   │   ├── canvas_sanitize.rb
│   │   ├── canvas_security.rb
│   │   ├── class_name.rb
│   │   ├── config_file.rb
│   │   ├── consul.rb
│   │   ├── datadog_apm.rb
│   │   ├── decimal_megabyte.rb
│   │   ├── delayed_job.rb
│   │   ├── diigo.rb
│   │   ├── dropped_columns.rb
│   │   ├── dynamodb_date_support.rb
│   │   ├── empty.rb
│   │   ├── errors.rb
│   │   ├── event_stream.rb
│   │   ├── external_migrations.rb
│   │   ├── folio.rb
│   │   ├── google_drive.rb
│   │   ├── guard_rail.rb
│   │   ├── i18n.rb
│   │   ├── incoming_mail.rb
│   │   ├── inflections.rb
│   │   ├── inst_access.rb
│   │   ├── inst_access_support.rb
│   │   ├── inst_statsd.rb
│   │   ├── irb.rb
│   │   ├── job_live_events_context.rb
│   │   ├── json.rb
│   │   ├── jwt_workflow.rb
│   │   ├── live_events.rb
│   │   ├── local_cache.rb
│   │   ├── marginalia.rb
│   │   ├── mime_types.rb
│   │   ├── no_timeouts_debugging.rb
│   │   ├── oauth.rb
│   │   ├── observers.rb
│   │   ├── openstruct.rb
│   │   ├── outgoing_mail.rb
│   │   ├── outrigger.rb
│   │   ├── periodic_jobs.rb
│   │   ├── permissions_registry.rb
│   │   ├── postgresql_adapter.rb
│   │   ├── prosopite.rb
│   │   ├── rack.rb
│   │   ├── rails_patches.rb
│   │   ├── reports.rb
│   │   ├── revved_asset_urls.rb
│   │   ├── ruby_version_compat.rb
│   │   ├── rubyzip.rb
│   │   ├── saml.rb
│   │   ├── sentry.rb
│   │   ├── session_store.rb
│   │   ├── simply_versioned.rb
│   │   ├── statsd_timing.rb
│   │   ├── strong_parameters.rb
│   │   ├── stubs.rb
│   │   ├── switchman.rb
│   │   ├── template_streaming.rb
│   │   ├── time.rb
│   │   ├── zeitwerk.rb
│   │   └── ~safe_yaml.rb
│   ├── llm_configs
│   │   ├── discussion_topic_insights.yml
│   │   ├── discussion_topic_summary_raw.yml
│   │   ├── discussion_topic_summary_refined.yml
│   │   ├── rich_content_generate.yml
│   │   ├── rich_content_modify.yml
│   │   └── rubric_create.yml
│   ├── local_cache.yml.example
│   ├── locales
│   │   ├── ar.rb
│   │   ├── ar.yml
│   │   ├── ca.rb
│   │   ├── ca.yml
│   │   ├── community.csv
│   │   ├── cy.rb
│   │   ├── cy.yml
│   │   ├── da-x-k12.yml
│   │   ├── da.rb
│   │   ├── da.yml
│   │   ├── de.rb
│   │   ├── de.yml
│   │   ├── el.rb
│   │   ├── el.yml
│   │   ├── en-AU.yml
│   │   ├── en-CA.yml
│   │   ├── en-GB.yml
│   │   ├── en.yml
│   │   ├── es-ES.rb
│   │   ├── es-ES.yml
│   │   ├── es.rb
│   │   ├── es.yml
│   │   ├── fa.rb
│   │   ├── fa.yml
│   │   ├── fi.rb
│   │   ├── fi.yml
│   │   ├── fr-CA.yml
│   │   ├── fr.rb
│   │   ├── fr.yml
│   │   ├── ga.rb
│   │   ├── ga.yml
│   │   ├── he.rb
│   │   ├── he.yml
│   │   ├── hi.rb
│   │   ├── hi.yml
│   │   ├── ht.rb
│   │   ├── ht.yml
│   │   ├── hu.rb
│   │   ├── hu.yml
│   │   ├── hy.rb
│   │   ├── hy.yml
│   │   ├── id.rb
│   │   ├── id.yml
│   │   ├── is.rb
│   │   ├── is.yml
│   │   ├── it.rb
│   │   ├── it.yml
│   │   ├── ja.rb
│   │   ├── ja.yml
│   │   ├── ko.rb
│   │   ├── ko.yml
│   │   ├── locales.yml
│   │   ├── mi.rb
│   │   ├── mi.yml
│   │   ├── ms.rb
│   │   ├── ms.yml
│   │   ├── nb-x-k12.yml
│   │   ├── nb.rb
│   │   ├── nb.yml
│   │   ├── nl.rb
│   │   ├── nl.yml
│   │   ├── nn.rb
│   │   ├── nn.yml
│   │   ├── pl.rb
│   │   ├── pl.yml
│   │   ├── pt-BR.yml
│   │   ├── pt.rb
│   │   ├── pt.yml
│   │   ├── ru.rb
│   │   ├── ru.yml
│   │   ├── sl.rb
│   │   ├── sl.yml
│   │   ├── sv-x-k12.yml
│   │   ├── sv.rb
│   │   ├── sv.yml
│   │   ├── th.rb
│   │   ├── th.yml
│   │   ├── tr.rb
│   │   ├── tr.yml
│   │   ├── uk.rb
│   │   ├── uk.yml
│   │   ├── vi.rb
│   │   ├── vi.yml
│   │   ├── zh-Hans.rb
│   │   ├── zh-Hans.yml
│   │   ├── zh-Hant.rb
│   │   └── zh-Hant.yml
│   ├── logging.yml.example
│   ├── marginalia.yml.example
│   ├── memcache.yml.example
│   ├── notification_failures.yml.example
│   ├── notification_service.yml.example
│   ├── offline_web.yml.sample
│   ├── outgoing_mail.yml.example
│   ├── periodic_jobs.yml.example
│   ├── puma.rb
│   ├── redis.yml.example
│   ├── routes.rb
│   ├── saml
│   │   ├── inc-md-cert.pem
│   │   └── ukfederation.pem
│   ├── saml.yml.example
│   ├── security.yml.example
│   ├── selenium.yml.example
│   ├── sentry.yml.example
│   ├── session_store.yml.example
│   ├── spring.rb
│   ├── statsd.yml.example
│   ├── styleguide.yml
│   ├── teams
│   │   ├── README.md
│   │   ├── evaluate.yml
│   │   ├── learning-experience.yml
│   │   ├── quizzes.yml
│   │   ├── rich-content-experience.yml
│   │   └── vice.yml
│   ├── testrail.yml.example
│   ├── twilio.yml.example
│   ├── vault.yml.example
│   └── vault_contents.yml.example
├── config.ru
├── db
│   └── migrate
│       ├── 20101201000090_validate_migration_integrity.rb
│       ├── 20101210192618_init_canvas_db.rb
│       ├── 20101216224513_create_delayed_jobs.rb
│       ├── 20101217224513_set_replica_identities.rb
│       ├── 20111111214312_load_initial_data.rb
│       ├── 20141109202906_create_initial_partitions.rb
│       ├── 20230901164455_add_embeddings.rb
│       ├── 20230901164555_set_replica_identity_on_embeddings.rb
│       ├── 20250108205503_create_course_reports.rb
│       ├── 20250109155943_drop_page_views_count_from_user.rb
│       ├── 20250114133002_unset_discussion_no_message.rb
│       ├── 20250115173552_fixup_twitter_auth_providers_and_pseudos.rb
│       ├── 20250122185939_drop_asv_qsv_views.rb
│       ├── 20250123211448_delete_orphaned_feature_flags.rb
│       ├── 20250124180839_add_replica_identity_to_course_report.rb
│       ├── 20250128145900_delete_obsolete_manage_content_role_overrides.rb
│       ├── 20250128192754_guard_against_untransformed_tool_configurations.rb
│       ├── 20250128195812_add_view_archived_courses_permission.rb
│       ├── 20250128202614_drop_lti_tool_configurations_settings.rb
│       ├── 20250130162550_rename_asset_reports_check_constraint.rb
│       ├── 20250131093250_create_estimated_duration.rb
│       ├── 20250131095050_set_replica_identity_index_on_estimated_duration.rb
│       ├── 20250203150232_add_weighted_and_time_to_complete_fields.rb
│       ├── 20250205183014_delete_obsolete_manage_assignments_role_override.rb
│       ├── 20250212091507_add_lti_id_to_submission.rb
│       ├── 20250212091508_drop_lti_assets_foreign_keys.rb
│       ├── 20250212091509_update_lti_assets_uq_index.rb
│       ├── 20250220142936_add_user_to_attachment_associations.rb
│       ├── 20250226075610_add_summary_enabled_to_discussion_topic_participants.rb
│       ├── 20250226232155_add_lti_registration_id_to_context_external_tools.rb
│       ├── 20250303234845_backfill_context_external_tool_lti_registration_ids.rb
│       ├── 20250304111509_add_sha256_checksum_to_lti_assets.rb
│       ├── 20250305152021_change_course_report_job_id_and_user_id_to_bigint.rb
│       ├── 20250305175940_add_caused_by_reset_to_lti_overlay_versions.rb
│       ├── 20250311154006_create_discussion_topic_insights.rb
│       ├── 20250311154327_add_replica_identity_index_to_discussion_topic_insights.rb
│       ├── 20250314081723_change_default_sort_order_in_discussion_topic_participants.rb
│       ├── 20250317094616_create_discussion_topic_insight_entries.rb
│       ├── 20250317094633_add_replica_identity_index_to_discussion_topic_insight_entries.rb
│       ├── 20250317124309_add_asset_processor_eula_required_to_context_external_tools.rb
│       ├── 20250318145922_add_workflow_state_to_account_notifications.rb
│       ├── 20250320141356_create_lti_asset_processor_eula_acceptances.rb
│       ├── 20250320144159_add_replica_identity_index_to_lti_asset_processor_eula_acceptances.rb
│       ├── 20250324175109_add_field_name_to_attachment_associations.rb
│       ├── 20250326180233_add_user_uuid_custom_variable_to_internal_tools.rb
│       ├── 20250402190939_add_description_to_lti_registration.rb
│       ├── 20250407183101_add_content_library_to_courses.rb
│       ├── 20250408000001_create_auto_grade_results.rb
│       ├── 20250408000002_set_auto_grade_results_replica_identity.rb
│       ├── 20250409194908_add_data_json_to_custom_data.rb
│       ├── 20250409194910_schedule_custom_data_jsonb_copy.rb
│       ├── 20250414211602_create_lti_context_controls.rb
│       ├── 20250414211624_add_replica_identity_to_lti_context_controls.rb
│       ├── 20250415131656_sync_important_date_with_child_events.rb
│       ├── 20250418145020_add_authorized_flows_to_developer_keys.rb
│       ├── 20250424144501_localize_root_account_ids_on_attachment.rb
│       ├── 20250506193657_change_lti_context_control_indices.rb
│       ├── 20250509134008_remove_context_controls_registration_fk.rb
│       ├── 66137131007895491_regenerate_brand_files_based_on_new_defaults_predeploy.rb
│       ├── 66137131007895492_regenerate_brand_files_based_on_new_defaults_postdeploy.rb
│       └── 99999999999999999999_ensure_test_db_empty.rb
├── doc
│   ├── DEPRECATION.md
│   ├── api
│   │   ├── README.md
│   │   ├── all_resources.md
│   │   ├── api_routes.rb
│   │   ├── appendix
│   │   │   ├── html
│   │   │   ├── markdown
│   │   │   │   └── listing.erb
│   │   │   └── setup.rb
│   │   ├── assignment_selection_placement.md
│   │   ├── assignment_tools.md
│   │   ├── canvas_roles.md
│   │   ├── changelog.md
│   │   ├── collaborations_placement.md
│   │   ├── compound_documents.md
│   │   ├── content_item.md
│   │   ├── data_services
│   │   │   ├── caliper_event_template.md.erb
│   │   │   ├── caliper_structure_template.md.erb
│   │   │   ├── canvas_event_template.md.erb
│   │   │   ├── canvas_metadata_template.md.erb
│   │   │   ├── data_services_caliper_loader.rb
│   │   │   ├── data_services_canvas_loader.rb
│   │   │   ├── data_services_events_loader.rb
│   │   │   ├── data_services_markdown_creator.rb
│   │   │   ├── json
│   │   │   │   ├── caliper
│   │   │   │   │   ├── actor_extensions.json
│   │   │   │   │   ├── event-types
│   │   │   │   │   │   ├── asset_accessed.json
│   │   │   │   │   │   ├── assignment_created.json
│   │   │   │   │   │   ├── assignment_override_created.json
│   │   │   │   │   │   ├── assignment_override_updated.json
│   │   │   │   │   │   ├── assignment_updated.json
│   │   │   │   │   │   ├── attachment_created.json
│   │   │   │   │   │   ├── attachment_deleted.json
│   │   │   │   │   │   ├── attachment_updated.json
│   │   │   │   │   │   ├── course_created.json
│   │   │   │   │   │   ├── course_updated.json
│   │   │   │   │   │   ├── discussion_entry_created.json
│   │   │   │   │   │   ├── discussion_topic_created.json
│   │   │   │   │   │   ├── enrollment_created.json
│   │   │   │   │   │   ├── enrollment_state_created.json
│   │   │   │   │   │   ├── enrollment_state_updated.json
│   │   │   │   │   │   ├── enrollment_updated.json
│   │   │   │   │   │   ├── grade_change.json
│   │   │   │   │   │   ├── group_category_created.json
│   │   │   │   │   │   ├── group_created.json
│   │   │   │   │   │   ├── group_membership_created.json
│   │   │   │   │   │   ├── logged_in.json
│   │   │   │   │   │   ├── logged_out.json
│   │   │   │   │   │   ├── quiz_submitted.json
│   │   │   │   │   │   ├── submission_created.json
│   │   │   │   │   │   ├── submission_updated.json
│   │   │   │   │   │   ├── syllabus_updated.json
│   │   │   │   │   │   ├── user_account_association_created.json
│   │   │   │   │   │   ├── wiki_page_created.json
│   │   │   │   │   │   ├── wiki_page_deleted.json
│   │   │   │   │   │   └── wiki_page_updated.json
│   │   │   │   │   └── extensions.json
│   │   │   │   └── canvas
│   │   │   │       ├── event-types
│   │   │   │       │   ├── account_created.json
│   │   │   │       │   ├── account_notification_created.json
│   │   │   │       │   ├── account_updated.json
│   │   │   │       │   ├── asset_accessed.json
│   │   │   │       │   ├── assignment_created.json
│   │   │   │       │   ├── assignment_group_created.json
│   │   │   │       │   ├── assignment_group_updated.json
│   │   │   │       │   ├── assignment_override_created.json
│   │   │   │       │   ├── assignment_override_updated.json
│   │   │   │       │   ├── assignment_updated.json
│   │   │   │       │   ├── attachment_created.json
│   │   │   │       │   ├── attachment_deleted.json
│   │   │   │       │   ├── attachment_updated.json
│   │   │   │       │   ├── content_migration_completed.json
│   │   │   │       │   ├── conversation_created.json
│   │   │   │       │   ├── conversation_forwarded.json
│   │   │   │       │   ├── conversation_message_created.json
│   │   │   │       │   ├── course_completed.json
│   │   │   │       │   ├── course_created.json
│   │   │   │       │   ├── course_grade_change.json
│   │   │   │       │   ├── course_progress.json
│   │   │   │       │   ├── course_section_created.json
│   │   │   │       │   ├── course_section_updated.json
│   │   │   │       │   ├── course_updated.json
│   │   │   │       │   ├── discussion_entry_created.json
│   │   │   │       │   ├── discussion_entry_submitted.json
│   │   │   │       │   ├── discussion_topic_created.json
│   │   │   │       │   ├── discussion_topic_updated.json
│   │   │   │       │   ├── enrollment_created.json
│   │   │   │       │   ├── enrollment_state_created.json
│   │   │   │       │   ├── enrollment_state_updated.json
│   │   │   │       │   ├── enrollment_updated.json
│   │   │   │       │   ├── grade_change.json
│   │   │   │       │   ├── grade_override.json
│   │   │   │       │   ├── group_category_created.json
│   │   │   │       │   ├── group_category_updated.json
│   │   │   │       │   ├── group_created.json
│   │   │   │       │   ├── group_membership_created.json
│   │   │   │       │   ├── group_membership_updated.json
│   │   │   │       │   ├── group_updated.json
│   │   │   │       │   ├── learning_outcome_created.json
│   │   │   │       │   ├── learning_outcome_group_created.json
│   │   │   │       │   ├── learning_outcome_group_updated.json
│   │   │   │       │   ├── learning_outcome_link_created.json
│   │   │   │       │   ├── learning_outcome_link_updated.json
│   │   │   │       │   ├── learning_outcome_result_created.json
│   │   │   │       │   ├── learning_outcome_result_updated.json
│   │   │   │       │   ├── learning_outcome_updated.json
│   │   │   │       │   ├── logged_in.json
│   │   │   │       │   ├── logged_out.json
│   │   │   │       │   ├── module_created.json
│   │   │   │       │   ├── module_item_created.json
│   │   │   │       │   ├── module_item_updated.json
│   │   │   │       │   ├── module_updated.json
│   │   │   │       │   ├── outcome_calculation_method_created.json
│   │   │   │       │   ├── outcome_calculation_method_updated.json
│   │   │   │       │   ├── outcome_proficiency_created.json
│   │   │   │       │   ├── outcome_proficiency_updated.json
│   │   │   │       │   ├── outcomes_retry_outcome_alignment_clone.json
│   │   │   │       │   ├── plagiarism_resubmit.json
│   │   │   │       │   ├── quiz_submitted.json
│   │   │   │       │   ├── rubric_assessed.json
│   │   │   │       │   ├── sis_batch_created.json
│   │   │   │       │   ├── sis_batch_updated.json
│   │   │   │       │   ├── submission_comment_created.json
│   │   │   │       │   ├── submission_created.json
│   │   │   │       │   ├── submission_updated.json
│   │   │   │       │   ├── syllabus_updated.json
│   │   │   │       │   ├── user_account_association_created.json
│   │   │   │       │   ├── user_created.json
│   │   │   │       │   ├── user_updated.json
│   │   │   │       │   ├── wiki_page_created.json
│   │   │   │       │   ├── wiki_page_deleted.json
│   │   │   │       │   └── wiki_page_updated.json
│   │   │   │       └── metadata.json
│   │   │   └── md
│   │   │       ├── dynamic
│   │   │       └── static
│   │   │           ├── data_service_introduction.md
│   │   │           └── data_service_setup.md
│   │   ├── developer_keys.md
│   │   ├── docstring
│   │   │   ├── html
│   │   │   │   └── text.erb
│   │   │   ├── markdown
│   │   │   │   └── text.erb
│   │   │   └── setup.rb
│   │   ├── editor_button_placement.md
│   │   ├── endpoint_attributes.md
│   │   ├── file_uploads.md
│   │   ├── fulldoc
│   │   │   ├── html
│   │   │   │   ├── api_scopes
│   │   │   │   │   ├── api_scope_mapping_writer.rb
│   │   │   │   │   └── scope_mapper_template.erb
│   │   │   │   ├── css
│   │   │   │   │   ├── common.css
│   │   │   │   │   ├── highlight.default.css
│   │   │   │   │   ├── prettify.css
│   │   │   │   │   └── screen.css
│   │   │   │   ├── js
│   │   │   │   │   ├── backbone-min.js
│   │   │   │   │   ├── handlebars-1.0.0.js
│   │   │   │   │   ├── highlight.7.3.pack.js
│   │   │   │   │   ├── jquery-1.8.0.min.js
│   │   │   │   │   ├── jquery.ba-bbq.min.js
│   │   │   │   │   ├── jquery.min.js
│   │   │   │   │   ├── jquery.slideto.min.js
│   │   │   │   │   ├── jquery.wiggle.min.js
│   │   │   │   │   ├── prettify.js
│   │   │   │   │   ├── shred.bundle.js
│   │   │   │   │   ├── swagger-ui.js
│   │   │   │   │   ├── swagger-ui.min.js
│   │   │   │   │   ├── swagger.js
│   │   │   │   │   └── underscore-min.js
│   │   │   │   ├── live.html
│   │   │   │   ├── setup.rb
│   │   │   │   └── swagger
│   │   │   │       ├── argument_view.rb
│   │   │   │       ├── canvas_api
│   │   │   │       │   └── deprecatable.rb
│   │   │   │       ├── controller_list_view.rb
│   │   │   │       ├── controller_view.rb
│   │   │   │       ├── deprecated_method_view.rb
│   │   │   │       ├── formatted_type.rb
│   │   │   │       ├── hash_view.rb
│   │   │   │       ├── method_view.rb
│   │   │   │       ├── model_view.rb
│   │   │   │       ├── object_part_view.rb
│   │   │   │       ├── object_view.rb
│   │   │   │       ├── response_field_view.rb
│   │   │   │       ├── return_view.rb
│   │   │   │       └── route_view.rb
│   │   │   └── markdown
│   │   │       ├── decorator
│   │   │       │   ├── decorator.rb
│   │   │       │   └── gitbook_decorator.rb
│   │   │       ├── setup.rb
│   │   │       └── sidebar
│   │   │           └── sidebar.md.erb
│   │   ├── graphql.md
│   │   ├── group_category_csv.md
│   │   ├── homework_submission_placement.md
│   │   ├── jwt_access_tokens.md
│   │   ├── layout
│   │   │   ├── html
│   │   │   │   ├── footer.erb
│   │   │   │   ├── header.erb
│   │   │   │   ├── headers.erb
│   │   │   │   ├── layout.erb
│   │   │   │   ├── setup.rb
│   │   │   │   └── sidebar.erb
│   │   │   ├── markdown
│   │   │   │   ├── footer.erb
│   │   │   │   ├── header.erb
│   │   │   │   ├── headers.erb
│   │   │   │   ├── layout.erb
│   │   │   │   └── setup.rb
│   │   │   └── setup.rb
│   │   ├── link_selection_placement.md
│   │   ├── lti_dev_key_config.md
│   │   ├── lti_launch_overview.md
│   │   ├── lti_window_post_message.md
│   │   ├── masquerading.md
│   │   ├── method_details
│   │   │   ├── html
│   │   │   │   ├── header.erb
│   │   │   │   └── method_signature.erb
│   │   │   ├── markdown
│   │   │   │   ├── header.erb
│   │   │   │   ├── method_signature.erb
│   │   │   │   └── setup.rb
│   │   │   └── setup.rb
│   │   ├── migration_selection_placement.md
│   │   ├── navigation_tools.md
│   │   ├── oauth.md
│   │   ├── oauth_endpoints.md
│   │   ├── object_ids.md
│   │   ├── originality_report_appendix.md
│   │   ├── outcomes_csv.md
│   │   ├── pagination.md
│   │   ├── placements_overview.md
│   │   ├── plagiarism_platform.md
│   │   ├── pns.md
│   │   ├── provisioning.md
│   │   ├── registration.md
│   │   ├── sis_csv.md
│   │   ├── subscriptions_appendix.md
│   │   ├── tags
│   │   │   ├── html
│   │   │   │   ├── example_request.erb
│   │   │   │   ├── example_response.erb
│   │   │   │   ├── generic_tag.erb
│   │   │   │   ├── index.erb
│   │   │   │   ├── request_parameters.erb
│   │   │   │   ├── response_fields.erb
│   │   │   │   ├── returns.erb
│   │   │   │   └── see.erb
│   │   │   ├── markdown
│   │   │   │   ├── example_request.erb
│   │   │   │   ├── example_response.erb
│   │   │   │   ├── generic_tag.erb
│   │   │   │   ├── index.erb
│   │   │   │   ├── request_parameters.erb
│   │   │   │   ├── response_fields.erb
│   │   │   │   ├── returns.erb
│   │   │   │   └── see.erb
│   │   │   └── setup.rb
│   │   ├── throttling.md
│   │   ├── tools_intro.md
│   │   ├── tools_variable_substitutions.head.md
│   │   ├── tools_variable_substitutions.md
│   │   ├── tools_xml.md
│   │   ├── topic
│   │   │   ├── html
│   │   │   │   ├── header.erb
│   │   │   │   ├── method_details_list.erb
│   │   │   │   └── topic_doc.erb
│   │   │   ├── markdown
│   │   │   │   ├── header.erb
│   │   │   │   ├── method_details_list.erb
│   │   │   │   ├── setup.rb
│   │   │   │   └── topic_doc.erb
│   │   │   └── setup.rb
│   │   └── xapi.md
│   ├── copyright.md
│   ├── detect_n_plus_one_queries.md
│   ├── diagrams
│   │   └── Group Assignments.xmind
│   ├── docker
│   │   ├── README.md
│   │   ├── consul.md
│   │   ├── developing_with_docker.md
│   │   ├── getting_docker.md
│   │   └── vault.md
│   ├── examples
│   │   ├── README
│   │   ├── group_assignment.md
│   │   ├── question_specific_statistics.md
│   │   ├── quiz_question_answers.md
│   │   └── quiz_submission_manual_scoring.md
│   ├── flamegraphs.md
│   ├── high_level.txt
│   ├── i18n.md
│   ├── images
│   │   ├── README
│   │   ├── dynamic-registration-sequence-diagram.png
│   │   ├── eula.png
│   │   ├── gradebook-2.png
│   │   ├── gradebook.png
│   │   ├── group_assignment.png
│   │   ├── placements
│   │   │   ├── account_navigation.png
│   │   │   ├── analytics_hub.png
│   │   │   ├── assignment_edit.png
│   │   │   ├── assignment_group_menu.png
│   │   │   ├── assignment_index_menu.png
│   │   │   ├── assignment_menu.png
│   │   │   ├── assignment_selection.png
│   │   │   ├── assignment_view.png
│   │   │   ├── collaboration.png
│   │   │   ├── course_assignments_menu.png
│   │   │   ├── course_home_sub_navigation.png
│   │   │   ├── course_navigation.png
│   │   │   ├── course_settings_sub_navigation.png
│   │   │   ├── discussion_topic_index_menu.png
│   │   │   ├── discussion_topic_menu.png
│   │   │   ├── editor_button.png
│   │   │   ├── file_index_menu.png
│   │   │   ├── file_menu.png
│   │   │   ├── global_navigation.png
│   │   │   ├── homework_submission.png
│   │   │   ├── link_selection.png
│   │   │   ├── migration_selection.png
│   │   │   ├── module_group_menu.png
│   │   │   ├── module_group_menu_open.png
│   │   │   ├── module_index_menu.png
│   │   │   ├── module_index_menu_modal.png
│   │   │   ├── module_menu.png
│   │   │   ├── module_menu_modal.png
│   │   │   ├── module_menu_modal_open.png
│   │   │   ├── post_grades.png
│   │   │   ├── quiz_index_menu.png
│   │   │   ├── quiz_menu.png
│   │   │   ├── student_context_card.png
│   │   │   ├── submission_type_selection.png
│   │   │   ├── tool_configuration.png
│   │   │   ├── top_navigation.png
│   │   │   ├── user_navigation.png
│   │   │   ├── wiki_index_menu.png
│   │   │   └── wiki_page_menu.png
│   │   ├── pns
│   │   │   ├── dynamicreg.png
│   │   │   └── manualreg.png
│   │   ├── speedgrader.png
│   │   ├── student_grades.png
│   │   ├── submission_details.png
│   │   └── throbber.gif
│   ├── live_events.md
│   ├── lti
│   │   ├── 00_start_here.md
│   │   ├── 01_lti_overview.md
│   │   ├── 02_tool_installation.md
│   │   ├── 03_lti_launches.md
│   │   ├── 04_plagiarism_detection_platform.md
│   │   ├── 05_lti_1_1_launches.md
│   │   ├── 06_lti_2_0_launches.md
│   │   ├── 07_lti_1_3_launches.md
│   │   ├── 08_custom_parameters.md
│   │   ├── 09_lti_1_1_implementation.md
│   │   ├── 10_example_tools.md
│   │   ├── 11_testing.md
│   │   ├── 12_deep_linking.md
│   │   ├── 13_basic_outcomes.md
│   │   ├── 14_placements.md
│   │   ├── 15_plagiarism.md
│   │   ├── 16_privacy_level.md
│   │   ├── 17_platform_storage.md
│   │   └── assets
│   │       ├── lti_launch_overview.png
│   │       ├── lti_tables.png
│   │       └── src
│   │           ├── lti_launch_overview.plantuml
│   │           └── lti_tables.plantuml
│   ├── openapi
│   │   └── lti
│   │       ├── accounts.yaml
│   │       ├── authorize_redirect.yaml
│   │       ├── courses.yaml
│   │       ├── developer_keys.yaml
│   │       ├── groups.yaml
│   │       ├── register.yaml
│   │       ├── registration_token.yaml
│   │       ├── registrations.yaml
│   │       └── security.yaml
│   ├── profiling_ruby.md
│   ├── styleguide
│   │   └── template.mustache
│   ├── testing_javascript.md
│   ├── testing_with_selenium.md
│   ├── trace_database_queries.md
│   ├── ui
│   │   ├── graphq_validation_errors.md
│   │   ├── js_code_coverage.md
│   │   ├── react_components.md
│   │   ├── testing_javascript.md
│   │   ├── workflows
│   │   │   ├── improve_typescript.md
│   │   │   ├── modernize_react.md
│   │   │   ├── modernize_react_ref_strings.md
│   │   │   └── stabilize_tests.md
│   │   └── working_with_webpack.md
│   ├── using_guard_rail_in_development.md
│   └── yard_plugins
│       └── lti_variable_expansion_plugin.rb
├── docker-compose
│   ├── config
│   │   ├── cache_store.yml
│   │   ├── consul.yml
│   │   ├── database.yml
│   │   ├── delayed_jobs.yml
│   │   ├── domain.yml
│   │   ├── dynamic_settings.yml
│   │   ├── new-jenkins
│   │   │   ├── database.yml
│   │   │   ├── dynamodb.yml
│   │   │   ├── file_store.yml
│   │   │   └── security.yml
│   │   ├── outgoing_mail.yml
│   │   ├── redis.yml
│   │   ├── security.yml
│   │   ├── selenium.yml
│   │   └── vault.yml
│   ├── consul.override.yml
│   ├── dynamodb.override.yml
│   ├── karma
│   │   └── Dockerfile
│   ├── kinesis.override.yml
│   ├── lti-test-tool.override.yml
│   ├── mailcatcher.override.yml
│   ├── pgweb.override.yml
│   ├── postgres
│   │   ├── Dockerfile
│   │   ├── create-dbs.sh
│   │   └── wait-for-it
│   ├── puma.override.yml
│   ├── rce-api.override.yml
│   ├── rdbg.override.yml
│   ├── selenium.override.yml
│   ├── statsd.override.yml
│   ├── vault
│   │   └── Dockerfile
│   ├── vault.override.yml
│   └── watch-es-packages.override.yml
├── docker-compose.new-jenkins-flakey-spec-catcher.yml
├── docker-compose.new-jenkins-js.yml
├── docker-compose.new-jenkins-package-translations.yml
├── docker-compose.new-jenkins-selenium.yml
├── docker-compose.new-jenkins.consumer.yml
├── docker-compose.new-jenkins.vendored-gems.yml
├── docker-compose.new-jenkins.yml
├── docker-compose.spring.yml
├── docker-compose.yml
├── eslint.config.jest.js
├── eslint.config.js
├── eslint.config.qunit.js
├── gems
│   ├── README.md
│   ├── activesupport-suspend_callbacks
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── LICENSE.txt
│   │   ├── README.md
│   │   ├── Rakefile
│   │   ├── activesupport-suspend_callbacks.gemspec
│   │   ├── lib
│   │   │   └── active_support
│   │   │       └── callbacks
│   │   │           ├── suspension
│   │   │           │   └── registry.rb
│   │   │           └── suspension.rb
│   │   ├── spec
│   │   │   ├── active_support
│   │   │   │   └── callbacks
│   │   │   │       ├── suspension
│   │   │   │       │   └── registry_spec.rb
│   │   │   │       └── suspension_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── acts_as_list
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── README
│   │   ├── acts_as_list.gemspec
│   │   ├── lib
│   │   │   ├── active_record
│   │   │   │   └── acts
│   │   │   │       └── list.rb
│   │   │   └── acts_as_list.rb
│   │   ├── spec
│   │   │   └── list_spec.rb
│   │   └── test.sh
│   ├── adheres_to_policy
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── README.md
│   │   ├── Rakefile
│   │   ├── adheres_to_policy.gemspec
│   │   ├── lib
│   │   │   ├── adheres_to_policy
│   │   │   │   ├── cache.rb
│   │   │   │   ├── class_methods.rb
│   │   │   │   ├── condition.rb
│   │   │   │   ├── configuration.rb
│   │   │   │   ├── instance_methods.rb
│   │   │   │   ├── policy.rb
│   │   │   │   └── results.rb
│   │   │   └── adheres_to_policy.rb
│   │   ├── spec
│   │   │   ├── adheres_to_policy
│   │   │   │   ├── cache_spec.rb
│   │   │   │   ├── class_methods_spec.rb
│   │   │   │   ├── condition_spec.rb
│   │   │   │   ├── configuration_spec.rb
│   │   │   │   ├── instance_methods_spec.rb
│   │   │   │   └── policy_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── attachment_fu
│   │   ├── CHANGELOG
│   │   ├── LICENSE
│   │   ├── README
│   │   ├── attachment_fu.gemspec
│   │   ├── lib
│   │   │   ├── attachment_fu
│   │   │   │   ├── backends
│   │   │   │   │   ├── file_system_backend.rb
│   │   │   │   │   └── s3_backend.rb
│   │   │   │   ├── processors
│   │   │   │   │   └── mini_magick_processor.rb
│   │   │   │   ├── railtie.rb
│   │   │   │   └── version.rb
│   │   │   └── attachment_fu.rb
│   │   └── spec
│   │       └── lib
│   │           └── attachment_fu
│   │               └── backends
│   │                   └── s3_backend_spec.rb
│   ├── autoextend
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── autoextend.gemspec
│   │   ├── lib
│   │   │   ├── autoextend
│   │   │   │   └── extension.rb
│   │   │   └── autoextend.rb
│   │   ├── spec
│   │   │   ├── autoextend_spec.rb
│   │   │   └── autoload
│   │   │       └── autoextend_spec
│   │   │           ├── test_later_method.rb
│   │   │           ├── test_module.rb
│   │   │           └── test_module2.rb
│   │   └── test.sh
│   ├── bookmarked_collection
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── Rakefile
│   │   ├── bookmarked_collection.gemspec
│   │   ├── lib
│   │   │   ├── bookmarked_collection
│   │   │   │   ├── collection.rb
│   │   │   │   ├── composite_collection.rb
│   │   │   │   ├── composite_proxy.rb
│   │   │   │   ├── concat_collection.rb
│   │   │   │   ├── concat_proxy.rb
│   │   │   │   ├── filter_proxy.rb
│   │   │   │   ├── merge_proxy.rb
│   │   │   │   ├── proxy.rb
│   │   │   │   ├── simple_bookmarker.rb
│   │   │   │   ├── sync_filter_proxy.rb
│   │   │   │   ├── transform_proxy.rb
│   │   │   │   └── wrap_proxy.rb
│   │   │   └── bookmarked_collection.rb
│   │   ├── spec
│   │   │   ├── bookmarked_collection
│   │   │   │   ├── bookmarked_collection_spec.rb
│   │   │   │   ├── collection_spec.rb
│   │   │   │   ├── merge_proxy_spec.rb
│   │   │   │   ├── proxy_spec.rb
│   │   │   │   └── simple_bookmarker_spec.rb
│   │   │   ├── spec_helper.rb
│   │   │   └── support
│   │   │       └── active_record.rb
│   │   └── test.sh
│   ├── broadcast_policy
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── README.md
│   │   ├── broadcast_policy.gemspec
│   │   ├── lib
│   │   │   ├── broadcast_policy
│   │   │   │   ├── class_methods.rb
│   │   │   │   ├── instance_methods.rb
│   │   │   │   ├── notification_policy.rb
│   │   │   │   ├── policy_list.rb
│   │   │   │   ├── singleton_methods.rb
│   │   │   │   └── version.rb
│   │   │   └── broadcast_policy.rb
│   │   ├── spec
│   │   │   ├── broadcast_policy
│   │   │   │   ├── broadcast_policy_spec.rb
│   │   │   │   ├── instance_methods_spec.rb
│   │   │   │   ├── notification_policy_spec.rb
│   │   │   │   ├── policy_list_spec.rb
│   │   │   │   └── singleton_methods_spec.rb
│   │   │   ├── spec_helper.rb
│   │   │   └── support
│   │   │       ├── mock_notification_finder.rb
│   │   │       ├── mock_notifier.rb
│   │   │       └── mock_suspended_user.rb
│   │   └── test.sh
│   ├── canvas_breach_mitigation
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── LICENSE.txt
│   │   ├── README.md
│   │   ├── canvas_breach_mitigation.gemspec
│   │   ├── lib
│   │   │   ├── canvas_breach_mitigation
│   │   │   │   └── masking_secrets.rb
│   │   │   └── canvas_breach_mitigation.rb
│   │   ├── spec
│   │   │   ├── masking_secrets_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── canvas_cache
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── README.md
│   │   ├── canvas_cache.gemspec
│   │   ├── lib
│   │   │   ├── canvas_cache
│   │   │   │   ├── hash_ring.rb
│   │   │   │   ├── memory_settings.rb
│   │   │   │   ├── redis.rb
│   │   │   │   └── redis_cache_store.rb
│   │   │   ├── canvas_cache.rb
│   │   │   └── redis_client
│   │   │       ├── logging.rb
│   │   │       ├── max_clients.rb
│   │   │       └── twemproxy.rb
│   │   ├── spec
│   │   │   ├── canvas_cache
│   │   │   │   ├── hash_ring_spec.rb
│   │   │   │   ├── redis
│   │   │   │   │   └── distributed_spec.rb
│   │   │   │   └── redis_spec.rb
│   │   │   ├── fixtures
│   │   │   │   └── config
│   │   │   │       └── redis.yml
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── canvas_color
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── canvas_color.gemspec
│   │   └── lib
│   │       └── canvas_color.rb
│   ├── canvas_crummy
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── LICENSE.txt
│   │   ├── README.md
│   │   ├── Rakefile
│   │   ├── canvas_crummy.gemspec
│   │   └── lib
│   │       ├── canvas_crummy
│   │       │   ├── controller_methods.rb
│   │       │   └── view_methods.rb
│   │       └── canvas_crummy.rb
│   ├── canvas_dynamodb
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── README.md
│   │   ├── Rakefile
│   │   ├── canvas_dynamodb-0.0.1.gem
│   │   ├── canvas_dynamodb.gemspec
│   │   ├── lib
│   │   │   ├── canvas_dynamodb
│   │   │   │   ├── batch_builder_base.rb
│   │   │   │   ├── batch_get_builder.rb
│   │   │   │   ├── batch_write_builder.rb
│   │   │   │   └── database.rb
│   │   │   └── canvas_dynamodb.rb
│   │   └── spec
│   │       ├── lib
│   │       │   └── database_spec.rb
│   │       └── spec_helper.rb
│   ├── canvas_errors
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── README.md
│   │   ├── canvas_errors.gemspec
│   │   ├── config
│   │   │   ├── README.md
│   │   │   ├── code_ownership.yml
│   │   │   └── teams
│   │   │       └── test.yml
│   │   ├── lib
│   │   │   ├── canvas_errors
│   │   │   │   └── job_info.rb
│   │   │   └── canvas_errors.rb
│   │   ├── spec
│   │   │   ├── canvas_errors
│   │   │   │   └── job_info_spec.rb
│   │   │   ├── canvas_errors_spec.rb
│   │   │   ├── data
│   │   │   │   └── owned_class.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── canvas_ext
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── Rakefile
│   │   ├── canvas_ext.gemspec
│   │   ├── lib
│   │   │   ├── canvas_ext
│   │   │   │   ├── array.rb
│   │   │   │   ├── hash.rb
│   │   │   │   └── object.rb
│   │   │   └── canvas_ext.rb
│   │   ├── spec
│   │   │   ├── canvas_ext
│   │   │   │   ├── array_spec.rb
│   │   │   │   ├── date_spec.rb
│   │   │   │   ├── hash_spec.rb
│   │   │   │   └── object_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── canvas_http
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── Rakefile
│   │   ├── canvas_http.gemspec
│   │   ├── lib
│   │   │   ├── canvas_http
│   │   │   │   └── circuit_breaker.rb
│   │   │   └── canvas_http.rb
│   │   ├── spec
│   │   │   ├── canvas_http
│   │   │   │   └── circuit_breaker_spec.rb
│   │   │   ├── canvas_http_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── canvas_kaltura
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── Rakefile
│   │   ├── canvas_kaltura.gemspec
│   │   ├── lib
│   │   │   ├── canvas_kaltura
│   │   │   │   ├── kaltura_client_v3.rb
│   │   │   │   └── kaltura_string_io.rb
│   │   │   └── canvas_kaltura.rb
│   │   ├── spec
│   │   │   ├── canvas_kaltura
│   │   │   │   ├── kaltura_client_v3_spec.rb
│   │   │   │   └── kaltura_string_io_spec.rb
│   │   │   ├── canvas_kaltura_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── canvas_mimetype_fu
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── LICENSE.txt
│   │   ├── README.md
│   │   ├── Rakefile
│   │   ├── canvas_mimetype_fu.gemspec
│   │   ├── lib
│   │   │   ├── canvas_mimetype_fu
│   │   │   │   ├── extensions_const.rb
│   │   │   │   ├── mime_types.yml
│   │   │   │   └── mimetype_fu.rb
│   │   │   └── canvas_mimetype_fu.rb
│   │   ├── spec
│   │   │   ├── canvas_mimetype_fu
│   │   │   │   └── mime_type_spec.rb
│   │   │   ├── fixtures
│   │   │   │   ├── file.jpg
│   │   │   │   ├── file.rb
│   │   │   │   └── file.unknown
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── canvas_panda_pub
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── Rakefile
│   │   ├── canvas_panda_pub.gemspec
│   │   ├── lib
│   │   │   ├── canvas_panda_pub
│   │   │   │   ├── async_worker.rb
│   │   │   │   └── client.rb
│   │   │   └── canvas_panda_pub.rb
│   │   ├── spec
│   │   │   ├── canvas_panda_pub
│   │   │   │   ├── async_worker_spec.rb
│   │   │   │   └── client_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── canvas_partman
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── LICENSE.txt
│   │   ├── README.md
│   │   ├── canvas_partman.gemspec
│   │   ├── lib
│   │   │   ├── canvas_partman
│   │   │   │   ├── concerns
│   │   │   │   │   └── partitioned.rb
│   │   │   │   ├── dynamic_relation.rb
│   │   │   │   ├── migration.rb
│   │   │   │   ├── partition_manager
│   │   │   │   │   ├── by_date.rb
│   │   │   │   │   └── by_id.rb
│   │   │   │   ├── partition_manager.rb
│   │   │   │   └── version.rb
│   │   │   ├── canvas_partman.rb
│   │   │   └── generators
│   │   │       ├── partition_migration_generator.rb
│   │   │       └── templates
│   │   │           └── migration.rb.erb
│   │   ├── spec
│   │   │   ├── canvas_partman
│   │   │   │   ├── concerns
│   │   │   │   │   └── partitioned_spec.rb
│   │   │   │   ├── migration_spec.rb
│   │   │   │   └── partition_manager_spec.rb
│   │   │   ├── fixtures
│   │   │   │   ├── animal.rb
│   │   │   │   ├── db
│   │   │   │   │   ├── 20141103000000_add_foo_to_partman_animals.rb
│   │   │   │   │   ├── 20141103000001_add_bar_to_partman_animals.rb
│   │   │   │   │   ├── 20141103000002_remove_foo_from_partman_animals.rb
│   │   │   │   │   ├── 20141103000003_add_another_thing_to_partman_animals.rb
│   │   │   │   │   └── 20141103000004_add_race_index_to_partman_animals.rb
│   │   │   │   ├── trail.rb
│   │   │   │   ├── week_event.rb
│   │   │   │   └── zoo.rb
│   │   │   ├── spec_helper.rb
│   │   │   └── support
│   │   │       └── schema_helper.rb
│   │   └── test.sh
│   ├── canvas_quiz_statistics
│   │   ├── CHANGELOG.md
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── Guardfile
│   │   ├── LICENSE.txt
│   │   ├── README.md
│   │   ├── Rakefile
│   │   ├── TODO.md
│   │   ├── canvas_quiz_statistics.gemspec
│   │   ├── lib
│   │   │   ├── canvas_quiz_statistics
│   │   │   │   ├── analyzers
│   │   │   │   │   ├── base
│   │   │   │   │   │   ├── constants.rb
│   │   │   │   │   │   └── dsl.rb
│   │   │   │   │   ├── base.rb
│   │   │   │   │   ├── calculated.rb
│   │   │   │   │   ├── concerns
│   │   │   │   │   │   └── has_answers.rb
│   │   │   │   │   ├── essay.rb
│   │   │   │   │   ├── file_upload.rb
│   │   │   │   │   ├── fill_in_multiple_blanks.rb
│   │   │   │   │   ├── matching.rb
│   │   │   │   │   ├── multiple_answers.rb
│   │   │   │   │   ├── multiple_choice.rb
│   │   │   │   │   ├── multiple_dropdowns.rb
│   │   │   │   │   ├── numerical.rb
│   │   │   │   │   ├── short_answer.rb
│   │   │   │   │   └── true_false.rb
│   │   │   │   ├── analyzers.rb
│   │   │   │   ├── util.rb
│   │   │   │   └── version.rb
│   │   │   └── canvas_quiz_statistics.rb
│   │   ├── spec
│   │   │   ├── canvas_quiz_statistics
│   │   │   │   ├── analyzers
│   │   │   │   │   ├── base_spec.rb
│   │   │   │   │   ├── calculated_spec.rb
│   │   │   │   │   ├── essay_spec.rb
│   │   │   │   │   ├── file_upload_spec.rb
│   │   │   │   │   ├── fill_in_multiple_blanks_spec.rb
│   │   │   │   │   ├── matching_spec.rb
│   │   │   │   │   ├── multiple_answers_spec.rb
│   │   │   │   │   ├── multiple_choice_spec.rb
│   │   │   │   │   ├── multiple_dropdowns_spec.rb
│   │   │   │   │   ├── numerical_spec.rb
│   │   │   │   │   ├── shared_metrics
│   │   │   │   │   │   ├── correct.rb
│   │   │   │   │   │   ├── essay_full_credit.rb
│   │   │   │   │   │   ├── essay_responses.rb
│   │   │   │   │   │   ├── incorrect.rb
│   │   │   │   │   │   └── partially_correct.rb
│   │   │   │   │   └── short_answer_spec.rb
│   │   │   │   ├── answer_analyzers_spec.rb
│   │   │   │   ├── support
│   │   │   │   │   ├── fixtures
│   │   │   │   │   │   ├── calculated_question_data.json
│   │   │   │   │   │   ├── essay_question_data.json
│   │   │   │   │   │   ├── file_upload_question_data.json
│   │   │   │   │   │   ├── fill_in_multiple_blanks_question_data.json
│   │   │   │   │   │   ├── matching_question_data.json
│   │   │   │   │   │   ├── multiple_answers_question_data.json
│   │   │   │   │   │   ├── multiple_choice_question_data.json
│   │   │   │   │   │   ├── multiple_dropdowns_question_data.json
│   │   │   │   │   │   ├── numerical_question_data.json
│   │   │   │   │   │   └── short_answer_question_data.json
│   │   │   │   │   └── question_helpers.rb
│   │   │   │   └── util_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── canvas_sanitize
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── README.md
│   │   ├── Rakefile
│   │   ├── canvas_sanitize.gemspec
│   │   ├── lib
│   │   │   ├── canvas_sanitize
│   │   │   │   └── canvas_sanitize.rb
│   │   │   └── canvas_sanitize.rb
│   │   ├── spec
│   │   │   ├── canvas_sanitize
│   │   │   │   └── canvas_sanitize_spec.rb
│   │   │   ├── fixtures
│   │   │   │   └── xss
│   │   │   │       ├── 1.xss
│   │   │   │       ├── 10.xss
│   │   │   │       ├── 11.xss
│   │   │   │       ├── 12.xss
│   │   │   │       ├── 13.xss
│   │   │   │       ├── 14.xss
│   │   │   │       ├── 15.xss
│   │   │   │       ├── 16.xss
│   │   │   │       ├── 17.xss
│   │   │   │       ├── 18.xss
│   │   │   │       ├── 19.xss
│   │   │   │       ├── 2.xss
│   │   │   │       ├── 20.xss
│   │   │   │       ├── 21.xss
│   │   │   │       ├── 22.xss
│   │   │   │       ├── 23.xss
│   │   │   │       ├── 24.xss
│   │   │   │       ├── 25.xss
│   │   │   │       ├── 26.xss
│   │   │   │       ├── 27.xss
│   │   │   │       ├── 28.xss
│   │   │   │       ├── 29.xss
│   │   │   │       ├── 3.xss
│   │   │   │       ├── 30.xss
│   │   │   │       ├── 31.xss
│   │   │   │       ├── 32.xss
│   │   │   │       ├── 33.xss
│   │   │   │       ├── 34.xss
│   │   │   │       ├── 35.xss
│   │   │   │       ├── 36.xss
│   │   │   │       ├── 37.xss
│   │   │   │       ├── 38.xss
│   │   │   │       ├── 39.xss
│   │   │   │       ├── 4.xss
│   │   │   │       ├── 40.xss
│   │   │   │       ├── 41.xss
│   │   │   │       ├── 42.xss
│   │   │   │       ├── 43.xss
│   │   │   │       ├── 44.xss
│   │   │   │       ├── 45.xss
│   │   │   │       ├── 46.xss
│   │   │   │       ├── 47.xss
│   │   │   │       ├── 48.xss
│   │   │   │       ├── 49.xss
│   │   │   │       ├── 50.xss
│   │   │   │       ├── 51.xss
│   │   │   │       ├── 52.xss
│   │   │   │       ├── 53.xss
│   │   │   │       ├── 54.xss
│   │   │   │       ├── 55.xss
│   │   │   │       ├── 56.xss
│   │   │   │       ├── 57.xss
│   │   │   │       ├── 58.xss
│   │   │   │       ├── 59.xss
│   │   │   │       ├── 6.xss
│   │   │   │       ├── 61.xss
│   │   │   │       ├── 62.xss
│   │   │   │       ├── 63.xss
│   │   │   │       ├── 64.xss
│   │   │   │       ├── 65.xss
│   │   │   │       ├── 66.xss
│   │   │   │       ├── 67.xss
│   │   │   │       ├── 68.xss
│   │   │   │       ├── 69.xss
│   │   │   │       ├── 7.xss
│   │   │   │       ├── 70.xss
│   │   │   │       ├── 71.xss
│   │   │   │       ├── 73.xss
│   │   │   │       ├── 74.xss
│   │   │   │       ├── 75.xss
│   │   │   │       ├── 76.xss
│   │   │   │       ├── 77.xss
│   │   │   │       ├── 78.xss
│   │   │   │       ├── 79.xss
│   │   │   │       ├── 8.xss
│   │   │   │       ├── 80.xss
│   │   │   │       ├── 82.xss
│   │   │   │       ├── 83.xss
│   │   │   │       ├── 84.xss
│   │   │   │       ├── 85.xss
│   │   │   │       ├── 86.xss
│   │   │   │       ├── 87.xss
│   │   │   │       ├── 88.xss
│   │   │   │       ├── 89.xss
│   │   │   │       ├── 9.xss
│   │   │   │       ├── 91.xss
│   │   │   │       ├── 92.xss
│   │   │   │       ├── 93.xss
│   │   │   │       ├── 94.xss
│   │   │   │       ├── 95.xss
│   │   │   │       ├── 96.xss
│   │   │   │       ├── 97.xss
│   │   │   │       ├── 98.xss
│   │   │   │       └── 99.xss
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── canvas_security
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── README.md
│   │   ├── canvas_security.gemspec
│   │   ├── lib
│   │   │   ├── canvas_security
│   │   │   │   ├── jwk_key_pair.rb
│   │   │   │   ├── jwt_workflow.rb
│   │   │   │   ├── key_storage.rb
│   │   │   │   ├── page_view_jwt.rb
│   │   │   │   ├── rsa_key_pair.rb
│   │   │   │   ├── services_jwt.rb
│   │   │   │   └── spec
│   │   │   │       └── jwt_env.rb
│   │   │   └── canvas_security.rb
│   │   ├── spec
│   │   │   ├── canvas_security
│   │   │   │   ├── jwk_key_pair_spec.rb
│   │   │   │   ├── jwt_workflow_spec.rb
│   │   │   │   ├── key_storage_spec.rb
│   │   │   │   ├── page_view_jwt_spec.rb
│   │   │   │   ├── rsa_key_pair_spec.rb
│   │   │   │   └── services_jwt_spec.rb
│   │   │   ├── canvas_security_spec.rb
│   │   │   ├── fixtures
│   │   │   │   └── config
│   │   │   │       ├── redis.yml
│   │   │   │       └── security.yml
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── canvas_slug
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── Rakefile
│   │   ├── canvas_slug.gemspec
│   │   ├── lib
│   │   │   └── canvas_slug.rb
│   │   ├── spec
│   │   │   ├── canvas_slug
│   │   │   │   └── canvas_slug_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── canvas_sort
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── Rakefile
│   │   ├── canvas_sort.gemspec
│   │   ├── lib
│   │   │   ├── canvas_sort
│   │   │   │   ├── sort_first.rb
│   │   │   │   └── sort_last.rb
│   │   │   └── canvas_sort.rb
│   │   ├── spec
│   │   │   ├── canvas_sort
│   │   │   │   └── sorting_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── canvas_stringex
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── LICENSE.txt
│   │   ├── README.rdoc
│   │   ├── Rakefile
│   │   ├── canvas_stringex.gemspec
│   │   ├── lib
│   │   │   ├── canvas_stringex.rb
│   │   │   └── lucky_sneaks
│   │   │       ├── acts_as_url.rb
│   │   │       ├── string_extensions.rb
│   │   │       ├── unidecoder.rb
│   │   │       └── unidecoder_data
│   │   │           ├── x00.json
│   │   │           ├── x01.json
│   │   │           ├── x02.json
│   │   │           ├── x03.json
│   │   │           ├── x04.json
│   │   │           ├── x05.json
│   │   │           ├── x06.json
│   │   │           ├── x07.json
│   │   │           ├── x09.json
│   │   │           ├── x0a.json
│   │   │           ├── x0b.json
│   │   │           ├── x0c.json
│   │   │           ├── x0d.json
│   │   │           ├── x0e.json
│   │   │           ├── x0f.json
│   │   │           ├── x10.json
│   │   │           ├── x11.json
│   │   │           ├── x12.json
│   │   │           ├── x13.json
│   │   │           ├── x14.json
│   │   │           ├── x15.json
│   │   │           ├── x16.json
│   │   │           ├── x17.json
│   │   │           ├── x18.json
│   │   │           ├── x1e.json
│   │   │           ├── x1f.json
│   │   │           ├── x20.json
│   │   │           ├── x21.json
│   │   │           ├── x22.json
│   │   │           ├── x23.json
│   │   │           ├── x24.json
│   │   │           ├── x25.json
│   │   │           ├── x26.json
│   │   │           ├── x27.json
│   │   │           ├── x28.json
│   │   │           ├── x2e.json
│   │   │           ├── x2f.json
│   │   │           ├── x30.json
│   │   │           ├── x31.json
│   │   │           ├── x32.json
│   │   │           ├── x33.json
│   │   │           ├── x4d.json
│   │   │           ├── x4e.json
│   │   │           ├── x4f.json
│   │   │           ├── x50.json
│   │   │           ├── x51.json
│   │   │           ├── x52.json
│   │   │           ├── x53.json
│   │   │           ├── x54.json
│   │   │           ├── x55.json
│   │   │           ├── x56.json
│   │   │           ├── x57.json
│   │   │           ├── x58.json
│   │   │           ├── x59.json
│   │   │           ├── x5a.json
│   │   │           ├── x5b.json
│   │   │           ├── x5c.json
│   │   │           ├── x5d.json
│   │   │           ├── x5e.json
│   │   │           ├── x5f.json
│   │   │           ├── x60.json
│   │   │           ├── x61.json
│   │   │           ├── x62.json
│   │   │           ├── x63.json
│   │   │           ├── x64.json
│   │   │           ├── x65.json
│   │   │           ├── x66.json
│   │   │           ├── x67.json
│   │   │           ├── x68.json
│   │   │           ├── x69.json
│   │   │           ├── x6a.json
│   │   │           ├── x6b.json
│   │   │           ├── x6c.json
│   │   │           ├── x6d.json
│   │   │           ├── x6e.json
│   │   │           ├── x6f.json
│   │   │           ├── x70.json
│   │   │           ├── x71.json
│   │   │           ├── x72.json
│   │   │           ├── x73.json
│   │   │           ├── x74.json
│   │   │           ├── x75.json
│   │   │           ├── x76.json
│   │   │           ├── x77.json
│   │   │           ├── x78.json
│   │   │           ├── x79.json
│   │   │           ├── x7a.json
│   │   │           ├── x7b.json
│   │   │           ├── x7c.json
│   │   │           ├── x7d.json
│   │   │           ├── x7e.json
│   │   │           ├── x7f.json
│   │   │           ├── x80.json
│   │   │           ├── x81.json
│   │   │           ├── x82.json
│   │   │           ├── x83.json
│   │   │           ├── x84.json
│   │   │           ├── x85.json
│   │   │           ├── x86.json
│   │   │           ├── x87.json
│   │   │           ├── x88.json
│   │   │           ├── x89.json
│   │   │           ├── x8a.json
│   │   │           ├── x8b.json
│   │   │           ├── x8c.json
│   │   │           ├── x8d.json
│   │   │           ├── x8e.json
│   │   │           ├── x8f.json
│   │   │           ├── x90.json
│   │   │           ├── x91.json
│   │   │           ├── x92.json
│   │   │           ├── x93.json
│   │   │           ├── x94.json
│   │   │           ├── x95.json
│   │   │           ├── x96.json
│   │   │           ├── x97.json
│   │   │           ├── x98.json
│   │   │           ├── x99.json
│   │   │           ├── x9a.json
│   │   │           ├── x9b.json
│   │   │           ├── x9c.json
│   │   │           ├── x9d.json
│   │   │           ├── x9e.json
│   │   │           ├── x9f.json
│   │   │           ├── xa0.json
│   │   │           ├── xa1.json
│   │   │           ├── xa2.json
│   │   │           ├── xa3.json
│   │   │           ├── xa4.json
│   │   │           ├── xac.json
│   │   │           ├── xad.json
│   │   │           ├── xae.json
│   │   │           ├── xaf.json
│   │   │           ├── xb0.json
│   │   │           ├── xb1.json
│   │   │           ├── xb2.json
│   │   │           ├── xb3.json
│   │   │           ├── xb4.json
│   │   │           ├── xb5.json
│   │   │           ├── xb6.json
│   │   │           ├── xb7.json
│   │   │           ├── xb8.json
│   │   │           ├── xb9.json
│   │   │           ├── xba.json
│   │   │           ├── xbb.json
│   │   │           ├── xbc.json
│   │   │           ├── xbd.json
│   │   │           ├── xbe.json
│   │   │           ├── xbf.json
│   │   │           ├── xc0.json
│   │   │           ├── xc1.json
│   │   │           ├── xc2.json
│   │   │           ├── xc3.json
│   │   │           ├── xc4.json
│   │   │           ├── xc5.json
│   │   │           ├── xc6.json
│   │   │           ├── xc7.json
│   │   │           ├── xc8.json
│   │   │           ├── xc9.json
│   │   │           ├── xca.json
│   │   │           ├── xcb.json
│   │   │           ├── xcc.json
│   │   │           ├── xcd.json
│   │   │           ├── xce.json
│   │   │           ├── xcf.json
│   │   │           ├── xd0.json
│   │   │           ├── xd1.json
│   │   │           ├── xd2.json
│   │   │           ├── xd3.json
│   │   │           ├── xd4.json
│   │   │           ├── xd5.json
│   │   │           ├── xd6.json
│   │   │           ├── xd7.json
│   │   │           ├── xf9.json
│   │   │           ├── xfa.json
│   │   │           ├── xfb.json
│   │   │           ├── xfc.json
│   │   │           ├── xfd.json
│   │   │           ├── xfe.json
│   │   │           └── xff.json
│   │   ├── spec
│   │   │   ├── lucky_sneaks
│   │   │   │   ├── acts_as_url_spec.rb
│   │   │   │   ├── string_extensions_spec.rb
│   │   │   │   ├── unicode_point_suite
│   │   │   │   │   ├── basic_latin_spec.rb
│   │   │   │   │   └── codepoint_test_helper.rb
│   │   │   │   └── unidecoder_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── canvas_text_helper
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── Rakefile
│   │   ├── canvas_text_helper.gemspec
│   │   ├── config
│   │   │   └── locales
│   │   │       └── en.yml
│   │   ├── lib
│   │   │   └── canvas_text_helper.rb
│   │   ├── spec
│   │   │   ├── canvas_text_helper_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── canvas_time
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── Rakefile
│   │   ├── canvas_time.gemspec
│   │   ├── lib
│   │   │   └── canvas_time.rb
│   │   ├── spec
│   │   │   ├── canvas_time
│   │   │   │   └── time_spec.rb
│   │   │   ├── canvas_time_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── canvas_unzip
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── Rakefile
│   │   ├── canvas_unzip.gemspec
│   │   ├── lib
│   │   │   └── canvas_unzip.rb
│   │   ├── spec
│   │   │   ├── canvas_unzip_spec.rb
│   │   │   ├── fixtures
│   │   │   │   ├── bigcompression.zip
│   │   │   │   ├── empty.imscc
│   │   │   │   ├── empty.tar
│   │   │   │   ├── empty.tar.gz
│   │   │   │   ├── empty.zip
│   │   │   │   ├── evil.imscc
│   │   │   │   ├── evil.tar
│   │   │   │   ├── evil.tar.gz
│   │   │   │   ├── evil.zip
│   │   │   │   ├── test.imscc
│   │   │   │   ├── test.tar
│   │   │   │   ├── test.tar.gz
│   │   │   │   └── test.zip
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── config_file
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── README.md
│   │   ├── config_file.gemspec
│   │   ├── lib
│   │   │   └── config_file.rb
│   │   ├── spec
│   │   │   ├── config_file_spec.rb
│   │   │   ├── fixtures
│   │   │   │   └── config
│   │   │   │       └── database.yml
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── csv_diff
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── csv_diff.gemspec
│   │   ├── lib
│   │   │   ├── csv_diff
│   │   │   │   ├── diff.rb
│   │   │   │   └── version.rb
│   │   │   └── csv_diff.rb
│   │   ├── spec
│   │   │   ├── csv_diff_spec.rb
│   │   │   ├── files
│   │   │   │   ├── 1.curr.csv
│   │   │   │   ├── 1.out.csv
│   │   │   │   └── 1.prev.csv
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── diigo
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── diigo.gemspec
│   │   ├── lib
│   │   │   ├── diigo
│   │   │   │   └── connection.rb
│   │   │   └── diigo.rb
│   │   ├── spec
│   │   │   ├── diigo
│   │   │   │   └── connection_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── dr_diff
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── README.md
│   │   ├── Rakefile
│   │   ├── config
│   │   ├── dr_diff.gemspec
│   │   ├── lib
│   │   │   ├── dr_diff
│   │   │   │   ├── command_capture.rb
│   │   │   │   ├── diff_parser.rb
│   │   │   │   ├── git_proxy.rb
│   │   │   │   └── manager.rb
│   │   │   └── dr_diff.rb
│   │   ├── spec
│   │   │   ├── diff_parser_spec.rb
│   │   │   ├── git_proxy_spec.rb
│   │   │   ├── manager_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── dynamic_settings
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── README.md
│   │   ├── dynamic_settings.gemspec
│   │   ├── lib
│   │   │   ├── dynamic_settings
│   │   │   │   ├── circuit_breaker.rb
│   │   │   │   ├── fallback_proxy.rb
│   │   │   │   ├── memory_cache.rb
│   │   │   │   ├── null_request_cache.rb
│   │   │   │   └── prefix_proxy.rb
│   │   │   └── dynamic_settings.rb
│   │   ├── spec
│   │   │   ├── dynamic_settings
│   │   │   │   ├── circuit_breaker_spec.rb
│   │   │   │   ├── config
│   │   │   │   ├── fallback_proxy_spec.rb
│   │   │   │   ├── memory_cache_spec.rb
│   │   │   │   └── prefix_proxy_spec.rb
│   │   │   ├── dynamic_settings_spec.rb
│   │   │   ├── fixtures
│   │   │   │   ├── config
│   │   │   │   │   └── dynamic_settings.yml
│   │   │   │   └── setting.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── event_stream
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── event_stream.gemspec
│   │   ├── lib
│   │   │   ├── event_stream
│   │   │   │   ├── attr_config.rb
│   │   │   │   ├── backend
│   │   │   │   │   └── active_record.rb
│   │   │   │   ├── failure.rb
│   │   │   │   ├── index.rb
│   │   │   │   ├── index_strategy
│   │   │   │   │   └── active_record.rb
│   │   │   │   ├── logger.rb
│   │   │   │   ├── record.rb
│   │   │   │   └── stream.rb
│   │   │   └── event_stream.rb
│   │   ├── spec
│   │   │   ├── event_stream
│   │   │   │   ├── attr_config_spec.rb
│   │   │   │   ├── backend
│   │   │   │   │   └── active_record_spec.rb
│   │   │   │   ├── failure_spec.rb
│   │   │   │   ├── index_strategy
│   │   │   │   │   └── active_record_spec.rb
│   │   │   │   ├── logger_spec.rb
│   │   │   │   ├── record_spec.rb
│   │   │   │   └── stream_spec.rb
│   │   │   ├── event_stream_spec.rb
│   │   │   ├── spec_helper.rb
│   │   │   └── support
│   │   │       └── active_record.rb
│   │   └── test.sh
│   ├── gemfile_prefix.rb
│   ├── google_drive
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── google_drive.gemspec
│   │   ├── lib
│   │   │   ├── google_drive
│   │   │   │   ├── client.rb
│   │   │   │   ├── connection.rb
│   │   │   │   ├── connection_exception.rb
│   │   │   │   ├── entry.rb
│   │   │   │   ├── masquerading_exception.rb
│   │   │   │   ├── no_token_error.rb
│   │   │   │   └── workflow_error.rb
│   │   │   └── google_drive.rb
│   │   ├── spec
│   │   │   ├── fixtures
│   │   │   │   └── google_drive
│   │   │   │       └── file_data.json
│   │   │   ├── google_drive
│   │   │   │   ├── client_spec.rb
│   │   │   │   └── connection_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── html_text_helper
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── html_text_helper.gemspec
│   │   ├── lib
│   │   │   └── html_text_helper.rb
│   │   ├── spec
│   │   │   ├── html_text_helper_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── i18n_extraction
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── Rakefile
│   │   ├── i18n_extraction.gemspec
│   │   ├── lib
│   │   │   ├── i18n_extraction
│   │   │   │   ├── i18nliner_extensions.rb
│   │   │   │   └── i18nliner_scope_extensions.rb
│   │   │   └── i18n_extraction.rb
│   │   ├── spec
│   │   │   ├── i18n_extraction
│   │   │   │   └── i18nliner_extensions_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── i18n_tasks
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── Rakefile
│   │   ├── i18n_tasks.gemspec
│   │   ├── lib
│   │   │   ├── i18n_tasks
│   │   │   │   ├── csv_backend.rb
│   │   │   │   ├── environment.rb
│   │   │   │   ├── extract.rb
│   │   │   │   ├── generate_js.rb
│   │   │   │   ├── hash_extensions.rb
│   │   │   │   ├── i18n_import.rb
│   │   │   │   ├── lolcalize.rb
│   │   │   │   └── railtie.rb
│   │   │   ├── i18n_tasks.rb
│   │   │   └── tasks
│   │   │       └── i18n.rake
│   │   ├── spec
│   │   │   ├── i18n_tasks
│   │   │   │   ├── extract_spec.rb
│   │   │   │   ├── generate_js_spec.rb
│   │   │   │   ├── i18n_import_spec.rb
│   │   │   │   └── lolcalize_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── incoming_mail_processor
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── incoming_mail_processor.gemspec
│   │   ├── lib
│   │   │   ├── incoming_mail_processor
│   │   │   │   ├── configurable_timeout.rb
│   │   │   │   ├── deprecated_settings.rb
│   │   │   │   ├── directory_mailbox.rb
│   │   │   │   ├── imap_mailbox.rb
│   │   │   │   ├── incoming_message_processor.rb
│   │   │   │   ├── instrumentation.rb
│   │   │   │   ├── mailbox_account.rb
│   │   │   │   ├── pop3_mailbox.rb
│   │   │   │   ├── settings.rb
│   │   │   │   └── sqs_mailbox.rb
│   │   │   └── incoming_mail_processor.rb
│   │   ├── spec
│   │   │   ├── fixtures
│   │   │   │   ├── expected
│   │   │   │   │   ├── multipart_mixed.eml.html_body
│   │   │   │   │   ├── multipart_mixed.eml.text_body
│   │   │   │   │   ├── multipart_mixed_no_html_part.eml.html_body
│   │   │   │   │   ├── multipart_mixed_no_html_part.eml.text_body
│   │   │   │   │   ├── nested_multipart_sample.eml.html_body
│   │   │   │   │   ├── nested_multipart_sample.eml.text_body
│   │   │   │   │   ├── no_image.eml.html_body
│   │   │   │   │   └── no_image.eml.text_body
│   │   │   │   ├── multipart_mixed.eml
│   │   │   │   ├── multipart_mixed_no_html_part.eml
│   │   │   │   ├── nested_multipart_sample.eml
│   │   │   │   └── no_image.eml
│   │   │   ├── incoming_mail_processor
│   │   │   │   ├── configurable_timeout_spec.rb
│   │   │   │   ├── directory_mailbox_spec.rb
│   │   │   │   ├── imap_mailbox_spec.rb
│   │   │   │   ├── incoming_message_processor_spec.rb
│   │   │   │   ├── instrumentation_spec.rb
│   │   │   │   ├── mailbox_spec_helper.rb
│   │   │   │   ├── pop3_mailbox_spec.rb
│   │   │   │   └── sqs_mailbox_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── json_token
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── Rakefile
│   │   ├── json_token.gemspec
│   │   ├── lib
│   │   │   └── json_token.rb
│   │   ├── spec
│   │   │   ├── json_token_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── legacy_multipart
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── Rakefile
│   │   ├── legacy_multipart.gemspec
│   │   ├── lib
│   │   │   ├── legacy_multipart
│   │   │   │   ├── file_param.rb
│   │   │   │   ├── param.rb
│   │   │   │   ├── post.rb
│   │   │   │   ├── sequenced_stream.rb
│   │   │   │   └── terminator.rb
│   │   │   └── legacy_multipart.rb
│   │   ├── spec
│   │   │   ├── legacy_multipart
│   │   │   │   ├── post_spec.rb
│   │   │   │   └── sequenced_stream_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── live_events
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── Rakefile
│   │   ├── lib
│   │   │   ├── live_events
│   │   │   │   ├── async_worker.rb
│   │   │   │   └── client.rb
│   │   │   └── live_events.rb
│   │   ├── live_events.gemspec
│   │   ├── spec
│   │   │   ├── live_events
│   │   │   │   ├── async_worker_spec.rb
│   │   │   │   └── client_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── lti-advantage
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── LICENSE.txt
│   │   ├── README.md
│   │   ├── Rakefile
│   │   ├── lib
│   │   │   ├── lti_advantage
│   │   │   │   ├── claims
│   │   │   │   │   ├── activity.rb
│   │   │   │   │   ├── asset.rb
│   │   │   │   │   ├── assignment_and_grade_service.rb
│   │   │   │   │   ├── context.rb
│   │   │   │   │   ├── eulaservice.rb
│   │   │   │   │   ├── for_user.rb
│   │   │   │   │   ├── launch_presentation.rb
│   │   │   │   │   ├── lis.rb
│   │   │   │   │   ├── lti1p1.rb
│   │   │   │   │   ├── names_and_roles_service.rb
│   │   │   │   │   ├── platform.rb
│   │   │   │   │   ├── platform_notification_service.rb
│   │   │   │   │   ├── resource_link.rb
│   │   │   │   │   └── submission.rb
│   │   │   │   ├── claims.rb
│   │   │   │   ├── messages
│   │   │   │   │   ├── asset_processor_settings_request.rb
│   │   │   │   │   ├── deep_linking_request.rb
│   │   │   │   │   ├── eula_request.rb
│   │   │   │   │   ├── jwt_message.rb
│   │   │   │   │   ├── login_request.rb
│   │   │   │   │   ├── pns_notice.rb
│   │   │   │   │   ├── report_review_request.rb
│   │   │   │   │   └── resource_link_request.rb
│   │   │   │   ├── messages.rb
│   │   │   │   ├── models
│   │   │   │   │   ├── deep_linking_setting.rb
│   │   │   │   │   └── pns_notice_claim.rb
│   │   │   │   ├── models.rb
│   │   │   │   ├── serializers
│   │   │   │   │   └── jwt_message_serializer.rb
│   │   │   │   ├── serializers.rb
│   │   │   │   ├── type_validator.rb
│   │   │   │   └── version.rb
│   │   │   └── lti_advantage.rb
│   │   ├── lti-advantage.gemspec
│   │   ├── spec
│   │   │   ├── lti_advantage
│   │   │   │   ├── messages
│   │   │   │   │   ├── asset_processor_settings_request_spec.rb
│   │   │   │   │   ├── deep_linking_request_spec.rb
│   │   │   │   │   ├── eula_request_spec.rb
│   │   │   │   │   ├── message_claims_examples.rb
│   │   │   │   │   ├── pns_notice_spec.rb
│   │   │   │   │   ├── report_review_request_spec.rb
│   │   │   │   │   └── resource_link_request_spec.rb
│   │   │   │   ├── models
│   │   │   │   │   ├── deep_linking_setting_spec.rb
│   │   │   │   │   └── pns_notice_claim_spec.rb
│   │   │   │   └── serializers
│   │   │   │       └── jwt_message_serializer_spec.rb
│   │   │   ├── lti_advantage_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── lti_outbound
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── LICENSE.txt
│   │   ├── README.md
│   │   ├── Rakefile
│   │   ├── lib
│   │   │   ├── lti_outbound
│   │   │   │   ├── lti_account.rb
│   │   │   │   ├── lti_assignment.rb
│   │   │   │   ├── lti_consumer_instance.rb
│   │   │   │   ├── lti_context.rb
│   │   │   │   ├── lti_course.rb
│   │   │   │   ├── lti_model.rb
│   │   │   │   ├── lti_role.rb
│   │   │   │   ├── lti_tool.rb
│   │   │   │   ├── lti_user.rb
│   │   │   │   ├── tool_launch.rb
│   │   │   │   └── variable_substitutor.rb
│   │   │   └── lti_outbound.rb
│   │   ├── lti_outbound.gemspec
│   │   ├── spec
│   │   │   ├── lti_outbound
│   │   │   │   ├── lti_account_spec.rb
│   │   │   │   ├── lti_assignment_spec.rb
│   │   │   │   ├── lti_consumer_instance_spec.rb
│   │   │   │   ├── lti_context_spec.rb
│   │   │   │   ├── lti_course_spec.rb
│   │   │   │   ├── lti_model_spec.rb
│   │   │   │   ├── lti_roles_spec.rb
│   │   │   │   ├── lti_tool_spec.rb
│   │   │   │   ├── lti_user_spec.rb
│   │   │   │   ├── tool_launch_spec.rb
│   │   │   │   └── variable_substitutor_spec.rb
│   │   │   ├── shared_examples
│   │   │   │   ├── an_lti_context.rb
│   │   │   │   ├── it_has_an_attribute_setter_and_getter_for.rb
│   │   │   │   └── it_provides_variable_mapping.rb
│   │   │   ├── spec_helper.rb
│   │   │   └── support
│   │   │       └── i18n_monkey_patch.rb
│   │   └── test.sh
│   ├── paginated_collection
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── Rakefile
│   │   ├── lib
│   │   │   ├── paginated_collection
│   │   │   │   ├── collection.rb
│   │   │   │   └── proxy.rb
│   │   │   └── paginated_collection.rb
│   │   ├── paginated_collection.gemspec
│   │   ├── spec
│   │   │   ├── paginated_collection
│   │   │   │   └── paginated_collection_spec.rb
│   │   │   ├── spec_helper.rb
│   │   │   └── support
│   │   │       └── active_record.rb
│   │   └── test.sh
│   ├── plugins
│   │   ├── academic_benchmark
│   │   │   ├── academic_benchmark.gemspec
│   │   │   ├── app
│   │   │   │   └── views
│   │   │   │       └── academic_benchmark
│   │   │   │           └── _plugin_settings.erb
│   │   │   ├── config
│   │   │   │   └── initializers
│   │   │   │       └── zeitwerk.rb
│   │   │   ├── lib
│   │   │   │   ├── academic_benchmark
│   │   │   │   │   ├── ab_gem_extensions
│   │   │   │   │   │   ├── authority.rb
│   │   │   │   │   │   ├── common.rb
│   │   │   │   │   │   ├── document.rb
│   │   │   │   │   │   ├── publication.rb
│   │   │   │   │   │   ├── section.rb
│   │   │   │   │   │   └── standard.rb
│   │   │   │   │   ├── converter.rb
│   │   │   │   │   ├── engine.rb
│   │   │   │   │   ├── outcome_data
│   │   │   │   │   │   ├── base.rb
│   │   │   │   │   │   ├── from_api.rb
│   │   │   │   │   │   └── from_file.rb
│   │   │   │   │   └── outcome_data.rb
│   │   │   │   └── academic_benchmark.rb
│   │   │   └── spec_canvas
│   │   │       ├── academic_benchmark
│   │   │       │   └── converter_spec.rb
│   │   │       ├── academic_benchmark_spec.rb
│   │   │       └── fixtures
│   │   │           ├── api_all_standards_response.json
│   │   │           └── florida_standards.json
│   │   ├── account_reports
│   │   │   ├── account_reports.gemspec
│   │   │   ├── app
│   │   │   │   └── views
│   │   │   │       └── accounts
│   │   │   │           ├── _course_storage_csv_description.html.erb
│   │   │   │           ├── _date_picker_parameter.html.erb
│   │   │   │           ├── _developer_key_report_csv_description.html.erb
│   │   │   │           ├── _eportfolio_report_csv_description.html.erb
│   │   │   │           ├── _eportfolio_report_csv_parameters.html.erb
│   │   │   │           ├── _grade_export_csv_description.html.erb
│   │   │   │           ├── _grade_export_csv_parameters.html.erb
│   │   │   │           ├── _include_deleted_parameter.html.erb
│   │   │   │           ├── _include_only_deleted_parameter.html.erb
│   │   │   │           ├── _last_enrollment_activity_csv_description.html.erb
│   │   │   │           ├── _last_user_access_csv_description.html.erb
│   │   │   │           ├── _lti_report_csv_description.html.erb
│   │   │   │           ├── _mgp_grade_export_csv_description.html.erb
│   │   │   │           ├── _mgp_grade_export_csv_parameters.html.erb
│   │   │   │           ├── _outcome_export_csv_description.html.erb
│   │   │   │           ├── _outcome_results_csv_description.html.erb
│   │   │   │           ├── _outcome_results_csv_parameters.html.erb
│   │   │   │           ├── _provisioning_csv_description.html.erb
│   │   │   │           ├── _provisioning_csv_parameters.html.erb
│   │   │   │           ├── _public_courses_csv_description.html.erb
│   │   │   │           ├── _recently_deleted_courses_csv_description.html.erb
│   │   │   │           ├── _sis_export_csv_description.html.erb
│   │   │   │           ├── _sis_export_csv_parameters.html.erb
│   │   │   │           ├── _student_assignment_outcome_map_csv_description.html.erb
│   │   │   │           ├── _students_with_no_submissions_csv_description.html.erb
│   │   │   │           ├── _students_with_no_submissions_csv_parameters.html.erb
│   │   │   │           ├── _term_and_date_picker_parameters.html.erb
│   │   │   │           ├── _term_and_date_pickers_parameters.html.erb
│   │   │   │           ├── _term_selector_parameters.html.erb
│   │   │   │           ├── _terms_parameters.html.erb
│   │   │   │           ├── _unpublished_courses_csv_description.html.erb
│   │   │   │           ├── _unused_courses_csv_description.html.erb
│   │   │   │           ├── _user_access_tokens_csv_description.html.erb
│   │   │   │           └── _zero_activity_csv_description.html.erb
│   │   │   ├── lib
│   │   │   │   ├── account_reports
│   │   │   │   │   ├── course_reports.rb
│   │   │   │   │   ├── default.rb
│   │   │   │   │   ├── developer_key_reports.rb
│   │   │   │   │   ├── engine.rb
│   │   │   │   │   ├── eportfolio_reports.rb
│   │   │   │   │   ├── grade_reports.rb
│   │   │   │   │   ├── improved_outcome_reports
│   │   │   │   │   │   ├── base_outcome_report.rb
│   │   │   │   │   │   ├── outcome_results_report.rb
│   │   │   │   │   │   └── student_assignment_outcome_map_report.rb
│   │   │   │   │   ├── lti_reports.rb
│   │   │   │   │   ├── outcome_export.rb
│   │   │   │   │   ├── outcome_reports.rb
│   │   │   │   │   ├── report_helper.rb
│   │   │   │   │   ├── sis_exporter.rb
│   │   │   │   │   ├── student_reports.rb
│   │   │   │   │   └── version.rb
│   │   │   │   └── account_reports.rb
│   │   │   └── spec_canvas
│   │   │       ├── account_report_spec.rb
│   │   │       ├── course_reports_spec.rb
│   │   │       ├── developer_key_reports_spec.rb
│   │   │       ├── eportfolio_reports_spec.rb
│   │   │       ├── grade_reports_spec.rb
│   │   │       ├── improved_outcome_reports
│   │   │       │   ├── base_outcome_report_spec.rb
│   │   │       │   ├── outcome_results_report_spec.rb
│   │   │       │   ├── shared
│   │   │       │   │   ├── improved_outcome_reports_spec_helpers.rb
│   │   │       │   │   ├── setup.rb
│   │   │       │   │   └── shared_examples.rb
│   │   │       │   └── student_assignment_outcome_map_report_spec.rb
│   │   │       ├── integrations
│   │   │       │   └── account_spec.rb
│   │   │       ├── lti_reports_spec.rb
│   │   │       ├── outcome_export_spec.rb
│   │   │       ├── outcome_reports_spec.rb
│   │   │       ├── report_helper_spec.rb
│   │   │       ├── report_spec_helper.rb
│   │   │       ├── sis_provisioning_reports_spec.rb
│   │   │       └── student_reports_spec.rb
│   │   ├── moodle_importer
│   │   │   ├── lib
│   │   │   │   ├── moodle_importer
│   │   │   │   │   ├── converter.rb
│   │   │   │   │   ├── engine.rb
│   │   │   │   │   └── version.rb
│   │   │   │   └── moodle_importer.rb
│   │   │   ├── moodle_importer.gemspec
│   │   │   └── spec_canvas
│   │   │       ├── fixtures
│   │   │       │   ├── moodle_backup_1_9.zip
│   │   │       │   └── moodle_backup_2.zip
│   │   │       ├── moodle1_9_converter_spec.rb
│   │   │       └── moodle2_converter_spec.rb
│   │   ├── qti_exporter
│   │   │   ├── Readme.txt
│   │   │   ├── app
│   │   │   │   └── views
│   │   │   │       └── plugins
│   │   │   │           └── _qti_converter_settings.html.erb
│   │   │   ├── config
│   │   │   │   └── initializers
│   │   │   │       └── zeitwerk.rb
│   │   │   ├── lib
│   │   │   │   ├── canvas
│   │   │   │   │   ├── migration
│   │   │   │   │   │   └── worker
│   │   │   │   │   │       └── qti_worker.rb
│   │   │   │   │   └── plugins
│   │   │   │   │       └── validators
│   │   │   │   │           └── qti_plugin_validator.rb
│   │   │   │   ├── qti
│   │   │   │   │   ├── assessment_item_converter.rb
│   │   │   │   │   ├── assessment_test_converter.rb
│   │   │   │   │   ├── associate_interaction.rb
│   │   │   │   │   ├── calculated_interaction.rb
│   │   │   │   │   ├── choice_interaction.rb
│   │   │   │   │   ├── converter.rb
│   │   │   │   │   ├── extended_text_interaction.rb
│   │   │   │   │   ├── fill_in_the_blank.rb
│   │   │   │   │   ├── flavors.rb
│   │   │   │   │   ├── html_helper.rb
│   │   │   │   │   ├── numeric_interaction.rb
│   │   │   │   │   ├── order_interaction.rb
│   │   │   │   │   ├── question_type_educated_guesser.rb
│   │   │   │   │   └── respondus_settings.rb
│   │   │   │   ├── qti.rb
│   │   │   │   ├── qti_exporter
│   │   │   │   │   ├── engine.rb
│   │   │   │   │   └── version.rb
│   │   │   │   └── qti_exporter.rb
│   │   │   ├── qti_exporter.gemspec
│   │   │   └── spec_canvas
│   │   │       ├── fixtures
│   │   │       │   ├── angel
│   │   │       │   │   └── questions
│   │   │       │   │       ├── assessment.xml
│   │   │       │   │       ├── essay.xml
│   │   │       │   │       ├── multiple_answer.xml
│   │   │       │   │       ├── multiple_choice.xml
│   │   │       │   │       ├── p_essay.xml
│   │   │       │   │       ├── p_fib.xml
│   │   │       │   │       ├── p_likert_scale.xml
│   │   │       │   │       ├── p_matching.xml
│   │   │       │   │       ├── p_multiple_answers.xml
│   │   │       │   │       ├── p_multiple_choice.xml
│   │   │       │   │       ├── p_offline.xml
│   │   │       │   │       ├── p_ordering.xml
│   │   │       │   │       ├── p_short_answer.xml
│   │   │       │   │       ├── p_short_answer_as_essay.xml
│   │   │       │   │       ├── p_true_false.xml
│   │   │       │   │       └── true_false.xml
│   │   │       │   ├── bb8
│   │   │       │   │   └── questions
│   │   │       │   │       ├── assessment.xml
│   │   │       │   │       ├── calculated_complex.xml
│   │   │       │   │       ├── calculated_numeric.xml
│   │   │       │   │       ├── calculated_simple.xml
│   │   │       │   │       ├── either_or_agree_disagree.xml
│   │   │       │   │       ├── either_or_right_wrong.xml
│   │   │       │   │       ├── either_or_true_false.xml
│   │   │       │   │       ├── either_or_yes_no.xml
│   │   │       │   │       ├── essay.xml
│   │   │       │   │       ├── file_upload.xml
│   │   │       │   │       ├── fill_in_the_blank.xml
│   │   │       │   │       ├── fill_in_the_blank_plus.xml
│   │   │       │   │       ├── hot_spot.xml
│   │   │       │   │       ├── jumbled_sentence.xml
│   │   │       │   │       ├── likert.xml
│   │   │       │   │       ├── matching.xml
│   │   │       │   │       ├── multiple_answer.xml
│   │   │       │   │       ├── multiple_choice.xml
│   │   │       │   │       ├── multiple_choice_blank_answers.xml
│   │   │       │   │       ├── ordering.xml
│   │   │       │   │       ├── quiz_bowl.xml
│   │   │       │   │       ├── short_response.xml
│   │   │       │   │       ├── true_false.xml
│   │   │       │   │       └── with_image.xml
│   │   │       │   ├── bb9
│   │   │       │   │   ├── group_with_selection_references.xml
│   │   │       │   │   └── questions
│   │   │       │   │       ├── matching.xml
│   │   │       │   │       ├── matching2.xml
│   │   │       │   │       ├── matching3.xml
│   │   │       │   │       ├── minus_one.xml
│   │   │       │   │       ├── multiple_answers.xml
│   │   │       │   │       └── true_false.xml
│   │   │       │   ├── bb_vista
│   │   │       │   │   ├── questions
│   │   │       │   │   │   ├── mc.xml
│   │   │       │   │   │   ├── no_response_id.xml
│   │   │       │   │   │   ├── short_to_fimb.xml
│   │   │       │   │   │   └── true_false.xml
│   │   │       │   │   └── vista_archive.zip
│   │   │       │   ├── bbultra
│   │   │       │   │   └── questions
│   │   │       │   │       ├── multiple_choice.xml
│   │   │       │   │       └── text_only_question.xml
│   │   │       │   ├── canvas
│   │   │       │   │   ├── calculated.xml
│   │   │       │   │   ├── calculated_simple.xml
│   │   │       │   │   ├── calculated_without_formula.xml
│   │   │       │   │   ├── empty_assessment.xml.qti
│   │   │       │   │   ├── empty_assessment_no_ident.xml
│   │   │       │   │   ├── essay.xml
│   │   │       │   │   ├── essay2.xml
│   │   │       │   │   ├── external_bank.xml
│   │   │       │   │   ├── fimb.xml
│   │   │       │   │   ├── matching.xml
│   │   │       │   │   ├── mc_text_answers.xml
│   │   │       │   │   ├── multiple_answers.xml
│   │   │       │   │   ├── multiple_choice.xml
│   │   │       │   │   ├── multiple_choice_html.xml
│   │   │       │   │   ├── multiple_dropdowns.xml
│   │   │       │   │   ├── numerical.xml
│   │   │       │   │   ├── short_answer.xml
│   │   │       │   │   ├── text_only.xml
│   │   │       │   │   ├── true_false.xml
│   │   │       │   │   └── true_false2.xml
│   │   │       │   ├── canvas_respondus_question_types.zip
│   │   │       │   ├── cengage
│   │   │       │   │   └── questions
│   │   │       │   │       ├── group_to_bank.xml
│   │   │       │   │       └── question_with_bank.xml
│   │   │       │   ├── d2l
│   │   │       │   │   ├── assessment.xml
│   │   │       │   │   ├── assessment_references.xml
│   │   │       │   │   ├── fib.xml
│   │   │       │   │   ├── long_answer.xml
│   │   │       │   │   ├── matching.xml
│   │   │       │   │   ├── math.xml
│   │   │       │   │   ├── multi_select.xml
│   │   │       │   │   ├── multiple_choice.xml
│   │   │       │   │   ├── multiple_short.xml
│   │   │       │   │   ├── no_condition.xml
│   │   │       │   │   ├── ordering.xml
│   │   │       │   │   ├── short_answer.xml
│   │   │       │   │   ├── simple_math.xml
│   │   │       │   │   ├── text_only.xml
│   │   │       │   │   └── true_false.xml
│   │   │       │   ├── html_sanitization
│   │   │       │   │   └── questions
│   │   │       │   │       ├── escaped
│   │   │       │   │       │   ├── angel_essay.xml
│   │   │       │   │       │   ├── bracket_attribute.xml
│   │   │       │   │       │   ├── matching.xml
│   │   │       │   │       │   ├── multiple_answer.xml
│   │   │       │   │       │   ├── multiple_choice.xml
│   │   │       │   │       │   └── unmatched_brackets.xml
│   │   │       │   │       └── nodes
│   │   │       │   │           ├── essay.xml
│   │   │       │   │           ├── matching.xml
│   │   │       │   │           ├── multiple_answer.xml
│   │   │       │   │           └── multiple_choice.xml
│   │   │       │   ├── qti
│   │   │       │   │   ├── canvas_qti.zip
│   │   │       │   │   ├── inline_choice_interaction.xml
│   │   │       │   │   ├── inline_choice_interaction_2.xml
│   │   │       │   │   ├── lti_qti_new_quizzes.zip
│   │   │       │   │   ├── manifest_qti_1_2.xml
│   │   │       │   │   ├── manifest_qti_2_1.xml
│   │   │       │   │   ├── manifest_qti_2_ns.xml
│   │   │       │   │   ├── more_terrible_qti.xml
│   │   │       │   │   ├── plain_qti.zip
│   │   │       │   │   ├── qti_2_1.zip
│   │   │       │   │   ├── sanitize_metadata.xml
│   │   │       │   │   ├── terrible_qti.xml
│   │   │       │   │   ├── weird_html.xml
│   │   │       │   │   └── zero_point_mc.xml
│   │   │       │   ├── qti2_conformance
│   │   │       │   │   ├── VE_IP_01.zip
│   │   │       │   │   ├── VE_IP_02.zip
│   │   │       │   │   ├── VE_IP_03.zip
│   │   │       │   │   ├── VE_IP_04.zip
│   │   │       │   │   ├── VE_IP_05.zip
│   │   │       │   │   ├── VE_IP_06.zip
│   │   │       │   │   ├── VE_IP_07.zip
│   │   │       │   │   ├── VE_IP_11.zip
│   │   │       │   │   ├── VE_TP_01.zip
│   │   │       │   │   ├── VE_TP_02.zip
│   │   │       │   │   ├── VE_TP_03.zip
│   │   │       │   │   ├── VE_TP_04.zip
│   │   │       │   │   ├── VE_TP_05.zip
│   │   │       │   │   └── VE_TP_06.zip
│   │   │       │   ├── respondus
│   │   │       │   │   ├── questions
│   │   │       │   │   │   ├── algorithm_question.xml
│   │   │       │   │   │   ├── assessment.xml
│   │   │       │   │   │   ├── essay.xml
│   │   │       │   │   │   ├── fill_in_the_blank.xml
│   │   │       │   │   │   ├── matching.xml
│   │   │       │   │   │   ├── multiple_choice.xml
│   │   │       │   │   │   ├── multiple_response.xml
│   │   │       │   │   │   ├── multiple_response_partial.xml
│   │   │       │   │   │   └── true_false.xml
│   │   │       │   │   └── zero_point_mc.xml
│   │   │       │   └── spec-canvas-1.zip
│   │   │       ├── lib
│   │   │       │   ├── qti
│   │   │       │   │   ├── angel_cc_questions_spec.rb
│   │   │       │   │   ├── angel_propietery_questions_spec.rb
│   │   │       │   │   ├── assessment_test_converter_spec.rb
│   │   │       │   │   ├── bb8_questions_spec.rb
│   │   │       │   │   ├── bb9_questions_spec.rb
│   │   │       │   │   ├── canvas_questions_spec.rb
│   │   │       │   │   ├── cengage_questions_spec.rb
│   │   │       │   │   ├── d2l_questions_spec.rb
│   │   │       │   │   ├── html_sanitization_spec.rb
│   │   │       │   │   ├── qti_1_2_zip_spec.rb
│   │   │       │   │   ├── qti_2_1_conformance_spec.rb
│   │   │       │   │   ├── qti_2_1_zip_spec.rb
│   │   │       │   │   ├── qti_items_spec.rb
│   │   │       │   │   ├── respondus_spec.rb
│   │   │       │   │   └── vista_questions_spec.rb
│   │   │       │   └── qti_migration_tool_spec.rb
│   │   │       ├── qti_exporter_spec.rb
│   │   │       └── qti_helper.rb
│   │   ├── respondus_soap_endpoint
│   │   │   ├── Gemfile.d
│   │   │   │   └── _before.rb
│   │   │   ├── app
│   │   │   │   └── views
│   │   │   │       └── respondus_soap_endpoint
│   │   │   │           └── _plugin_settings.html.erb
│   │   │   ├── lib
│   │   │   │   ├── respondus_soap_endpoint
│   │   │   │   │   ├── api_port.rb
│   │   │   │   │   ├── engine.rb
│   │   │   │   │   ├── middleware.rb
│   │   │   │   │   ├── plugin_validator.rb
│   │   │   │   │   ├── urn_RespondusAPI.rb
│   │   │   │   │   ├── urn_RespondusAPIMappingRegistry.rb
│   │   │   │   │   ├── urn_RespondusAPIServant.rb
│   │   │   │   │   └── version.rb
│   │   │   │   ├── respondus_soap_endpoint.rb
│   │   │   │   └── soap
│   │   │   │       └── property
│   │   │   ├── respondus_soap_endpoint.gemspec
│   │   │   └── spec_canvas
│   │   │       └── integration
│   │   │           └── respondus_endpoint_spec.rb
│   │   └── simply_versioned
│   │       ├── CHANGES
│   │       ├── MIT-LICENSE
│   │       ├── README
│   │       ├── lib
│   │       │   ├── simply_versioned
│   │       │   │   ├── gem_version.rb
│   │       │   │   └── version.rb
│   │       │   └── simply_versioned.rb
│   │       ├── simply_versioned.gemspec
│   │       └── spec_canvas
│   │           └── simply_versioned_spec.rb
│   ├── request_context
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── README.md
│   │   ├── lib
│   │   │   ├── request_context
│   │   │   │   ├── generator.rb
│   │   │   │   └── session.rb
│   │   │   └── request_context.rb
│   │   ├── request_context.gemspec
│   │   ├── spec
│   │   │   ├── request_context
│   │   │   │   ├── generator_spec.rb
│   │   │   │   └── session_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── rubocop-canvas
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── README.md
│   │   ├── Rakefile
│   │   ├── config
│   │   │   └── default.yml
│   │   ├── lib
│   │   │   ├── rubocop_canvas
│   │   │   │   ├── cops
│   │   │   │   │   ├── datafixup
│   │   │   │   │   │   ├── eager_load.rb
│   │   │   │   │   │   └── strand_downstream_jobs.rb
│   │   │   │   │   ├── lint
│   │   │   │   │   │   ├── no_file_utils_rm_rf.rb
│   │   │   │   │   │   └── no_sleep.rb
│   │   │   │   │   ├── migration
│   │   │   │   │   │   ├── add_foreign_key.rb
│   │   │   │   │   │   ├── add_index.rb
│   │   │   │   │   │   ├── change_column.rb
│   │   │   │   │   │   ├── change_column_null.rb
│   │   │   │   │   │   ├── data_fixup.rb
│   │   │   │   │   │   ├── delay.rb
│   │   │   │   │   │   ├── execute.rb
│   │   │   │   │   │   ├── function_unqualified_table.rb
│   │   │   │   │   │   ├── id_column.rb
│   │   │   │   │   │   ├── non_transactional.rb
│   │   │   │   │   │   ├── predeploy.rb
│   │   │   │   │   │   ├── primary_key.rb
│   │   │   │   │   │   ├── remove_column.rb
│   │   │   │   │   │   ├── rename_table.rb
│   │   │   │   │   │   ├── root_account_id.rb
│   │   │   │   │   │   └── set_replica_identity_in_separate_transaction.rb
│   │   │   │   │   ├── specs
│   │   │   │   │   │   ├── ensure_spec_extension.rb
│   │   │   │   │   │   ├── no_before_once_stubs.rb
│   │   │   │   │   │   ├── no_disable_implicit_wait.rb
│   │   │   │   │   │   ├── no_execute_script.rb
│   │   │   │   │   │   ├── no_no_such_element_error.rb
│   │   │   │   │   │   ├── no_selenium_web_driver_wait.rb
│   │   │   │   │   │   ├── no_skip_without_ticket.rb
│   │   │   │   │   │   ├── no_strftime.rb
│   │   │   │   │   │   ├── no_wait_for_no_such_element.rb
│   │   │   │   │   │   ├── prefer_f_over_fj.rb
│   │   │   │   │   │   ├── scope_helper_modules.rb
│   │   │   │   │   │   └── scope_includes.rb
│   │   │   │   │   └── style
│   │   │   │   │       └── concat_array_literals.rb
│   │   │   │   ├── helpers
│   │   │   │   │   ├── consts.rb
│   │   │   │   │   ├── current_def.rb
│   │   │   │   │   ├── file_meta.rb
│   │   │   │   │   ├── indifferent.rb
│   │   │   │   │   ├── migration_tags.rb
│   │   │   │   │   ├── new_tables.rb
│   │   │   │   │   └── non_transactional.rb
│   │   │   │   └── version.rb
│   │   │   └── rubocop_canvas.rb
│   │   ├── rubocop-canvas.gemspec
│   │   ├── spec
│   │   │   ├── rubocop
│   │   │   │   ├── canvas
│   │   │   │   │   └── migration_tags_spec.rb
│   │   │   │   └── cop
│   │   │   │       ├── datafixup
│   │   │   │       │   ├── eager_load_spec.rb
│   │   │   │       │   └── strand_downstream_jobs_spec.rb
│   │   │   │       ├── lint
│   │   │   │       │   ├── no_file_utils_rm_rf_spec.rb
│   │   │   │       │   └── no_sleep_spec.rb
│   │   │   │       ├── migration
│   │   │   │       │   ├── add_foreign_key_spec.rb
│   │   │   │       │   ├── add_index_spec.rb
│   │   │   │       │   ├── change_column_null_spec.rb
│   │   │   │       │   ├── change_column_spec.rb
│   │   │   │       │   ├── data_fixup_spec.rb
│   │   │   │       │   ├── delay_spec.rb
│   │   │   │       │   ├── execute_spec.rb
│   │   │   │       │   ├── function_unqualified_table_spec.rb
│   │   │   │       │   ├── id_column_spec.rb
│   │   │   │       │   ├── non_transactional_spec.rb
│   │   │   │       │   ├── predeploy_spec.rb
│   │   │   │       │   ├── primary_key_spec.rb
│   │   │   │       │   ├── remove_column_spec.rb
│   │   │   │       │   ├── rename_table_spec.rb
│   │   │   │       │   ├── root_account_id_spec.rb
│   │   │   │       │   └── set_replica_identity_in_separate_transaction_spec.rb
│   │   │   │       └── specs
│   │   │   │           ├── ensure_spec_extension_spec.rb
│   │   │   │           ├── no_before_once_stubs_spec.rb
│   │   │   │           ├── no_disable_implicit_wait_spec.rb
│   │   │   │           ├── no_execute_script_spec.rb
│   │   │   │           ├── no_no_such_element_error_spec.rb
│   │   │   │           ├── no_selenium_web_driver_wait_spec.rb
│   │   │   │           ├── no_skip_without_ticket_spec.rb
│   │   │   │           ├── no_strftime_spec.rb
│   │   │   │           ├── no_wait_for_no_such_element_spec.rb
│   │   │   │           ├── prefer_f_over_fj_spec.rb
│   │   │   │           ├── scope_helper_modules_spec.rb
│   │   │   │           └── scope_includes_spec.rb
│   │   │   └── spec_helper.rb
│   │   └── test.sh
│   ├── stringify_ids
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── lib
│   │   │   └── stringify_ids.rb
│   │   ├── spec
│   │   │   ├── spec_helper.rb
│   │   │   └── stringify_ids_spec.rb
│   │   ├── stringify_ids.gemspec
│   │   └── test.sh
│   ├── tatl_tael
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── README.md
│   │   ├── Rakefile
│   │   ├── config
│   │   │   └── default.yml
│   │   ├── lib
│   │   │   ├── tatl_tael
│   │   │   │   ├── linters
│   │   │   │   │   ├── by_role_linter.rb
│   │   │   │   │   ├── copyright_linter.rb
│   │   │   │   │   ├── ruby_specs_linter.rb
│   │   │   │   │   ├── selenium_specs_linter.rb
│   │   │   │   │   ├── simple
│   │   │   │   │   │   ├── jsx_specs_linter.rb
│   │   │   │   │   │   ├── new_erb_linter.rb
│   │   │   │   │   │   └── public_js_specs_linter.rb
│   │   │   │   │   └── simple_linter.rb
│   │   │   │   └── linters.rb
│   │   │   └── tatl_tael.rb
│   │   ├── spec
│   │   │   ├── lib
│   │   │   │   └── tatl_tael
│   │   │   │       ├── linters
│   │   │   │       │   ├── by_role_linter_spec.rb
│   │   │   │       │   ├── copyright_linter_spec.rb
│   │   │   │       │   ├── fixtures
│   │   │   │       │   │   ├── by_role_linter
│   │   │   │       │   │   │   └── __tests__
│   │   │   │       │   │   │       ├── fake_queries.js
│   │   │   │       │   │   │       ├── valid.js
│   │   │   │       │   │   │       ├── valid.jsx
│   │   │   │       │   │   │       ├── valid.ts
│   │   │   │       │   │   │       └── valid.tsx
│   │   │   │       │   │   └── copyright_linter
│   │   │   │       │   │       ├── js
│   │   │   │       │   │       │   ├── invalid__missing--auto-corrected.js
│   │   │   │       │   │       │   ├── invalid__missing-present--auto-corrected.js
│   │   │   │       │   │       │   ├── invalid__missing-present.js
│   │   │   │       │   │       │   ├── invalid__missing.js
│   │   │   │       │   │       │   └── valid.js
│   │   │   │       │   │       └── rb
│   │   │   │       │   │           ├── invalid__bad-ending-token--raises--auto-corrected.rb
│   │   │   │       │   │           ├── invalid__bad-ending-token--raises.rb
│   │   │   │       │   │           ├── invalid__missing--auto-corrected.rb
│   │   │   │       │   │           ├── invalid__missing-with-encoding--auto-corrected.rb
│   │   │   │       │   │           ├── invalid__missing-with-encoding.rb
│   │   │   │       │   │           ├── invalid__missing.rb
│   │   │   │       │   │           ├── invalid__wrong-holder--auto-corrected.rb
│   │   │   │       │   │           ├── invalid__wrong-holder.rb
│   │   │   │       │   │           ├── valid.rb
│   │   │   │       │   │           ├── valid__encoding-emacs.rb
│   │   │   │       │   │           └── valid__encoding.rb
│   │   │   │       │   ├── ruby_specs_linter_spec.rb
│   │   │   │       │   ├── selenium_specs_linter_spec.rb
│   │   │   │       │   ├── shared_constants.rb
│   │   │   │       │   ├── shared_linter_examples.rb
│   │   │   │       │   ├── simple
│   │   │   │       │   │   ├── jsx_specs_linter_spec.rb
│   │   │   │       │   │   ├── new_erb_linter_spec.rb
│   │   │   │       │   │   └── public_js_specs_linter_spec.rb
│   │   │   │       │   └── simple_linter_spec.rb
│   │   │   │       └── linters_spec.rb
│   │   │   └── spec_helper.rb
│   │   ├── tatl_tael.gemspec
│   │   └── test.sh
│   ├── test_all_gems.sh
│   ├── turnitin_api
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── LICENSE.txt
│   │   ├── README.md
│   │   ├── Rakefile
│   │   ├── bin
│   │   │   ├── console
│   │   │   └── setup
│   │   ├── lib
│   │   │   ├── turnitin_api
│   │   │   │   ├── outcomes_response_transformer.rb
│   │   │   │   └── version.rb
│   │   │   └── turnitin_api.rb
│   │   ├── spec
│   │   │   ├── fixtures
│   │   │   │   └── outcome_detailed_response.json
│   │   │   ├── outcomes_response_transformer_spec.rb
│   │   │   ├── spec_helper.rb
│   │   │   └── turnitin_spec.rb
│   │   ├── test.sh
│   │   └── turnitin_api.gemspec
│   ├── utf8_cleaner
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── Rakefile
│   │   ├── lib
│   │   │   └── utf8_cleaner.rb
│   │   ├── spec
│   │   │   ├── spec_helper.rb
│   │   │   └── utf8_cleaner_spec.rb
│   │   ├── test.sh
│   │   └── utf8_cleaner.gemspec
│   └── workflow
│       ├── Gemfile
│       ├── Gemfile.lock
│       ├── lib
│       │   └── workflow.rb
│       └── workflow.gemspec
├── gulpfile.js
├── hooks
│   └── pre-commit
├── inst-cli
│   ├── doc
│   │   └── docker
│   │       └── developing_with_docker.md
│   └── docker-compose
│       ├── config
│       │   ├── domain.yml
│       │   ├── dynamic_settings.yml.erb
│       │   └── redis.yml
│       ├── docker-compose.local.dev.yml
│       ├── mailcatcher.override.yml
│       ├── pgweb.override.yml
│       ├── rce-api.override.yml
│       ├── rspack-hmr.override.yml
│       ├── s3.override.yml
│       └── selenium.override.yml
├── issue_template.md
├── jest
│   ├── MockBroadcastChannel.ts
│   ├── coffeeTransformer.js
│   ├── environmentWrapper.js
│   ├── etc
│   │   └── ForceFailure.js
│   ├── handlebarsTransformer.js
│   ├── imageMock.js
│   ├── jest-setup.js
│   ├── logPlaygroundURLOnFailure.js
│   ├── rawLoader.js
│   ├── stubInstUi.js
│   └── styleMock.js
├── jest.config.js
├── lib
│   ├── account_services.rb
│   ├── address_book
│   │   ├── base.rb
│   │   ├── caching.rb
│   │   ├── empty.rb
│   │   ├── messageable_user.rb
│   │   ├── performance_tap.rb
│   │   └── service.rb
│   ├── address_book.rb
│   ├── anonymity.rb
│   ├── api
│   │   ├── errors.rb
│   │   ├── html
│   │   │   ├── content.rb
│   │   │   ├── link.rb
│   │   │   ├── media_tag.rb
│   │   │   ├── track_tag.rb
│   │   │   └── url_proxy.rb
│   │   └── v1
│   │       ├── account.rb
│   │       ├── account_calendar.rb
│   │       ├── account_notifications.rb
│   │       ├── account_report.rb
│   │       ├── admin.rb
│   │       ├── api_context.rb
│   │       ├── assessment_request.rb
│   │       ├── assignment.rb
│   │       ├── assignment_group.rb
│   │       ├── assignment_override.rb
│   │       ├── attachment.rb
│   │       ├── authentication_event.rb
│   │       ├── authentication_provider.rb
│   │       ├── avatar.rb
│   │       ├── block_editor_template.rb
│   │       ├── calendar_event.rb
│   │       ├── collaboration.rb
│   │       ├── collaborator.rb
│   │       ├── comm_message.rb
│   │       ├── communication_channel.rb
│   │       ├── conferences.rb
│   │       ├── content_export.rb
│   │       ├── content_migration.rb
│   │       ├── content_share.rb
│   │       ├── context.rb
│   │       ├── context_module.rb
│   │       ├── conversation.rb
│   │       ├── course.rb
│   │       ├── course_event.rb
│   │       ├── course_json.rb
│   │       ├── course_report.rb
│   │       ├── custom_gradebook_column.rb
│   │       ├── developer_key.rb
│   │       ├── discussion_topics.rb
│   │       ├── enrollment_term.rb
│   │       ├── eportfolio.rb
│   │       ├── epub_export.rb
│   │       ├── external_feeds.rb
│   │       ├── external_tools.rb
│   │       ├── favorite.rb
│   │       ├── feature_flag.rb
│   │       ├── folders.rb
│   │       ├── grade_change_event.rb
│   │       ├── gradebook_history.rb
│   │       ├── grading_standard.rb
│   │       ├── group.rb
│   │       ├── group_category.rb
│   │       ├── history_entry.rb
│   │       ├── json.rb
│   │       ├── learning_object_dates.rb
│   │       ├── locked.rb
│   │       ├── lti
│   │       │   ├── context_control.rb
│   │       │   ├── deployment.rb
│   │       │   ├── overlay.rb
│   │       │   ├── overlay_version.rb
│   │       │   ├── registration.rb
│   │       │   ├── registration_account_binding.rb
│   │       │   └── resource_link.rb
│   │       ├── master_courses.rb
│   │       ├── media_object.rb
│   │       ├── media_track.rb
│   │       ├── moderation_grader.rb
│   │       ├── module_assignment_override.rb
│   │       ├── notification_policy.rb
│   │       ├── observer_alert.rb
│   │       ├── observer_alert_threshold.rb
│   │       ├── outcome.rb
│   │       ├── outcome_import.rb
│   │       ├── outcome_proficiency.rb
│   │       ├── outcome_results.rb
│   │       ├── page_view.rb
│   │       ├── planner_item.rb
│   │       ├── planner_note.rb
│   │       ├── planner_override.rb
│   │       ├── plugin.rb
│   │       ├── post_grades_status.rb
│   │       ├── preview_html.rb
│   │       ├── progress.rb
│   │       ├── pseudonym.rb
│   │       ├── quiz.rb
│   │       ├── quiz_group.rb
│   │       ├── quiz_ip_filter.rb
│   │       ├── quiz_question.rb
│   │       ├── quiz_submission.rb
│   │       ├── quiz_submission_question.rb
│   │       ├── quizzes_next
│   │       │   └── quiz.rb
│   │       ├── role.rb
│   │       ├── rubric.rb
│   │       ├── rubric_assessment.rb
│   │       ├── rubric_association.rb
│   │       ├── search_result.rb
│   │       ├── section.rb
│   │       ├── section_enrollments.rb
│   │       ├── sis_assignment.rb
│   │       ├── sis_import.rb
│   │       ├── sis_import_error.rb
│   │       ├── stream_item.rb
│   │       ├── submission.rb
│   │       ├── submission_comment.rb
│   │       ├── tab.rb
│   │       ├── todo_item.rb
│   │       ├── token.rb
│   │       ├── usage_rights.rb
│   │       ├── user.rb
│   │       ├── user_profile.rb
│   │       ├── web_zip_export.rb
│   │       └── wiki_page.rb
│   ├── api.rb
│   ├── api_route_set.rb
│   ├── app_center
│   │   └── app_api.rb
│   ├── asset_signature.rb
│   ├── assignment_override_applicator.rb
│   ├── assignment_util.rb
│   ├── atom_feed_helper.rb
│   ├── authentication_methods
│   │   └── inst_access_token.rb
│   ├── authentication_methods.rb
│   ├── base
│   │   ├── active_record
│   │   │   └── cache_register.rb
│   │   ├── active_support
│   │   │   ├── cache
│   │   │   │   ├── delif.lua
│   │   │   │   ├── ha_store.rb
│   │   │   │   ├── safe_redis_race_condition.rb
│   │   │   │   └── zonal_redis_cache_store.rb
│   │   │   └── cache_register.rb
│   │   ├── api_scope_mapper_fallback.rb
│   │   ├── canvas
│   │   │   ├── cache
│   │   │   │   ├── debounced_clear.lua
│   │   │   │   ├── fallback_expiration_cache.rb
│   │   │   │   ├── fallback_memory_cache.rb
│   │   │   │   └── local_redis_cache.rb
│   │   │   ├── credentials.rb
│   │   │   ├── plugin.rb
│   │   │   ├── plugins.rb
│   │   │   ├── reloader.rb
│   │   │   ├── vault
│   │   │   │   ├── aws_credential_provider.rb
│   │   │   │   └── file_client.rb
│   │   │   └── vault.rb
│   │   ├── canvas.rb
│   │   ├── csv_with_i18n.rb
│   │   ├── dynamic_settings_initializer.rb
│   │   ├── local_cache.rb
│   │   ├── multi_cache.rb
│   │   ├── open_object.rb
│   │   ├── request_cache.rb
│   │   └── temp_cache.rb
│   ├── basic_lti
│   │   ├── basic_outcomes.rb
│   │   ├── errors.rb
│   │   ├── quizzes_next_lti_response.rb
│   │   ├── quizzes_next_submission_reverter.rb
│   │   ├── quizzes_next_versioned_submission.rb
│   │   └── sourcedid.rb
│   ├── basic_lti.rb
│   ├── brand_account_chain_resolver.rb
│   ├── brand_config_helpers.rb
│   ├── brand_config_regenerator.rb
│   ├── brandable_css.rb
│   ├── browser_support.rb
│   ├── canvadocs
│   │   └── session.rb
│   ├── canvadocs.rb
│   ├── canvas
│   │   ├── account_cacher.rb
│   │   ├── active_record
│   │   │   └── migration
│   │   │       └── defer_foreign_keys.rb
│   │   ├── apm
│   │   │   ├── inst_jobs
│   │   │   │   └── plugin.rb
│   │   │   └── stub_tracer.rb
│   │   ├── apm.rb
│   │   ├── aws.rb
│   │   ├── aws_credential_provider.rb
│   │   ├── builders
│   │   │   └── enrollment_date_builder.rb
│   │   ├── cache_register
│   │   │   ├── get_key.lua
│   │   │   └── get_with_batched_keys.lua
│   │   ├── cache_register.rb
│   │   ├── cdn
│   │   │   ├── registry
│   │   │   │   ├── gulp.rb
│   │   │   │   └── webpack.rb
│   │   │   ├── registry.rb
│   │   │   ├── revved_asset_urls.rb
│   │   │   └── s3_uploader.rb
│   │   ├── cdn.rb
│   │   ├── crocodoc.rb
│   │   ├── cross_region_query_metrics.rb
│   │   ├── draft_state_validations.rb
│   │   ├── dynamo_db
│   │   │   ├── database_builder.rb
│   │   │   └── dev_utils.rb
│   │   ├── error_stats.rb
│   │   ├── errors
│   │   │   ├── info.rb
│   │   │   ├── log_entry.rb
│   │   │   ├── reporter.rb
│   │   │   └── worker_info.rb
│   │   ├── errors.rb
│   │   ├── failure_percent_counter
│   │   │   ├── failure_rate.lua
│   │   │   └── increment_counter.lua
│   │   ├── failure_percent_counter.rb
│   │   ├── grade_validations.rb
│   │   ├── icu.rb
│   │   ├── live_events.rb
│   │   ├── live_events_callbacks.rb
│   │   ├── lock_explanation.rb
│   │   ├── lockdown_browser.rb
│   │   ├── message_helper.rb
│   │   ├── migration
│   │   │   ├── archive.rb
│   │   │   ├── error.rb
│   │   │   ├── external_content
│   │   │   │   ├── migrator.rb
│   │   │   │   ├── service_interface.rb
│   │   │   │   └── translator.rb
│   │   │   ├── helpers
│   │   │   │   └── selective_content_formatter.rb
│   │   │   ├── migrator.rb
│   │   │   ├── migrator_helper.rb
│   │   │   ├── package_identifier.rb
│   │   │   ├── validators
│   │   │   │   ├── course_copy_validator.rb
│   │   │   │   └── zip_importer_validator.rb
│   │   │   ├── worker
│   │   │   │   ├── cc_worker.rb
│   │   │   │   ├── course_copy_worker.rb
│   │   │   │   └── zip_file_worker.rb
│   │   │   ├── worker.rb
│   │   │   └── xml_helper.rb
│   │   ├── migration.rb
│   │   ├── oauth
│   │   │   ├── asymmetric_client_credentials_provider.rb
│   │   │   ├── client_credentials_provider.rb
│   │   │   ├── grant_types
│   │   │   │   ├── authorization_code.rb
│   │   │   │   ├── authorization_code_with_pkce.rb
│   │   │   │   ├── base_type.rb
│   │   │   │   ├── client_credentials.rb
│   │   │   │   └── refresh_token.rb
│   │   │   ├── invalid_request_error.rb
│   │   │   ├── invalid_scope_error.rb
│   │   │   ├── key_storage.rb
│   │   │   ├── pkce.rb
│   │   │   ├── provider.rb
│   │   │   ├── request_error.rb
│   │   │   ├── service_user_client_credentials_provider.rb
│   │   │   ├── site_admin_client_credentials_provider.rb
│   │   │   ├── symmetric_client_credentials_provider.rb
│   │   │   └── token.rb
│   │   ├── oauth.rb
│   │   ├── outcome_import_validations.rb
│   │   ├── plugins
│   │   │   ├── default_plugins.rb
│   │   │   ├── ticketing_system
│   │   │   │   ├── base_plugin.rb
│   │   │   │   ├── custom_error.rb
│   │   │   │   ├── email_plugin.rb
│   │   │   │   └── web_post_plugin.rb
│   │   │   ├── ticketing_system.rb
│   │   │   ├── validators
│   │   │   │   ├── account_reports_validator.rb
│   │   │   │   ├── app_center_validator.rb
│   │   │   │   ├── big_blue_button_fallback_validator.rb
│   │   │   │   ├── big_blue_button_validator.rb
│   │   │   │   ├── diigo_validator.rb
│   │   │   │   ├── etherpad_validator.rb
│   │   │   │   ├── google_drive_validator.rb
│   │   │   │   ├── i18n_validator.rb
│   │   │   │   ├── inst_fs_validator.rb
│   │   │   │   ├── kaltura_validator.rb
│   │   │   │   ├── panda_pub_validator.rb
│   │   │   │   ├── sessions_validator.rb
│   │   │   │   ├── ticketing_system_validator.rb
│   │   │   │   └── wimba_validator.rb
│   │   │   └── validators.rb
│   │   ├── redis_connections.rb
│   │   ├── request_forgery_protection.rb
│   │   ├── root_account_cacher.rb
│   │   ├── security
│   │   │   ├── jwt_validator.rb
│   │   │   ├── login_registry.rb
│   │   │   ├── password_policy.rb
│   │   │   ├── password_policy_account_setting_validator.rb
│   │   │   └── recryption.rb
│   │   ├── security.rb
│   │   ├── soft_deletable.rb
│   │   ├── twilio.rb
│   │   └── uploaded_file.rb
│   ├── canvas_imported_html_converter.rb
│   ├── canvas_logger.rb
│   ├── capture_job_ids.rb
│   ├── cc
│   │   ├── assignment_groups.rb
│   │   ├── assignment_resources.rb
│   │   ├── basic_lti_links.rb
│   │   ├── blueprint_settings.rb
│   │   ├── canvas_resource.rb
│   │   ├── cc_exporter.rb
│   │   ├── cc_helper.rb
│   │   ├── course_paces.rb
│   │   ├── events.rb
│   │   ├── exporter
│   │   │   ├── epub
│   │   │   │   ├── book.rb
│   │   │   │   ├── converters
│   │   │   │   │   ├── assignment_epub_converter.rb
│   │   │   │   │   ├── cartridge_converter.rb
│   │   │   │   │   ├── files_converter.rb
│   │   │   │   │   ├── media_converter.rb
│   │   │   │   │   ├── module_epub_converter.rb
│   │   │   │   │   ├── object_path_converter.rb
│   │   │   │   │   ├── quiz_epub_converter.rb
│   │   │   │   │   ├── topic_epub_converter.rb
│   │   │   │   │   └── wiki_epub_converter.rb
│   │   │   │   ├── exportable.rb
│   │   │   │   ├── exporter.rb
│   │   │   │   ├── files_directory.rb
│   │   │   │   ├── module_sorter.rb
│   │   │   │   ├── template.rb
│   │   │   │   └── templates
│   │   │   │       ├── announcements_template.html.erb
│   │   │   │       ├── assignments_template.html.erb
│   │   │   │       ├── content_sorting_template.html.erb
│   │   │   │       ├── css_template.css
│   │   │   │       ├── files_template.html.erb
│   │   │   │       ├── module_sorting_template.html.erb
│   │   │   │       ├── pages_template.html.erb
│   │   │   │       ├── quizzes_template.html.erb
│   │   │   │       ├── syllabus_template.html.erb
│   │   │   │       ├── toc_template.html.erb
│   │   │   │       └── topics_template.html.erb
│   │   │   ├── epub.rb
│   │   │   └── web_zip
│   │   │       ├── exportable.rb
│   │   │       ├── exporter.rb
│   │   │       └── zip_package.rb
│   │   ├── external_feeds.rb
│   │   ├── grading_standards.rb
│   │   ├── importer
│   │   │   ├── blti_converter.rb
│   │   │   ├── canvas
│   │   │   │   ├── assignment_converter.rb
│   │   │   │   ├── blueprint_settings_converter.rb
│   │   │   │   ├── converter.rb
│   │   │   │   ├── course_paces_converter.rb
│   │   │   │   ├── course_settings.rb
│   │   │   │   ├── learning_outcomes_converter.rb
│   │   │   │   ├── lti_resource_link_converter.rb
│   │   │   │   ├── media_track_converter.rb
│   │   │   │   ├── module_converter.rb
│   │   │   │   ├── quiz_converter.rb
│   │   │   │   ├── quiz_metadata_converter.rb
│   │   │   │   ├── rubrics_converter.rb
│   │   │   │   ├── tool_profile_converter.rb
│   │   │   │   ├── topic_converter.rb
│   │   │   │   ├── webcontent_converter.rb
│   │   │   │   └── wiki_converter.rb
│   │   │   ├── cc_worker.rb
│   │   │   └── standard
│   │   │       ├── assignment_converter.rb
│   │   │       ├── converter.rb
│   │   │       ├── discussion_converter.rb
│   │   │       ├── org_converter.rb
│   │   │       ├── quiz_converter.rb
│   │   │       ├── webcontent_converter.rb
│   │   │       └── weblink_converter.rb
│   │   ├── importer.rb
│   │   ├── late_policy.rb
│   │   ├── learning_outcomes.rb
│   │   ├── lti_resource_links.rb
│   │   ├── manifest.rb
│   │   ├── module_meta.rb
│   │   ├── new_quizzes_links_replacer.rb
│   │   ├── organization.rb
│   │   ├── qti
│   │   │   ├── migration_ids_replacer.rb
│   │   │   ├── new_quizzes_generator.rb
│   │   │   ├── qti_generator.rb
│   │   │   ├── qti_items.rb
│   │   │   └── qti_manifest.rb
│   │   ├── qti.rb
│   │   ├── resource.rb
│   │   ├── rubrics.rb
│   │   ├── schema.rb
│   │   ├── tool_profiles.rb
│   │   ├── topic_resources.rb
│   │   ├── web_links.rb
│   │   ├── web_resources.rb
│   │   ├── wiki_resources.rb
│   │   └── xsd
│   │       └── cccv1p0.xsd
│   ├── cc.rb
│   ├── cedar_client.rb
│   ├── checkpoint.rb
│   ├── checkpoint_labels.rb
│   ├── concluded_grading_standard_setter.rb
│   ├── content_licenses.rb
│   ├── content_notices.rb
│   ├── content_zipper.rb
│   ├── conversation_batch_scrubber.rb
│   ├── conversation_helper.rb
│   ├── copy_authorized_links.rb
│   ├── course_link_validator.rb
│   ├── course_pace_docx_generator.rb
│   ├── course_pace_due_dates_calculator.rb
│   ├── course_pace_hard_end_date_compressor.rb
│   ├── course_paces_date_helpers.rb
│   ├── custom_validations.rb
│   ├── cuty_capt.rb
│   ├── data_fixup
│   │   ├── add_lti_id_to_users.rb
│   │   ├── add_manage_account_banks_permission_to_quiz_lti_tools.rb
│   │   ├── add_media_data_attribute_to_iframes.rb
│   │   ├── add_media_id_and_style_display_attributes_to_iframes.rb
│   │   ├── add_new_default_report.rb
│   │   ├── add_role_overrides_for_new_permission.rb
│   │   ├── add_role_overrides_for_permission_combination.rb
│   │   ├── add_user_uuid_to_learning_outcome_results.rb
│   │   ├── backfill_authorized_flows_on_developer_key.rb
│   │   ├── backfill_new_default_help_link.rb
│   │   ├── backfill_nulls.rb
│   │   ├── bulk_column_updater.rb
│   │   ├── clear_account_settings.rb
│   │   ├── clear_feature_flags.rb
│   │   ├── copy_custom_data_to_jsonb.rb
│   │   ├── copy_role_overrides.rb
│   │   ├── create_lti_registrations_from_developer_keys.rb
│   │   ├── create_media_objects_for_media_attachments_lacking.rb
│   │   ├── delete_discussion_topic_no_message.rb
│   │   ├── delete_duplicate_rows.rb
│   │   ├── delete_orphaned_feature_flags.rb
│   │   ├── delete_role_overrides.rb
│   │   ├── delete_scores_for_assignment_groups.rb
│   │   ├── fix_data_inconsistency_in_learning_outcomes.rb
│   │   ├── get_media_from_notorious_into_instfs.rb
│   │   ├── granular_permissions
│   │   │   ├── add_role_overrides_for_manage_courses_add.rb
│   │   │   └── add_role_overrides_for_manage_courses_delete.rb
│   │   ├── import_instfs_attachments.rb
│   │   ├── localize_root_account_ids_on_attachment.rb
│   │   ├── lti
│   │   │   ├── add_user_uuid_custom_variable_to_internal_tools.rb
│   │   │   ├── backfill_context_external_tool_lti_registration_ids.rb
│   │   │   ├── backfill_lti_overlays_from_ims_registrations.rb
│   │   │   ├── backfill_lti_registration_account_bindings.rb
│   │   │   └── update_custom_params.rb
│   │   ├── move_feature_flags_to_settings.rb
│   │   ├── move_sub_account_grading_periods_to_courses.rb
│   │   ├── populate_conversation_participant_private_hash.rb
│   │   ├── populate_identity_hash_on_context_external_tools.rb
│   │   ├── populate_root_account_id_on_asset_user_accesses.rb
│   │   ├── populate_root_account_id_on_models.rb
│   │   ├── populate_root_account_ids_on_communication_channels.rb
│   │   ├── populate_root_account_ids_on_learning_outcomes.rb
│   │   ├── populate_root_account_ids_on_users.rb
│   │   ├── reassociate_grading_period_groups.rb
│   │   ├── rebuild_quiz_submissions_from_quiz_submission_events.rb
│   │   ├── rebuild_quiz_submissions_from_quiz_submission_versions.rb
│   │   ├── recalculate_section_override_dates.rb
│   │   ├── reclaim_instfs_attachments.rb
│   │   ├── remove_twitter_auth_providers.rb
│   │   ├── replace_media_object_links_for_media_attachment_links.rb
│   │   ├── resend_plagiarism_events.rb
│   │   ├── reset_file_verifiers.rb
│   │   ├── set_sizing_for_media_attachment_iframes.rb
│   │   ├── sync_important_date_with_child_events.rb
│   │   └── update_developer_key_scopes.rb
│   ├── dates_overridable.rb
│   ├── delayed_message_scrubber.rb
│   ├── differentiable_assignment.rb
│   ├── dump_helper.rb
│   ├── duplicating_objects.rb
│   ├── effective_due_dates.rb
│   ├── email_address_validator.rb
│   ├── enrollments_from_user_list.rb
│   ├── eportfolio_page.rb
│   ├── extensions
│   │   ├── active_record
│   │   │   └── enum.rb
│   │   └── active_record.rb
│   ├── external_auth_observation
│   │   └── saml.rb
│   ├── external_feed_aggregator.rb
│   ├── external_statuses.rb
│   ├── feature.rb
│   ├── feature_flags
│   │   ├── docviewer_iwork_predicate.rb
│   │   ├── hooks.rb
│   │   ├── loader.rb
│   │   └── usage_metrics_predicate.rb
│   ├── feature_flags.rb
│   ├── file_authenticator.rb
│   ├── file_in_context.rb
│   ├── file_splitter.rb
│   ├── global_lookups
│   │   ├── config.rb
│   │   └── dev_utils.rb
│   ├── global_lookups.rb
│   ├── google_docs_preview.rb
│   ├── grade_calculator.rb
│   ├── grade_display.rb
│   ├── gradebook
│   │   ├── apply_score_to_ungraded_submissions.rb
│   │   └── final_grade_overrides.rb
│   ├── gradebook_exporter.rb
│   ├── gradebook_grading_period_assignments.rb
│   ├── gradebook_importer.rb
│   ├── gradebook_settings_helpers.rb
│   ├── gradebook_user_ids.rb
│   ├── grading_period_helper.rb
│   ├── has_content_tags.rb
│   ├── health_checks.rb
│   ├── host_url.rb
│   ├── i18n
│   │   └── backend
│   │       ├── csv.rb
│   │       ├── dont_trust_pluralizations.rb
│   │       └── meta_lazy_loadable.rb
│   ├── i18n_time_zone.rb
│   ├── inst_fs.rb
│   ├── late_policy_applicator.rb
│   ├── latex
│   │   └── math_ml.rb
│   ├── latex.rb
│   ├── learn_platform
│   │   ├── api.rb
│   │   └── global_api.rb
│   ├── learning_outcome_context.rb
│   ├── llm_configs.rb
│   ├── locale_selection.rb
│   ├── locked_for.rb
│   ├── logging_filter.rb
│   ├── login_hooks.rb
│   ├── lti
│   │   ├── api_service_helper.rb
│   │   ├── app_collator.rb
│   │   ├── app_launch_collator.rb
│   │   ├── app_util.rb
│   │   ├── capabilities_helper.rb
│   │   ├── content_item_converter.rb
│   │   ├── content_item_response.rb
│   │   ├── content_item_selection_request.rb
│   │   ├── content_item_util.rb
│   │   ├── context_tool_finder.rb
│   │   ├── deep_linking_data.rb
│   │   ├── deep_linking_util.rb
│   │   ├── errors
│   │   │   ├── error_logger.rb
│   │   │   └── invalid_tool_proxy_error.rb
│   │   ├── errors.rb
│   │   ├── external_tool_name_bookmarker.rb
│   │   ├── external_tool_tab.rb
│   │   ├── helpers
│   │   │   └── jwt_message_helper.rb
│   │   ├── ims
│   │   │   ├── advantage_access_token.rb
│   │   │   ├── advantage_access_token_request_helper.rb
│   │   │   └── advantage_errors.rb
│   │   ├── key_storage.rb
│   │   ├── logging.rb
│   │   ├── membership_service
│   │   │   ├── collator_base.rb
│   │   │   ├── course_group_collator.rb
│   │   │   ├── course_lis_person_collator.rb
│   │   │   ├── group_lis_person_collator.rb
│   │   │   ├── lis_person_collator_base.rb
│   │   │   ├── membership_collator_factory.rb
│   │   │   └── page_presenter.rb
│   │   ├── message_authenticator.rb
│   │   ├── message_handler_name_bookmarker.rb
│   │   ├── messages
│   │   │   ├── asset_processor_settings_request.rb
│   │   │   ├── deep_linking_request.rb
│   │   │   ├── eula_request.rb
│   │   │   ├── jwt_message.rb
│   │   │   ├── pns_notice.rb
│   │   │   ├── report_review_request.rb
│   │   │   └── resource_link_request.rb
│   │   ├── name_bookmarker_base.rb
│   │   ├── oauth2
│   │   │   ├── access_token.rb
│   │   │   ├── authorization_validator.rb
│   │   │   └── invalid_token_error.rb
│   │   ├── oidc.rb
│   │   ├── permission_checker.rb
│   │   ├── plagiarism_subscriptions_helper.rb
│   │   ├── platform_storage.rb
│   │   ├── privacy_level_expander.rb
│   │   ├── quizzes_next_helper.rb
│   │   ├── re_reg_constraint.rb
│   │   ├── redis_message_client.rb
│   │   ├── scope_union.rb
│   │   ├── security.rb
│   │   ├── substitutions_helper.rb
│   │   ├── tool_proxy_name_bookmarker.rb
│   │   ├── tool_proxy_validator.rb
│   │   ├── v1p1
│   │   │   └── asset.rb
│   │   ├── variable_expander.rb
│   │   └── variable_expansion.rb
│   ├── material_changes.rb
│   ├── math_man.rb
│   ├── memory_limit.rb
│   ├── message_dispatcher.rb
│   ├── message_scrubber.rb
│   ├── messageable_user
│   │   └── calculator.rb
│   ├── messageable_user.rb
│   ├── microsoft_sync
│   │   ├── canvas_models_helpers.rb
│   │   ├── debug_info_tracker.rb
│   │   ├── errors.rb
│   │   ├── graph_service
│   │   │   ├── education_classes_endpoints.rb
│   │   │   ├── endpoints_base.rb
│   │   │   ├── group_membership_change_result.rb
│   │   │   ├── groups_endpoints.rb
│   │   │   ├── http.rb
│   │   │   ├── special_case.rb
│   │   │   ├── teams_endpoints.rb
│   │   │   └── users_endpoints.rb
│   │   ├── graph_service.rb
│   │   ├── graph_service_helpers.rb
│   │   ├── login_service.rb
│   │   ├── membership_diff.rb
│   │   ├── partial_membership_diff.rb
│   │   ├── settings_validator.rb
│   │   ├── state_machine_job.rb
│   │   ├── syncer_steps.rb
│   │   └── users_uluvs_finder.rb
│   ├── missing_policy_applicator.rb
│   ├── model_cache.rb
│   ├── moderation.rb
│   ├── must_view_module_progressor.rb
│   ├── mutable.rb
│   ├── net_ldap_extensions.rb
│   ├── notification_message_creator.rb
│   ├── outcomes
│   │   ├── csv_importer.rb
│   │   ├── enrollments.rb
│   │   ├── import.rb
│   │   ├── learning_outcome_group_children.rb
│   │   ├── outcome_friendly_description_resolver.rb
│   │   └── result_analytics.rb
│   ├── package_root.rb
│   ├── pandata_events
│   │   ├── credential_service.rb
│   │   └── errors.rb
│   ├── pandata_events.rb
│   ├── permissions.rb
│   ├── permissions_helper.rb
│   ├── plannable.rb
│   ├── planner_api_helper.rb
│   ├── planner_helper.rb
│   ├── progress_runner.rb
│   ├── pronouns.rb
│   ├── quiz_math_data_fixup.rb
│   ├── rake
│   │   └── task_graph.rb
│   ├── reporting
│   │   └── counts_report.rb
│   ├── request_error.rb
│   ├── rubric_assessment_csv_importer.rb
│   ├── rubric_context.rb
│   ├── rubric_csv_importer.rb
│   ├── rubric_importer_errors.rb
│   ├── schemas
│   │   ├── base.rb
│   │   ├── internal_lti_configuration.rb
│   │   ├── lti
│   │   │   ├── ims
│   │   │   │   ├── lti_tool_configuration.rb
│   │   │   │   ├── oidc_registration.rb
│   │   │   │   └── registration_overlay.rb
│   │   │   ├── overlay.rb
│   │   │   └── public_jwk.rb
│   │   └── lti_configuration.rb
│   ├── scope_filter.rb
│   ├── score_statistics_generator.rb
│   ├── scrypt_provider.rb
│   ├── search_term_helper.rb
│   ├── send_to_stream.rb
│   ├── sentry_extensions
│   │   ├── settings.rb
│   │   └── tracing
│   │       └── active_record_subscriber.rb
│   ├── sentry_proxy.rb
│   ├── services
│   │   ├── address_book.rb
│   │   ├── analytics_hub.rb
│   │   ├── feature_analytics_service.rb
│   │   ├── live_events_subscription_service.rb
│   │   ├── notification_service.rb
│   │   ├── platform_service_speedgrader.rb
│   │   ├── rich_content.rb
│   │   ├── screencap_service.rb
│   │   └── submit_homework_service.rb
│   ├── session_token.rb
│   ├── simple_stats.rb
│   ├── simple_tags.rb
│   ├── sis
│   │   ├── abstract_course_importer.rb
│   │   ├── account_importer.rb
│   │   ├── admin_importer.rb
│   │   ├── base_importer.rb
│   │   ├── change_sis_id_importer.rb
│   │   ├── course_importer.rb
│   │   ├── csv
│   │   │   ├── abstract_course_importer.rb
│   │   │   ├── account_importer.rb
│   │   │   ├── admin_importer.rb
│   │   │   ├── change_sis_id_importer.rb
│   │   │   ├── course_importer.rb
│   │   │   ├── csv_base_importer.rb
│   │   │   ├── diff_generator.rb
│   │   │   ├── enrollment_importer.rb
│   │   │   ├── grade_publishing_results_importer.rb
│   │   │   ├── group_category_importer.rb
│   │   │   ├── group_importer.rb
│   │   │   ├── group_membership_importer.rb
│   │   │   ├── import_refactored.rb
│   │   │   ├── login_importer.rb
│   │   │   ├── section_importer.rb
│   │   │   ├── term_importer.rb
│   │   │   ├── user_importer.rb
│   │   │   ├── user_observer_importer.rb
│   │   │   └── xlist_importer.rb
│   │   ├── enrollment_importer.rb
│   │   ├── grade_publishing_results_importer.rb
│   │   ├── group_category_importer.rb
│   │   ├── group_importer.rb
│   │   ├── group_membership_importer.rb
│   │   ├── models
│   │   │   ├── data_change.rb
│   │   │   ├── enrollment.rb
│   │   │   └── user.rb
│   │   ├── section_importer.rb
│   │   ├── term_importer.rb
│   │   ├── user_importer.rb
│   │   ├── user_observer_importer.rb
│   │   └── xlist_importer.rb
│   ├── sis.rb
│   ├── smart_search.rb
│   ├── smart_searchable.rb
│   ├── sorts_assignments.rb
│   ├── ssl_common.rb
│   ├── stats.rb
│   ├── sticky_sis_fields.rb
│   ├── submission_lifecycle_manager.rb
│   ├── submission_list.rb
│   ├── submission_search.rb
│   ├── submittable.rb
│   ├── submittables_grading_period_protection.rb
│   ├── summary_message_consolidator.rb
│   ├── support_helpers
│   │   ├── assignment_resubmission.rb
│   │   ├── controller_helpers.rb
│   │   ├── crocodoc.rb
│   │   ├── fixer.rb
│   │   ├── plagiarism_platform.rb
│   │   ├── submission_lifecycle_manage.rb
│   │   └── tii.rb
│   ├── tasks
│   │   ├── brand_configs.rake
│   │   ├── canvas
│   │   │   ├── cdn.rake
│   │   │   └── quizzes.rake
│   │   ├── canvas.rake
│   │   ├── ci.rake
│   │   ├── coverage_report.rake
│   │   ├── css.rake
│   │   ├── db.rake
│   │   ├── db_create_data.rake
│   │   ├── db_load_data.rake
│   │   ├── db_nuke.rake
│   │   ├── docs.rake
│   │   ├── graphql.rake
│   │   ├── i18nliner.rake
│   │   ├── js.rake
│   │   ├── pact.rake
│   │   ├── pact_broker.rake
│   │   ├── parallel_exclude.rb
│   │   ├── remove_schema_sig.rake
│   │   ├── rspec.rake
│   │   └── stormbreaker.rake
│   ├── text_helper.rb
│   ├── time_zone_helper.rb
│   ├── timed_cache.rb
│   ├── token_scopes.rb
│   ├── token_scopes_helper.rb
│   ├── translation.rb
│   ├── turnitin
│   │   ├── attachment_manager.rb
│   │   ├── errors.rb
│   │   ├── outcome_response_processor.rb
│   │   ├── response.rb
│   │   └── tii_client.rb
│   ├── turnitin.rb
│   ├── turnitin_id.rb
│   ├── unzip_attachment.rb
│   ├── user_content
│   │   └── files_handler.rb
│   ├── user_content.rb
│   ├── user_list.rb
│   ├── user_list_v2.rb
│   ├── user_merge.rb
│   ├── user_search.rb
│   ├── utils
│   │   ├── date_presenter.rb
│   │   ├── datetime_range_presenter.rb
│   │   ├── hash_utils.rb
│   │   ├── inst_statsd_utils
│   │   │   └── timing.rb
│   │   ├── relative_date.rb
│   │   └── time_presenter.rb
│   ├── uuid_helper.rb
│   ├── vericite.rb
│   ├── visibility_plucking_helper.rb
│   └── zip_extractor.rb
├── log
├── package.json
├── packages
│   ├── babel-preset-pretranslated-translations-package-format-message
│   │   ├── LICENSE
│   │   ├── index.js
│   │   └── package.json
│   ├── bootstrap-dropdown
│   │   ├── eslint.config.js
│   │   ├── index.js
│   │   └── package.json
│   ├── bootstrap-select
│   │   ├── eslint.config.js
│   │   ├── index.js
│   │   ├── index.scss
│   │   └── package.json
│   ├── browserslist-config-canvas-lms
│   │   ├── LICENSE
│   │   ├── README.md
│   │   ├── index.js
│   │   └── package.json
│   ├── canvas-media
│   │   ├── CHANGELOG.md
│   │   ├── __mocks__
│   │   │   ├── @instructure
│   │   │   │   └── studio-player
│   │   │   │       ├── _mockStudioPlayer.js
│   │   │   │       └── index.js
│   │   │   └── fileMock.js
│   │   ├── biome.json
│   │   ├── jest
│   │   │   └── jest-setup.js
│   │   ├── locales
│   │   │   └── en.json
│   │   ├── package.json
│   │   ├── scripts
│   │   │   ├── commitTranslations.sh
│   │   │   ├── installTranslations.js
│   │   │   └── publish_to_npm.sh
│   │   ├── src
│   │   │   ├── ClosedCaptionCreator
│   │   │   │   ├── ClosedCaptionCreatorRow.jsx
│   │   │   │   ├── __tests__
│   │   │   │   │   └── ClosedCaptionCreatorRow.test.jsx
│   │   │   │   └── index.jsx
│   │   │   ├── ComputerPanel.jsx
│   │   │   ├── MediaRecorder.js
│   │   │   ├── RocketSVG.jsx
│   │   │   ├── UploadMedia.jsx
│   │   │   ├── __mocks__
│   │   │   │   └── screenfull.js
│   │   │   ├── __tests__
│   │   │   │   ├── CanvasSelect.test.jsx
│   │   │   │   ├── ClosedCaptionPanel.test.jsx
│   │   │   │   ├── ComputerPanel.test.tsx
│   │   │   │   ├── UploadMedia.test.tsx
│   │   │   │   ├── closedCaptionLanguages.test.js
│   │   │   │   ├── saveMediaRecording.test.js
│   │   │   │   ├── useComputerPanelFocus.test.jsx
│   │   │   │   └── utils.test.js
│   │   │   ├── acceptedMediaFileTypes.js
│   │   │   ├── closedCaptionLanguages.js
│   │   │   ├── format-message.js
│   │   │   ├── getTranslations.js
│   │   │   ├── index.js
│   │   │   ├── saveMediaRecording.js
│   │   │   ├── shared
│   │   │   │   ├── CanvasSelect.jsx
│   │   │   │   ├── FileSizeError.js
│   │   │   │   ├── LoadingIndicator.jsx
│   │   │   │   ├── constants.js
│   │   │   │   ├── shortid.js
│   │   │   │   └── utils.js
│   │   │   ├── translationShape.js
│   │   │   ├── translations
│   │   │   │   └── locales
│   │   │   │       ├── ab.js
│   │   │   │       ├── ar.js
│   │   │   │       ├── ca.js
│   │   │   │       ├── cs.js
│   │   │   │       ├── cs_CZ.js
│   │   │   │       ├── cy.js
│   │   │   │       ├── da-x-k12.js
│   │   │   │       ├── da.js
│   │   │   │       ├── da_DK.js
│   │   │   │       ├── de.js
│   │   │   │       ├── el.js
│   │   │   │       ├── en-AU-x-unimelb.js
│   │   │   │       ├── en-GB-x-ukhe.js
│   │   │   │       ├── en.js
│   │   │   │       ├── en_AU.js
│   │   │   │       ├── en_CA.js
│   │   │   │       ├── en_CY.js
│   │   │   │       ├── en_GB.js
│   │   │   │       ├── en_NZ.js
│   │   │   │       ├── en_SE.js
│   │   │   │       ├── en_US.js
│   │   │   │       ├── es.js
│   │   │   │       ├── es_ES.js
│   │   │   │       ├── es_GT.js
│   │   │   │       ├── fa_IR.js
│   │   │   │       ├── fi.js
│   │   │   │       ├── fr.js
│   │   │   │       ├── fr_CA.js
│   │   │   │       ├── ga.js
│   │   │   │       ├── he.js
│   │   │   │       ├── hi.js
│   │   │   │       ├── ht.js
│   │   │   │       ├── hu.js
│   │   │   │       ├── hu_HU.js
│   │   │   │       ├── hy.js
│   │   │   │       ├── id.js
│   │   │   │       ├── id_ID.js
│   │   │   │       ├── is.js
│   │   │   │       ├── it.js
│   │   │   │       ├── ja.js
│   │   │   │       ├── ko.js
│   │   │   │       ├── ko_KR.js
│   │   │   │       ├── lt.js
│   │   │   │       ├── lt_LT.js
│   │   │   │       ├── mi.js
│   │   │   │       ├── mn_MN.js
│   │   │   │       ├── ms.js
│   │   │   │       ├── nb-x-k12.js
│   │   │   │       ├── nb.js
│   │   │   │       ├── nl.js
│   │   │   │       ├── nl_NL.js
│   │   │   │       ├── nn.js
│   │   │   │       ├── pl.js
│   │   │   │       ├── pt.js
│   │   │   │       ├── pt_BR.js
│   │   │   │       ├── ro.js
│   │   │   │       ├── ru.js
│   │   │   │       ├── se.js
│   │   │   │       ├── sl.js
│   │   │   │       ├── sv-x-k12.js
│   │   │   │       ├── sv.js
│   │   │   │       ├── sv_SE.js
│   │   │   │       ├── tg.js
│   │   │   │       ├── th.js
│   │   │   │       ├── th_TH.js
│   │   │   │       ├── tl_PH.js
│   │   │   │       ├── tr.js
│   │   │   │       ├── uk_UA.js
│   │   │   │       ├── vi.js
│   │   │   │       ├── vi_VN.js
│   │   │   │       ├── zh-Hans.js
│   │   │   │       ├── zh-Hant.js
│   │   │   │       ├── zh.js
│   │   │   │       ├── zh_HK.js
│   │   │   │       ├── zh_TW.Big5.js
│   │   │   │       └── zh_TW.js
│   │   │   └── useComputerPanelFocus.js
│   │   ├── tsconfig.json
│   │   ├── vitest-mock-css.js
│   │   ├── vitest.config.ts
│   │   └── vitest.setup.ts
│   ├── canvas-rce
│   │   ├── CHANGELOG.md
│   │   ├── DEVELOPMENT.md
│   │   ├── Dockerfile
│   │   ├── LICENSE
│   │   ├── README.md
│   │   ├── __mocks__
│   │   │   └── @instructure
│   │   │       └── studio-player
│   │   │           └── _mockStudioPlayer.js
│   │   ├── __tests__
│   │   │   ├── common
│   │   │   │   ├── indicate.test.js
│   │   │   │   └── mimeClass.test.js
│   │   │   ├── module
│   │   │   │   ├── contentInsertionUtils.test.js
│   │   │   │   ├── indicatorRegion.test.js
│   │   │   │   ├── normalizeLocale.test.js
│   │   │   │   ├── normalizeProps.test.js
│   │   │   │   ├── sanitizePlugins.test.js
│   │   │   │   └── wrapInitCb.test.js
│   │   │   ├── rcs
│   │   │   │   └── api.test.js
│   │   │   └── sidebar
│   │   │       ├── actions
│   │   │       │   ├── all_files.test.js
│   │   │       │   ├── data.test.js
│   │   │       │   └── utils.js
│   │   │       └── reducers
│   │   │           └── all_files.test.js
│   │   ├── babel-register.js
│   │   ├── babel.config.cjs.js
│   │   ├── babel.config.js
│   │   ├── build.sh
│   │   ├── demo
│   │   │   ├── DemoOptions.jsx
│   │   │   ├── app.jsx
│   │   │   └── test-plugin
│   │   │       ├── clickCallback.js
│   │   │       └── plugin.js
│   │   ├── doc
│   │   │   └── I18n.md
│   │   ├── docker-compose.yml
│   │   ├── eslint.config.js
│   │   ├── github-pages
│   │   │   └── index.html
│   │   ├── jest
│   │   │   ├── jest-setup-framework.js
│   │   │   └── jest-setup.js
│   │   ├── jest.config.js
│   │   ├── locales
│   │   │   └── en.json
│   │   ├── package.json
│   │   ├── scripts
│   │   │   ├── build-canvas
│   │   │   ├── commitTranslations.sh
│   │   │   ├── demo.sh
│   │   │   ├── generateSvgs.js
│   │   │   ├── installTranslations.js
│   │   │   ├── npm_localpublish.sh
│   │   │   ├── npm_localpush.sh
│   │   │   ├── npm_localrev.sh
│   │   │   ├── npmlocal_build.sh
│   │   │   └── publish_to_npm.sh
│   │   ├── src
│   │   │   ├── __tests__
│   │   │   │   └── defaultTinymceConfig.test.js
│   │   │   ├── bridge
│   │   │   │   ├── Bridge.js
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── bridge.test.js
│   │   │   │   │   └── bridge2.test.js
│   │   │   │   └── index.js
│   │   │   ├── canvasFileBrowser
│   │   │   │   ├── FileBrowser.jsx
│   │   │   │   ├── README.md
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── FileBrowser.test.jsx
│   │   │   │   │   └── filesHelpers.js
│   │   │   │   └── en-US.js
│   │   │   ├── common
│   │   │   │   ├── FlashAlert.jsx
│   │   │   │   ├── README.md
│   │   │   │   ├── __tests__
│   │   │   │   │   └── fileUrl.test.js
│   │   │   │   ├── browser.js
│   │   │   │   ├── fileUrl.ts
│   │   │   │   ├── getCookie.js
│   │   │   │   ├── incremental-loading
│   │   │   │   │   ├── LoadMoreButton.jsx
│   │   │   │   │   ├── LoadingIndicator.jsx
│   │   │   │   │   ├── LoadingStatus.tsx
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   └── incrementalLoading.test.jsx
│   │   │   │   │   ├── index.js
│   │   │   │   │   └── useIncrementalLoading.js
│   │   │   │   ├── indicate.js
│   │   │   │   ├── mimeClass.js
│   │   │   │   └── natcompare.js
│   │   │   ├── defaultTinymceConfig.ts
│   │   │   ├── elementDenylist.ts
│   │   │   ├── enhance-user-content
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── enhance_user_content.test.js
│   │   │   │   │   ├── instructure_helper.test.js
│   │   │   │   │   ├── jqueryish_funcs.test.js
│   │   │   │   │   ├── mathml.test.js
│   │   │   │   │   ├── media_comment_thumbnail.test.js
│   │   │   │   │   └── sanitizeUrl.test.js
│   │   │   │   ├── doc_previews.jsx
│   │   │   │   ├── enhance_user_content.js
│   │   │   │   ├── external_links.js
│   │   │   │   ├── index.js
│   │   │   │   ├── instructure_helper.js
│   │   │   │   ├── jqueryish_funcs.js
│   │   │   │   ├── mathml.js
│   │   │   │   └── media_comment_thumbnail.js
│   │   │   ├── format-message.js
│   │   │   ├── getThemeVars.ts
│   │   │   ├── getTranslations.js
│   │   │   ├── index.ts
│   │   │   ├── rce
│   │   │   │   ├── AlertMessageArea.tsx
│   │   │   │   ├── DraggingBlocker.jsx
│   │   │   │   ├── KeyboardShortcutModal.jsx
│   │   │   │   ├── RCE.tsx
│   │   │   │   ├── RCEGlobals.js
│   │   │   │   ├── RCEVariants.ts
│   │   │   │   ├── RCEWrapper.tsx
│   │   │   │   ├── RCEWrapper.utils.ts
│   │   │   │   ├── RCEWrapperProps.ts
│   │   │   │   ├── RceHtmlEditor.tsx
│   │   │   │   ├── ResizeHandle.jsx
│   │   │   │   ├── RestoreAutoSaveModal.jsx
│   │   │   │   ├── ShowOnFocusButton
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   └── ShowOnFocusButton.test.jsx
│   │   │   │   │   └── index.jsx
│   │   │   │   ├── StatusBar.jsx
│   │   │   │   ├── __mocks__
│   │   │   │   │   ├── _mockCryptoEs.ts
│   │   │   │   │   ├── _mockStudioPlayer.js
│   │   │   │   │   ├── styleMock.js
│   │   │   │   │   └── tinymceReact.jsx
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── FakeEditor.js
│   │   │   │   │   ├── RCE.test.jsx
│   │   │   │   │   ├── RCEGlobals.test.js
│   │   │   │   │   ├── RCEWrapper1.test.jsx
│   │   │   │   │   ├── RCEWrapper2.test.jsx
│   │   │   │   │   ├── RCEWrapper3.test.jsx
│   │   │   │   │   ├── RCEWrapper4.test.jsx
│   │   │   │   │   ├── RCEWrapper5.test.jsx
│   │   │   │   │   ├── RceHtmlEditor.test.tsx
│   │   │   │   │   ├── ResizeHandle.test.jsx
│   │   │   │   │   ├── RestoreAutoSaveModal.test.jsx
│   │   │   │   │   ├── StatusBar.test.jsx
│   │   │   │   │   ├── _mockIcons.js
│   │   │   │   │   ├── alertHandler.test.js
│   │   │   │   │   ├── contentHelpers.js
│   │   │   │   │   ├── contentInsertion.test.js
│   │   │   │   │   ├── contentRendering.test.js
│   │   │   │   │   ├── liveRegionHelper.js
│   │   │   │   │   ├── root.test.jsx
│   │   │   │   │   ├── transformContent.test.ts
│   │   │   │   │   └── userOS.test.ts
│   │   │   │   ├── alertHandler.js
│   │   │   │   ├── biome.json
│   │   │   │   ├── contentInsertion.js
│   │   │   │   ├── contentInsertionUtils.js
│   │   │   │   ├── contentRendering.jsx
│   │   │   │   ├── customEvents.ts
│   │   │   │   ├── editorLanguage.js
│   │   │   │   ├── indicatorRegion.js
│   │   │   │   ├── normalizeLocale.ts
│   │   │   │   ├── normalizeProps.ts
│   │   │   │   ├── plugins
│   │   │   │   │   ├── instructure-ui-icons
│   │   │   │   │   │   └── plugin.ts
│   │   │   │   │   ├── instructure_color
│   │   │   │   │   │   ├── clickCallback.tsx
│   │   │   │   │   │   ├── components
│   │   │   │   │   │   │   ├── ColorPicker.tsx
│   │   │   │   │   │   │   ├── ColorPopup.tsx
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── ColorPicker.test.tsx
│   │   │   │   │   │   │   │   └── colorUtils.test.ts
│   │   │   │   │   │   │   └── colorUtils.ts
│   │   │   │   │   │   └── plugin.ts
│   │   │   │   │   ├── instructure_condensed_buttons
│   │   │   │   │   │   ├── core
│   │   │   │   │   │   │   └── ListUtils.ts
│   │   │   │   │   │   ├── plugin.ts
│   │   │   │   │   │   └── ui
│   │   │   │   │   │       ├── alignment-button.ts
│   │   │   │   │   │       ├── directionality-button.js
│   │   │   │   │   │       ├── indent-outdent-button.ts
│   │   │   │   │   │       ├── list-button.ts
│   │   │   │   │   │       └── subscript-superscript-button.ts
│   │   │   │   │   ├── instructure_documents
│   │   │   │   │   │   ├── clickCallback.js
│   │   │   │   │   │   ├── components
│   │   │   │   │   │   │   ├── DocumentsPanel.jsx
│   │   │   │   │   │   │   ├── Link.jsx
│   │   │   │   │   │   │   └── __tests__
│   │   │   │   │   │   │       ├── DocumentsPanel.test.jsx
│   │   │   │   │   │   │       └── Link.test.jsx
│   │   │   │   │   │   └── plugin.ts
│   │   │   │   │   ├── instructure_equation
│   │   │   │   │   │   ├── EquationEditorModal
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── advancedOnlySyntax.test.js
│   │   │   │   │   │   │   │   ├── advancedPreference.test.ts
│   │   │   │   │   │   │   │   ├── index.test.jsx
│   │   │   │   │   │   │   │   ├── latexTextareaUtil.test.ts
│   │   │   │   │   │   │   │   └── parseLatex.test.ts
│   │   │   │   │   │   │   ├── advancedOnlySyntax.js
│   │   │   │   │   │   │   ├── advancedPreference.ts
│   │   │   │   │   │   │   ├── index.jsx
│   │   │   │   │   │   │   ├── latexTextareaUtil.ts
│   │   │   │   │   │   │   ├── mathjax.override.css
│   │   │   │   │   │   │   ├── parseLatex.ts
│   │   │   │   │   │   │   └── styles.js
│   │   │   │   │   │   ├── EquationEditorToolbar
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   └── index.test.jsx
│   │   │   │   │   │   │   ├── buttons.js
│   │   │   │   │   │   │   └── index.jsx
│   │   │   │   │   │   ├── MathIcon
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   └── index.test.jsx
│   │   │   │   │   │   │   ├── index.jsx
│   │   │   │   │   │   │   └── svgs.js
│   │   │   │   │   │   ├── clickCallback.jsx
│   │   │   │   │   │   ├── mathlive
│   │   │   │   │   │   │   └── index.js
│   │   │   │   │   │   └── plugin.ts
│   │   │   │   │   ├── instructure_fullscreen
│   │   │   │   │   │   └── plugin.ts
│   │   │   │   │   ├── instructure_html_view
│   │   │   │   │   │   ├── clickCallback.js
│   │   │   │   │   │   └── plugin.ts
│   │   │   │   │   ├── instructure_icon_maker
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── clickCallback.test.jsx
│   │   │   │   │   │   │   └── registerEditToolbar.test.js
│   │   │   │   │   │   ├── clickCallback.jsx
│   │   │   │   │   │   ├── components
│   │   │   │   │   │   │   ├── CreateIconMakerForm
│   │   │   │   │   │   │   │   ├── ColorSection.jsx
│   │   │   │   │   │   │   │   ├── CreateIconMakerForm.jsx
│   │   │   │   │   │   │   │   ├── Footer.jsx
│   │   │   │   │   │   │   │   ├── Group.jsx
│   │   │   │   │   │   │   │   ├── Header.jsx
│   │   │   │   │   │   │   │   ├── ImageSection
│   │   │   │   │   │   │   │   │   ├── Course.jsx
│   │   │   │   │   │   │   │   │   ├── ImageOptions.jsx
│   │   │   │   │   │   │   │   │   ├── ImageSection.jsx
│   │   │   │   │   │   │   │   │   ├── ModeSelect.jsx
│   │   │   │   │   │   │   │   │   ├── MultiColor
│   │   │   │   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   │   │   │   └── index.test.jsx
│   │   │   │   │   │   │   │   │   │   ├── index.jsx
│   │   │   │   │   │   │   │   │   │   └── svg.js
│   │   │   │   │   │   │   │   │   ├── SVGList.jsx
│   │   │   │   │   │   │   │   │   ├── SVGThumbnail.jsx
│   │   │   │   │   │   │   │   │   ├── SingleColor
│   │   │   │   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   │   │   │   └── index.test.jsx
│   │   │   │   │   │   │   │   │   │   ├── index.jsx
│   │   │   │   │   │   │   │   │   │   └── svg.js
│   │   │   │   │   │   │   │   │   ├── Upload.jsx
│   │   │   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   │   │   ├── Course.test.jsx
│   │   │   │   │   │   │   │   │   │   ├── ImageOptions.test.jsx
│   │   │   │   │   │   │   │   │   │   ├── ImageSection.1.test.jsx
│   │   │   │   │   │   │   │   │   │   ├── ImageSection.2.test.jsx
│   │   │   │   │   │   │   │   │   │   ├── ImageSection.3.test.jsx
│   │   │   │   │   │   │   │   │   │   ├── ImageSection.4.test.jsx
│   │   │   │   │   │   │   │   │   │   ├── ModeSelect.test.jsx
│   │   │   │   │   │   │   │   │   │   ├── SVGIcon.test.jsx
│   │   │   │   │   │   │   │   │   │   ├── SVGList.test.jsx
│   │   │   │   │   │   │   │   │   │   ├── Upload.test.jsx
│   │   │   │   │   │   │   │   │   │   └── utils.test.js
│   │   │   │   │   │   │   │   │   ├── index.js
│   │   │   │   │   │   │   │   │   ├── propTypes.js
│   │   │   │   │   │   │   │   │   └── utils.js
│   │   │   │   │   │   │   │   ├── Preview.jsx
│   │   │   │   │   │   │   │   ├── ShapeSection.jsx
│   │   │   │   │   │   │   │   ├── TextSection.jsx
│   │   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   │   ├── ColorSection.test.jsx
│   │   │   │   │   │   │   │   │   ├── Footer.test.jsx
│   │   │   │   │   │   │   │   │   ├── Header.test.jsx
│   │   │   │   │   │   │   │   │   ├── PreviewSection.test.jsx
│   │   │   │   │   │   │   │   │   ├── ShapeSection.test.jsx
│   │   │   │   │   │   │   │   │   └── TextSection.test.jsx
│   │   │   │   │   │   │   │   └── index.js
│   │   │   │   │   │   │   ├── IconMakerTray.jsx
│   │   │   │   │   │   │   ├── SavedIconMakerList.jsx
│   │   │   │   │   │   │   └── __tests__
│   │   │   │   │   │   │       ├── IconMakerTray.1.test.js
│   │   │   │   │   │   │       ├── IconMakerTray.2.test.js
│   │   │   │   │   │   │       ├── IconMakerTray.3.test.js
│   │   │   │   │   │   │       └── SavedIconMakerList.test.jsx
│   │   │   │   │   │   ├── plugin.ts
│   │   │   │   │   │   ├── reducers
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── ImageSection.test.js
│   │   │   │   │   │   │   │   └── svgSettings.test.js
│   │   │   │   │   │   │   ├── imageSection.js
│   │   │   │   │   │   │   └── svgSettings.js
│   │   │   │   │   │   ├── registerEditToolbar.js
│   │   │   │   │   │   ├── svg
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── image.test.js
│   │   │   │   │   │   │   │   ├── index.test.js
│   │   │   │   │   │   │   │   ├── metadata.test.js
│   │   │   │   │   │   │   │   ├── settings.test.js
│   │   │   │   │   │   │   │   ├── shape.test.js
│   │   │   │   │   │   │   │   ├── text.test.js
│   │   │   │   │   │   │   │   └── utils.test.js
│   │   │   │   │   │   │   ├── clipPath.js
│   │   │   │   │   │   │   ├── constants.js
│   │   │   │   │   │   │   ├── font.js
│   │   │   │   │   │   │   ├── image.js
│   │   │   │   │   │   │   ├── index.js
│   │   │   │   │   │   │   ├── metadata.js
│   │   │   │   │   │   │   ├── settings.js
│   │   │   │   │   │   │   ├── shape.js
│   │   │   │   │   │   │   ├── text.js
│   │   │   │   │   │   │   └── utils.js
│   │   │   │   │   │   └── utils
│   │   │   │   │   │       ├── IconMakerClose.ts
│   │   │   │   │   │       ├── IconMakerFormHasChanges.ts
│   │   │   │   │   │       ├── __tests__
│   │   │   │   │   │       │   ├── IconMakerClose.test.ts
│   │   │   │   │   │       │   ├── IconMakerFormHasChanges.test.ts
│   │   │   │   │   │       │   ├── addIconMakerAttributes.test.ts
│   │   │   │   │   │       │   ├── iconValidation.test.js
│   │   │   │   │   │       │   ├── useDebouncedValue.test.jsx
│   │   │   │   │   │       │   └── useMockedDebouncedValue.jsx
│   │   │   │   │   │       ├── addIconMakerAttributes.ts
│   │   │   │   │   │       ├── iconValidation.js
│   │   │   │   │   │       ├── iconsLabels.js
│   │   │   │   │   │       └── useDebouncedValue.jsx
│   │   │   │   │   ├── instructure_image
│   │   │   │   │   │   ├── ImageEmbedOptions.js
│   │   │   │   │   │   ├── ImageList
│   │   │   │   │   │   │   ├── Image.jsx
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── Image.test.jsx
│   │   │   │   │   │   │   │   └── ImageList.test.jsx
│   │   │   │   │   │   │   └── index.jsx
│   │   │   │   │   │   ├── ImageOptionsTray
│   │   │   │   │   │   │   ├── TrayController.jsx
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── ImageOptionsTray.test.jsx
│   │   │   │   │   │   │   │   ├── ImageOptionsTrayDriver.js
│   │   │   │   │   │   │   │   ├── TrayController.IconOptions.test.js
│   │   │   │   │   │   │   │   └── TrayController.test.jsx
│   │   │   │   │   │   │   └── index.jsx
│   │   │   │   │   │   ├── Images
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   └── Images.test.jsx
│   │   │   │   │   │   │   └── index.jsx
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── ImageEmbedOptions.test.js
│   │   │   │   │   │   │   └── clickCallback.test.js
│   │   │   │   │   │   ├── clickCallback.js
│   │   │   │   │   │   └── plugin.ts
│   │   │   │   │   ├── instructure_links
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   └── validateURL.test.js
│   │   │   │   │   │   ├── clickCallback.js
│   │   │   │   │   │   ├── components
│   │   │   │   │   │   │   ├── AccordionSection.jsx
│   │   │   │   │   │   │   ├── CollectionPanel.jsx
│   │   │   │   │   │   │   ├── Link.jsx
│   │   │   │   │   │   │   ├── LinkOptionsDialog
│   │   │   │   │   │   │   │   ├── LinkOptionsDialogController.jsx
│   │   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   │   ├── LinkOptionsDialog.test.jsx
│   │   │   │   │   │   │   │   │   ├── LinkOptionsDialogController.test.jsx
│   │   │   │   │   │   │   │   │   └── LinkOptionsDialogDriver.js
│   │   │   │   │   │   │   │   └── index.jsx
│   │   │   │   │   │   │   ├── LinkOptionsTray
│   │   │   │   │   │   │   │   ├── LinkOptionsTrayController.jsx
│   │   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   │   ├── LinkOptionsTray.test.jsx
│   │   │   │   │   │   │   │   │   ├── LinkOptionsTrayController.test.jsx
│   │   │   │   │   │   │   │   │   └── LinkOptionsTrayDriver.js
│   │   │   │   │   │   │   │   └── index.jsx
│   │   │   │   │   │   │   ├── LinkSet.jsx
│   │   │   │   │   │   │   ├── LinksPanel.jsx
│   │   │   │   │   │   │   ├── NavigationPanel.jsx
│   │   │   │   │   │   │   ├── NoResults.tsx
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── AccordionSection.test.jsx
│   │   │   │   │   │   │   │   ├── CollectionPanel.test.jsx
│   │   │   │   │   │   │   │   ├── Link.test.jsx
│   │   │   │   │   │   │   │   ├── LinkSet.test.jsx
│   │   │   │   │   │   │   │   ├── LinksPanel.test.jsx
│   │   │   │   │   │   │   │   ├── NavigationPanel.test.jsx
│   │   │   │   │   │   │   │   └── NoResults.test.tsx
│   │   │   │   │   │   │   └── propTypes.js
│   │   │   │   │   │   ├── plugin.ts
│   │   │   │   │   │   └── validateURL.js
│   │   │   │   │   ├── instructure_media_embed
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   └── clickCallback.test.js
│   │   │   │   │   │   ├── clickCallback.jsx
│   │   │   │   │   │   ├── components
│   │   │   │   │   │   │   ├── Embed.jsx
│   │   │   │   │   │   │   └── __tests__
│   │   │   │   │   │   │       └── Embed.test.jsx
│   │   │   │   │   │   └── plugin.ts
│   │   │   │   │   ├── instructure_paste
│   │   │   │   │   │   ├── pasteMenuCommand.js
│   │   │   │   │   │   └── plugin.ts
│   │   │   │   │   ├── instructure_rce_external_tools
│   │   │   │   │   │   ├── ExternalToolsEnv.ts
│   │   │   │   │   │   ├── RceToolWrapper.ts
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── ExternalToolsEnv.test.ts
│   │   │   │   │   │   │   ├── RceToolWrapper.test.ts
│   │   │   │   │   │   │   ├── TestContentItems.ts
│   │   │   │   │   │   │   └── initExternalToolsLocalPlugin.test.ts
│   │   │   │   │   │   ├── components
│   │   │   │   │   │   │   ├── ExternalToolDialog
│   │   │   │   │   │   │   │   ├── ExternalToolDialog.tsx
│   │   │   │   │   │   │   │   ├── ExternalToolDialogModal.tsx
│   │   │   │   │   │   │   │   └── ExternalToolDialogTray.tsx
│   │   │   │   │   │   │   ├── ExternalToolSelectionDialog
│   │   │   │   │   │   │   │   ├── ExternalToolSelectionDialog.tsx
│   │   │   │   │   │   │   │   └── ExternalToolSelectionItem.tsx
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── ExpandoText.test.tsx
│   │   │   │   │   │   │   │   ├── ExternalToolDialog.test.tsx
│   │   │   │   │   │   │   │   ├── ExternalToolSelectionDialog.test.tsx
│   │   │   │   │   │   │   │   └── LtiTool.test.tsx
│   │   │   │   │   │   │   └── util
│   │   │   │   │   │   │       ├── ExpandoText.tsx
│   │   │   │   │   │   │       └── ToolLaunchIframe.tsx
│   │   │   │   │   │   ├── constants.ts
│   │   │   │   │   │   ├── dialog-helper.tsx
│   │   │   │   │   │   ├── helpers
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   └── tags.test.ts
│   │   │   │   │   │   │   └── tags.ts
│   │   │   │   │   │   ├── jquery
│   │   │   │   │   │   │   └── jquery.dropdownList.ts
│   │   │   │   │   │   ├── lti11-content-items
│   │   │   │   │   │   │   ├── RceLti11ContentItem.tsx
│   │   │   │   │   │   │   └── __tests__
│   │   │   │   │   │   │       ├── RceLti11ContentItem.test.ts
│   │   │   │   │   │   │       └── exampleLti11ContentItems.ts
│   │   │   │   │   │   ├── lti13-content-items
│   │   │   │   │   │   │   ├── Lti13ContentItemJson.ts
│   │   │   │   │   │   │   ├── RceLti13ContentItem.ts
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   └── processEditorContentItems.test.ts
│   │   │   │   │   │   │   ├── models
│   │   │   │   │   │   │   │   ├── BaseLinkContentItem.ts
│   │   │   │   │   │   │   │   ├── HtmlFragmentContentItem.ts
│   │   │   │   │   │   │   │   ├── ImageContentItem.ts
│   │   │   │   │   │   │   │   ├── LinkContentItem.ts
│   │   │   │   │   │   │   │   ├── ResourceLinkContentItem.ts
│   │   │   │   │   │   │   │   └── __tests__
│   │   │   │   │   │   │   │       ├── HtmlFragmentContentItem.test.ts
│   │   │   │   │   │   │   │       ├── ImageContentItem.test.ts
│   │   │   │   │   │   │   │       ├── LinkContentItem.test.ts
│   │   │   │   │   │   │   │       └── ResourceLinkContentItem.test.ts
│   │   │   │   │   │   │   ├── processEditorContentItems.ts
│   │   │   │   │   │   │   └── rceLti13ContentItemFromJson.ts
│   │   │   │   │   │   ├── plugin.tsx
│   │   │   │   │   │   └── util
│   │   │   │   │   │       ├── __tests__
│   │   │   │   │   │       │   └── addParentFrameContextToUrl.test.ts
│   │   │   │   │   │       ├── addParentFrameContextToUrl.ts
│   │   │   │   │   │       └── externalToolsForToolbar.ts
│   │   │   │   │   ├── instructure_record
│   │   │   │   │   │   ├── AudioOptionsTray
│   │   │   │   │   │   │   ├── TrayController.jsx
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── AudioOptionsTray.test.jsx
│   │   │   │   │   │   │   │   ├── AudioOptionsTrayDriver.js
│   │   │   │   │   │   │   │   └── TrayController.test.jsx
│   │   │   │   │   │   │   └── index.jsx
│   │   │   │   │   │   ├── MediaPanel
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   └── MediaPanel.test.jsx
│   │   │   │   │   │   │   └── index.jsx
│   │   │   │   │   │   ├── VideoOptionsTray
│   │   │   │   │   │   │   ├── TrayController.jsx
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── TrayController.1.test.jsx
│   │   │   │   │   │   │   │   ├── TrayController.2.test.jsx
│   │   │   │   │   │   │   │   ├── VideoOptionsTray.1.test.jsx
│   │   │   │   │   │   │   │   ├── VideoOptionsTray.2.test.jsx
│   │   │   │   │   │   │   │   └── VideoOptionsTrayDriver.js
│   │   │   │   │   │   │   └── index.jsx
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   └── clickCallback.test.js
│   │   │   │   │   │   ├── clickCallback.jsx
│   │   │   │   │   │   ├── mediaTranslations.js
│   │   │   │   │   │   └── plugin.ts
│   │   │   │   │   ├── instructure_search_and_replace
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── FindReplaceTray.1.test.tsx
│   │   │   │   │   │   │   ├── FindReplaceTray.2.test.tsx
│   │   │   │   │   │   │   └── getSelectionContext.test.ts
│   │   │   │   │   │   ├── clickCallback.tsx
│   │   │   │   │   │   ├── components
│   │   │   │   │   │   │   ├── FindReplaceTray.tsx
│   │   │   │   │   │   │   └── FindReplaceTrayController.tsx
│   │   │   │   │   │   ├── getSelectionContext.ts
│   │   │   │   │   │   ├── plugin.ts
│   │   │   │   │   │   └── types.d.ts
│   │   │   │   │   ├── instructure_studio_media_options
│   │   │   │   │   │   └── plugin.ts
│   │   │   │   │   ├── instructure_wordcount
│   │   │   │   │   │   ├── clickCallback.tsx
│   │   │   │   │   │   ├── components
│   │   │   │   │   │   │   ├── WordCountModal.tsx
│   │   │   │   │   │   │   └── __tests__
│   │   │   │   │   │   │       └── WordCountModal.test.tsx
│   │   │   │   │   │   ├── plugin.ts
│   │   │   │   │   │   └── utils
│   │   │   │   │   │       ├── __tests__
│   │   │   │   │   │       │   ├── countContent.test.ts
│   │   │   │   │   │       │   └── tableContent.test.ts
│   │   │   │   │   │       ├── countContent.ts
│   │   │   │   │   │       └── tableContent.ts
│   │   │   │   │   ├── shared
│   │   │   │   │   │   ├── CanvasContentTray.jsx
│   │   │   │   │   │   ├── CheckerboardStyling.js
│   │   │   │   │   │   ├── ColorInput.jsx
│   │   │   │   │   │   ├── ConditionalTooltip.jsx
│   │   │   │   │   │   ├── ContentSelection.js
│   │   │   │   │   │   ├── DimensionUtils.js
│   │   │   │   │   │   ├── DimensionsInput
│   │   │   │   │   │   │   ├── DimensionInput.jsx
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── DimensionsInput.1.test.jsx
│   │   │   │   │   │   │   │   ├── DimensionsInput.2.test.jsx
│   │   │   │   │   │   │   │   ├── DimensionsInput.3.test.jsx
│   │   │   │   │   │   │   │   ├── DimensionsInput.4.test.jsx
│   │   │   │   │   │   │   │   ├── DimensionsInput.5.test.jsx
│   │   │   │   │   │   │   │   ├── DimensionsInputDriver.js
│   │   │   │   │   │   │   │   └── NumberInputDriver.js
│   │   │   │   │   │   │   ├── index.jsx
│   │   │   │   │   │   │   └── useDimensionsState.js
│   │   │   │   │   │   ├── ErrorBoundary.jsx
│   │   │   │   │   │   ├── EventUtils.ts
│   │   │   │   │   │   ├── Filter.jsx
│   │   │   │   │   │   ├── FixedContentTray.jsx
│   │   │   │   │   │   ├── ImageCropper
│   │   │   │   │   │   │   ├── DirectionRegion.tsx
│   │   │   │   │   │   │   ├── Modal.jsx
│   │   │   │   │   │   │   ├── Preview.jsx
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── DirectionRegion.test.tsx
│   │   │   │   │   │   │   │   ├── Modal.test.jsx
│   │   │   │   │   │   │   │   ├── Preview.test.jsx
│   │   │   │   │   │   │   │   └── imageCropUtils.test.js
│   │   │   │   │   │   │   ├── constants.js
│   │   │   │   │   │   │   ├── controls
│   │   │   │   │   │   │   │   ├── CustomNumberInput.jsx
│   │   │   │   │   │   │   │   ├── ResetControls.jsx
│   │   │   │   │   │   │   │   ├── RotationControls.jsx
│   │   │   │   │   │   │   │   ├── ShapeControls.jsx
│   │   │   │   │   │   │   │   ├── ZoomControls.jsx
│   │   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   │   ├── CustomNumberInput.test.jsx
│   │   │   │   │   │   │   │   │   ├── ResetControls.test.jsx
│   │   │   │   │   │   │   │   │   ├── RotationControls.test.jsx
│   │   │   │   │   │   │   │   │   ├── ShapeControls.test.jsx
│   │   │   │   │   │   │   │   │   ├── ZoomControls.test.jsx
│   │   │   │   │   │   │   │   │   └── utils.test.js
│   │   │   │   │   │   │   │   ├── index.jsx
│   │   │   │   │   │   │   │   ├── useDebouncedNumericValue.js
│   │   │   │   │   │   │   │   └── utils.js
│   │   │   │   │   │   │   ├── imageCropUtils.js
│   │   │   │   │   │   │   ├── index.js
│   │   │   │   │   │   │   ├── propTypes.js
│   │   │   │   │   │   │   ├── reducers
│   │   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   │   └── imageCropper.test.js
│   │   │   │   │   │   │   │   └── imageCropper.js
│   │   │   │   │   │   │   ├── shape.js
│   │   │   │   │   │   │   ├── svg
│   │   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   │   ├── index.test.js
│   │   │   │   │   │   │   │   │   ├── shape.test.js
│   │   │   │   │   │   │   │   │   └── utils.test.js
│   │   │   │   │   │   │   │   ├── index.js
│   │   │   │   │   │   │   │   ├── shape.js
│   │   │   │   │   │   │   │   └── utils.js
│   │   │   │   │   │   │   ├── useKeyMouseEvents.js
│   │   │   │   │   │   │   └── useMouseWheel.js
│   │   │   │   │   │   ├── ImageOptionsForm.jsx
│   │   │   │   │   │   ├── LinkDisplay.jsx
│   │   │   │   │   │   ├── PreviewIcon.jsx
│   │   │   │   │   │   ├── Previewable.js
│   │   │   │   │   │   ├── RceFileBrowser.jsx
│   │   │   │   │   │   ├── StoreContext.jsx
│   │   │   │   │   │   ├── StudioLtiSupportUtils.ts
│   │   │   │   │   │   ├── UnknownFileTypePanel.jsx
│   │   │   │   │   │   ├── Upload
│   │   │   │   │   │   │   ├── CanvasContentPanel.tsx
│   │   │   │   │   │   │   ├── CategoryProcessor.js
│   │   │   │   │   │   │   ├── ComputerPanel.jsx
│   │   │   │   │   │   │   ├── PanelFilter.tsx
│   │   │   │   │   │   │   ├── SvgCategoryProcessor.js
│   │   │   │   │   │   │   ├── UploadFile.tsx
│   │   │   │   │   │   │   ├── UploadFileModal.jsx
│   │   │   │   │   │   │   ├── UrlPanel.jsx
│   │   │   │   │   │   │   ├── UsageRightsSelectBox.jsx
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── CanvasContentPanel.test.tsx
│   │   │   │   │   │   │   │   ├── CategoryProcessor.test.js
│   │   │   │   │   │   │   │   ├── ComputerPanel.test.jsx
│   │   │   │   │   │   │   │   ├── PanelFilter.test.tsx
│   │   │   │   │   │   │   │   ├── SvgCategoryProcessor.test.js
│   │   │   │   │   │   │   │   ├── UploadFile.test.jsx
│   │   │   │   │   │   │   │   ├── UploadFileModal.test.jsx
│   │   │   │   │   │   │   │   ├── UrlPanel.test.jsx
│   │   │   │   │   │   │   │   └── doFileUpload.test.jsx
│   │   │   │   │   │   │   ├── doFileUpload.tsx
│   │   │   │   │   │   │   └── index.ts
│   │   │   │   │   │   ├── __mocks__
│   │   │   │   │   │   │   └── screenfull.js
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── CanvasContentTray.test.jsx
│   │   │   │   │   │   │   ├── CheckerboardStyling.test.js
│   │   │   │   │   │   │   ├── ColorInput.test.jsx
│   │   │   │   │   │   │   ├── ConditionalTooltip.test.jsx
│   │   │   │   │   │   │   ├── ContentSelection.test.js
│   │   │   │   │   │   │   ├── DimensionUtils.test.js
│   │   │   │   │   │   │   ├── EventUtils.test.ts
│   │   │   │   │   │   │   ├── Filter.1.test.jsx
│   │   │   │   │   │   │   ├── Filter.2.test.jsx
│   │   │   │   │   │   │   ├── FixedContentTray.test.jsx
│   │   │   │   │   │   │   ├── ImageOptionsForm.test.jsx
│   │   │   │   │   │   │   ├── LinkDisplay.test.jsx
│   │   │   │   │   │   │   ├── PreviewIcon.test.jsx
│   │   │   │   │   │   │   ├── RceFileBrowser.test.jsx
│   │   │   │   │   │   │   ├── StudioLtiSupportUtils.test.ts
│   │   │   │   │   │   │   ├── buildDownloadUrl.test.js
│   │   │   │   │   │   │   ├── compressionUtils.test.js
│   │   │   │   │   │   │   ├── dateUtils.test.js
│   │   │   │   │   │   │   ├── fileShape.test.js
│   │   │   │   │   │   │   ├── fileTypeUtils.test.ts
│   │   │   │   │   │   │   ├── fileUtils.test.js
│   │   │   │   │   │   │   ├── linkUtils.test.jsx
│   │   │   │   │   │   │   ├── round.test.js
│   │   │   │   │   │   │   ├── trayUtils.test.js
│   │   │   │   │   │   │   └── useDataUrl.test.js
│   │   │   │   │   │   ├── ai_tools
│   │   │   │   │   │   │   ├── AIResponseModal.tsx
│   │   │   │   │   │   │   ├── AIToolsTray.tsx
│   │   │   │   │   │   │   ├── aiicons.tsx
│   │   │   │   │   │   │   └── index.ts
│   │   │   │   │   │   ├── buildDownloadUrl.js
│   │   │   │   │   │   ├── canvasContentUtils.tsx
│   │   │   │   │   │   ├── compressionUtils.js
│   │   │   │   │   │   ├── dateUtils.js
│   │   │   │   │   │   ├── do-fetch-api-effect
│   │   │   │   │   │   │   ├── README.md
│   │   │   │   │   │   │   ├── defaultFetchOptions.ts
│   │   │   │   │   │   │   ├── doFetchApi.ts
│   │   │   │   │   │   │   ├── get-cookie.ts
│   │   │   │   │   │   │   ├── index.ts
│   │   │   │   │   │   │   ├── parse-link-header.ts
│   │   │   │   │   │   │   └── query-string-encoding.ts
│   │   │   │   │   │   ├── fileShape.js
│   │   │   │   │   │   ├── fileTypeUtils.ts
│   │   │   │   │   │   ├── fileUtils.js
│   │   │   │   │   │   ├── linkUtils.jsx
│   │   │   │   │   │   ├── round.js
│   │   │   │   │   │   ├── trayUtils.js
│   │   │   │   │   │   ├── useDataUrl.js
│   │   │   │   │   │   └── useFilterSettings.ts
│   │   │   │   │   └── tinymce-a11y-checker
│   │   │   │   │       ├── CHANGELOG.md
│   │   │   │   │       ├── components
│   │   │   │   │       │   ├── ColorField.tsx
│   │   │   │   │       │   ├── __tests__
│   │   │   │   │       │   │   ├── ColorField.test.jsx
│   │   │   │   │       │   │   ├── __snapshots__
│   │   │   │   │       │   │   │   └── checker.test.jsx.snap
│   │   │   │   │       │   │   └── checker.test.jsx
│   │   │   │   │       │   ├── checker.jsx
│   │   │   │   │       │   ├── color-picker.jsx
│   │   │   │   │       │   ├── placeholder-svg.jsx
│   │   │   │   │       │   └── pointer.jsx
│   │   │   │   │       ├── node-checker.js
│   │   │   │   │       ├── plugin.jsx
│   │   │   │   │       ├── rules
│   │   │   │   │       │   ├── __mocks__
│   │   │   │   │       │   │   └── index.js
│   │   │   │   │       │   ├── __tests__
│   │   │   │   │       │   │   ├── __snapshots__
│   │   │   │   │       │   │   │   ├── adjacent-links.test.js.snap
│   │   │   │   │       │   │   │   ├── headings-sequence.test.js.snap
│   │   │   │   │       │   │   │   ├── headings-start-at-h2.test.js.snap
│   │   │   │   │       │   │   │   ├── img-alt-filename.test.js.snap
│   │   │   │   │       │   │   │   ├── img-alt-length.test.js.snap
│   │   │   │   │       │   │   │   ├── img-alt.test.js.snap
│   │   │   │   │       │   │   │   ├── large-text-contrast.test.js.snap
│   │   │   │   │       │   │   │   ├── list-structure.test.js.snap
│   │   │   │   │       │   │   │   ├── paragraphs-for-headings.test.js.snap
│   │   │   │   │       │   │   │   ├── small-text-contrast.test.js.snap
│   │   │   │   │       │   │   │   ├── table-caption.test.js.snap
│   │   │   │   │       │   │   │   ├── table-header-scope.test.js.snap
│   │   │   │   │       │   │   │   └── table-header.test.js.snap
│   │   │   │   │       │   │   ├── adjacent-links.test.js
│   │   │   │   │       │   │   ├── headings-sequence.test.js
│   │   │   │   │       │   │   ├── headings-start-at-h2.test.js
│   │   │   │   │       │   │   ├── img-alt-filename.test.js
│   │   │   │   │       │   │   ├── img-alt-length.test.js
│   │   │   │   │       │   │   ├── img-alt.test.js
│   │   │   │   │       │   │   ├── index.test.js
│   │   │   │   │       │   │   ├── large-text-contrast.test.js
│   │   │   │   │       │   │   ├── list-structure.test.js
│   │   │   │   │       │   │   ├── paragraphs-for-headings.test.js
│   │   │   │   │       │   │   ├── small-text-contrast.test.js
│   │   │   │   │       │   │   ├── table-caption.test.js
│   │   │   │   │       │   │   ├── table-header-scope.test.js
│   │   │   │   │       │   │   └── table-header.test.js
│   │   │   │   │       │   ├── adjacent-links.js
│   │   │   │   │       │   ├── headings-sequence.js
│   │   │   │   │       │   ├── headings-start-at-h2.js
│   │   │   │   │       │   ├── img-alt-filename.js
│   │   │   │   │       │   ├── img-alt-length.js
│   │   │   │   │       │   ├── img-alt.js
│   │   │   │   │       │   ├── index.js
│   │   │   │   │       │   ├── large-text-contrast.js
│   │   │   │   │       │   ├── list-structure.js
│   │   │   │   │       │   ├── paragraphs-for-headings.js
│   │   │   │   │       │   ├── small-text-contrast.js
│   │   │   │   │       │   ├── table-caption.js
│   │   │   │   │       │   ├── table-header-scope.js
│   │   │   │   │       │   └── table-header.js
│   │   │   │   │       └── utils
│   │   │   │   │           ├── __tests__
│   │   │   │   │           │   ├── colors.test.ts
│   │   │   │   │           │   ├── describe.test.js
│   │   │   │   │           │   ├── dom.test.js
│   │   │   │   │           │   ├── indicate.test.js
│   │   │   │   │           │   ├── rule-enhancer.test.js
│   │   │   │   │           │   └── strings.test.js
│   │   │   │   │           ├── colors.ts
│   │   │   │   │           ├── describe.js
│   │   │   │   │           ├── dom.js
│   │   │   │   │           ├── indicate.js
│   │   │   │   │           ├── rgb-hex.js
│   │   │   │   │           ├── rule-enhancer.js
│   │   │   │   │           └── strings.js
│   │   │   │   ├── root.tsx
│   │   │   │   ├── sanitizePlugins.js
│   │   │   │   ├── screenreaderOnFormat.ts
│   │   │   │   ├── style.js
│   │   │   │   ├── tinyRCE.js
│   │   │   │   ├── tinymce.oxide.content.min.css.js
│   │   │   │   ├── tinymce.oxide.skin.min.css.js
│   │   │   │   ├── transformContent.ts
│   │   │   │   ├── types.ts
│   │   │   │   ├── userOS.ts
│   │   │   │   └── wrapInitCb.ts
│   │   │   ├── rcs
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── api.test.js
│   │   │   │   │   └── buildError.test.js
│   │   │   │   ├── api.js
│   │   │   │   ├── buildError.js
│   │   │   │   └── fake.js
│   │   │   ├── sidebar
│   │   │   │   ├── __tests__
│   │   │   │   │   └── dragHtml.test.js
│   │   │   │   ├── actions
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   ├── documents.test.js
│   │   │   │   │   │   ├── files.test.js
│   │   │   │   │   │   ├── filter.test.js
│   │   │   │   │   │   ├── flickr.test.js
│   │   │   │   │   │   ├── images.test.js
│   │   │   │   │   │   ├── media.test.js
│   │   │   │   │   │   ├── session.test.js
│   │   │   │   │   │   ├── upload.test.js
│   │   │   │   │   │   └── utils.js
│   │   │   │   │   ├── all_files.js
│   │   │   │   │   ├── data.js
│   │   │   │   │   ├── documents.js
│   │   │   │   │   ├── files.js
│   │   │   │   │   ├── filter.js
│   │   │   │   │   ├── flickr.js
│   │   │   │   │   ├── images.js
│   │   │   │   │   ├── links.js
│   │   │   │   │   ├── media.js
│   │   │   │   │   ├── session.js
│   │   │   │   │   ├── ui.js
│   │   │   │   │   └── upload.js
│   │   │   │   ├── containers
│   │   │   │   │   ├── Sidebar.js
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   └── sidebarHandlers.test.js
│   │   │   │   │   └── sidebarHandlers.js
│   │   │   │   ├── dragHtml.ts
│   │   │   │   ├── reducers
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   ├── collection.test.js
│   │   │   │   │   │   ├── context.test.js
│   │   │   │   │   │   ├── documents.test.js
│   │   │   │   │   │   ├── files.test.js
│   │   │   │   │   │   ├── flickr.test.js
│   │   │   │   │   │   ├── folder.test.js
│   │   │   │   │   │   ├── folders.test.js
│   │   │   │   │   │   ├── images.test.js
│   │   │   │   │   │   ├── reducers.test.js
│   │   │   │   │   │   ├── session.test.js
│   │   │   │   │   │   ├── ui.test.js
│   │   │   │   │   │   └── upload.test.js
│   │   │   │   │   ├── all_files.js
│   │   │   │   │   ├── collection.js
│   │   │   │   │   ├── collections.js
│   │   │   │   │   ├── documents.js
│   │   │   │   │   ├── files.js
│   │   │   │   │   ├── filter.js
│   │   │   │   │   ├── flickr.js
│   │   │   │   │   ├── folder.js
│   │   │   │   │   ├── folders.js
│   │   │   │   │   ├── images.js
│   │   │   │   │   ├── index.js
│   │   │   │   │   ├── media.js
│   │   │   │   │   ├── newPageLinkExpanded.js
│   │   │   │   │   ├── noop.js
│   │   │   │   │   ├── rootFolderId.js
│   │   │   │   │   ├── session.js
│   │   │   │   │   ├── ui.js
│   │   │   │   │   └── upload.js
│   │   │   │   └── store
│   │   │   │       ├── __tests__
│   │   │   │       │   └── initialState.test.js
│   │   │   │       ├── configureStore.js
│   │   │   │       └── initialState.js
│   │   │   ├── translations
│   │   │   │   ├── locales
│   │   │   │   │   ├── ab.js
│   │   │   │   │   ├── ar.js
│   │   │   │   │   ├── ca.js
│   │   │   │   │   ├── cs.js
│   │   │   │   │   ├── cs_CZ.js
│   │   │   │   │   ├── cy.js
│   │   │   │   │   ├── da-x-k12.js
│   │   │   │   │   ├── da.js
│   │   │   │   │   ├── da_DK.js
│   │   │   │   │   ├── de.js
│   │   │   │   │   ├── el.js
│   │   │   │   │   ├── en-AU-x-unimelb.js
│   │   │   │   │   ├── en-GB-x-ukhe.js
│   │   │   │   │   ├── en.js
│   │   │   │   │   ├── en_AU.js
│   │   │   │   │   ├── en_CA.js
│   │   │   │   │   ├── en_CY.js
│   │   │   │   │   ├── en_GB.js
│   │   │   │   │   ├── en_NZ.js
│   │   │   │   │   ├── en_SE.js
│   │   │   │   │   ├── en_US.js
│   │   │   │   │   ├── es.js
│   │   │   │   │   ├── es_ES.js
│   │   │   │   │   ├── es_GT.js
│   │   │   │   │   ├── fa_IR.js
│   │   │   │   │   ├── fi.js
│   │   │   │   │   ├── fr.js
│   │   │   │   │   ├── fr_CA.js
│   │   │   │   │   ├── ga.js
│   │   │   │   │   ├── he.js
│   │   │   │   │   ├── hi.js
│   │   │   │   │   ├── ht.js
│   │   │   │   │   ├── hu.js
│   │   │   │   │   ├── hu_HU.js
│   │   │   │   │   ├── hy.js
│   │   │   │   │   ├── id.js
│   │   │   │   │   ├── id_ID.js
│   │   │   │   │   ├── is.js
│   │   │   │   │   ├── it.js
│   │   │   │   │   ├── ja.js
│   │   │   │   │   ├── ko.js
│   │   │   │   │   ├── ko_KR.js
│   │   │   │   │   ├── lt.js
│   │   │   │   │   ├── lt_LT.js
│   │   │   │   │   ├── mi.js
│   │   │   │   │   ├── mn_MN.js
│   │   │   │   │   ├── ms.js
│   │   │   │   │   ├── nb-x-k12.js
│   │   │   │   │   ├── nb.js
│   │   │   │   │   ├── nl.js
│   │   │   │   │   ├── nl_NL.js
│   │   │   │   │   ├── nn.js
│   │   │   │   │   ├── pl.js
│   │   │   │   │   ├── pt.js
│   │   │   │   │   ├── pt_BR.js
│   │   │   │   │   ├── ro.js
│   │   │   │   │   ├── ru.js
│   │   │   │   │   ├── se.js
│   │   │   │   │   ├── sl.js
│   │   │   │   │   ├── sv-x-k12.js
│   │   │   │   │   ├── sv.js
│   │   │   │   │   ├── sv_SE.js
│   │   │   │   │   ├── tg.js
│   │   │   │   │   ├── th.js
│   │   │   │   │   ├── th_TH.js
│   │   │   │   │   ├── tl_PH.js
│   │   │   │   │   ├── tr.js
│   │   │   │   │   ├── uk_UA.js
│   │   │   │   │   ├── vi.js
│   │   │   │   │   ├── vi_VN.js
│   │   │   │   │   ├── zh-Hans.js
│   │   │   │   │   ├── zh-Hant.js
│   │   │   │   │   ├── zh.js
│   │   │   │   │   ├── zh_HK.js
│   │   │   │   │   ├── zh_TW.Big5.js
│   │   │   │   │   └── zh_TW.js
│   │   │   │   └── tinymce
│   │   │   │       ├── ar_SA.js
│   │   │   │       ├── bg_BG.js
│   │   │   │       ├── ca.js
│   │   │   │       ├── cs.js
│   │   │   │       ├── cy.js
│   │   │   │       ├── da.js
│   │   │   │       ├── de.js
│   │   │   │       ├── el.js
│   │   │   │       ├── en_GB.js
│   │   │   │       ├── es.js
│   │   │   │       ├── fa_IR.js
│   │   │   │       ├── fi.js
│   │   │   │       ├── fr_FR.js
│   │   │   │       ├── ga.js
│   │   │   │       ├── he_IL.js
│   │   │   │       ├── hu_HU.js
│   │   │   │       ├── hy.js
│   │   │   │       ├── id.js
│   │   │   │       ├── it.js
│   │   │   │       ├── ja.js
│   │   │   │       ├── ko_KR.js
│   │   │   │       ├── nb_NO.js
│   │   │   │       ├── nl.js
│   │   │   │       ├── pl.js
│   │   │   │       ├── pt_BR.js
│   │   │   │       ├── pt_PT.js
│   │   │   │       ├── ro.js
│   │   │   │       ├── ru.js
│   │   │   │       ├── ru_RU.js
│   │   │   │       ├── sl.js
│   │   │   │       ├── sr.js
│   │   │   │       ├── sv_SE.js
│   │   │   │       ├── th.js
│   │   │   │       ├── tr_TR.js
│   │   │   │       ├── uk_UA.js
│   │   │   │       ├── vi_VN.js
│   │   │   │       ├── zh_CN.js
│   │   │   │       └── zh_TW.js
│   │   │   └── util
│   │   │       ├── DeepPartialNullable.ts
│   │   │       ├── ExtractRequired.ts
│   │   │       ├── TypedDict.ts
│   │   │       ├── __tests__
│   │   │       │   ├── contextHelper.test.ts
│   │   │       │   ├── deepMockProxy.test.ts
│   │   │       │   ├── deepMockProxy.ts
│   │   │       │   ├── jsdomInnerText.ts
│   │   │       │   ├── loadingPlaceholder.test.ts
│   │   │       │   ├── simpleCache.test.ts
│   │   │       │   ├── textarea-editing-util.test.ts
│   │   │       │   └── url-util.test.ts
│   │   │       ├── assertNever.ts
│   │   │       ├── contextHelper.ts
│   │   │       ├── elem-util.ts
│   │   │       ├── encrypted-storage.ts
│   │   │       ├── file-url-util.ts
│   │   │       ├── fullscreenHelpers.ts
│   │   │       ├── instui-icon-helper.ts
│   │   │       ├── loadingPlaceholder.ts
│   │   │       ├── simpleCache.ts
│   │   │       ├── string-util.ts
│   │   │       ├── textarea-editing-util.ts
│   │   │       ├── tinymce-plugin-util.ts
│   │   │       └── url-util.ts
│   │   ├── testcafe
│   │   │   ├── RCEWrapper.test.js
│   │   │   ├── StatusBar.test.js
│   │   │   ├── axe.test.js
│   │   │   ├── enhanceUserContent.html
│   │   │   ├── enhanceUserContent.test.js
│   │   │   ├── entry.jsx
│   │   │   └── testcafe.html
│   │   ├── tsconfig.json
│   │   ├── types
│   │   │   ├── format-message-generate-id.d.ts
│   │   │   └── js-beautify.d.ts
│   │   ├── webpack.demo.config.js
│   │   ├── webpack.dev.config.js
│   │   ├── webpack.shared.config.js
│   │   └── webpack.testcafe.config.js
│   ├── date-js
│   │   ├── LICENSE.txt
│   │   ├── core.js
│   │   ├── eslint.config.js
│   │   ├── globalization
│   │   │   └── en-US.js
│   │   ├── package.json
│   │   ├── parser.js
│   │   └── sugarpak.js
│   ├── date-js-alias
│   │   ├── package.json
│   │   └── parser.js
│   ├── defer-promise
│   │   ├── __tests__
│   │   │   └── deferPromise.test.js
│   │   ├── index.d.ts
│   │   ├── index.js
│   │   └── package.json
│   ├── deparam
│   │   ├── index.js
│   │   └── package.json
│   ├── filter-console-messages
│   │   ├── index.js
│   │   └── package.json
│   ├── force-screenreader-to-reparse
│   │   ├── index.js
│   │   └── package.json
│   ├── format-message-estree-util
│   │   ├── index.js
│   │   ├── jsx.js
│   │   └── package.json
│   ├── get-cookie
│   │   ├── __tests__
│   │   │   └── index.test.js
│   │   ├── index.js
│   │   └── package.json
│   ├── grading-utils
│   │   ├── CHANGELOG.md
│   │   ├── README.md
│   │   ├── package.json
│   │   └── src
│   │       ├── __tests__
│   │       │   └── index.test.js
│   │       └── index.js
│   ├── html-escape
│   │   ├── index.js
│   │   └── package.json
│   ├── html-escape-old
│   │   ├── index.js
│   │   └── package.json
│   ├── jquery
│   │   ├── eslint.config.js
│   │   ├── jquery.js
│   │   └── package.json
│   ├── jquery-fancy-placeholder
│   │   ├── index.js
│   │   └── package.json
│   ├── jquery-kyle-menu
│   │   ├── index.js
│   │   ├── monkey-patches.js
│   │   ├── package.json
│   │   └── popup.js
│   ├── jquery-pageless
│   │   ├── eslint.config.js
│   │   ├── index.js
│   │   └── package.json
│   ├── jquery-popover
│   │   ├── index.js
│   │   └── package.json
│   ├── jquery-qtip
│   │   ├── index.js
│   │   └── package.json
│   ├── jquery-scroll-into-view
│   │   ├── index.js
│   │   └── package.json
│   ├── jquery-scroll-to-visible
│   │   ├── eslint.config.js
│   │   ├── index.js
│   │   ├── jquery.scrollTo.js
│   │   └── package.json
│   ├── jquery-selectmenu
│   │   ├── index.js
│   │   └── package.json
│   ├── jquery-tinypubsub
│   │   ├── eslint.config.js
│   │   ├── index.js
│   │   └── package.json
│   ├── jqueryui
│   │   ├── autocomplete.js
│   │   ├── button.js
│   │   ├── core.js
│   │   ├── datepicker.js
│   │   ├── dialog.js
│   │   ├── draggable.js
│   │   ├── droppable.js
│   │   ├── eslint.config.js
│   │   ├── menu.js
│   │   ├── mouse.js
│   │   ├── package.json
│   │   ├── position.js
│   │   ├── progressbar.js
│   │   ├── resizable.js
│   │   ├── sortable.js
│   │   ├── tabs.js
│   │   ├── tooltip.js
│   │   └── widget.js
│   ├── k5uploader
│   │   ├── CHANGELOG.md
│   │   ├── LICENSE
│   │   ├── README.md
│   │   ├── biome.json
│   │   ├── package.json
│   │   ├── src
│   │   │   ├── __tests__
│   │   │   │   ├── entry_service.test.js
│   │   │   │   ├── kaltura_request_builder.test.js
│   │   │   │   ├── ui_config.test.js
│   │   │   │   ├── uiconf_service.test.js
│   │   │   │   └── upload_result.test.js
│   │   │   ├── defaults.js
│   │   │   ├── entry_service.js
│   │   │   ├── file_filter.js
│   │   │   ├── filter_from_node.js
│   │   │   ├── index.d.ts
│   │   │   ├── index.js
│   │   │   ├── k5_options.js
│   │   │   ├── kaltura_request_builder.js
│   │   │   ├── kaltura_session.js
│   │   │   ├── md5.js
│   │   │   ├── message_bus.js
│   │   │   ├── messenger.js
│   │   │   ├── object_merge.js
│   │   │   ├── session_manager.js
│   │   │   ├── signature_builder.js
│   │   │   ├── ui_config.js
│   │   │   ├── ui_config_from_node.js
│   │   │   ├── uiconf_service.js
│   │   │   ├── upload_result.js
│   │   │   ├── uploader.js
│   │   │   └── url_params.js
│   │   ├── tsconfig.json
│   │   └── vitest.config.ts
│   ├── link-header-parsing
│   │   ├── __tests__
│   │   │   ├── __snapshots__
│   │   │   │   └── parseLinkHeaderFromAxios.test.js.snap
│   │   │   └── parseLinkHeaderFromAxios.test.js
│   │   ├── package.json
│   │   ├── parseLinkHeader.js
│   │   ├── parseLinkHeaderFromAxios.js
│   │   ├── parseLinkHeaderFromXHR.d.ts
│   │   └── parseLinkHeaderFromXHR.js
│   ├── moment-utils
│   │   ├── __tests__
│   │   │   ├── changeTimezone.test.js
│   │   │   └── index.test.js
│   │   ├── changeTimezone.js
│   │   ├── datePickerFormat.js
│   │   ├── datetime.js
│   │   ├── formats.js
│   │   ├── index.js
│   │   ├── package.json
│   │   └── specHelpers.js
│   ├── obj-unflatten
│   │   ├── index.js
│   │   └── package.json
│   ├── query-string-encoding
│   │   ├── __tests__
│   │   │   └── index.test.ts
│   │   ├── index.d.ts
│   │   ├── index.js
│   │   └── package.json
│   ├── react-dnd-test-backend
│   │   ├── eslint.config.js
│   │   ├── index.js
│   │   └── package.json
│   ├── ready
│   │   ├── index.js
│   │   └── package.json
│   ├── sanitize-html-with-tinymce
│   │   ├── __tests__
│   │   │   └── index.test.js
│   │   ├── index.js
│   │   └── package.json
│   ├── slickgrid
│   │   ├── eslint.config.js
│   │   ├── images
│   │   │   ├── sort-asc.gif
│   │   │   └── sort-desc.gif
│   │   ├── index.js
│   │   ├── jquery.event.drag-2.2.js
│   │   ├── package.json
│   │   ├── plugins
│   │   │   └── slick.rowselectionmodel.js
│   │   ├── slick.core.js
│   │   ├── slick.editors.js
│   │   ├── slick.grid.js
│   │   └── slick.grid.scss
│   └── translations
│       ├── __mocks__
│       │   ├── fs.js
│       │   └── path.js
│       ├── bin
│       │   ├── __tests__
│       │   │   └── split-strings.test.js
│       │   ├── cli.js
│       │   ├── get-translation-list.js
│       │   ├── read-translation-file.js
│       │   └── split-strings.js
│       ├── index.js
│       ├── jest.config.js
│       ├── lib
│       │   ├── ab.json
│       │   ├── ar.json
│       │   ├── ca.json
│       │   ├── canvas-media
│       │   │   ├── ab.json
│       │   │   ├── ar.json
│       │   │   ├── ca.json
│       │   │   ├── cs.json
│       │   │   ├── cs_CZ.json
│       │   │   ├── cy.json
│       │   │   ├── da-x-k12.json
│       │   │   ├── da.json
│       │   │   ├── da_DK.json
│       │   │   ├── de.json
│       │   │   ├── el.json
│       │   │   ├── en-AU-x-unimelb.json
│       │   │   ├── en-GB-x-ukhe.json
│       │   │   ├── en.json
│       │   │   ├── en_AU.json
│       │   │   ├── en_CA.json
│       │   │   ├── en_CY.json
│       │   │   ├── en_GB.json
│       │   │   ├── en_NZ.json
│       │   │   ├── en_SE.json
│       │   │   ├── en_US.json
│       │   │   ├── es.json
│       │   │   ├── es_ES.json
│       │   │   ├── es_GT.json
│       │   │   ├── fa_IR.json
│       │   │   ├── fi.json
│       │   │   ├── fr.json
│       │   │   ├── fr_CA.json
│       │   │   ├── ga.json
│       │   │   ├── he.json
│       │   │   ├── hi.json
│       │   │   ├── ht.json
│       │   │   ├── hu.json
│       │   │   ├── hu_HU.json
│       │   │   ├── hy.json
│       │   │   ├── id.json
│       │   │   ├── id_ID.json
│       │   │   ├── is.json
│       │   │   ├── it.json
│       │   │   ├── ja.json
│       │   │   ├── ko.json
│       │   │   ├── ko_KR.json
│       │   │   ├── lt.json
│       │   │   ├── lt_LT.json
│       │   │   ├── mi.json
│       │   │   ├── mn_MN.json
│       │   │   ├── ms.json
│       │   │   ├── nb-x-k12.json
│       │   │   ├── nb.json
│       │   │   ├── nl.json
│       │   │   ├── nl_NL.json
│       │   │   ├── nn.json
│       │   │   ├── pl.json
│       │   │   ├── pt.json
│       │   │   ├── pt_BR.json
│       │   │   ├── ro.json
│       │   │   ├── ru.json
│       │   │   ├── se.json
│       │   │   ├── sl.json
│       │   │   ├── sv-x-k12.json
│       │   │   ├── sv.json
│       │   │   ├── sv_SE.json
│       │   │   ├── tg.json
│       │   │   ├── th.json
│       │   │   ├── th_TH.json
│       │   │   ├── tl_PH.json
│       │   │   ├── tr.json
│       │   │   ├── uk_UA.json
│       │   │   ├── vi.json
│       │   │   ├── vi_VN.json
│       │   │   ├── zh-Hans.json
│       │   │   ├── zh-Hant.json
│       │   │   ├── zh.json
│       │   │   ├── zh_HK.json
│       │   │   ├── zh_TW.Big5.json
│       │   │   └── zh_TW.json
│       │   ├── canvas-rce
│       │   │   ├── ab.json
│       │   │   ├── ar.json
│       │   │   ├── ca.json
│       │   │   ├── cs.json
│       │   │   ├── cs_CZ.json
│       │   │   ├── cy.json
│       │   │   ├── da-x-k12.json
│       │   │   ├── da.json
│       │   │   ├── da_DK.json
│       │   │   ├── de.json
│       │   │   ├── el.json
│       │   │   ├── en-AU-x-unimelb.json
│       │   │   ├── en-GB-x-ukhe.json
│       │   │   ├── en.json
│       │   │   ├── en_AU.json
│       │   │   ├── en_CA.json
│       │   │   ├── en_CY.json
│       │   │   ├── en_GB.json
│       │   │   ├── en_NZ.json
│       │   │   ├── en_SE.json
│       │   │   ├── en_US.json
│       │   │   ├── es.json
│       │   │   ├── es_ES.json
│       │   │   ├── es_GT.json
│       │   │   ├── fa_IR.json
│       │   │   ├── fi.json
│       │   │   ├── fr.json
│       │   │   ├── fr_CA.json
│       │   │   ├── ga.json
│       │   │   ├── he.json
│       │   │   ├── hi.json
│       │   │   ├── ht.json
│       │   │   ├── hu.json
│       │   │   ├── hu_HU.json
│       │   │   ├── hy.json
│       │   │   ├── id.json
│       │   │   ├── id_ID.json
│       │   │   ├── is.json
│       │   │   ├── it.json
│       │   │   ├── ja.json
│       │   │   ├── ko.json
│       │   │   ├── ko_KR.json
│       │   │   ├── lt.json
│       │   │   ├── lt_LT.json
│       │   │   ├── mi.json
│       │   │   ├── mn_MN.json
│       │   │   ├── ms.json
│       │   │   ├── nb-x-k12.json
│       │   │   ├── nb.json
│       │   │   ├── nl.json
│       │   │   ├── nl_NL.json
│       │   │   ├── nn.json
│       │   │   ├── pl.json
│       │   │   ├── pt.json
│       │   │   ├── pt_BR.json
│       │   │   ├── ro.json
│       │   │   ├── ru.json
│       │   │   ├── se.json
│       │   │   ├── sl.json
│       │   │   ├── sv-x-k12.json
│       │   │   ├── sv.json
│       │   │   ├── sv_SE.json
│       │   │   ├── tg.json
│       │   │   ├── th.json
│       │   │   ├── th_TH.json
│       │   │   ├── tl_PH.json
│       │   │   ├── tr.json
│       │   │   ├── uk_UA.json
│       │   │   ├── vi.json
│       │   │   ├── vi_VN.json
│       │   │   ├── zh-Hans.json
│       │   │   ├── zh-Hant.json
│       │   │   ├── zh.json
│       │   │   ├── zh_HK.json
│       │   │   ├── zh_TW.Big5.json
│       │   │   └── zh_TW.json
│       │   ├── cs.json
│       │   ├── cs_CZ.json
│       │   ├── cy.json
│       │   ├── da-x-k12.json
│       │   ├── da.json
│       │   ├── da_DK.json
│       │   ├── de.json
│       │   ├── el.json
│       │   ├── en-AU-x-unimelb.json
│       │   ├── en-GB-x-ukhe.json
│       │   ├── en.json
│       │   ├── en_AU.json
│       │   ├── en_CA.json
│       │   ├── en_CY.json
│       │   ├── en_GB.json
│       │   ├── en_NZ.json
│       │   ├── en_SE.json
│       │   ├── en_US.json
│       │   ├── es.json
│       │   ├── es_ES.json
│       │   ├── es_GT.json
│       │   ├── fa_IR.json
│       │   ├── fi.json
│       │   ├── fr.json
│       │   ├── fr_CA.json
│       │   ├── ga.json
│       │   ├── he.json
│       │   ├── hi.json
│       │   ├── ht.json
│       │   ├── hu.json
│       │   ├── hu_HU.json
│       │   ├── hy.json
│       │   ├── id.json
│       │   ├── id_ID.json
│       │   ├── is.json
│       │   ├── it.json
│       │   ├── ja.json
│       │   ├── ko.json
│       │   ├── ko_KR.json
│       │   ├── lt.json
│       │   ├── lt_LT.json
│       │   ├── mi.json
│       │   ├── mn_MN.json
│       │   ├── ms.json
│       │   ├── nb-x-k12.json
│       │   ├── nb.json
│       │   ├── nl.json
│       │   ├── nl_NL.json
│       │   ├── nn.json
│       │   ├── pl.json
│       │   ├── pt.json
│       │   ├── pt_BR.json
│       │   ├── ro.json
│       │   ├── ru.json
│       │   ├── se.json
│       │   ├── sl.json
│       │   ├── sv-x-k12.json
│       │   ├── sv.json
│       │   ├── sv_SE.json
│       │   ├── tg.json
│       │   ├── th.json
│       │   ├── th_TH.json
│       │   ├── tl_PH.json
│       │   ├── tr.json
│       │   ├── uk_UA.json
│       │   ├── vi.json
│       │   ├── vi_VN.json
│       │   ├── zh-Hans.json
│       │   ├── zh-Hant.json
│       │   ├── zh.json
│       │   ├── zh_HK.json
│       │   ├── zh_TW.Big5.json
│       │   └── zh_TW.json
│       └── package.json
├── patches
│   └── format-message+6.2.3.patch
├── public
│   ├── 422.html
│   ├── 500.html
│   ├── Canvas.png
│   ├── _crossdomain.xml
│   ├── apple-touch-icon.png
│   ├── dimdim_welcome.html
│   ├── drawing.html
│   ├── enable-javascript.html
│   ├── equella_cancel.html
│   ├── equella_success.html
│   ├── favicon.ico
│   ├── file_removed
│   │   └── file_removed.pdf
│   ├── fonts
│   │   ├── Symbola.eot
│   │   ├── Symbola.otf
│   │   ├── Symbola.svg
│   │   ├── Symbola.ttf
│   │   ├── Symbola.woff
│   │   ├── architects_daughter
│   │   │   └── ArchitectsDaughter-Regular.woff2
│   │   ├── balsamiq_sans
│   │   │   ├── BalsamiqSans-Bold.woff2
│   │   │   ├── BalsamiqSans-BoldItalic.woff2
│   │   │   ├── BalsamiqSans-Italic.woff2
│   │   │   └── BalsamiqSans-Regular.woff2
│   │   ├── canvas
│   │   │   ├── canvas-icons.eot
│   │   │   ├── canvas-icons.svg
│   │   │   ├── canvas-icons.ttf
│   │   │   └── canvas-icons.woff
│   │   ├── icons
│   │   │   ├── add.svg
│   │   │   ├── address-book.svg
│   │   │   ├── analytics.svg
│   │   │   ├── android.svg
│   │   │   ├── announcement.svg
│   │   │   ├── apple.svg
│   │   │   ├── arrow-down.svg
│   │   │   ├── arrow-left.svg
│   │   │   ├── arrow-open-left.svg
│   │   │   ├── arrow-open-right.svg
│   │   │   ├── arrow-right.svg
│   │   │   ├── arrow-up.svg
│   │   │   ├── assignment.svg
│   │   │   ├── audio.svg
│   │   │   ├── bookmark.svg
│   │   │   ├── calendar-day.svg
│   │   │   ├── calendar-days.svg
│   │   │   ├── calendar-month.svg
│   │   │   ├── check-dark.svg
│   │   │   ├── check-mark.svg
│   │   │   ├── check-plus.svg
│   │   │   ├── check.svg
│   │   │   ├── clock.svg
│   │   │   ├── cloud-lock.svg
│   │   │   ├── collapse.svg
│   │   │   ├── collection-save.svg
│   │   │   ├── collection.svg
│   │   │   ├── commons.svg
│   │   │   ├── complete.svg
│   │   │   ├── compose.svg
│   │   │   ├── copy-course.svg
│   │   │   ├── discussion-check.svg
│   │   │   ├── discussion-new.svg
│   │   │   ├── discussion-reply-2.svg
│   │   │   ├── discussion-reply-dark.svg
│   │   │   ├── discussion-reply.svg
│   │   │   ├── discussion-search.svg
│   │   │   ├── discussion-x.svg
│   │   │   ├── discussion.svg
│   │   │   ├── document.svg
│   │   │   ├── download.svg
│   │   │   ├── drag-handle.svg
│   │   │   ├── drop-down.svg
│   │   │   ├── edit.svg
│   │   │   ├── educators.svg
│   │   │   ├── email.svg
│   │   │   ├── empty.svg
│   │   │   ├── end.svg
│   │   │   ├── equation.svg
│   │   │   ├── equella.svg
│   │   │   ├── expand-items.svg
│   │   │   ├── expand.svg
│   │   │   ├── export-content.svg
│   │   │   ├── export.svg
│   │   │   ├── eye.svg
│   │   │   ├── facebook-boxed.svg
│   │   │   ├── facebook.svg
│   │   │   ├── files-copyright.svg
│   │   │   ├── files-creative-commons.svg
│   │   │   ├── files-fair-use.svg
│   │   │   ├── files-obtained-permission.svg
│   │   │   ├── files-public-domain.svg
│   │   │   ├── filmstrip.svg
│   │   │   ├── flag.svg
│   │   │   ├── folder-locked.svg
│   │   │   ├── folder.svg
│   │   │   ├── forward.svg
│   │   │   ├── github.svg
│   │   │   ├── gradebook-export.svg
│   │   │   ├── gradebook-import.svg
│   │   │   ├── gradebook.svg
│   │   │   ├── group-new-dark.svg
│   │   │   ├── group-new.svg
│   │   │   ├── group.svg
│   │   │   ├── hamburger.svg
│   │   │   ├── heart.svg
│   │   │   ├── home.svg
│   │   │   ├── hour-glass.svg
│   │   │   ├── image.svg
│   │   │   ├── import-content.svg
│   │   │   ├── import.svg
│   │   │   ├── indent.svg
│   │   │   ├── indent2.svg
│   │   │   ├── info.svg
│   │   │   ├── instructure.svg
│   │   │   ├── invitation.svg
│   │   │   ├── keyboard-shortcuts.svg
│   │   │   ├── like.svg
│   │   │   ├── link.svg
│   │   │   ├── linkedin.svg
│   │   │   ├── lock.svg
│   │   │   ├── lti.svg
│   │   │   ├── mark-as-read.svg
│   │   │   ├── masquerade.svg
│   │   │   ├── mastery-path.svg
│   │   │   ├── materials-required-light.svg
│   │   │   ├── materials-required.svg
│   │   │   ├── mature-light.svg
│   │   │   ├── mature.svg
│   │   │   ├── media.svg
│   │   │   ├── message.svg
│   │   │   ├── mini-arrow-down.svg
│   │   │   ├── mini-arrow-left.svg
│   │   │   ├── mini-arrow-right.svg
│   │   │   ├── mini-arrow-up.svg
│   │   │   ├── minimize.svg
│   │   │   ├── module.svg
│   │   │   ├── more.svg
│   │   │   ├── ms-excel.svg
│   │   │   ├── ms-ppt.svg
│   │   │   ├── ms-word.svg
│   │   │   ├── muted.svg
│   │   │   ├── next-unread.svg
│   │   │   ├── not-graded.svg
│   │   │   ├── note-dark.svg
│   │   │   ├── note-light.svg
│   │   │   ├── off.svg
│   │   │   ├── outdent.svg
│   │   │   ├── outdent2.svg
│   │   │   ├── paperclip.svg
│   │   │   ├── partial.svg
│   │   │   ├── pdf.svg
│   │   │   ├── peer-graded.svg
│   │   │   ├── peer-review.svg
│   │   │   ├── pin.svg
│   │   │   ├── pinterest.svg
│   │   │   ├── plus.svg
│   │   │   ├── post-to-sis.svg
│   │   │   ├── prerequisite.svg
│   │   │   ├── printer.svg
│   │   │   ├── publish.svg
│   │   │   ├── question.svg
│   │   │   ├── quiz-stats-avg.svg
│   │   │   ├── quiz-stats-deviation.svg
│   │   │   ├── quiz-stats-high.svg
│   │   │   ├── quiz-stats-low.svg
│   │   │   ├── quiz-stats-time.svg
│   │   │   ├── quiz.svg
│   │   │   ├── refresh.svg
│   │   │   ├── remove-from-collection.svg
│   │   │   ├── replied.svg
│   │   │   ├── reply-2.svg
│   │   │   ├── reply-all-2.svg
│   │   │   ├── reset.svg
│   │   │   ├── rss-add.svg
│   │   │   ├── rss.svg
│   │   │   ├── rubric-dark.svg
│   │   │   ├── rubric.svg
│   │   │   ├── search-address-book.svg
│   │   │   ├── search.svg
│   │   │   ├── settings-2.svg
│   │   │   ├── settings.svg
│   │   │   ├── skype.svg
│   │   │   ├── speed-grader.svg
│   │   │   ├── standards.svg
│   │   │   ├── star-light.svg
│   │   │   ├── star.svg
│   │   │   ├── stats.svg
│   │   │   ├── student-view.svg
│   │   │   ├── syllabus.svg
│   │   │   ├── table.svg
│   │   │   ├── tag.svg
│   │   │   ├── target.svg
│   │   │   ├── text-center.svg
│   │   │   ├── text-left.svg
│   │   │   ├── text-right.svg
│   │   │   ├── text.svg
│   │   │   ├── timer.svg
│   │   │   ├── toggle-left.svg
│   │   │   ├── toggle-right.svg
│   │   │   ├── trash.svg
│   │   │   ├── trouble.svg
│   │   │   ├── twitter-boxed.svg
│   │   │   ├── twitter.svg
│   │   │   ├── unknown2.svg
│   │   │   ├── unlock.svg
│   │   │   ├── unmuted.svg
│   │   │   ├── unpublish.svg
│   │   │   ├── unpublished.svg
│   │   │   ├── updown.svg
│   │   │   ├── upload.svg
│   │   │   ├── user-add.svg
│   │   │   ├── user.svg
│   │   │   ├── video.svg
│   │   │   ├── warning.svg
│   │   │   ├── windows.svg
│   │   │   ├── wordpress.svg
│   │   │   ├── x.svg
│   │   │   └── zipped.svg
│   │   ├── instructure_icons
│   │   │   ├── Line
│   │   │   │   ├── InstructureIcons-Line.css
│   │   │   │   ├── InstructureIcons-Line.eot
│   │   │   │   ├── InstructureIcons-Line.svg
│   │   │   │   ├── InstructureIcons-Line.ttf
│   │   │   │   ├── InstructureIcons-Line.woff
│   │   │   │   ├── InstructureIcons-Line.woff2
│   │   │   │   └── InstructureIcons-Line_icon-map.scss
│   │   │   ├── Solid
│   │   │   │   ├── InstructureIcons-Solid.css
│   │   │   │   ├── InstructureIcons-Solid.eot
│   │   │   │   ├── InstructureIcons-Solid.svg
│   │   │   │   ├── InstructureIcons-Solid.ttf
│   │   │   │   ├── InstructureIcons-Solid.woff
│   │   │   │   ├── InstructureIcons-Solid.woff2
│   │   │   │   └── InstructureIcons-Solid_icon-map.scss
│   │   │   └── index.js
│   │   ├── lato
│   │   │   ├── extended
│   │   │   │   ├── Lato-Bold.woff2
│   │   │   │   ├── Lato-BoldItalic.woff2
│   │   │   │   ├── Lato-Italic.woff2
│   │   │   │   ├── Lato-Light.woff2
│   │   │   │   └── Lato-Regular.woff2
│   │   │   └── latin
│   │   │       ├── LatoLatin-Bold.ttf
│   │   │       ├── LatoLatin-Italic.ttf
│   │   │       ├── LatoLatin-Light.ttf
│   │   │       └── LatoLatin-Regular.ttf
│   │   ├── open_dyslexic
│   │   │   ├── OpenDyslexic-Bold-Italic.woff2
│   │   │   ├── OpenDyslexic-Bold.woff2
│   │   │   ├── OpenDyslexic-Italic.woff2
│   │   │   ├── OpenDyslexic-Regular.woff2
│   │   │   └── OpenDyslexicMono-Regular.woff2
│   │   └── stixgeneral-bundle
│   │       ├── STIXFontLicense2010.txt
│   │       ├── stixgeneral-webfont.eot
│   │       ├── stixgeneral-webfont.svg
│   │       ├── stixgeneral-webfont.ttf
│   │       ├── stixgeneral-webfont.woff
│   │       ├── stixgeneralbol-webfont.eot
│   │       ├── stixgeneralbol-webfont.svg
│   │       ├── stixgeneralbol-webfont.ttf
│   │       ├── stixgeneralbol-webfont.woff
│   │       ├── stixgeneralbolita-webfont.eot
│   │       ├── stixgeneralbolita-webfont.svg
│   │       ├── stixgeneralbolita-webfont.ttf
│   │       ├── stixgeneralbolita-webfont.woff
│   │       ├── stixgeneralitalic-webfont.eot
│   │       ├── stixgeneralitalic-webfont.svg
│   │       ├── stixgeneralitalic-webfont.ttf
│   │       └── stixgeneralitalic-webfont.woff
│   ├── ie-is-not-supported.html
│   ├── images
│   │   ├── 401_permissions.svg
│   │   ├── 401_unpublished.svg
│   │   ├── 404_notfound.svg
│   │   ├── 4_percent_opacity.png
│   │   ├── 500_pageerror.svg
│   │   ├── Money_Noise_tm.png
│   │   ├── Pen-2-256x256.png
│   │   ├── UploadFile.svg
│   │   ├── a.png
│   │   ├── account_calendars_empty_state.svg
│   │   ├── active_tab.gif
│   │   ├── add-remove.png
│   │   ├── add-small-dim.png
│   │   ├── add-small.png
│   │   ├── add.png
│   │   ├── add_dim.png
│   │   ├── add_feed.png
│   │   ├── add_left.png
│   │   ├── add_right.png
│   │   ├── ajax-loader-bar.gif
│   │   ├── ajax-loader-black-on-white-static.gif
│   │   ├── ajax-loader-black-on-white.gif
│   │   ├── ajax-loader-ccc.gif
│   │   ├── ajax-loader-linear.gif
│   │   ├── ajax-loader-medium-444.gif
│   │   ├── ajax-loader-small-ccc.gif
│   │   ├── ajax-loader-small.gif
│   │   ├── ajax-loader-white-on-black copy-static.gif
│   │   ├── ajax-loader-white-on-black.gif
│   │   ├── ajax-loader.gif
│   │   ├── ajax-reload-animated.gif
│   │   ├── ajax-reload.gif
│   │   ├── all_submissions_icon.png
│   │   ├── ampersand_big.png
│   │   ├── announcement.png
│   │   ├── announcement_icon.png
│   │   ├── announcement_icon_small.png
│   │   ├── answers_sprite.png
│   │   ├── answers_sprite_hc.png
│   │   ├── apple-touch-icon.png -> ../apple-touch-icon.png
│   │   ├── arrow_left.png
│   │   ├── arrow_right.png
│   │   ├── assignment.png
│   │   ├── assignment_old.png
│   │   ├── assignments2_grading_static.png
│   │   ├── assignments2_rubric_static.png
│   │   ├── atom.png
│   │   ├── attributions.txt
│   │   ├── audio-green.gif
│   │   ├── audio-red.gif
│   │   ├── audio-yellow.gif
│   │   ├── audio.png
│   │   ├── audio_comment.gif
│   │   ├── avatar-50.png
│   │   ├── avatar.png
│   │   ├── back.png
│   │   ├── back_forward.png
│   │   ├── ball.png
│   │   ├── ball_big.png
│   │   ├── ball_bigger.png
│   │   ├── beta-tag.png
│   │   ├── binder.png
│   │   ├── black-header-bg.png
│   │   ├── blank.png
│   │   ├── blank_answer.png
│   │   ├── block_editor
│   │   │   ├── about-image2.png
│   │   │   ├── canvas_logo.svg
│   │   │   ├── canvas_logo_black.svg
│   │   │   ├── canvas_logo_white.svg
│   │   │   ├── default_about_image.svg
│   │   │   ├── default_hero_image.svg
│   │   │   ├── hero-image2.svg
│   │   │   ├── scratch.png
│   │   │   ├── section-about.png
│   │   │   ├── section-announcement.png
│   │   │   ├── section-columns.png
│   │   │   ├── section-footer.png
│   │   │   ├── section-hero.png
│   │   │   ├── section-navigation.png
│   │   │   ├── section-quiz.png
│   │   │   ├── section-resources.png
│   │   │   ├── template-1.png
│   │   │   ├── template-2.png
│   │   │   ├── template.png
│   │   │   └── templates
│   │   │       ├── 2021_12_HE_Canva_Hex_Image_10.png
│   │   │       ├── 2022_Illustration_Analytics_Hexagon.png
│   │   │       ├── Designer.svg
│   │   │       ├── DigitalPrint.svg
│   │   │       ├── INSTRUCTURE_2022-May_CofI-37.jpg
│   │   │       ├── INSTRUCTURE_2022-May_Roosevelt-390.jpg
│   │   │       ├── INSTRUCTURE_2022-May_Timberline-59.jpg
│   │   │       ├── Video_Lesson-3000x.png
│   │   │       ├── WebDesign_1.svg
│   │   │       ├── acrylic-painting-artwork-2022-01-19-00-01-18-utc.jpg
│   │   │       ├── banner-3.png
│   │   │       ├── bookIdea.png
│   │   │       ├── canvas_logo.svg
│   │   │       ├── canvas_logo_black.svg
│   │   │       ├── canvas_logo_white.svg
│   │   │       ├── career1-2x.png
│   │   │       ├── education.png
│   │   │       ├── english-teacher-sitting-at-desk-explaining-lesson-2023-11-27-04-59-41-utc.jpg
│   │   │       ├── female-psychologist-psychiatrist-looking-at-webca-2023-11-27-05-26-04-utc.jpg
│   │   │       ├── global-1.svg
│   │   │       ├── grad.svg
│   │   │       ├── gradient-banner.svg
│   │   │       ├── grape-gradient-banner.svg
│   │   │       ├── instructor-photo.png
│   │   │       ├── jaguar.png
│   │   │       ├── macaw.png
│   │   │       ├── milky-way-landscape-in-a-star-sky-in-a-summer-lave-2022-08-26-14-11-16-utc.jpg
│   │   │       ├── onlineEDU.svg
│   │   │       ├── orangutan.png
│   │   │       ├── planet.svg
│   │   │       ├── poison-dart-frog.png
│   │   │       ├── readingAB.svg
│   │   │       ├── teacher-explaining-the-maths-at-school-2021-09-04-11-43-18-utc.jpg
│   │   │       ├── teacherNote.svg
│   │   │       ├── video-placeholder.png
│   │   │       ├── water-cycle.svg
│   │   │       └── world-history.svg
│   │   ├── blue
│   │   │   ├── bg.jpg
│   │   │   ├── bg.png
│   │   │   ├── bg@2x.jpg
│   │   │   ├── canvas-icons-16x16-blue.png
│   │   │   ├── canvas-icons-16x16-dkgrey.png
│   │   │   ├── canvas-icons-16x16-ltgrey.png
│   │   │   └── quickstart-icons.png
│   │   ├── blue_small_loading.gif
│   │   ├── bookmark.png
│   │   ├── bookmark_gray.png
│   │   ├── breadcrumb-arrow-dark.svg
│   │   ├── breadcrumb-arrow-light.svg
│   │   ├── breadcrumb-home.png
│   │   ├── button-bg-active-blue.png
│   │   ├── button-bg-active-gray.png
│   │   ├── button-bg-grad.png
│   │   ├── button-bg-hover.png
│   │   ├── button_bg.png
│   │   ├── calendar.png
│   │   ├── calendar_icon.png
│   │   ├── cancel.png
│   │   ├── canvas
│   │   │   ├── header_bg.png
│   │   │   ├── header_bg@2x.png
│   │   │   ├── menu_arrow.png
│   │   │   ├── menu_arrow_white.png
│   │   │   ├── top_bar_bg.png
│   │   │   └── top_bar_bg@2x.png
│   │   ├── canvas-email.png
│   │   ├── canvas-logo.svg
│   │   ├── canvas-web-conferencing.png
│   │   ├── canvas_logomark_only@2x.png
│   │   ├── cc
│   │   │   ├── attribution.gif
│   │   │   ├── cc_by.png
│   │   │   ├── cc_by_nc.png
│   │   │   ├── cc_by_nc_nd.png
│   │   │   ├── cc_by_nc_sa.png
│   │   │   ├── cc_by_nd.png
│   │   │   ├── cc_by_sa.png
│   │   │   ├── copyright.png
│   │   │   ├── no_derivative_works.gif
│   │   │   ├── non_commercial.gif
│   │   │   ├── private.png
│   │   │   ├── public_domain.png
│   │   │   └── share_alike.gif
│   │   ├── check.png
│   │   ├── check_16.png
│   │   ├── check_36.png
│   │   ├── checkbox_sprite2.png
│   │   ├── checkbox_sprite3.png
│   │   ├── checkboxes-customlist.png
│   │   ├── checked.png
│   │   ├── circle-check.png
│   │   ├── circle-plus.png
│   │   ├── close-button.png
│   │   ├── close.png
│   │   ├── cluttered.png
│   │   ├── cog-with-droparrow-active.png
│   │   ├── cog-with-droparrow.png
│   │   ├── collaboration_folder.png
│   │   ├── collapse.12px.png
│   │   ├── collapse.png
│   │   ├── comment_top.png
│   │   ├── comment_top_correct.png
│   │   ├── comment_top_neutral.png
│   │   ├── conference.png
│   │   ├── conference_big.png
│   │   ├── conversations
│   │   │   └── intro
│   │   │       ├── icon.png
│   │   │       ├── image2.png
│   │   │       ├── image3.png
│   │   │       ├── image4.png
│   │   │       ├── image5.png
│   │   │       ├── image6.png
│   │   │       ├── image7.png
│   │   │       ├── image8.png
│   │   │       └── image9.png
│   │   ├── correct_answer.png
│   │   ├── course_content_icon.png
│   │   ├── crumb.png
│   │   ├── custom_feed.png
│   │   ├── dashboard_message_icons.png
│   │   ├── dashcards
│   │   │   ├── ic-dashcard-toggle-cards.png
│   │   │   ├── ic-dashcard-toggle-stream.png
│   │   │   └── ic-dashcard-toggle.png
│   │   ├── datepicker.gif
│   │   ├── delete.png
│   │   ├── delete_circle.png
│   │   ├── delete_circle_big.png
│   │   ├── delete_circle_gray.png
│   │   ├── deprecated_panda.svg
│   │   ├── dialog.png
│   │   ├── diigo.png
│   │   ├── diigo_icon.png
│   │   ├── diigo_small_icon.png
│   │   ├── discussion_entry_just_read.png
│   │   ├── discussion_entry_unread.png
│   │   ├── discussion_icon.12px.png
│   │   ├── discussion_icon.png
│   │   ├── discussion_icon_small.png
│   │   ├── discussion_topic-gray.png
│   │   ├── discussion_topic.png
│   │   ├── discussions
│   │   │   ├── assignment_bg.png
│   │   │   ├── child_bg.png
│   │   │   ├── child_highlighed_bg.png
│   │   │   ├── collapse_icon.png
│   │   │   ├── expand_icon.png
│   │   │   ├── line.png
│   │   │   ├── line_highlighted.png
│   │   │   └── next_unread_icon.png
│   │   ├── divider_bg.png
│   │   ├── dotted_pic.png
│   │   ├── download.12px.png
│   │   ├── download.png
│   │   ├── downtick.png
│   │   ├── draft_dark.png
│   │   ├── draft_white.png
│   │   ├── drag_handle.png
│   │   ├── dropped_for_grading_bg.png
│   │   ├── due_date_icon.png
│   │   ├── earmark.png
│   │   ├── earmark_hover.12px.png
│   │   ├── earmark_hover.png
│   │   ├── edit.gif
│   │   ├── edit.png
│   │   ├── edit_gray.png
│   │   ├── editor
│   │   │   └── external_tools.png
│   │   ├── ellipses.png
│   │   ├── email.png
│   │   ├── email_big-gray.png
│   │   ├── email_big.png
│   │   ├── email_signature.png
│   │   ├── enrollment_invitation.png
│   │   ├── equella_icon.png
│   │   ├── error_bottom.png
│   │   ├── ether_pad.png
│   │   ├── etherpad_icon.ico
│   │   ├── excel_icon.png
│   │   ├── expand.12px.png
│   │   ├── expand.png
│   │   ├── facebook.png
│   │   ├── facebook_icon.png
│   │   ├── fail.png
│   │   ├── favicon-green.ico
│   │   ├── favicon-yellow.ico
│   │   ├── favicon.ico -> ../favicon.ico
│   │   ├── favicon_large.png
│   │   ├── feedback.png
│   │   ├── fft_ribbon.png
│   │   ├── file-audio.png
│   │   ├── file-video.png
│   │   ├── file.12px.png
│   │   ├── file.png
│   │   ├── file_big.png
│   │   ├── file_big_locked.png
│   │   ├── file_download.png
│   │   ├── file_multiple.png
│   │   ├── file_upload.png
│   │   ├── find.png
│   │   ├── flagged_question-rtl.png
│   │   ├── flagged_question.png
│   │   ├── flagged_question_dim.png
│   │   ├── flagged_question_hc.png
│   │   ├── flagged_question_hc@2x.png
│   │   ├── flash_error_background.gif
│   │   ├── flash_message_background.gif
│   │   ├── flickr_creative_commons_small_icon.png
│   │   ├── flickr_logo.svg
│   │   ├── folder_big.png
│   │   ├── folder_big_2.png
│   │   ├── folder_big_3.png
│   │   ├── folder_big_4.png
│   │   ├── folder_big_locked.png
│   │   ├── folder_big_locked_2.png
│   │   ├── folder_big_locked_4.png
│   │   ├── folder_closed.png
│   │   ├── folder_locked.png
│   │   ├── folder_open.png
│   │   ├── footer-logo.png
│   │   ├── footer-logo@2x.png
│   │   ├── forms
│   │   │   ├── ic-checkbox-bg.svg
│   │   │   └── ic-icon-arrow-down.svg
│   │   ├── forward.png
│   │   ├── get-started-btn.png
│   │   ├── gift.svg
│   │   ├── google_calendar.png
│   │   ├── google_calendar_icon.png
│   │   ├── google_docs.png
│   │   ├── google_docs_icon.ico
│   │   ├── google_docs_icon.png
│   │   ├── google_drive.png
│   │   ├── google_drive_icon.png
│   │   ├── gradebook-comments-sprite.png
│   │   ├── gradebook-comments-sprite2.png
│   │   ├── gradebook-comments-sprite3-high-contrast.png
│   │   ├── gradebook-comments-sprite3-high-contrast@2x.png
│   │   ├── gradebook-comments-sprite3.png
│   │   ├── gradebook-comments-sprite3@2x.png
│   │   ├── gradebook-dropped-indicator.png
│   │   ├── gradebook-late-indicator.png
│   │   ├── gradebook-resubmitted-indicator.png
│   │   ├── gradebook_checkbox_sprite.png
│   │   ├── gradebook_toolbar_bg.png
│   │   ├── graded.16px.png
│   │   ├── graded.png
│   │   ├── graded_discussion_topic.png
│   │   ├── graded_quiz.png
│   │   ├── grading_icon.png
│   │   ├── grading_icon@2x.png
│   │   ├── grading_icon_gray.png
│   │   ├── grading_icon_gray@2x.png
│   │   ├── graph.png
│   │   ├── group-placeholder.png
│   │   ├── group.png
│   │   ├── groups_folder.png
│   │   ├── h2_bg.png
│   │   ├── hammer.png
│   │   ├── help.png
│   │   ├── help_big.pn.png
│   │   ├── history.png
│   │   ├── history_old.png
│   │   ├── hourglass.png
│   │   ├── hover_checked.png
│   │   ├── ical.png
│   │   ├── ical_big.png
│   │   ├── icon-arrow-left.svg
│   │   ├── icon-arrow-right-white.svg
│   │   ├── icon-arrow-right.svg
│   │   ├── icon-checkmark-gray.svg
│   │   ├── icon-checkmark-plus-gray.svg
│   │   ├── icon-checkmark-plus-success-high-contrast.svg
│   │   ├── icon-checkmark-plus-success.svg
│   │   ├── icon-checkmark-rev.svg
│   │   ├── icon-checkmark.svg
│   │   ├── icon-clock.png
│   │   ├── icon-sound-muted.svg
│   │   ├── icon-x-black.svg
│   │   ├── icons
│   │   │   ├── application_edit.png
│   │   │   ├── cross.png
│   │   │   ├── key.png
│   │   │   ├── mc-assignment-pub.svg
│   │   │   ├── mc-assignment-unpub.svg
│   │   │   ├── mc_icon_pub.svg
│   │   │   ├── mc_icon_unpub.svg
│   │   │   └── tick.png
│   │   ├── iframe.png
│   │   ├── image.gif
│   │   ├── image_icon.gif
│   │   ├── inactive_tab.gif
│   │   ├── incorrect_answer.png
│   │   ├── indent_thin.png
│   │   ├── information.png
│   │   ├── inst_combo
│   │   │   ├── text-bg.gif
│   │   │   └── trigger.gif
│   │   ├── inst_tree
│   │   │   ├── file_types
│   │   │   │   ├── page_white.png
│   │   │   │   ├── page_white_acrobat.png
│   │   │   │   ├── page_white_camera.png
│   │   │   │   ├── page_white_cd.png
│   │   │   │   ├── page_white_code.png
│   │   │   │   ├── page_white_excel.png
│   │   │   │   ├── page_white_flash.png
│   │   │   │   ├── page_white_office.png
│   │   │   │   ├── page_white_paintbrush.png
│   │   │   │   ├── page_white_picture.png
│   │   │   │   ├── page_white_powerpoint.png
│   │   │   │   ├── page_white_text.png
│   │   │   │   ├── page_white_word.png
│   │   │   │   ├── page_white_world.png
│   │   │   │   ├── page_white_zip.png
│   │   │   │   └── sound_none.png
│   │   │   ├── folder.png
│   │   │   ├── leaf-drag.gif
│   │   │   ├── line-vertical.gif
│   │   │   ├── minus.gif
│   │   │   ├── plus.gif
│   │   │   └── separator-drag.gif
│   │   ├── instructuresaurus.png
│   │   ├── instructuresaurus_404.png
│   │   ├── invitation_icon.png
│   │   ├── jqueryui
│   │   │   ├── button_bg.png
│   │   │   ├── datepicker.gif
│   │   │   ├── datepicker_icons.gif
│   │   │   ├── gradebook-header-drop.png
│   │   │   ├── gradebook-header-drop2-high-contrast.png
│   │   │   ├── gradebook-header-drop2-high-contrast@2x.png
│   │   │   ├── gradebook-header-drop2.png
│   │   │   ├── gradebook-header-drop2@2x.png
│   │   │   ├── icon_sprite.png
│   │   │   ├── large_blue_gradient.png
│   │   │   ├── progress_bar.gif
│   │   │   ├── slider_h_bg.gif
│   │   │   ├── slider_handles.png
│   │   │   ├── slider_v_bg.gif
│   │   │   ├── tab_bg.gif
│   │   │   ├── tab_bg_blue.gif
│   │   │   ├── the_gradient.gif
│   │   │   ├── ui-bg_diagonals-thick_18_b81900_40x40.png
│   │   │   ├── ui-bg_diagonals-thick_20_666666_40x40.png
│   │   │   ├── ui-bg_flat_0_aaaaaa_40x100.png
│   │   │   ├── ui-bg_flat_10_000000_40x100.png
│   │   │   ├── ui-bg_flat_55_fbec88_40x100.png
│   │   │   ├── ui-bg_glass_100_f6f6f6_1x400.png
│   │   │   ├── ui-bg_glass_100_fdf5ce_1x400.png
│   │   │   ├── ui-bg_glass_65_ffffff_1x400.png
│   │   │   ├── ui-bg_glass_75_d0e5f5_1x400.png
│   │   │   ├── ui-bg_glass_85_dfeffc_1x400.png
│   │   │   ├── ui-bg_glass_95_fef1ec_1x400.png
│   │   │   ├── ui-bg_gloss-wave_35_f6a828_500x100.png
│   │   │   ├── ui-bg_gloss-wave_55_5c9ccc_500x100.png
│   │   │   ├── ui-bg_highlight-soft_100_eeeeee_1x100.png
│   │   │   ├── ui-bg_highlight-soft_75_ffe45c_1x100.png
│   │   │   ├── ui-bg_inset-hard_100_f5f8f9_1x100.png
│   │   │   ├── ui-bg_inset-hard_100_fcfdfd_1x100.png
│   │   │   ├── ui-icon-cog.png
│   │   │   ├── ui-icon-radio-on.png
│   │   │   ├── ui-icon-sections.png
│   │   │   ├── ui-icons_217bc0_256x240.png
│   │   │   ├── ui-icons_222222_256x240.png
│   │   │   ├── ui-icons_228ef1_256x240.png
│   │   │   ├── ui-icons_2e83ff_256x240.png
│   │   │   ├── ui-icons_469bdd_256x240.png
│   │   │   ├── ui-icons_6da8d5_256x240.png
│   │   │   ├── ui-icons_cd0a0a_256x240.png
│   │   │   ├── ui-icons_d8e7f3_256x240.png
│   │   │   ├── ui-icons_ef8c08_256x240.png
│   │   │   ├── ui-icons_f9bd01_256x240.png
│   │   │   ├── ui-icons_ffd27a_256x240.png
│   │   │   └── ui-icons_ffffff_256x240.png
│   │   ├── late_grading_icon.png
│   │   ├── learner_passport
│   │   │   ├── certificate_of_achievement.png
│   │   │   ├── certificate_of_completion.png
│   │   │   ├── ribbon.png
│   │   │   ├── university_badge.png
│   │   │   └── wharton.png
│   │   ├── learning_outcome.png
│   │   ├── link.png
│   │   ├── linked_in.png
│   │   ├── linked_in_icon.png
│   │   ├── load.gif
│   │   ├── lock yellow.png
│   │   ├── lock.png
│   │   ├── lock_closed.png
│   │   ├── lock_for_file_folder.png
│   │   ├── lock_small.png
│   │   ├── locked_small.png
│   │   ├── login
│   │   │   ├── canvas-logo.svg
│   │   │   └── canvas-logo@2x.png
│   │   ├── login-input-bg.png
│   │   ├── logo_watermark.png
│   │   ├── magnifying_glass.svg
│   │   ├── matching_arrow.png
│   │   ├── media-saving.gif
│   │   ├── media_comment.gif
│   │   ├── media_comment.png
│   │   ├── media_comment_embed.png
│   │   ├── mediaelement
│   │   │   ├── flashmediaelement.swf -> ../../../node_modules/mediaelement/build/flashmediaelement.swf
│   │   │   └── silverlightmediaelement.xap -> ../../../node_modules/mediaelement/build/silverlightmediaelement.xap
│   │   ├── membership_update_icon.png
│   │   ├── menu_option-nq8.png
│   │   ├── menu_option.png
│   │   ├── menu_option_faint-nq8.png
│   │   ├── menu_option_faint.png
│   │   ├── menu_option_hover-nq8.png
│   │   ├── menu_option_hover.png
│   │   ├── message_icon.png
│   │   ├── messages
│   │   │   ├── actions-bg.png
│   │   │   ├── actions-dd-sprite.png
│   │   │   ├── add-person-sprite.png
│   │   │   ├── address-book-icon-sprite.png
│   │   │   ├── attach-blue.png
│   │   │   ├── attach-gray.png
│   │   │   ├── attach-icon-sprite.png
│   │   │   ├── audio-blue.png
│   │   │   ├── audio-gray.png
│   │   │   ├── avatar-50.png
│   │   │   ├── avatar-group-50.png
│   │   │   ├── avatar-sprites.png
│   │   │   ├── button-bg.png
│   │   │   ├── checkbox-sprite.png
│   │   │   ├── compose-button-sm_sprite.png
│   │   │   ├── compose-button-sprite.png
│   │   │   ├── compose-icon.png
│   │   │   ├── context-search-sprite.png
│   │   │   ├── expand-context.png
│   │   │   ├── finder-active.png
│   │   │   ├── flag.png
│   │   │   ├── indeterminate-progress.gif
│   │   │   ├── media-blue.png
│   │   │   ├── media-gray.png
│   │   │   ├── media.png
│   │   │   ├── menu-checked-sprites.png
│   │   │   ├── menu-top.png
│   │   │   ├── message-action-sprites.png
│   │   │   ├── messages-background.png
│   │   │   ├── new-replied-icon_sprite.png
│   │   │   ├── open_in_new_window-sprite.png
│   │   │   ├── small-button-sprite.png
│   │   │   ├── star-active.png
│   │   │   ├── star-lit.png
│   │   │   ├── star.png
│   │   │   └── token-delete.png
│   │   ├── microphone.png
│   │   ├── microphone_pencil.png
│   │   ├── mimeClassIcons
│   │   │   ├── audio.svg
│   │   │   ├── code.svg
│   │   │   ├── doc.svg
│   │   │   ├── file.svg
│   │   │   ├── flash.svg
│   │   │   ├── folder-locked.svg
│   │   │   ├── folder.svg
│   │   │   ├── html.svg
│   │   │   ├── image.svg
│   │   │   ├── pdf.svg
│   │   │   ├── ppt.svg
│   │   │   ├── text.svg
│   │   │   ├── video.svg
│   │   │   ├── xls.svg
│   │   │   └── zip.svg
│   │   ├── mime_types
│   │   │   ├── application_msword.png
│   │   │   ├── application_pdf.png
│   │   │   ├── application_vnd.ms-excel.png
│   │   │   ├── application_vnd.ms-powerpoint.png
│   │   │   ├── locked.png
│   │   │   ├── originals
│   │   │   │   ├── application_vnd.ms-excel.png
│   │   │   │   └── application_vnd.ms-powerpoint.png
│   │   │   ├── text_plain.png
│   │   │   └── unknown.png
│   │   ├── mobile-global-nav-logo.svg
│   │   ├── mobile_login
│   │   │   ├── canvas_logo_login.svg
│   │   │   ├── mobile-login-bg.jpg
│   │   │   └── mobile_background.png
│   │   ├── modal_close.svg
│   │   ├── move-nq8.png
│   │   ├── move-ns.png
│   │   ├── move.gif
│   │   ├── move.png
│   │   ├── negative_answer-nq8.png
│   │   ├── negative_answer.png
│   │   ├── neutral_answer.png
│   │   ├── no_pic.gif
│   │   ├── noisy-gray.jpg
│   │   ├── not_a_file.png
│   │   ├── not_found_page
│   │   │   └── empty-planet.svg
│   │   ├── not_graded.16px.png
│   │   ├── not_graded.png
│   │   ├── number_of_students.png
│   │   ├── observer_enrollment.png
│   │   ├── observer_enrollment_small.png
│   │   ├── original_add.png
│   │   ├── other_icon.png
│   │   ├── outcomes
│   │   │   ├── clipboard_checklist.svg
│   │   │   ├── enabled_filter.svg
│   │   │   ├── exceeds_mastery.svg
│   │   │   ├── find_outcomes_mobile.svg
│   │   │   ├── mastery.svg
│   │   │   ├── near_mastery.svg
│   │   │   ├── no_evidence.svg
│   │   │   ├── no_outcomes.svg
│   │   │   ├── outcomes.svg
│   │   │   ├── remediation.svg
│   │   │   └── unassessed.svg
│   │   ├── outdent_thin.png
│   │   ├── overview_video_thumbnail.png
│   │   ├── page_white_get.png
│   │   ├── panda-cycle-loader.gif
│   │   ├── panda-profile-placeholder.jpg
│   │   ├── partial_answer.png
│   │   ├── pass.10px.dim.png
│   │   ├── pass.png
│   │   ├── peer_review.png
│   │   ├── pending_review.png
│   │   ├── person.png
│   │   ├── person_big.png
│   │   ├── person_gray.png
│   │   ├── pie-chart-disabled.png
│   │   ├── play_button.png
│   │   ├── play_overlay.png
│   │   ├── play_overlay_small.png
│   │   ├── popout.png
│   │   ├── popout_big.png
│   │   ├── preview.png
│   │   ├── preview_big.png
│   │   ├── preview_dim.png
│   │   ├── publish_dark.png
│   │   ├── publish_draft_sprite.png
│   │   ├── publish_white.png
│   │   ├── published.png
│   │   ├── quick_links.png
│   │   ├── quiz.12px.png
│   │   ├── quiz.png
│   │   ├── quizzes
│   │   │   └── quiz_stats_empty.png
│   │   ├── raty
│   │   │   ├── cancel-off.png
│   │   │   ├── cancel-on.png
│   │   │   ├── star-half-big.png
│   │   │   ├── star-half.png
│   │   │   ├── star-off-big.png
│   │   │   ├── star-off.png
│   │   │   ├── star-on-big.png
│   │   │   └── star-on.png
│   │   ├── record.gif
│   │   ├── refresh.png
│   │   ├── refresh_icon.png
│   │   ├── registration
│   │   │   ├── down-arrow.png
│   │   │   ├── landing_buttons.png
│   │   │   ├── logo.png
│   │   │   ├── page-background.png
│   │   │   ├── signup_bg.png
│   │   │   └── watch-video-ribbon.png
│   │   ├── reminder_icon.png
│   │   ├── rename.png
│   │   ├── reply.png
│   │   ├── rubric.png
│   │   ├── rubric_comment.png
│   │   ├── sadpanda.svg
│   │   ├── save.gif
│   │   ├── sg-logo.svg
│   │   ├── shadow.png
│   │   ├── shadow_back.png
│   │   ├── short_message.png
│   │   ├── shuffle.png
│   │   ├── six_state_checkbox.png
│   │   ├── six_state_checkbox.psd
│   │   ├── skype.png
│   │   ├── skype_icon.png
│   │   ├── slideshow
│   │   │   ├── back-disabled.png
│   │   │   ├── back.png
│   │   │   ├── background-slice.png
│   │   │   ├── blue-circle-nav.png
│   │   │   ├── close.png
│   │   │   ├── forward-disabled.png
│   │   │   ├── forward.png
│   │   │   ├── separator.png
│   │   │   └── white-circle-nav.png
│   │   ├── social-icons.png
│   │   ├── sort.png
│   │   ├── sound_mute.png
│   │   ├── sound_none.png
│   │   ├── speedgrader_icon.png
│   │   ├── splitpane_handle-ew.gif
│   │   ├── stamp_big.png
│   │   ├── star-sprite.png
│   │   ├── star.png
│   │   ├── student_enrollment.png
│   │   ├── student_enrollment_small.png
│   │   ├── student_message_icon.png
│   │   ├── student_view_icon.png
│   │   ├── submission_comment_icon.png
│   │   ├── summaries_icon.png
│   │   ├── svg-icons
│   │   │   ├── icon-collaborations.svg
│   │   │   ├── icon_lock.svg
│   │   │   ├── svg_canvas_logomark_only.svg
│   │   │   ├── svg_icon_accounts_new_styles.svg
│   │   │   ├── svg_icon_activity_stream.svg
│   │   │   ├── svg_icon_apps.svg
│   │   │   ├── svg_icon_arrow_right.svg
│   │   │   ├── svg_icon_calendar.svg
│   │   │   ├── svg_icon_calendar_new_styles.svg
│   │   │   ├── svg_icon_courses.svg
│   │   │   ├── svg_icon_courses_new_styles.svg
│   │   │   ├── svg_icon_dashboard.svg
│   │   │   ├── svg_icon_dashboard2.svg
│   │   │   ├── svg_icon_download.svg
│   │   │   ├── svg_icon_grades.svg
│   │   │   ├── svg_icon_grades_new_styles.svg
│   │   │   ├── svg_icon_groups_new_styles.svg
│   │   │   ├── svg_icon_help.svg
│   │   │   ├── svg_icon_inbox.svg
│   │   │   ├── svg_icon_mail.svg
│   │   │   ├── svg_icon_post_to_sis.svg
│   │   │   ├── svg_icon_post_to_sis_active.svg
│   │   │   ├── svg_icon_sis_not_synced.svg
│   │   │   └── svg_icon_sis_synced.svg
│   │   ├── ta_enrollment.png
│   │   ├── ta_enrollment_small.png
│   │   ├── tablesorter
│   │   │   ├── asc.gif
│   │   │   ├── bg.png
│   │   │   ├── bg_hover.png
│   │   │   └── desc.gif
│   │   ├── tag_icon.png
│   │   ├── teacher_enrollment.png
│   │   ├── teacher_enrollment_icon.png
│   │   ├── teacher_enrollment_small.png
│   │   ├── test-waiting.gif
│   │   ├── text_entry.png
│   │   ├── text_entry_dim.png
│   │   ├── theme
│   │   │   ├── 222222_11x11_icon_arrows_leftright.gif
│   │   │   ├── 222222_11x11_icon_arrows_updown.gif
│   │   │   ├── 222222_11x11_icon_close.gif
│   │   │   ├── 222222_11x11_icon_doc.gif
│   │   │   ├── 222222_11x11_icon_folder_closed.gif
│   │   │   ├── 222222_11x11_icon_folder_open.gif
│   │   │   ├── 222222_11x11_icon_minus.gif
│   │   │   ├── 222222_11x11_icon_plus.gif
│   │   │   ├── 222222_11x11_icon_resize_se.gif
│   │   │   ├── 222222_35x9_colorpicker_indicator.gif.gif
│   │   │   ├── 222222_7x7_arrow_down.gif
│   │   │   ├── 222222_7x7_arrow_left.gif
│   │   │   ├── 222222_7x7_arrow_right.gif
│   │   │   ├── 222222_7x7_arrow_up.gif
│   │   │   ├── 2C4C5E_256x240_icons.png
│   │   │   ├── 2C4C5E_500x100_textures_12_gloss_wave_55.png
│   │   │   ├── 888888_11x11_icon_arrows_leftright.gif
│   │   │   ├── 888888_11x11_icon_arrows_updown.gif
│   │   │   ├── 888888_11x11_icon_close.gif
│   │   │   ├── 888888_11x11_icon_doc.gif
│   │   │   ├── 888888_11x11_icon_folder_closed.gif
│   │   │   ├── 888888_11x11_icon_folder_open.gif
│   │   │   ├── 888888_11x11_icon_minus.gif
│   │   │   ├── 888888_11x11_icon_plus.gif
│   │   │   ├── 888888_7x7_arrow_down.gif
│   │   │   ├── 888888_7x7_arrow_left.gif
│   │   │   ├── 888888_7x7_arrow_right.gif
│   │   │   ├── 888888_7x7_arrow_up.gif
│   │   │   ├── E6E6E6_1x25_textures_04_highlight_hard_75.png
│   │   │   ├── F2F5F7_1x100_textures_03_highlight_soft_75.png
│   │   │   ├── d8d8d8_40x100_textures_02_glass_90.png
│   │   │   ├── f3f3f3_40x100_textures_01_flat_0.png
│   │   │   ├── ffffff_11x11_icon_arrows_leftright.gif
│   │   │   ├── ffffff_11x11_icon_arrows_updown.gif
│   │   │   ├── ffffff_11x11_icon_close.gif
│   │   │   ├── ffffff_11x11_icon_doc.gif
│   │   │   ├── ffffff_11x11_icon_folder_closed.gif
│   │   │   ├── ffffff_11x11_icon_folder_open.gif
│   │   │   ├── ffffff_11x11_icon_minus.gif
│   │   │   ├── ffffff_11x11_icon_plus.gif
│   │   │   ├── ffffff_256x240_icons.png
│   │   │   ├── ffffff_7x7_arrow_down.gif
│   │   │   ├── ffffff_7x7_arrow_left.gif
│   │   │   ├── ffffff_7x7_arrow_right.gif
│   │   │   └── ffffff_7x7_arrow_up.gif
│   │   ├── three_state_checkbox.gif
│   │   ├── tick.png
│   │   ├── tinybg.png
│   │   ├── tinybutton.png
│   │   ├── toggle-handle.svg
│   │   ├── tooltip_carat.png
│   │   ├── transparent_16x16.png
│   │   ├── trophy.svg
│   │   ├── turnitin_acceptable_score.png
│   │   ├── turnitin_error_score.png
│   │   ├── turnitin_failure_score.png
│   │   ├── turnitin_no_score.png
│   │   ├── turnitin_none_score.png
│   │   ├── turnitin_pending_score.png
│   │   ├── turnitin_problem_score.png
│   │   ├── turnitin_submission_error.png
│   │   ├── turnitin_submission_pending.png
│   │   ├── turnitin_warning_score.png
│   │   ├── tutorial-tray-images
│   │   │   ├── Panda_Analytics.svg
│   │   │   ├── Panda_Announcements.svg
│   │   │   ├── Panda_Assignments.svg
│   │   │   ├── Panda_Collaborations.svg
│   │   │   ├── Panda_Conferences.svg
│   │   │   ├── Panda_Discussions.svg
│   │   │   ├── Panda_Files.svg
│   │   │   ├── Panda_Grades.svg
│   │   │   ├── Panda_Home.svg
│   │   │   ├── Panda_Map.svg
│   │   │   ├── Panda_Modules.svg
│   │   │   ├── Panda_Pages.svg
│   │   │   ├── Panda_People.svg
│   │   │   ├── Panda_Quizzes.svg
│   │   │   ├── Panda_Syllabus.svg
│   │   │   ├── Panda_Teacher.svg
│   │   │   ├── announcements.svg
│   │   │   ├── assignments.svg
│   │   │   ├── collaborations.svg
│   │   │   ├── conferences.svg
│   │   │   ├── discussions.svg
│   │   │   ├── files.svg
│   │   │   ├── grades.svg
│   │   │   ├── import.svg
│   │   │   ├── module_tutorial.svg
│   │   │   ├── page.svg
│   │   │   ├── people.svg
│   │   │   ├── publish.png
│   │   │   ├── quiz.svg
│   │   │   ├── settings.svg
│   │   │   └── syllabus.svg
│   │   ├── ugly_find.png
│   │   ├── unlock.png
│   │   ├── unpublished.png
│   │   ├── unshuffle.png
│   │   ├── unsort.png
│   │   ├── upload_rocket.svg
│   │   ├── uptick.png
│   │   ├── url.gif
│   │   ├── url.png
│   │   ├── use_canvas_free_callout.png
│   │   ├── video.png
│   │   ├── warn_graded.png
│   │   ├── warning.png
│   │   ├── warning_16.png
│   │   ├── warning_36.png
│   │   ├── warning_dim.png
│   │   ├── webcam.png
│   │   ├── webcam_preview.png
│   │   ├── windows-tile-wide.png
│   │   ├── windows-tile.png
│   │   ├── wizard-bg.jpg
│   │   ├── wizard-todo-checked.svg
│   │   ├── wizard-todo-unchecked.svg
│   │   ├── wizard_next.png
│   │   ├── word_bubble.png
│   │   ├── word_bubble_dim.png
│   │   ├── youtube_embed.png
│   │   ├── youtube_logo.png
│   │   └── youtube_tiny.png
│   ├── inst-fs-sw.js
│   ├── javascripts
│   │   ├── lti_post_message_forwarding.js
│   │   └── translations
│   │       └── en.json
│   ├── loading_submission.html
│   ├── media_record
│   │   ├── KRecord.swf
│   │   ├── KUpload.swf
│   │   ├── locale.xml
│   │   └── skin.swf
│   ├── partials
│   │   ├── _custom_search.html
│   │   └── _license_help.html
│   ├── robots.txt
│   └── simple_response.json
├── renovate.json
├── rspack.config.js
├── schema.graphql
├── script
│   ├── brakeman
│   ├── bundle_update
│   ├── bundle_update_config.yml
│   ├── canvas_init
│   ├── canvas_update
│   ├── common
│   │   ├── canvas
│   │   │   └── build_helpers.sh
│   │   ├── os
│   │   │   ├── linux
│   │   │   │   ├── dev_setup.sh
│   │   │   │   └── impl.sh
│   │   │   └── mac
│   │   │       └── dev_setup.sh
│   │   └── utils
│   │       ├── common.sh
│   │       ├── dinghy_proxy_setup.sh
│   │       ├── docker_desktop_setup.sh
│   │       ├── dory_setup.sh
│   │       ├── logging.sh
│   │       └── spinner.sh
│   ├── configure_replication.sh
│   ├── consume_consul_events
│   ├── delayed_job
│   ├── docker_dev_setup.sh
│   ├── docker_dev_update.sh
│   ├── docker_pull_image.sh
│   ├── docker_webpack_monitoring.js
│   ├── find_leaky_spec
│   ├── generate_js_coverage
│   ├── generate_lti_variable_substitution_markdown
│   ├── generate_rsa_keypair.rb
│   ├── install_assets.sh
│   ├── install_hooks
│   ├── lint_commit_message
│   ├── linter.rb
│   ├── nuke_node.sh
│   ├── process_incoming_emails
│   ├── rebase_canvas_and_plugins.sh
│   ├── render_json_lint
│   ├── rlint
│   ├── stylelint
│   ├── tail_kinesis
│   ├── tatl_tael
│   ├── techdebt_stats.js
│   ├── webpack_watch_es_packages.sh
│   ├── xsslint.js
│   └── yarn-validate-workspace-deps.js
├── spec
│   ├── ams_spec_helper.rb
│   ├── apis
│   │   ├── api_spec_helper.rb
│   │   ├── auth_spec.rb
│   │   ├── error_handling_spec.rb
│   │   ├── file_uploads_spec_helper.rb
│   │   ├── general_api_spec.rb
│   │   ├── html
│   │   │   └── content_spec.rb
│   │   ├── locked_examples.rb
│   │   ├── lti
│   │   │   ├── analytics_service_spec.rb
│   │   │   ├── ims
│   │   │   │   ├── access_token_helper_spec.rb
│   │   │   │   ├── authorization_api_spec.rb
│   │   │   │   ├── tool_consumer_profile_api_spec.rb
│   │   │   │   ├── tool_proxy_api_spec.rb
│   │   │   │   └── tool_setting_api_spec.rb
│   │   │   ├── logout_service_spec.rb
│   │   │   ├── lti2_api_spec_helper.rb
│   │   │   ├── lti_api_spec.rb
│   │   │   ├── lti_app_api_spec.rb
│   │   │   ├── originality_reports_api_spec.rb
│   │   │   ├── plagiarism_assignments_api_controller_spec.rb
│   │   │   ├── submissions_api_spec.rb
│   │   │   ├── subscriptions_api_spec.rb
│   │   │   ├── subscriptions_validator_spec.rb
│   │   │   ├── tool_proxy_api_spec.rb
│   │   │   └── users_api_spec.rb
│   │   ├── swagger
│   │   │   ├── argument_view_spec.rb
│   │   │   ├── deprecated_method_view_spec.rb
│   │   │   ├── formatted_type_spec.rb
│   │   │   ├── method_view_spec.rb
│   │   │   ├── model_view_spec.rb
│   │   │   ├── object_part_view_spec.rb
│   │   │   ├── object_view_spec.rb
│   │   │   ├── response_field_view_spec.rb
│   │   │   ├── return_view_spec.rb
│   │   │   ├── route_view_spec.rb
│   │   │   └── swagger_helper.rb
│   │   ├── user_content_spec.rb
│   │   └── v1
│   │       ├── account_notifications_api_spec.rb
│   │       ├── account_reports_api_spec.rb
│   │       ├── accounts_api_spec.rb
│   │       ├── admins_api_spec.rb
│   │       ├── announcements_api_spec.rb
│   │       ├── anonymous_provisional_grades_api_spec.rb
│   │       ├── api_route_set_spec.rb
│   │       ├── appointment_groups_api_spec.rb
│   │       ├── assignment_extensions_controller_spec.rb
│   │       ├── assignment_groups_api_spec.rb
│   │       ├── assignment_overrides_spec.rb
│   │       ├── assignments_api_spec.rb
│   │       ├── authentication_audit_api_spec.rb
│   │       ├── authentication_providers_api_spec.rb
│   │       ├── calendar_events_api_spec.rb
│   │       ├── collaboration_json_spec.rb
│   │       ├── collaborations_api_spec.rb
│   │       ├── comm_messages_api_spec.rb
│   │       ├── communication_channels_api_spec.rb
│   │       ├── conditional_release
│   │       │   ├── rules_api_spec.rb
│   │       │   └── stats_api_spec.rb
│   │       ├── conferences_api_spec.rb
│   │       ├── content_exports_api_controller_spec.rb
│   │       ├── content_migrations_api_spec.rb
│   │       ├── content_share_spec.rb
│   │       ├── context_module_items_api_spec.rb
│   │       ├── context_modules_api_spec.rb
│   │       ├── conversations_api_spec.rb
│   │       ├── course_audit_api_spec.rb
│   │       ├── course_json_spec.rb
│   │       ├── course_nicknames_api_spec.rb
│   │       ├── courses_api_spec.rb
│   │       ├── csp_settings_spec.rb
│   │       ├── custom_gradebook_column_data_api_spec.rb
│   │       ├── custom_gradebook_columns_api_spec.rb
│   │       ├── developer_keys_spec.rb
│   │       ├── discussion_topic_users_controller_spec.rb
│   │       ├── discussion_topics_api_spec.rb
│   │       ├── enrollments_api_spec.rb
│   │       ├── eportfolios_api_spec.rb
│   │       ├── errors_api_spec.rb
│   │       ├── external_feeds_api_spec.rb
│   │       ├── external_tools_api_spec.rb
│   │       ├── favorites_api_spec.rb
│   │       ├── feature_flags_api_spec.rb
│   │       ├── files_controller_api_spec.rb
│   │       ├── folders_controller_api_spec.rb
│   │       ├── grade_change_audit_api_spec.rb
│   │       ├── gradebook_filters_api_controller_spec.rb
│   │       ├── gradebook_history_api_spec.rb
│   │       ├── gradebook_history_spec.rb
│   │       ├── grading_periods_api_spec.rb
│   │       ├── grading_standards_api_spec.rb
│   │       ├── group_categories_api_spec.rb
│   │       ├── groups_api_spec.rb
│   │       ├── history_api_spec.rb
│   │       ├── jobs_v2_api_spec.rb
│   │       ├── live_assessments
│   │       │   ├── assessments_api_spec.rb
│   │       │   └── results_api_spec.rb
│   │       ├── lti
│   │       │   ├── overlay_spec.rb
│   │       │   ├── registration_account_binding_spec.rb
│   │       │   └── registration_spec.rb
│   │       ├── master_courses
│   │       │   └── master_templates_api_spec.rb
│   │       ├── media_objects_controller_api_spec.rb
│   │       ├── migrations_issues_api_spec.rb
│   │       ├── moderation_set_api_spec.rb
│   │       ├── notification_preferences_api_spec.rb
│   │       ├── observer_alert_thresholds_api_controller_spec.rb
│   │       ├── observer_alerts_api_controller_spec.rb
│   │       ├── observer_pairing_codes_api_controller_spec.rb
│   │       ├── outcome_groups_api_spec.rb
│   │       ├── outcome_imports_api_controller_spec.rb
│   │       ├── outcome_proficiency_api_controller_spec.rb
│   │       ├── outcome_results_api_spec.rb
│   │       ├── outcomes_api_spec.rb
│   │       ├── outcomes_import
│   │       │   ├── fixtures
│   │       │   │   ├── achieve_authority_pubs.json
│   │       │   │   ├── api_list_authorities.json
│   │       │   │   ├── available_authorities.json
│   │       │   │   ├── available_return_val.json
│   │       │   │   ├── common_core_authority_pubs.json
│   │       │   │   └── iste_authority_pubs.json
│   │       │   └── outcomes_import_api_spec.rb
│   │       ├── pages_api_spec.rb
│   │       ├── pages_block_page_api_spec.rb
│   │       ├── peer_reviews_api_spec.rb
│   │       ├── polling
│   │       │   ├── poll_choices_api_spec.rb
│   │       │   ├── poll_sessions_api_spec.rb
│   │       │   ├── poll_submissions_api_spec.rb
│   │       │   └── polls_api_spec.rb
│   │       ├── profiles_api_controller_spec.rb
│   │       ├── progress_api_spec.rb
│   │       ├── provisional_grades_api_spec.rb
│   │       ├── pseudonyms_api_spec.rb
│   │       ├── quizzes
│   │       │   ├── course_quiz_extensions_api_spec.rb
│   │       │   ├── outstanding_quiz_submissions_spec.rb
│   │       │   ├── quiz_assignment_overrides_spec.rb
│   │       │   ├── quiz_extensions_api_spec.rb
│   │       │   ├── quiz_groups_api_spec.rb
│   │       │   ├── quiz_ip_filters_api_spec.rb
│   │       │   ├── quiz_questions_api_spec.rb
│   │       │   ├── quiz_reports_api_spec.rb
│   │       │   ├── quiz_statistics_api_spec.rb
│   │       │   ├── quiz_submission_events_api_spec.rb
│   │       │   ├── quiz_submission_files_spec.rb
│   │       │   ├── quiz_submission_questions_api_spec.rb
│   │       │   ├── quiz_submission_users_spec.rb
│   │       │   ├── quiz_submissions_api_spec.rb
│   │       │   └── quizzes_api_spec.rb
│   │       ├── quizzes_next
│   │       │   └── quizzes_api_controller_spec.rb
│   │       ├── roles_api_spec.rb
│   │       ├── rubrics_api_spec.rb
│   │       ├── scopes_api_controller_spec.rb
│   │       ├── search_api_spec.rb
│   │       ├── sections_api_spec.rb
│   │       ├── services_api_spec.rb
│   │       ├── shared_brand_configs_api_spec.rb
│   │       ├── sis_api_spec.rb
│   │       ├── sis_import_errors_api_spec.rb
│   │       ├── sis_imports_api_spec.rb
│   │       ├── smart_search_api_spec.rb
│   │       ├── stream_items_api_spec.rb
│   │       ├── submission_comments_api_spec.rb
│   │       ├── submissions_api_spec.rb
│   │       ├── tabs_api_spec.rb
│   │       ├── terms_api_spec.rb
│   │       ├── todo_items_api_spec.rb
│   │       ├── token_scoping_api_spec.rb
│   │       ├── tokens_api_spec.rb
│   │       ├── upcoming_events_api_spec.rb
│   │       ├── usage_rights_api_spec.rb
│   │       ├── user_observees_api_spec.rb
│   │       ├── user_profiles_api_spec.rb
│   │       ├── users_api_spec.rb
│   │       └── wiki_pages_api_spec.rb
│   ├── broadcast_integration.rb
│   ├── canvas_simplecov.rb
│   ├── conditional_release_spec_helper.rb
│   ├── contracts
│   │   ├── README.md
│   │   └── service_consumers
│   │       ├── api
│   │       │   ├── pact_helper.rb
│   │       │   ├── pact_setup.rb
│   │       │   ├── provider_states_for_consumer
│   │       │   │   ├── account_notifications_provider_states.rb
│   │       │   │   ├── account_reports_provider_states.rb
│   │       │   │   ├── announcements_provider_states.rb
│   │       │   │   ├── assignments_provider_states.rb
│   │       │   │   ├── calendar_events_provider_states.rb
│   │       │   │   ├── content_migration_provider_states.rb
│   │       │   │   ├── courses_provider_states.rb
│   │       │   │   ├── discussions_provider_states.rb
│   │       │   │   ├── grading_standards_provider_states.rb
│   │       │   │   ├── oauth_provider_states.rb
│   │       │   │   ├── quizzes_provider_states.rb
│   │       │   │   ├── users_provider_states.rb
│   │       │   │   └── wiki_pages_provider_states.rb
│   │       │   ├── provider_states_for_consumer.rb
│   │       │   └── proxy_app.rb
│   │       ├── jwt_signing_key
│   │       └── pact_config.rb
│   ├── controllers
│   │   ├── accessibility_controller_spec.rb
│   │   ├── account_calendars_api_controller_spec.rb
│   │   ├── account_grading_settings_controller_spec.rb
│   │   ├── accounts_controller_spec.rb
│   │   ├── announcements_controller_spec.rb
│   │   ├── anonymous_submissions_controller_spec.rb
│   │   ├── app_center_controller_spec.rb
│   │   ├── application_controller_spec.rb
│   │   ├── appointment_groups_controller_spec.rb
│   │   ├── assignment_groups_controller_spec.rb
│   │   ├── assignments_controller_spec.rb
│   │   ├── auditor_api_controller_spec.rb
│   │   ├── authentication_providers_controller_spec.rb
│   │   ├── big_blue_button_conferences_controller_spec.rb
│   │   ├── blackout_dates_controller_spec.rb
│   │   ├── bookmarks
│   │   │   └── bookmarks_controller_spec.rb
│   │   ├── brand_configs_api_controller_spec.rb
│   │   ├── brand_configs_controller_spec.rb
│   │   ├── calendar_events_controller_spec.rb
│   │   ├── calendars_controller_spec.rb
│   │   ├── canvadoc_sessions_controller_spec.rb
│   │   ├── career_controller_spec.rb
│   │   ├── collaborations_controller_spec.rb
│   │   ├── communication_channels_controller_spec.rb
│   │   ├── concerns
│   │   │   ├── captcha_validation_spec.rb
│   │   │   ├── granular_permission_enforcement_spec.rb
│   │   │   ├── horizon_mode_spec.rb
│   │   │   └── k5_mode_spec.rb
│   │   ├── conditional_release
│   │   │   └── stats_controller_spec.rb
│   │   ├── conferences_controller_spec.rb
│   │   ├── content_exports_controller_spec.rb
│   │   ├── content_migrations_controller_spec.rb
│   │   ├── content_shares_controller_spec.rb
│   │   ├── context_controller_spec.rb
│   │   ├── context_modules_controller_perf_update_spec.rb
│   │   ├── context_modules_controller_spec.rb
│   │   ├── conversations_controller_spec.rb
│   │   ├── course_paces_controller_spec.rb
│   │   ├── course_pacing
│   │   │   └── bulk_student_enrollment_paces_api_controller_spec.rb
│   │   ├── course_reports_controller_spec.rb
│   │   ├── courses_controller_spec.rb
│   │   ├── crocodoc_sessions_controller_spec.rb
│   │   ├── custom_data_controller_spec.rb
│   │   ├── developer_key_account_bindings_controller_spec.rb
│   │   ├── developer_keys_controller_spec.rb
│   │   ├── disable_post_to_sis_api_controller_spec.rb
│   │   ├── discussion_entries_controller_spec.rb
│   │   ├── discussion_topics_api_controller_spec.rb
│   │   ├── discussion_topics_controller_spec.rb
│   │   ├── docviewer_audit_events_controller_spec.rb
│   │   ├── eportfolio_categories_controller_spec.rb
│   │   ├── eportfolio_entries_controller_spec.rb
│   │   ├── eportfolios_controller_spec.rb
│   │   ├── epub_exports_controller_spec.rb
│   │   ├── equation_images_controller_spec.rb
│   │   ├── errors_controller_spec.rb
│   │   ├── external_content_controller_spec.rb
│   │   ├── external_tools_controller_spec.rb
│   │   ├── file_previews_controller_spec.rb
│   │   ├── files_controller_spec.rb
│   │   ├── folders_controller_spec.rb
│   │   ├── grade_change_audit_api_controller_spec.rb
│   │   ├── gradebook_csvs_controller_spec.rb
│   │   ├── gradebook_history_api_controller_spec.rb
│   │   ├── gradebook_settings_controller_spec.rb
│   │   ├── gradebook_uploads_controller_spec.rb
│   │   ├── gradebooks_controller_spec.rb
│   │   ├── grading_period_sets_controller_spec.rb
│   │   ├── grading_periods_controller_spec.rb
│   │   ├── grading_schemes_json_controller_spec.rb
│   │   ├── grading_standards_controller_spec.rb
│   │   ├── graphql_controller_spec.rb
│   │   ├── group_categories_controller_spec.rb
│   │   ├── groups_controller_spec.rb
│   │   ├── horizon_controller_spec.rb
│   │   ├── immersive_reader_controller_spec.rb
│   │   ├── info_controller_spec.rb
│   │   ├── inst_access_tokens_controller_spec.rb
│   │   ├── jwts_controller_spec.rb
│   │   ├── late_policy_controller_spec.rb
│   │   ├── learn_platform_controller_spec.rb
│   │   ├── learning_object_dates_controller_spec.rb
│   │   ├── legal_information_controller_spec.rb
│   │   ├── login
│   │   │   ├── canvas_controller_spec.rb
│   │   │   ├── cas_controller_spec.rb
│   │   │   ├── external_auth_observers_controller_spec.rb
│   │   │   ├── oauth2_controller_spec.rb
│   │   │   ├── otp_controller_spec.rb
│   │   │   ├── saml_controller_spec.rb
│   │   │   └── saml_idp_discovery_controller_spec.rb
│   │   ├── login_controller_spec.rb
│   │   ├── lti
│   │   │   ├── account_external_tools_controller_spec.rb
│   │   │   ├── account_lookup_controller_spec.rb
│   │   │   ├── asset_processor_launch_controller_spec.rb
│   │   │   ├── concerns
│   │   │   │   ├── parent_frame_shared_examples.rb
│   │   │   │   └── parent_frame_spec.rb
│   │   │   ├── context_controls_controller_spec.rb
│   │   │   ├── data_services_controller_spec.rb
│   │   │   ├── deployments_controller_spec.rb
│   │   │   ├── eula_launch_controller_spec.rb
│   │   │   ├── feature_flags_controller_spec.rb
│   │   │   ├── ims
│   │   │   │   ├── asset_processor_controller_spec.rb
│   │   │   │   ├── asset_processor_eula_controller_spec.rb
│   │   │   │   ├── authentication_controller_spec.rb
│   │   │   │   ├── concerns
│   │   │   │   │   ├── advantage_services_shared_context.rb
│   │   │   │   │   ├── advantage_services_shared_examples.rb
│   │   │   │   │   ├── advantage_services_spec.rb
│   │   │   │   │   ├── deep_linking_services_spec.rb
│   │   │   │   │   ├── deep_linking_spec_helper.rb
│   │   │   │   │   ├── gradebook_services_spec.rb
│   │   │   │   │   └── lti_services_shared_examples.rb
│   │   │   │   ├── deep_linking_controller_spec.rb
│   │   │   │   ├── dynamic_registration_controller_spec.rb
│   │   │   │   ├── line_items_controller_spec.rb
│   │   │   │   ├── names_and_roles_controller_spec.rb
│   │   │   │   ├── notice_handlers_controller_spec.rb
│   │   │   │   ├── openapi
│   │   │   │   │   ├── dynamic_registration.yml
│   │   │   │   │   └── openapi_spec_helper.rb
│   │   │   │   ├── results_controller_spec.rb
│   │   │   │   └── scores_controller_spec.rb
│   │   │   ├── launch_services_spec.rb
│   │   │   ├── membership_service_controller_spec.rb
│   │   │   ├── message_controller_spec.rb
│   │   │   ├── platform_storage_controller_spec.rb
│   │   │   ├── public_jwk_controller_spec.rb
│   │   │   ├── registrations_controller_spec.rb
│   │   │   ├── resource_links_controller_spec.rb
│   │   │   ├── token_controller_spec.rb
│   │   │   ├── tool_configurations_api_controller_spec.rb
│   │   │   └── tool_default_icon_controller_spec.rb
│   │   ├── lti_api_controllers_spec.rb
│   │   ├── master_courses
│   │   │   └── master_templates_controller_spec.rb
│   │   ├── media_objects_controller_spec.rb
│   │   ├── media_tracks_controller_spec.rb
│   │   ├── messages_controller_spec.rb
│   │   ├── microsoft_sync
│   │   │   └── groups_controller_spec.rb
│   │   ├── module_assignment_overrides_controller_spec.rb
│   │   ├── notification_preferences_controller_spec.rb
│   │   ├── oauth2_provider_controller_spec.rb
│   │   ├── oauth_proxy_controller_spec.rb
│   │   ├── outcome_results_controller_spec.rb
│   │   ├── outcomes_controller_spec.rb
│   │   ├── page_views_controller_spec.rb
│   │   ├── planner_controller_spec.rb
│   │   ├── planner_notes_controller_spec.rb
│   │   ├── planner_overrides_controller_spec.rb
│   │   ├── plugins_controller_spec.rb
│   │   ├── profile_controller_spec.rb
│   │   ├── progress_controller_spec.rb
│   │   ├── pseudonyms_controller_spec.rb
│   │   ├── question_banks_controller_spec.rb
│   │   ├── quizzes
│   │   │   ├── quiz_questions_controller_spec.rb
│   │   │   ├── quiz_submission_events_controller_spec.rb
│   │   │   ├── quiz_submissions_controller_spec.rb
│   │   │   └── quizzes_controller_spec.rb
│   │   ├── release_notes_controller_spec.rb
│   │   ├── rich_content_api_controller_spec.rb
│   │   ├── role_overrides_controller_spec.rb
│   │   ├── rubric_assessment_imports_controller_spec.rb
│   │   ├── rubric_assessments_controller_spec.rb
│   │   ├── rubric_associations_controller_spec.rb
│   │   ├── rubrics_controller_spec.rb
│   │   ├── search_controller_spec.rb
│   │   ├── sections_controller_spec.rb
│   │   ├── security_controller_spec.rb
│   │   ├── self_enrollments_controller_spec.rb
│   │   ├── sis_api_controller_spec.rb
│   │   ├── smart_search_controller_spec.rb
│   │   ├── sub_accounts_controller_spec.rb
│   │   ├── submission_comments_controller_spec.rb
│   │   ├── submissions
│   │   │   ├── abstract_submission_for_show_spec.rb
│   │   │   ├── anonymous_downloads_controller_spec.rb
│   │   │   ├── anonymous_previews_controller_spec.rb
│   │   │   ├── anonymous_submission_for_show_spec.rb
│   │   │   ├── attachment_for_submission_download_spec.rb
│   │   │   ├── downloads_controller_spec.rb
│   │   │   ├── previews_controller_spec.rb
│   │   │   ├── show_helper_spec.rb
│   │   │   └── submission_for_show_spec.rb
│   │   ├── submissions_controller_spec.rb
│   │   ├── support_helpers
│   │   │   ├── crocodoc_controller_spec.rb
│   │   │   ├── plagiarism_platform_controller_spec.rb
│   │   │   ├── submission_lifecycle_manage_controller_spec.rb
│   │   │   └── turnitin_controller_spec.rb
│   │   ├── temporary_enrollment_pairings_api_controller_spec.rb
│   │   ├── terms_api_controller_spec.rb
│   │   ├── terms_controller_spec.rb
│   │   ├── tokens_controller_spec.rb
│   │   ├── translation_controller_spec.rb
│   │   ├── user_lists_controller_spec.rb
│   │   ├── users_controller_spec.rb
│   │   ├── web_zip_export_controller_spec.rb
│   │   ├── what_if_grades_api_controller_spec.rb
│   │   ├── wiki_pages_api_controller_spec.rb
│   │   └── wiki_pages_controller_spec.rb
│   ├── coverage_tool.rb
│   ├── factories
│   │   ├── account_factory.rb
│   │   ├── account_notification_factory.rb
│   │   ├── admin_analytics_tool_factory.rb
│   │   ├── analytics_2_tool_factory.rb
│   │   ├── announcement_factory.rb
│   │   ├── assessment_question_bank_factory.rb
│   │   ├── assessment_question_factory.rb
│   │   ├── assessment_request.rb
│   │   ├── asset_processor_factory.rb
│   │   ├── assignment_factory.rb
│   │   ├── assignment_override_factory.rb
│   │   ├── attachment_factory.rb
│   │   ├── bookmark_service_factory.rb
│   │   ├── calendar_event_factory.rb
│   │   ├── collaboration_factory.rb
│   │   ├── comment_bank_item_factory.rb
│   │   ├── communication_channel_factory.rb
│   │   ├── content_export_factory.rb
│   │   ├── conversation_factory.rb
│   │   ├── course_factory.rb
│   │   ├── course_pace_factory.rb
│   │   ├── course_section_factory.rb
│   │   ├── custom_data_factory.rb
│   │   ├── delayed_message_factory.rb
│   │   ├── developer_key_factory.rb
│   │   ├── discussion_topic_factory.rb
│   │   ├── enrollment_factory.rb
│   │   ├── eportfolio_factory.rb
│   │   ├── external_feed_factory.rb
│   │   ├── external_tool_factory.rb
│   │   ├── folder_factory.rb
│   │   ├── grading_period_factory.rb
│   │   ├── grading_period_group_factory.rb
│   │   ├── grading_standard_factory.rb
│   │   ├── group_category_factory.rb
│   │   ├── group_factory.rb
│   │   ├── group_membership_factory.rb
│   │   ├── inbox_settings_factory.rb
│   │   ├── late_policy_factory.rb
│   │   ├── line_item_factory.rb
│   │   ├── lti_ims_registration_factory.rb
│   │   ├── lti_overlay_factory.rb
│   │   ├── lti_overlay_version_factory.rb
│   │   ├── lti_registration_account_binding_factory.rb
│   │   ├── lti_registration_factory.rb
│   │   ├── lti_result_factory.rb
│   │   ├── lti_tool_configuration_factory.rb
│   │   ├── media_object_factory.rb
│   │   ├── message_factory.rb
│   │   ├── notification_factory.rb
│   │   ├── notification_policy_factory.rb
│   │   ├── observer_alert_factory.rb
│   │   ├── observer_alert_threshold_factory.rb
│   │   ├── outcome_alignment_results_factory.rb
│   │   ├── outcome_alignment_stats_factory.rb
│   │   ├── outcome_calculation_method_factory.rb
│   │   ├── outcome_factory.rb
│   │   ├── outcome_friendly_description_factory.rb
│   │   ├── outcome_proficiency_factory.rb
│   │   ├── page_view_factory.rb
│   │   ├── planner_note_factory.rb
│   │   ├── planner_override_factory.rb
│   │   ├── pseudonym_factory.rb
│   │   ├── pseudonym_session_factory.rb
│   │   ├── quiz_factory.rb
│   │   ├── resource_link_factory.rb
│   │   ├── role_factory.rb
│   │   ├── rubric_assessment_factory.rb
│   │   ├── rubric_association_factory.rb
│   │   ├── rubric_factory.rb
│   │   ├── submission_comment_factory.rb
│   │   ├── submission_factory.rb
│   │   ├── user_factory.rb
│   │   ├── user_service_factory.rb
│   │   └── wiki_page_factory.rb
│   ├── factories.rb
│   ├── factory_bot
│   │   ├── assignments.rb
│   │   ├── conditional_release
│   │   │   ├── assignment_set_actions.rb
│   │   │   ├── assignment_set_associations.rb
│   │   │   ├── assignment_sets.rb
│   │   │   ├── rules.rb
│   │   │   └── scoring_ranges.rb
│   │   └── courses.rb
│   ├── factory_bot_spec_helper.rb
│   ├── feature_flag_helper.rb
│   ├── file_upload_helper.rb
│   ├── fixtures
│   │   ├── a11yCheckerTest1.css
│   │   ├── a11yCheckerTest2.css
│   │   ├── alphabet_soup.zip
│   │   ├── asset_files
│   │   │   ├── plugin_assets_1.yml
│   │   │   └── plugin_assets_2.yml
│   │   ├── attachments.zip
│   │   ├── block-editor
│   │   │   ├── kb-nav-test-page.json
│   │   │   ├── page-with-apple-icon.json
│   │   │   └── white-sands.jpg
│   │   ├── bounces.json
│   │   ├── courses.yml
│   │   ├── data_generation
│   │   │   └── generate_data.rb
│   │   ├── exporter
│   │   │   ├── cc-with-modules-export.imscc
│   │   │   └── cc-without-modules-export.imscc
│   │   ├── file_mail.txt
│   │   ├── files
│   │   │   ├── 100mpx.png
│   │   │   ├── 292
│   │   │   ├── 292.mp3
│   │   │   ├── Dog_file.txt
│   │   │   ├── a_file.txt
│   │   │   ├── amazing_file.txt
│   │   │   ├── b_file.txt
│   │   │   ├── c_file.txt
│   │   │   ├── cn_image.jpg
│   │   │   ├── conferences
│   │   │   │   ├── big_blue_button_delete_recordings.xml
│   │   │   │   ├── big_blue_button_failed_notstubbed.xml
│   │   │   │   ├── big_blue_button_get_recordings_bulk.json
│   │   │   │   ├── big_blue_button_get_recordings_deleted.json
│   │   │   │   ├── big_blue_button_get_recordings_none.xml
│   │   │   │   ├── big_blue_button_get_recordings_one.xml
│   │   │   │   ├── big_blue_button_get_recordings_two.json
│   │   │   │   └── big_blue_button_get_recordings_two.xml
│   │   │   ├── docs
│   │   │   │   ├── doc.doc
│   │   │   │   └── txt.txt
│   │   │   ├── empty_file.txt
│   │   │   ├── escaping_test[0].txt
│   │   │   ├── example.pdf
│   │   │   ├── good_data.txt
│   │   │   ├── group_categories
│   │   │   │   └── test_group_categories.csv
│   │   │   ├── hello-world.sh
│   │   │   ├── html-editing-test.html
│   │   │   ├── instructure.png
│   │   │   ├── migration
│   │   │   │   └── canvas_cc_minimum.zip
│   │   │   ├── outcomes
│   │   │   │   ├── test_outcomes_1.csv
│   │   │   │   ├── test_outcomes_no_groups.csv
│   │   │   │   └── test_outcomes_with_errors.csv
│   │   │   ├── rubric
│   │   │   │   └── assessments.csv
│   │   │   ├── sis
│   │   │   │   └── test_user_1.csv
│   │   │   ├── submissions.zip
│   │   │   ├── test.docx
│   │   │   ├── test.html
│   │   │   ├── test.js
│   │   │   ├── test.rtf
│   │   │   └── test_image.jpg
│   │   ├── gradebooks
│   │   │   ├── added_students.csv
│   │   │   ├── basic_course.csv
│   │   │   ├── basic_course_with_sis_login_id.csv
│   │   │   ├── pristine.csv
│   │   │   ├── some_changes.csv
│   │   │   ├── valid_gradebook_contents_with_last_and_first_names.csv
│   │   │   └── wat.csv
│   │   ├── html_mail.txt
│   │   ├── huge_zip.zip
│   │   ├── icon.svg
│   │   ├── icon_with_bad_xml.svg
│   │   ├── importer
│   │   │   ├── angel
│   │   │   │   └── rubric.json
│   │   │   ├── announcements.json
│   │   │   ├── assessments.json
│   │   │   ├── assignment.json
│   │   │   ├── bb8
│   │   │   │   ├── announcements.json
│   │   │   │   ├── assignment.json
│   │   │   │   ├── assignment_group.json
│   │   │   │   ├── calendar_event.json
│   │   │   │   ├── discussion_topic.json
│   │   │   │   ├── group.json
│   │   │   │   ├── group_discussion.json
│   │   │   │   ├── module.json
│   │   │   │   ├── quiz
│   │   │   │   │   ├── calculated_complex.json
│   │   │   │   │   ├── calculated_simple.json
│   │   │   │   │   ├── essay.json
│   │   │   │   │   ├── file_upload.json
│   │   │   │   │   ├── fill_in_multiple_blanks.json
│   │   │   │   │   ├── hot_spot.json
│   │   │   │   │   ├── matching.json
│   │   │   │   │   ├── multiple_answers.json
│   │   │   │   │   ├── multiple_choice.json
│   │   │   │   │   ├── multiple_dropdowns.json
│   │   │   │   │   ├── numerical.json
│   │   │   │   │   ├── ordering.json
│   │   │   │   │   ├── quiz.json
│   │   │   │   │   ├── quiz_bowl.json
│   │   │   │   │   ├── short_answer.json
│   │   │   │   │   └── true_false.json
│   │   │   │   ├── sub_items.json
│   │   │   │   └── wiki.json
│   │   │   ├── bb9
│   │   │   │   ├── quiz
│   │   │   │   │   └── matching.json
│   │   │   │   ├── wiki.json
│   │   │   │   └── wikis.json
│   │   │   ├── cengage
│   │   │   │   ├── question.json
│   │   │   │   └── quiz.json
│   │   │   ├── discussion_assignments.json
│   │   │   ├── import_from_migration.json
│   │   │   ├── import_from_migration_small.zip
│   │   │   ├── matching_tool_profiles.json
│   │   │   ├── module-item-select.json
│   │   │   ├── nonmatching_tool_profiles.json
│   │   │   ├── outcomes.json
│   │   │   ├── question_group.json
│   │   │   ├── single_question.json
│   │   │   ├── unzipped
│   │   │   │   ├── course_settings
│   │   │   │   │   ├── assignment_groups.xml
│   │   │   │   │   ├── canvas_export.txt
│   │   │   │   │   ├── course_settings.xml
│   │   │   │   │   ├── files_meta.xml
│   │   │   │   │   └── media_tracks.xml
│   │   │   │   ├── i964fd8107ac2c2e75e9a142971693976.json
│   │   │   │   ├── imsmanifest.xml
│   │   │   │   └── lti_resource_links
│   │   │   │       ├── 1234facc599d2202cf67dce042ee34321.xml
│   │   │   │       ├── 5678facc599d2202cf67dce042ee34321.xml
│   │   │   │       └── g534facc599d2202cf67dce042ee3105b.xml
│   │   │   └── vista
│   │   │       ├── announcements.json
│   │   │       ├── assignment.json
│   │   │       ├── calendar_event.json
│   │   │       ├── discussion_topic.json
│   │   │       ├── goal_category.json
│   │   │       ├── module.json
│   │   │       ├── quiz
│   │   │       │   ├── calculated_complex.json
│   │   │       │   ├── calculated_simple.json
│   │   │       │   ├── essay.json
│   │   │       │   ├── fill_in_multiple_blanks.json
│   │   │       │   ├── group_quiz_data.json
│   │   │       │   ├── matching.json
│   │   │       │   ├── multiple_answers.json
│   │   │       │   ├── multiple_choice.json
│   │   │       │   ├── new_quizzes_assignment.json
│   │   │       │   ├── short_answer.json
│   │   │       │   ├── simple_quiz_data.json
│   │   │       │   └── text_only_quiz_data.json
│   │   │       └── rubric.json
│   │   ├── lti
│   │   │   ├── config.course_assignments_menu.xml
│   │   │   ├── config.post_grades.xml
│   │   │   ├── config.youtube.xml
│   │   │   ├── content_items.json
│   │   │   ├── content_items_2.json
│   │   │   ├── lti_scopes.yml
│   │   │   └── tool_proxy.json
│   │   ├── mail.txt
│   │   ├── message_1.txt
│   │   ├── message_2.txt
│   │   ├── message_3.txt
│   │   ├── migration
│   │   │   ├── asmnt_example.zip
│   │   │   ├── canvas_announcement.zip
│   │   │   ├── canvas_attachment.zip
│   │   │   ├── canvas_cc_only_questions.zip
│   │   │   ├── canvas_cc_utf16_error.zip
│   │   │   ├── canvas_matching_reorder.zip
│   │   │   ├── canvas_quiz_media_comment.zip
│   │   │   ├── cc_ark_test.zip
│   │   │   ├── cc_assignment_extension.zip
│   │   │   ├── cc_default_qb_test.tar.gz
│   │   │   ├── cc_default_qb_test.zip
│   │   │   ├── cc_dotdot_madness.zip
│   │   │   ├── cc_empty_link.zip
│   │   │   ├── cc_file_to_page_test.zip
│   │   │   ├── cc_full_test.zip
│   │   │   ├── cc_full_test_smaller.zip
│   │   │   ├── cc_inline_qti.zip
│   │   │   ├── cc_lti_combine_test.zip
│   │   │   ├── cc_nested.zip
│   │   │   ├── cc_outcomes.imscc
│   │   │   ├── cc_pattern_match.zip
│   │   │   ├── cc_syllabus.zip
│   │   │   ├── cc_unsupported_resources.zip
│   │   │   ├── exported_data_cm.zip
│   │   │   ├── file.zip
│   │   │   ├── flat_imsmanifest.xml
│   │   │   ├── flat_imsmanifest_with_curriculum.xml
│   │   │   ├── flat_imsmanifest_with_variants.xml
│   │   │   ├── macfile.zip
│   │   │   ├── media_quiz_qti.zip
│   │   │   ├── package_identifier
│   │   │   │   ├── angel7-3.zip
│   │   │   │   ├── angel7-4.zip
│   │   │   │   ├── bb_learn.zip
│   │   │   │   ├── canvas.zip
│   │   │   │   ├── cc1-0.zip
│   │   │   │   ├── cc1-1.zip
│   │   │   │   ├── cc1-2.zip
│   │   │   │   ├── cc1-3.zip
│   │   │   │   ├── cc1-3flat.xml
│   │   │   │   ├── cc1-3thin.xml
│   │   │   │   ├── d2l.zip
│   │   │   │   ├── ims_cp.zip
│   │   │   │   ├── invalid.zip
│   │   │   │   ├── moodle1-9.zip
│   │   │   │   ├── moodle2.zip
│   │   │   │   ├── old_canvas.zip
│   │   │   │   ├── qti.zip
│   │   │   │   ├── scorm1-1.zip
│   │   │   │   ├── scorm1-2.zip
│   │   │   │   ├── scorm1-3.zip
│   │   │   │   ├── unknown.zip
│   │   │   │   ├── webct.zip
│   │   │   │   └── webct4-1.zip
│   │   │   ├── page-with-media.imscc
│   │   │   ├── plaintext_qti.zip
│   │   │   ├── quiz_qti.zip
│   │   │   ├── rcx-1949.imscc
│   │   │   ├── unicode-filename-test-export.imscc
│   │   │   └── whatthebackslash.zip
│   │   ├── multipart-request
│   │   ├── ok.json
│   │   ├── pug.jpg
│   │   ├── selection_test_lti.xml
│   │   ├── sis
│   │   │   ├── mac_sis_batch.zip
│   │   │   ├── utf8.csv
│   │   │   └── with_bom.csv
│   │   ├── submissions.zip
│   │   ├── test.xsd
│   │   ├── tilde.zip
│   │   ├── zip_with_long_filename_inside.zip
│   │   └── zipbomb.zip
│   ├── force_failure_spec.rb
│   ├── formatters
│   │   ├── error_context
│   │   │   ├── base_formatter.rb
│   │   │   ├── html_page_formatter
│   │   │   │   └── template.html.erb
│   │   │   ├── html_page_formatter.rb
│   │   │   └── stderr_formatter.rb
│   │   ├── nested_instafail_formatter.rb
│   │   ├── node_count_formatter.rb
│   │   ├── rerun_argument.rb
│   │   └── rerun_formatter.rb
│   ├── gem_integration
│   │   └── canvas_connect
│   │       ├── adobe_connect_conference_spec.rb
│   │       ├── adobe_connect_validator_spec.rb
│   │       └── meeting_archive_spec.rb
│   ├── graphql
│   │   ├── canvas_schema_spec.rb
│   │   ├── graph_ql_helpers
│   │   │   └── auto_grade_eligibility_helper_spec.rb
│   │   ├── graphql_helpers_spec.rb
│   │   ├── graphql_node_loader_spec.rb
│   │   ├── graphql_spec_helper.rb
│   │   ├── legacy_node_spec.rb
│   │   ├── loaders
│   │   │   ├── activity_stream_summary_loader_spec.rb
│   │   │   ├── asset_string_loader_spec.rb
│   │   │   ├── association_loader_spec.rb
│   │   │   ├── course_outcome_alignment_stats_loader_spec.rb
│   │   │   ├── discussion_entry_loader_spec.rb
│   │   │   ├── discussion_entry_user_loader_spec.rb
│   │   │   ├── entry_participant_loader_spec.rb
│   │   │   ├── foreign_key_loader_spec.rb
│   │   │   ├── has_postable_comments_loader_spec.rb
│   │   │   ├── id_loader_spec.rb
│   │   │   ├── outcome_alignment_loader_spec.rb
│   │   │   ├── outcome_friendly_description_loader_spec.rb
│   │   │   ├── section_grade_posted_state_spec.rb
│   │   │   ├── sisid_loader_spec.rb
│   │   │   ├── submission_group_id_loader_spec.rb
│   │   │   └── unsharded_id_loader_spec.rb
│   │   ├── mutation_audit_log_spec.rb
│   │   ├── mutations
│   │   │   ├── add_conversation_message_spec.rb
│   │   │   ├── create_assignment_spec.rb
│   │   │   ├── create_comment_bank_item_spec.rb
│   │   │   ├── create_conversation_spec.rb
│   │   │   ├── create_discussion_entry_draft_spec.rb
│   │   │   ├── create_discussion_entry_spec.rb
│   │   │   ├── create_discussion_topic_spec.rb
│   │   │   ├── create_group_in_set_spec.rb
│   │   │   ├── create_group_set_spec.rb
│   │   │   ├── create_internal_setting_spec.rb
│   │   │   ├── create_learning_outcome_group_spec.rb
│   │   │   ├── create_learning_outcome_spec.rb
│   │   │   ├── create_module_spec.rb
│   │   │   ├── create_outcome_calculation_method_spec.rb
│   │   │   ├── create_outcome_proficiency_spec.rb
│   │   │   ├── create_submission_comment_spec.rb
│   │   │   ├── create_submission_draft_spec.rb
│   │   │   ├── create_submission_spec.rb
│   │   │   ├── create_user_inbox_label_spec.rb
│   │   │   ├── delete_comment_bank_item_spec.rb
│   │   │   ├── delete_conversation_messages_spec.rb
│   │   │   ├── delete_conversations_spec.rb
│   │   │   ├── delete_custom_grade_status_spec.rb
│   │   │   ├── delete_discussion_entry_spec.rb
│   │   │   ├── delete_discussion_topic_spec.rb
│   │   │   ├── delete_internal_setting_spec.rb
│   │   │   ├── delete_outcome_calculation_method_spec.rb
│   │   │   ├── delete_outcome_links_spec.rb
│   │   │   ├── delete_outcome_proficiency_spec.rb
│   │   │   ├── delete_submission_comment_spec.rb
│   │   │   ├── delete_submission_draft_spec.rb
│   │   │   ├── delete_user_inbox_label_spec.rb
│   │   │   ├── hide_assignment_grades_for_sections_spec.rb
│   │   │   ├── hide_assignment_grades_spec.rb
│   │   │   ├── import_outcomes_spec.rb
│   │   │   ├── mark_submission_comments_read_spec.rb
│   │   │   ├── move_outcome_links_spec.rb
│   │   │   ├── post_assignment_grades_for_sections_spec.rb
│   │   │   ├── post_assignment_grades_spec.rb
│   │   │   ├── post_draft_submission_comment_spec.rb
│   │   │   ├── save_rubric_assessment_spec.rb
│   │   │   ├── set_assignment_post_policy_spec.rb
│   │   │   ├── set_course_post_policy_spec.rb
│   │   │   ├── set_friendly_description_spec.rb
│   │   │   ├── set_module_item_completion_spec.rb
│   │   │   ├── set_override_score_spec.rb
│   │   │   ├── set_override_status_spec.rb
│   │   │   ├── set_rubric_self_assessment_spec.rb
│   │   │   ├── subscribe_to_discussion_topic_spec.rb
│   │   │   ├── update_assignment_override_spec.rb
│   │   │   ├── update_assignment_spec.rb
│   │   │   ├── update_comment_bank_item_spec.rb
│   │   │   ├── update_conversation_participants_spec.rb
│   │   │   ├── update_discussion_entries_read_state_spec.rb
│   │   │   ├── update_discussion_entry_participant_spec.rb
│   │   │   ├── update_discussion_entry_spec.rb
│   │   │   ├── update_discussion_expanded_spec.rb
│   │   │   ├── update_discussion_read_state_spec.rb
│   │   │   ├── update_discussion_sort_order_spec.rb
│   │   │   ├── update_discussion_thread_read_state_spec.rb
│   │   │   ├── update_discussion_topic_participant_spec.rb
│   │   │   ├── update_discussion_topic_spec.rb
│   │   │   ├── update_gradebook_group_filter_spec.rb
│   │   │   ├── update_internal_setting_spec.rb
│   │   │   ├── update_learning_outcome_group_spec.rb
│   │   │   ├── update_learning_outcome_spec.rb
│   │   │   ├── update_my_inbox_settings_spec.rb
│   │   │   ├── update_notification_preferences_spec.rb
│   │   │   ├── update_outcome_calculation_method_spec.rb
│   │   │   ├── update_outcome_proficiency_spec.rb
│   │   │   ├── update_rubric_archived_state_spec.rb
│   │   │   ├── update_rubric_assessment_read_state_spec.rb
│   │   │   ├── update_speed_grader_settings_spec.rb
│   │   │   ├── update_split_screen_view_deeply_nested_alert_spec.rb
│   │   │   ├── update_submission_grade_spec.rb
│   │   │   ├── update_submission_grade_status_spec.rb
│   │   │   ├── update_submission_sticker_spec.rb
│   │   │   ├── update_submission_student_entered_score_spec.rb
│   │   │   ├── update_submissions_read_state_spec.rb
│   │   │   ├── update_user_discussions_splitscreen_view_spec.rb
│   │   │   ├── upsert_custom_grade_status_spec.rb
│   │   │   └── upsert_standard_grade_status_spec.rb
│   │   ├── postgres_statement_timeout_spec.rb
│   │   ├── selenium
│   │   │   └── context_card_selenium_spec.rb
│   │   ├── token_scoping_spec.rb
│   │   └── types
│   │       ├── account_type_spec.rb
│   │       ├── assessment_request_type_spec.rb
│   │       ├── assignment_group_type_spec.rb
│   │       ├── assignment_type_spec.rb
│   │       ├── checkpoint_type_spec.rb
│   │       ├── comment_bank_item_type_spec.rb
│   │       ├── conversation_type_spec.rb
│   │       ├── course_dashboard_card_type_spec.rb
│   │       ├── course_outcome_alignment_stats_type_spec.rb
│   │       ├── course_permissions_type_spec.rb
│   │       ├── course_progression_type_spec.rb
│   │       ├── course_type_spec.rb
│   │       ├── custom_grade_status_type_spec.rb
│   │       ├── discussion_entry_type_spec.rb
│   │       ├── discussion_type_spec.rb
│   │       ├── enrollment_type_spec.rb
│   │       ├── external_tool_type_spec.rb
│   │       ├── external_url_type_spec.rb
│   │       ├── file_type_spec.rb
│   │       ├── folder_type_spec.rb
│   │       ├── grades_type_spec.rb
│   │       ├── grading_period_group_type_spec.rb
│   │       ├── grading_period_type_spec.rb
│   │       ├── group_set_type_spec.rb
│   │       ├── group_type_spec.rb
│   │       ├── internal_setting_type_spec.rb
│   │       ├── learning_outcome_group_type_spec.rb
│   │       ├── learning_outcome_type_spec.rb
│   │       ├── media_object_type_spec.rb
│   │       ├── media_source_type_spec.rb
│   │       ├── messageable_user_type_spec.rb
│   │       ├── module_external_tool_type_spec.rb
│   │       ├── module_item_type_spec.rb
│   │       ├── module_progression_type_spec.rb
│   │       ├── module_type_spec.rb
│   │       ├── mutation_log_type_spec.rb
│   │       ├── notification_preferences_type_spec.rb
│   │       ├── outcome_alignment_type_spec.rb
│   │       ├── outcome_calculation_method_type_spec.rb
│   │       ├── outcome_friendly_description_type_spec.rb
│   │       ├── outcome_proficiency_type_spec.rb
│   │       ├── page_type_spec.rb
│   │       ├── post_policy_type_spec.rb
│   │       ├── proficiency_rating_type_spec.rb
│   │       ├── progress_type_spec.rb
│   │       ├── query_type_spec.rb
│   │       ├── quiz_item_type_spec.rb
│   │       ├── quiz_type_spec.rb
│   │       ├── rubric_assessment_rating_type_spec.rb
│   │       ├── rubric_assessment_type_spec.rb
│   │       ├── rubric_association_type_spec.rb
│   │       ├── rubric_criterion_type_spec.rb
│   │       ├── rubric_rating_type_spec.rb
│   │       ├── rubric_type_spec.rb
│   │       ├── section_type_spec.rb
│   │       ├── shared_examples
│   │       │   └── types_with_enumerable_workflow_states.rb
│   │       ├── standard_grade_status_type_spec.rb
│   │       ├── submission_comment_type_spec.rb
│   │       ├── submission_draft_type_spec.rb
│   │       ├── submission_type_spec.rb
│   │       ├── term_type_spec.rb
│   │       ├── usage_rights_type_spec.rb
│   │       └── user_type_spec.rb
│   ├── helpers
│   │   ├── accounts_helper_spec.rb
│   │   ├── alignments_helper_spec.rb
│   │   ├── application_helper_spec.rb
│   │   ├── assessment_request_helper_spec.rb
│   │   ├── assignments_helper_spec.rb
│   │   ├── attachment_helper_spec.rb
│   │   ├── avatar_helper_spec.rb
│   │   ├── broken_link_helper_spec.rb
│   │   ├── canvas_outcomes_helper_spec.rb
│   │   ├── collaborations_helper_spec.rb
│   │   ├── content_export_api_helper_spec.rb
│   │   ├── content_export_assignment_helper_spec.rb
│   │   ├── context_external_tools_helper_spec.rb
│   │   ├── context_modules_helper_spec.rb
│   │   ├── conversations_helper_spec.rb
│   │   ├── courses_helper_spec.rb
│   │   ├── custom_color_helper_spec.rb
│   │   ├── cyoe_helper_spec.rb
│   │   ├── dashboard_helper_spec.rb
│   │   ├── datadog_rum_helper_spec.rb
│   │   ├── default_due_time_helper_spec.rb
│   │   ├── gradebooks_helper_spec.rb
│   │   ├── grading_periods_helper_spec.rb
│   │   ├── graphql_type_tester.rb
│   │   ├── group_permission_helper_spec.rb
│   │   ├── inst_llm_helper_spec.rb
│   │   ├── k5_common.rb
│   │   ├── login
│   │   │   ├── canvas_helper_spec.rb
│   │   │   └── otp_helper_spec.rb
│   │   ├── messages
│   │   │   └── peer_reviews_helper_spec.rb
│   │   ├── mock_static_site_spec.rb
│   │   ├── new_quizzes_features_helper_spec.rb
│   │   ├── observer_enrollments_helper_spec.rb
│   │   ├── outcome_result_resolver_helper_spec.rb
│   │   ├── outcomes_features_helper_spec.rb
│   │   ├── outcomes_request_batcher_spec.rb
│   │   ├── outcomes_service_alignments_helper_spec.rb
│   │   ├── outcomes_service_authoritative_results_helper_spec.rb
│   │   ├── pact_api_consumer_proxy_spec.rb
│   │   ├── profile_helper_spec.rb
│   │   ├── quizzes_helper_spec.rb
│   │   ├── rrule_helper_spec.rb
│   │   ├── search_helper_spec.rb
│   │   ├── section_tab_helper_spec.rb
│   │   ├── stream_items_helper_spec.rb
│   │   ├── submissions_helper_spec.rb
│   │   ├── syllabus_helper_spec.rb
│   │   ├── url_helper_spec.rb
│   │   ├── usage_metrics_helper_spec.rb
│   │   ├── users_helper_spec.rb
│   │   ├── web_zip_export_helper_spec.rb
│   │   └── will_paginate_helper_spec.rb
│   ├── import_helper.rb
│   ├── initializers
│   │   ├── active_record_query_trace_spec.rb
│   │   ├── active_record_spec.rb
│   │   ├── active_support_spec.rb
│   │   ├── canvas_http_spec.rb
│   │   ├── class_name_spec.rb
│   │   ├── delayed_job_spec.rb
│   │   ├── folio_spec.rb
│   │   ├── gems_spec.rb
│   │   ├── i18n_spec.rb
│   │   ├── inst_access_support_spec.rb
│   │   ├── jwt_workflow_spec.rb
│   │   ├── periodic_jobs_spec.rb
│   │   ├── permissions_registry_spec.rb
│   │   ├── rack_spec.rb
│   │   ├── rails_patches_spec.rb
│   │   ├── ruby_version_compat_spec.rb
│   │   ├── sentry_spec.rb
│   │   └── switchman_spec.rb
│   ├── integration
│   │   ├── account_spec.rb
│   │   ├── application_spec.rb
│   │   ├── asset_accesses_spec.rb
│   │   ├── assignments_spec.rb
│   │   ├── autoextend_spec.rb
│   │   ├── avatar_is_fallback_spec.rb
│   │   ├── collaborations_spec.rb
│   │   ├── concluded_unconcluded_spec.rb
│   │   ├── conferences_spec.rb
│   │   ├── content_zipper_spec.rb
│   │   ├── context_module_spec.rb
│   │   ├── course_spec.rb
│   │   ├── cross_listing_spec.rb
│   │   ├── discussion_topics_spec.rb
│   │   ├── enrollment_date_restrictions_spec.rb
│   │   ├── external_tools_controller_spec.rb
│   │   ├── external_tools_spec.rb
│   │   ├── files_spec.rb
│   │   ├── groups_spec.rb
│   │   ├── live_events_spec.rb
│   │   ├── load_account_spec.rb
│   │   ├── locale_selection_spec.rb
│   │   ├── login
│   │   │   └── openid_connect_controller_spec.rb
│   │   ├── login_spec.rb
│   │   ├── otp_spec.rb
│   │   ├── page_view_spec.rb
│   │   ├── profile_spec.rb
│   │   ├── public_access_spec.rb
│   │   ├── question_banks_spec.rb
│   │   ├── quiz_regrading_spec.rb
│   │   ├── quiz_submissions_spec.rb
│   │   ├── quizzes_spec.rb
│   │   ├── request_throttling_spec.rb
│   │   ├── rubrics_spec.rb
│   │   ├── scores_spec.rb
│   │   ├── security_spec.rb
│   │   ├── sentry_trace_scrubber_spec.rb
│   │   ├── session_token_spec.rb
│   │   ├── sessions_timeout_spec.rb
│   │   ├── student_interactions_spec.rb
│   │   ├── syllabus_spec.rb
│   │   ├── track_memory_and_cpu_spec.rb
│   │   ├── user_content_spec.rb
│   │   ├── users_controller_spec.rb
│   │   ├── varied_due_dates_spec.rb
│   │   ├── web_app_manifest_spec.rb
│   │   └── wiki_page_spec.rb
│   ├── lib
│   │   ├── account_cacher_spec.rb
│   │   ├── active_support
│   │   │   └── cache
│   │   │       └── safe_redis_race_condition_spec.rb
│   │   ├── acts_as_list_spec.rb
│   │   ├── address_book
│   │   │   ├── empty_spec.rb
│   │   │   ├── messageable_user_spec.rb
│   │   │   └── service_spec.rb
│   │   ├── address_book_spec.rb
│   │   ├── anonymity_spec.rb
│   │   ├── api
│   │   │   ├── html
│   │   │   │   ├── content_spec.rb
│   │   │   │   ├── link_spec.rb
│   │   │   │   ├── media_tag_spec.rb
│   │   │   │   ├── track_tag_spec.rb
│   │   │   │   └── url_proxy_spec.rb
│   │   │   └── v1
│   │   │       ├── assignment_override_spec.rb
│   │   │       ├── assignment_spec.rb
│   │   │       ├── attachment_spec.rb
│   │   │       ├── calendar_event_spec.rb
│   │   │       ├── collaborator_spec.rb
│   │   │       ├── conferences_spec.rb
│   │   │       ├── context_module_spec.rb
│   │   │       ├── context_spec.rb
│   │   │       ├── course_event_spec.rb
│   │   │       ├── course_spec.rb
│   │   │       ├── custom_gradebook_column_spec.rb
│   │   │       ├── external_tools_spec.rb
│   │   │       ├── grade_change_event_spec.rb
│   │   │       ├── group_category_spec.rb
│   │   │       ├── group_spec.rb
│   │   │       ├── moderation_grader_spec.rb
│   │   │       ├── observer_alert_spec.rb
│   │   │       ├── observer_alert_threshold_spec.rb
│   │   │       ├── outcome_spec.rb
│   │   │       ├── page_view_spec.rb
│   │   │       ├── planner_item_spec.rb
│   │   │       ├── planner_override_spec.rb
│   │   │       ├── plugin_spec.rb
│   │   │       ├── pseudonym_spec.rb
│   │   │       ├── quiz_question_spec.rb
│   │   │       ├── quiz_submission_question_spec.rb
│   │   │       ├── rubric_assessment_spec.rb
│   │   │       ├── sis_assignment_spec.rb
│   │   │       ├── submission_comment_spec.rb
│   │   │       └── submission_spec.rb
│   │   ├── api_scope_mapper_fallback_spec.rb
│   │   ├── api_spec.rb
│   │   ├── app_center
│   │   │   └── app_api_spec.rb
│   │   ├── asset_signature_spec.rb
│   │   ├── assignment_override_applicator_spec.rb
│   │   ├── assignment_util_spec.rb
│   │   ├── atom_feed_helper_spec.rb
│   │   ├── authentication_methods
│   │   │   └── inst_access_token_spec.rb
│   │   ├── authentication_methods_spec.rb
│   │   ├── basic_lti
│   │   │   ├── basic_outcomes_spec.rb
│   │   │   ├── quizzes_next_lti_response_spec.rb
│   │   │   ├── quizzes_next_submission_reverter_spec.rb
│   │   │   ├── quizzes_next_versioned_submission_spec.rb
│   │   │   └── sourcedid_spec.rb
│   │   ├── basic_lti_spec.rb
│   │   ├── brand_account_chain_resolver_spec.rb
│   │   ├── brand_config_helpers_spec.rb
│   │   ├── brand_config_regenerator_spec.rb
│   │   ├── brandable_css_spec.rb
│   │   ├── browser_support_spec.rb
│   │   ├── canvadocs
│   │   │   └── session_spec.rb
│   │   ├── canvadocs_spec.rb
│   │   ├── canvas
│   │   │   ├── apm
│   │   │   │   └── inst_jobs
│   │   │   │       └── plugin_spec.rb
│   │   │   ├── apm_common.rb
│   │   │   ├── apm_spec.rb
│   │   │   ├── builders
│   │   │   │   └── enrollment_date_builder_spec.rb
│   │   │   ├── cache
│   │   │   │   ├── fallback_memory_cache_spec.rb
│   │   │   │   └── local_redis_cache_spec.rb
│   │   │   ├── cache_register_spec.rb
│   │   │   ├── cdn
│   │   │   │   └── registry_spec.rb
│   │   │   ├── cdn_spec.rb
│   │   │   ├── crocodoc_spec.rb
│   │   │   ├── cross_region_query_metrics_spec.rb
│   │   │   ├── draft_state_validations_examples.rb
│   │   │   ├── dynamic_settings
│   │   │   │   └── prefix_proxy_spec.rb
│   │   │   ├── error_stats_spec.rb
│   │   │   ├── errors
│   │   │   │   ├── info_spec.rb
│   │   │   │   ├── log_entry_spec.rb
│   │   │   │   ├── reporter_spec.rb
│   │   │   │   └── worker_info_spec.rb
│   │   │   ├── errors_spec.rb
│   │   │   ├── failure_percent_counter_spec.rb
│   │   │   ├── icu_spec.rb
│   │   │   ├── live_events_spec.rb
│   │   │   ├── lock_explanation_spec.rb
│   │   │   ├── migration
│   │   │   │   ├── external_content
│   │   │   │   │   ├── migrator_spec.rb
│   │   │   │   │   └── translator_spec.rb
│   │   │   │   ├── helpers
│   │   │   │   │   └── selective_content_formatter_spec.rb
│   │   │   │   ├── migrator_helper_spec.rb
│   │   │   │   ├── package_identifier_spec.rb
│   │   │   │   └── xml_helper_spec.rb
│   │   │   ├── migration_spec.rb
│   │   │   ├── oauth
│   │   │   │   ├── client_credentials_provider_spec.rb
│   │   │   │   ├── grant_types
│   │   │   │   │   ├── authorization_code_with_pkce_spec.rb
│   │   │   │   │   └── refresh_token_spec.rb
│   │   │   │   ├── invalid_scope_error_spec.rb
│   │   │   │   ├── pkce_spec.rb
│   │   │   │   ├── provider_spec.rb
│   │   │   │   ├── service_user_client_credentials_provider_spec.rb
│   │   │   │   └── token_spec.rb
│   │   │   ├── plugin_spec.rb
│   │   │   ├── plugins
│   │   │   │   ├── ticketing_system
│   │   │   │   │   ├── base_plugin_spec.rb
│   │   │   │   │   ├── custom_error_spec.rb
│   │   │   │   │   ├── email_plugin_spec.rb
│   │   │   │   │   └── web_post_plugin_spec.rb
│   │   │   │   └── ticketing_system_spec.rb
│   │   │   ├── redis_connections_spec.rb
│   │   │   ├── redis_spec.rb
│   │   │   ├── reloader_spec.rb
│   │   │   ├── request_forgery_protection_spec.rb
│   │   │   ├── request_throttle_spec.rb
│   │   │   ├── root_account_cacher_spec.rb
│   │   │   ├── security
│   │   │   │   ├── jwt_validator_spec.rb
│   │   │   │   ├── login_registry_spec.rb
│   │   │   │   ├── password_policy_account_setting_validator_spec.rb
│   │   │   │   ├── password_policy_spec.rb
│   │   │   │   └── recryption_spec.rb
│   │   │   ├── security_spec.rb
│   │   │   ├── twilio_spec.rb
│   │   │   ├── vault
│   │   │   │   ├── aws_credential_provider_spec.rb
│   │   │   │   └── file_client_spec.rb
│   │   │   └── vault_spec.rb
│   │   ├── canvas_imported_html_converter_spec.rb
│   │   ├── canvas_spec.rb
│   │   ├── cc
│   │   │   ├── assignment_resources_spec.rb
│   │   │   ├── basic_lti_links_spec.rb
│   │   │   ├── cc_exporter_spec.rb
│   │   │   ├── cc_helper_spec.rb
│   │   │   ├── cc_spec_helper.rb
│   │   │   ├── exporter
│   │   │   │   ├── epub
│   │   │   │   │   ├── converters
│   │   │   │   │   │   ├── media_converter_spec.rb
│   │   │   │   │   │   ├── module_epub_converter_spec.rb
│   │   │   │   │   │   └── object_path_converter_spec.rb
│   │   │   │   │   ├── exportable_spec.rb
│   │   │   │   │   └── exporter_spec.rb
│   │   │   │   └── web_zip
│   │   │   │       ├── exportable_spec.rb
│   │   │   │       ├── exporter_spec.rb
│   │   │   │       └── zip_package_spec.rb
│   │   │   ├── importer
│   │   │   │   ├── canvas
│   │   │   │   │   ├── converter_spec.rb
│   │   │   │   │   ├── course_settings_spec.rb
│   │   │   │   │   ├── lti_resource_link_converter_spec.rb
│   │   │   │   │   ├── tool_profile_converter_spec.rb
│   │   │   │   │   └── topic_converter_spec.rb
│   │   │   │   ├── canvas_cartridge_converter_spec.rb
│   │   │   │   ├── cc_worker_spec.rb
│   │   │   │   ├── common_cartridge_1_3_spec.rb
│   │   │   │   ├── common_cartridge_converter_spec.rb
│   │   │   │   └── standard
│   │   │   │       ├── assignment_converter_spec.rb
│   │   │   │       └── converter_spec.rb
│   │   │   ├── learning_outcome_spec.rb
│   │   │   ├── lti_resource_links_spec.rb
│   │   │   ├── new_quizzes_links_replacer_spec.rb
│   │   │   ├── qti
│   │   │   │   ├── fixtures
│   │   │   │   │   ├── nq_common_cartridge_export.zip
│   │   │   │   │   ├── nq_common_cartridge_export_with_bank.zip
│   │   │   │   │   ├── nq_common_cartridge_export_with_images.zip
│   │   │   │   │   └── nq_common_cartridge_with_mig_ids_map.zip
│   │   │   │   ├── migration_ids_replacer_spec.rb
│   │   │   │   ├── new_quizzes_generator_spec.rb
│   │   │   │   └── qti_generator_spec.rb
│   │   │   ├── schema_spec.rb
│   │   │   └── topic_resources_spec.rb
│   │   ├── checkpoint_spec.rb
│   │   ├── concluded_grading_standard_setter_spec.rb
│   │   ├── content_notices_spec.rb
│   │   ├── content_zipper_spec.rb
│   │   ├── course_link_validator_spec.rb
│   │   ├── course_pace_due_dates_calculator_spec.rb
│   │   ├── course_pace_hard_end_date_compressor_spec.rb
│   │   ├── course_paces_date_helpers_spec.rb
│   │   ├── crummy_spec.rb
│   │   ├── csv_with_i18n_spec.rb
│   │   ├── cuty_capt_spec.rb
│   │   ├── data_fixup
│   │   │   ├── add_media_data_attribute_to_iframes_spec.rb
│   │   │   ├── add_media_id_and_style_display_attributes_to_iframes_spec.rb
│   │   │   ├── add_user_uuid_to_learning_outcome_results_spec.rb
│   │   │   ├── backfill_new_default_help_link_spec.rb
│   │   │   ├── backfill_nulls_spec.rb
│   │   │   ├── bulk_column_updater_spec.rb
│   │   │   ├── clear_account_settings_spec.rb
│   │   │   ├── copy_custom_data_to_jsonb_spec.rb
│   │   │   ├── create_lti_registrations_from_developer_keys_spec.rb
│   │   │   ├── create_media_objects_for_media_attachments_lacking_spec.rb
│   │   │   ├── delete_discussion_topic_no_message_spec.rb
│   │   │   ├── delete_orphaned_feature_flags_spec.rb
│   │   │   ├── delete_role_overrides_spec.rb
│   │   │   ├── fix_data_inconsistency_in_learning_outcomes_spec.rb
│   │   │   ├── get_media_from_notorious_into_instfs_spec.rb
│   │   │   ├── granular_permissions
│   │   │   │   ├── add_role_overrides_for_manage_courses_add_spec.rb
│   │   │   │   └── add_role_overrides_for_manage_courses_delete_spec.rb
│   │   │   ├── localize_root_account_ids_on_attachment_spec.rb
│   │   │   ├── lti
│   │   │   │   ├── add_user_uuid_custom_variable_to_internal_tools_spec.rb
│   │   │   │   ├── backfill_context_external_tool_lti_registration_ids_spec.rb
│   │   │   │   ├── backfill_lti_overlays_from_ims_registrations_spec.rb
│   │   │   │   ├── backfill_lti_registration_account_bindings_spec.rb
│   │   │   │   └── update_custom_params_spec.rb
│   │   │   ├── move_feature_flags_to_settings_spec.rb
│   │   │   ├── move_sub_account_grading_periods_to_courses_spec.rb
│   │   │   ├── populate_identity_hash_on_context_external_tools_spec.rb
│   │   │   ├── populate_root_account_id_on_models_spec.rb
│   │   │   ├── populate_root_account_ids_on_communication_channels_spec.rb
│   │   │   ├── populate_root_account_ids_on_learning_outcomes_spec.rb
│   │   │   ├── populate_root_account_ids_on_users_spec.rb
│   │   │   ├── reassociate_grading_period_groups_spec.rb
│   │   │   ├── recalculate_section_override_dates_spec.rb
│   │   │   ├── reclaim_instfs_attachments_spec.rb
│   │   │   ├── remove_twitter_auth_providers_spec.rb
│   │   │   ├── replace_media_object_links_for_media_attachment_links_spec.rb
│   │   │   ├── resend_plagiarism_events_spec.rb
│   │   │   ├── reset_file_verifiers_spec.rb
│   │   │   ├── set_sizing_for_media_attachment_iframes_spec.rb
│   │   │   └── update_developer_key_scopes_spec.rb
│   │   ├── dates_overridable_spec.rb
│   │   ├── delayed_message_scrubber_spec.rb
│   │   ├── differentiable_assignment_spec.rb
│   │   ├── dump_helper_spec.rb
│   │   ├── duplicating_objects_spec.rb
│   │   ├── effective_due_dates_spec.rb
│   │   ├── email_address_validator_spec.rb
│   │   ├── enrollments_from_user_list_spec.rb
│   │   ├── ext
│   │   │   └── rubyzip_spec.rb
│   │   ├── extensions
│   │   │   └── active_record
│   │   │       └── enum_spec.rb
│   │   ├── external_feed_aggregator_spec.rb
│   │   ├── feature_flag_definitions_spec.rb
│   │   ├── feature_flags
│   │   │   ├── docviewer_iwork_predicate_spec.rb
│   │   │   └── usage_metrics_predicate_spec.rb
│   │   ├── feature_flags_spec.rb
│   │   ├── feature_spec.rb
│   │   ├── features
│   │   │   └── gradebook_export_configuration_spec.rb
│   │   ├── file_authenticator_spec.rb
│   │   ├── file_in_context_spec.rb
│   │   ├── grade_calculator_coffee_spec.rb
│   │   ├── grade_calculator_spec.rb
│   │   ├── gradebook
│   │   │   ├── apply_score_to_ungraded_submissions_spec.rb
│   │   │   └── final_grade_overrides_spec.rb
│   │   ├── gradebook_exporter_spec.rb
│   │   ├── gradebook_grading_period_assignments_spec.rb
│   │   ├── gradebook_importer_spec.rb
│   │   ├── gradebook_user_ids_spec.rb
│   │   ├── grading_period_helper_spec.rb
│   │   ├── ha_store_spec.rb
│   │   ├── health_checks_spec.rb
│   │   ├── host_url_spec.rb
│   │   ├── i18n_spec.rb
│   │   ├── i18n_time_zone_spec.rb
│   │   ├── inst_fs_spec.rb
│   │   ├── job_live_events_context_spec.rb
│   │   ├── late_policy_applicator_for_checkpoints_spec.rb
│   │   ├── late_policy_applicator_spec.rb
│   │   ├── latex
│   │   │   └── math_ml_spec.rb
│   │   ├── latex_spec.rb
│   │   ├── learn_platform
│   │   │   ├── api_spec.rb
│   │   │   └── global_api_spec.rb
│   │   ├── llm_configs_spec.rb
│   │   ├── local_cache_spec.rb
│   │   ├── locale_selection_spec.rb
│   │   ├── logging_filter_spec.rb
│   │   ├── lti
│   │   │   ├── api_service_helper_spec.rb
│   │   │   ├── app_util_spec.rb
│   │   │   ├── capabilities_helper_spec.rb
│   │   │   ├── content_item_converter_spec.rb
│   │   │   ├── content_item_response_spec.rb
│   │   │   ├── content_item_selection_request_spec.rb
│   │   │   ├── content_item_util_spec.rb
│   │   │   ├── context_tool_finder_spec.rb
│   │   │   ├── deep_linking_data_spec.rb
│   │   │   ├── deep_linking_util_spec.rb
│   │   │   ├── errors
│   │   │   │   └── error_logger_spec.rb
│   │   │   ├── external_tool_name_bookmarker_spec.rb
│   │   │   ├── external_tool_tab_spec.rb
│   │   │   ├── helpers
│   │   │   │   └── jwt_message_helper_spec.rb
│   │   │   ├── ims
│   │   │   │   ├── advantage_access_token_request_helper_spec.rb
│   │   │   │   ├── advantage_access_token_shared_context.rb
│   │   │   │   ├── advantage_access_token_spec.rb
│   │   │   │   └── advantage_errors_spec.rb
│   │   │   ├── logging_spec.rb
│   │   │   ├── membership_service
│   │   │   │   ├── course_group_collator_spec.rb
│   │   │   │   ├── course_lis_person_collator_spec.rb
│   │   │   │   ├── group_lis_person_collator_spec.rb
│   │   │   │   ├── membership_collator_factory_spec.rb
│   │   │   │   └── page_presenter_spec.rb
│   │   │   ├── message_authenticator_spec.rb
│   │   │   ├── message_handler_name_bookmarker_spec.rb
│   │   │   ├── messages
│   │   │   │   ├── asset_processor_settings_request_spec.rb
│   │   │   │   ├── deep_linking_request_spec.rb
│   │   │   │   ├── eula_request_spec.rb
│   │   │   │   ├── jwt_message_spec.rb
│   │   │   │   ├── lti_advantage_shared_examples.rb
│   │   │   │   ├── pns_notice_spec.rb
│   │   │   │   ├── report_review_request_spec.rb
│   │   │   │   └── resource_link_request_spec.rb
│   │   │   ├── name_bookmarker_base_shared_examples.rb
│   │   │   ├── oauth2
│   │   │   │   ├── access_token_spec.rb
│   │   │   │   └── authorization_validator_spec.rb
│   │   │   ├── permission_checker_spec.rb
│   │   │   ├── plagiarism_subscriptions_helper_spec.rb
│   │   │   ├── platform_storage_spec.rb
│   │   │   ├── privacy_level_expander_spec.rb
│   │   │   ├── re_reg_constraint_spec.rb
│   │   │   ├── redis_message_client_spec.rb
│   │   │   ├── scope_union_spec.rb
│   │   │   ├── security_spec.rb
│   │   │   ├── substitutions_helper_spec.rb
│   │   │   ├── tool_proxy_name_bookmarker_spec.rb
│   │   │   ├── tool_proxy_validator_spec.rb
│   │   │   ├── v1p1
│   │   │   │   └── asset_spec.rb
│   │   │   ├── variable_expander_spec.rb
│   │   │   └── variable_expansion_spec.rb
│   │   ├── material_changes_spec.rb
│   │   ├── math_man_spec.rb
│   │   ├── memory_limit_spec.rb
│   │   ├── message_dispatcher_spec.rb
│   │   ├── messageable_user
│   │   │   └── calculator_spec.rb
│   │   ├── messageable_user_spec.rb
│   │   ├── microsoft_sync
│   │   │   ├── canvas_models_helpers_spec.rb
│   │   │   ├── debug_info_tracker_spec.rb
│   │   │   ├── errors_spec.rb
│   │   │   ├── graph_service
│   │   │   │   ├── education_classes_endpoints_spec.rb
│   │   │   │   ├── group_membership_change_result_spec.rb
│   │   │   │   ├── groups_endpoints_spec.rb
│   │   │   │   ├── http_spec.rb
│   │   │   │   ├── special_case_spec.rb
│   │   │   │   ├── teams_endpoints_spec.rb
│   │   │   │   └── users_endpoints_spec.rb
│   │   │   ├── graph_service_helpers_spec.rb
│   │   │   ├── graph_service_spec.rb
│   │   │   ├── login_service_spec.rb
│   │   │   ├── membership_diff_spec.rb
│   │   │   ├── partial_membership_diff_spec.rb
│   │   │   ├── state_machine_job_spec.rb
│   │   │   ├── syncer_steps_spec.rb
│   │   │   └── users_uluvs_finder_spec.rb
│   │   ├── missing_policy_applicator_spec.rb
│   │   ├── model_cache_spec.rb
│   │   ├── moderation_spec.rb
│   │   ├── must_view_module_progressor_spec.rb
│   │   ├── mutable_spec.rb
│   │   ├── notification_message_creator_spec.rb
│   │   ├── outcomes
│   │   │   ├── csv_importer_spec.rb
│   │   │   ├── fixtures
│   │   │   │   ├── chn.csv
│   │   │   │   ├── demo.csv
│   │   │   │   ├── no-ratings.csv
│   │   │   │   ├── nor-excel.csv
│   │   │   │   ├── nor.csv
│   │   │   │   └── scoring.csv
│   │   │   ├── import_spec.rb
│   │   │   ├── learning_outcome_group_children_spec.rb
│   │   │   └── result_analytics_spec.rb
│   │   ├── package_root_spec.rb
│   │   ├── pandata_events
│   │   │   └── credential_service_spec.rb
│   │   ├── pandata_events_spec.rb
│   │   ├── permissions_helper_spec.rb
│   │   ├── permissions_spec.rb
│   │   ├── plannable_spec.rb
│   │   ├── planner_api_helper_spec.rb
│   │   ├── planner_helper_spec.rb
│   │   ├── postgresql_adapter_spec.rb
│   │   ├── progress_runner_spec.rb
│   │   ├── rake
│   │   │   └── task_graph_spec.rb
│   │   ├── reporting
│   │   │   └── counts_report_spec.rb
│   │   ├── safe_yaml_spec.rb
│   │   ├── samesite_transition_cookie_store_spec.rb
│   │   ├── schemas
│   │   │   ├── base_spec.rb
│   │   │   ├── internal_lti_configuration_spec.rb
│   │   │   ├── lti
│   │   │   │   ├── ims
│   │   │   │   │   ├── lti_tool_configuration_spec.rb
│   │   │   │   │   ├── oidc_registration_spec.rb
│   │   │   │   │   └── registration_overlay_spec.rb
│   │   │   │   ├── overlay_spec.rb
│   │   │   │   └── public_jwk_spec.rb
│   │   │   └── lti_configuration_spec.rb
│   │   ├── scope_filter_spec.rb
│   │   ├── score_statistics_generator_spec.rb
│   │   ├── search_term_helper_spec.rb
│   │   ├── security_spec.rb
│   │   ├── sentry_extensions
│   │   │   ├── settings_spec.rb
│   │   │   └── tracing
│   │   │       └── active_record_subscriber_spec.rb
│   │   ├── sentry_proxy_spec.rb
│   │   ├── services
│   │   │   ├── feature_analytics_service_spec.rb
│   │   │   ├── live_events_subscription_service_spec.rb
│   │   │   ├── notification_service_spec.rb
│   │   │   ├── rich_content_spec.rb
│   │   │   ├── screencap_service_spec.rb
│   │   │   └── submit_homework_service_spec.rb
│   │   ├── session_token_spec.rb
│   │   ├── sis
│   │   │   ├── course_importer_spec.rb
│   │   │   ├── csv
│   │   │   │   ├── abstract_course_importer_spec.rb
│   │   │   │   ├── account_importer_spec.rb
│   │   │   │   ├── admin_importer_spec.rb
│   │   │   │   ├── base_importer_spec.rb
│   │   │   │   ├── change_sis_id_importer_spec.rb
│   │   │   │   ├── course_importer_spec.rb
│   │   │   │   ├── diff_generator_spec.rb
│   │   │   │   ├── enrollment_importer_spec.rb
│   │   │   │   ├── grade_publishing_results_importer_spec.rb
│   │   │   │   ├── group_category_importer_spec.rb
│   │   │   │   ├── group_importer_spec.rb
│   │   │   │   ├── group_membership_importer_spec.rb
│   │   │   │   ├── import_refactored_spec.rb
│   │   │   │   ├── login_importer_spec.rb
│   │   │   │   ├── section_importer_spec.rb
│   │   │   │   ├── term_importer_spec.rb
│   │   │   │   ├── user_importer_spec.rb
│   │   │   │   ├── user_observer_importer_spec.rb
│   │   │   │   └── xlist_importer_spec.rb
│   │   │   ├── enrollment_importer_spec.rb
│   │   │   ├── group_membership_importer_spec.rb
│   │   │   ├── models
│   │   │   │   └── enrollment_spec.rb
│   │   │   └── user_importer_spec.rb
│   │   ├── smart_search_spec.rb
│   │   ├── smart_searchable_spec.rb
│   │   ├── sort_spec.rb
│   │   ├── sorts_assignments_spec.rb
│   │   ├── spec_helper_spec.rb
│   │   ├── ssl_common_spec.rb
│   │   ├── stats_spec.rb
│   │   ├── sticky_sis_fields_spec.rb
│   │   ├── submission_lifecycle_manager_spec.rb
│   │   ├── submission_list_spec.rb
│   │   ├── submission_search_spec.rb
│   │   ├── submittable_spec.rb
│   │   ├── summary_message_consolidator_spec.rb
│   │   ├── support_helpers
│   │   │   ├── crocodoc_spec.rb
│   │   │   ├── fixer_spec.rb
│   │   │   ├── submission_lifecycle_manage_spec.rb
│   │   │   └── tii_spec.rb
│   │   ├── text_helper_spec.rb
│   │   ├── timed_cache_spec.rb
│   │   ├── token_scopes
│   │   │   ├── last_known_accepted_scopes.rb
│   │   │   ├── last_known_scopes.yml
│   │   │   └── spec_helper.rb
│   │   ├── token_scopes_spec.rb
│   │   ├── translation_spec.rb
│   │   ├── turnitin
│   │   │   ├── attachment_manager_spec.rb
│   │   │   ├── outcome_response_processor_spec.rb
│   │   │   ├── tii_client_spec.rb
│   │   │   └── turnitin_spec_helper.rb
│   │   ├── turnitin_spec.rb
│   │   ├── unzip_attachment_spec.rb
│   │   ├── user_content
│   │   │   └── files_handler_spec.rb
│   │   ├── user_content_spec.rb
│   │   ├── user_list_spec.rb
│   │   ├── user_list_v2_spec.rb
│   │   ├── user_merge_spec.rb
│   │   ├── user_search_spec.rb
│   │   ├── utils
│   │   │   ├── date_presenter_spec.rb
│   │   │   ├── datetime_range_presenter_spec.rb
│   │   │   ├── hash_utils_spec.rb
│   │   │   ├── relative_date_spec.rb
│   │   │   └── time_presenter_spec.rb
│   │   ├── uuid_helper_spec.rb
│   │   ├── validates_as_url.rb
│   │   └── yaml_spec.rb
│   ├── lti2_course_spec_helper.rb
│   ├── lti2_spec_helper.rb
│   ├── lti_1_3_tool_configuration_spec_helper.rb
│   ├── lti_spec_helper.rb
│   ├── manual_seeding
│   │   └── large_gradebook_seeds.rb
│   ├── messages
│   │   ├── account_notification.erb_spec.rb
│   │   ├── account_user_notification.erb_spec.rb
│   │   ├── account_user_registration.erb_spec.rb
│   │   ├── added_to_conversation.erb_spec.rb
│   │   ├── alert.erb_spec.rb
│   │   ├── annotation_notification.erb_spec.rb
│   │   ├── announcement_reply.erb_spec.rb
│   │   ├── appointment_canceled_by_user.email.erb_spec.rb
│   │   ├── appointment_canceled_by_user.sms.erb_spec.rb
│   │   ├── appointment_deleted_for_user.email.erb_spec.rb
│   │   ├── appointment_deleted_for_user.sms.erb_spec.rb
│   │   ├── appointment_group_deleted.erb_spec.rb
│   │   ├── appointment_group_published.erb_spec.rb
│   │   ├── appointment_group_updated.erb_spec.rb
│   │   ├── appointment_reserved_by_user.erb_spec.rb
│   │   ├── appointment_reserved_for_user.erb_spec.rb
│   │   ├── assignment_changed.erb_spec.rb
│   │   ├── assignment_created.erb_spec.rb
│   │   ├── assignment_due_date_changed.erb_spec.rb
│   │   ├── assignment_due_date_override_changed.erb_spec.rb
│   │   ├── assignment_graded.erb_spec.rb
│   │   ├── assignment_resubmitted.erb_spec.rb
│   │   ├── assignment_submitted.erb_spec.rb
│   │   ├── blueprint_content_added.erb_spec.rb
│   │   ├── blueprint_sync_complete.erb_spec.rb
│   │   ├── checkpoints_created.erb_spec.rb
│   │   ├── collaboration_invitation.erb_spec.rb
│   │   ├── confirm_email_communication_channel.erb_spec.rb
│   │   ├── confirm_registration.erb_spec.rb
│   │   ├── confirm_sms_communication_channel.sms.erb_spec.rb
│   │   ├── content_export_failed.erb_spec.rb
│   │   ├── content_export_finished.erb_spec.rb
│   │   ├── content_link_error.erb_spec.rb
│   │   ├── conversation_created.erb_spec.rb
│   │   ├── conversation_message.erb_spec.rb
│   │   ├── discussion_mention.erb_spec.rb
│   │   ├── enrollment_accepted.erb_spec.rb
│   │   ├── enrollment_invitation.erb_spec.rb
│   │   ├── enrollment_notification.erb_spec.rb
│   │   ├── enrollment_registration.erb_spec.rb
│   │   ├── event_date_changed.erb_spec.rb
│   │   ├── forgot_password.erb_spec.rb
│   │   ├── grade_weight_changed.erb_spec.rb
│   │   ├── group_assignment_submitted_late.erb_spec.rb
│   │   ├── group_membership_accepted.erb_spec.rb
│   │   ├── group_membership_rejected.erb_spec.rb
│   │   ├── manually_created_access_token_created.erb_spec.rb
│   │   ├── merge_email_communication_channel.erb_spec.rb
│   │   ├── messages_helper.rb
│   │   ├── new_account_user.erb_spec.rb
│   │   ├── new_announcement.erb_spec.rb
│   │   ├── new_context_group_membership.erb_spec.rb
│   │   ├── new_context_group_membership_invitation.erb_spec.rb
│   │   ├── new_course.erb_spec.rb
│   │   ├── new_discussion_entry.erb_spec.rb
│   │   ├── new_discussion_topic.erb_spec.rb
│   │   ├── new_event_created.erb_spec.rb
│   │   ├── new_file_added.erb_spec.rb
│   │   ├── new_files_added.erb_spec.rb
│   │   ├── new_student_organized_group.erb_spec.rb
│   │   ├── new_user.erb_spec.rb
│   │   ├── peer_review_invitation.erb_spec.rb
│   │   ├── pseudonym_registration.erb_spec.rb
│   │   ├── pseudonym_registration_done.erb_spec.rb
│   │   ├── report_generated.erb_spec.rb
│   │   ├── report_generation_failed.erb_spec.rb
│   │   ├── reported_entry.erb_spec.rb
│   │   ├── rubric_assessment_submission_reminder.erb_spec.rb
│   │   ├── rubric_association_created.erb_spec.rb
│   │   ├── submission_comment.erb_spec.rb
│   │   ├── submission_grade_changed.erb_spec.rb
│   │   ├── submission_graded.erb_spec.rb
│   │   ├── submission_posted.erb_spec.rb
│   │   ├── submissions_posted.erb_spec.rb
│   │   ├── summaries.erb_spec.rb
│   │   ├── upcoming_assignment_alert.erb_spec.rb
│   │   ├── updated_wiki_page.erb_spec.rb
│   │   └── web_conference_invitation.erb_spec.rb
│   ├── migrations
│   │   ├── add_role_overrides_for_new_permission_spec.rb
│   │   ├── data_fixup
│   │   │   └── add_role_overrides_for_permission_combination_spec.rb
│   │   ├── foreign_keys_spec.rb
│   │   └── read_only_role_spec.rb
│   ├── models
│   │   ├── access_token_spec.rb
│   │   ├── accessibility
│   │   │   └── rules
│   │   │       ├── adjacent_links_rule_spec.rb
│   │   │       ├── headings_sequence_rule_spec.rb
│   │   │       ├── headings_start_at_h2_rule_spec.rb
│   │   │       ├── img_alt_filename_rule_spec.rb
│   │   │       ├── img_alt_length_rule_spec.rb
│   │   │       ├── img_alt_rule_spec.rb
│   │   │       ├── large_text_contrast_rule_spec.rb
│   │   │       ├── list_structure_rule_spec.rb
│   │   │       ├── paragraphs_for_headings_rule_spec.rb
│   │   │       ├── rule_test_helper.rb
│   │   │       ├── small_text_contrast_rule_spec.rb
│   │   │       ├── table_caption_rule_spec.rb
│   │   │       ├── table_header_rule_spec.rb
│   │   │       └── table_header_scope_rule_spec.rb
│   │   ├── account
│   │   │   └── help_links_spec.rb
│   │   ├── account_notification_spec.rb
│   │   ├── account_report_runner_spec.rb
│   │   ├── account_report_spec.rb
│   │   ├── account_spec.rb
│   │   ├── account_user_spec.rb
│   │   ├── active_record_base_spec.rb
│   │   ├── alert_spec.rb
│   │   ├── alerts
│   │   │   ├── delayed_alert_sender_spec.rb
│   │   │   ├── interaction_spec.rb
│   │   │   ├── ungraded_count_spec.rb
│   │   │   └── ungraded_timespan_spec.rb
│   │   ├── announcement_spec.rb
│   │   ├── anonymous_or_moderation_event_spec.rb
│   │   ├── appointment_group_spec.rb
│   │   ├── assessment_question_bank_spec.rb
│   │   ├── assessment_question_spec.rb
│   │   ├── assessment_request_spec.rb
│   │   ├── asset_user_access_log_spec.rb
│   │   ├── asset_user_access_spec.rb
│   │   ├── assignment
│   │   │   ├── grade_error_spec.rb
│   │   │   └── max_graders_reached_error_spec.rb
│   │   ├── assignment_configuration_tool_lookup_spec.rb
│   │   ├── assignment_group_spec.rb
│   │   ├── assignment_instance_methods_spec.rb
│   │   ├── assignment_override_spec.rb
│   │   ├── assignment_override_student_spec.rb
│   │   ├── assignment_spec.rb
│   │   ├── assignments
│   │   │   ├── needs_grading_count_query_spec.rb
│   │   │   └── scoped_to_user_spec.rb
│   │   ├── attachment_association_spec.rb
│   │   ├── attachment_spec.rb
│   │   ├── attachment_upload_status_spec.rb
│   │   ├── attachments
│   │   │   ├── garbage_collector_spec.rb
│   │   │   ├── s3_storage_spec.rb
│   │   │   ├── storage_spec.rb
│   │   │   └── verification_spec.rb
│   │   ├── auditors
│   │   │   ├── active_record
│   │   │   │   ├── attributes_spec.rb
│   │   │   │   ├── authentication_record_spec.rb
│   │   │   │   ├── course_record_spec.rb
│   │   │   │   ├── feature_flag_record_spec.rb
│   │   │   │   ├── grade_change_record_spec.rb
│   │   │   │   ├── partitioner_spec.rb
│   │   │   │   └── pseudonym_record_spec.rb
│   │   │   ├── authentication_spec.rb
│   │   │   ├── course_spec.rb
│   │   │   ├── feature_flag_spec.rb
│   │   │   ├── grade_change_spec.rb
│   │   │   └── pseudonym_spec.rb
│   │   ├── auditors_spec.rb
│   │   ├── authentication_provider
│   │   │   ├── apple_spec.rb
│   │   │   ├── facebook_spec.rb
│   │   │   ├── google_spec.rb
│   │   │   ├── ldap_spec.rb
│   │   │   ├── microsoft_spec.rb
│   │   │   ├── open_id_connect
│   │   │   │   ├── discovery_refresher_spec.rb
│   │   │   │   └── jwks_refresher_spec.rb
│   │   │   ├── open_id_connect_spec.rb
│   │   │   ├── plugin_settings_spec.rb
│   │   │   ├── saml
│   │   │   │   ├── in_common_spec.rb
│   │   │   │   └── metadata_refresher_spec.rb
│   │   │   └── saml_spec.rb
│   │   ├── authentication_provider_spec.rb
│   │   ├── auto_grade_result_spec.rb
│   │   ├── big_blue_button_conference_spec.rb
│   │   ├── blackout_date_spec.rb
│   │   ├── block_editor_template_spec.rb
│   │   ├── bookmark_service_spec.rb
│   │   ├── bounce_notification_processor_spec.rb
│   │   ├── brand_config_spec.rb
│   │   ├── broadcast_policies
│   │   │   ├── assignment_participants_spec.rb
│   │   │   ├── assignment_policy_spec.rb
│   │   │   ├── quiz_submission_policy_spec.rb
│   │   │   ├── submission_policy_spec.rb
│   │   │   └── wiki_page_policy_spec.rb
│   │   ├── calendar_event_spec.rb
│   │   ├── canvadoc_spec.rb
│   │   ├── canvadocs_annotation_context_spec.rb
│   │   ├── canvas_metadatum_spec.rb
│   │   ├── collaboration_spec.rb
│   │   ├── collaborator_spec.rb
│   │   ├── comment_bank_item_spec.rb
│   │   ├── communication_channel_spec.rb
│   │   ├── conditional_release
│   │   │   ├── assignment_set_action_spec.rb
│   │   │   ├── assignment_set_association_spec.rb
│   │   │   ├── assignment_set_spec.rb
│   │   │   ├── bounds_validations_spec.rb
│   │   │   ├── conditional_release_service_spec.rb
│   │   │   ├── override_handler_spec.rb
│   │   │   ├── rule_spec.rb
│   │   │   ├── scoring_range_spec.rb
│   │   │   └── stats_spec.rb
│   │   ├── content_export_spec.rb
│   │   ├── content_migration
│   │   │   ├── course_copy_assignments_spec.rb
│   │   │   ├── course_copy_attachments_spec.rb
│   │   │   ├── course_copy_blueprint_settings_spec.rb
│   │   │   ├── course_copy_conditional_release_spec.rb
│   │   │   ├── course_copy_cross_shard_spec.rb
│   │   │   ├── course_copy_dates_spec.rb
│   │   │   ├── course_copy_discussions_spec.rb
│   │   │   ├── course_copy_external_content_spec.rb
│   │   │   ├── course_copy_external_tools_spec.rb
│   │   │   ├── course_copy_helper.rb
│   │   │   ├── course_copy_item_notification_spec.rb
│   │   │   ├── course_copy_outcomes_spec.rb
│   │   │   ├── course_copy_pace_plans_spec.rb
│   │   │   ├── course_copy_quizzes_spec.rb
│   │   │   ├── course_copy_spec.rb
│   │   │   ├── course_copy_unpublished_items_spec.rb
│   │   │   ├── course_copy_wiki_spec.rb
│   │   │   └── cross_institution_migration_spec.rb
│   │   ├── content_migration_spec.rb
│   │   ├── content_participation_count_spec.rb
│   │   ├── content_participation_spec.rb
│   │   ├── content_share_spec.rb
│   │   ├── content_tag_spec.rb
│   │   ├── context_external_tool_spec.rb
│   │   ├── context_module_progression_spec.rb
│   │   ├── context_module_spec.rb
│   │   ├── context_spec.rb
│   │   ├── conversation_batch_spec.rb
│   │   ├── conversation_message_participant_spec.rb
│   │   ├── conversation_message_spec.rb
│   │   ├── conversation_participant_spec.rb
│   │   ├── conversation_spec.rb
│   │   ├── course_account_association_spec.rb
│   │   ├── course_date_range_spec.rb
│   │   ├── course_pace_module_item_spec.rb
│   │   ├── course_pace_spec.rb
│   │   ├── course_progress_spec.rb
│   │   ├── course_report_spec.rb
│   │   ├── course_score_statistic_spec.rb
│   │   ├── course_section_spec.rb
│   │   ├── course_spec.rb
│   │   ├── courses
│   │   │   ├── teacher_student_mapper_spec.rb
│   │   │   └── timetable_event_builder_spec.rb
│   │   ├── crocodoc_document_spec.rb
│   │   ├── csp
│   │   │   └── domain_spec.rb
│   │   ├── csp_spec.rb
│   │   ├── custom_data_spec.rb
│   │   ├── custom_grade_status_spec.rb
│   │   ├── custom_gradebook_column_datum_spec.rb
│   │   ├── custom_gradebook_column_spec.rb
│   │   ├── delayed_message_spec.rb
│   │   ├── delayed_notification_spec.rb
│   │   ├── developer_key_account_binding_spec.rb
│   │   ├── developer_key_spec.rb
│   │   ├── developer_keys
│   │   │   └── access_verifier_spec.rb
│   │   ├── discussion_entry_participant_spec.rb
│   │   ├── discussion_entry_spec.rb
│   │   ├── discussion_topic
│   │   │   ├── materialized_view_spec.rb
│   │   │   ├── prompt_presenter_spec.rb
│   │   │   └── scoped_to_sections_spec.rb
│   │   ├── discussion_topic_insight
│   │   │   └── entry_spec.rb
│   │   ├── discussion_topic_insight_spec.rb
│   │   ├── discussion_topic_participant_spec.rb
│   │   ├── discussion_topic_section_visibility_spec.rb
│   │   ├── discussion_topic_spec.rb
│   │   ├── discussion_topic_summary
│   │   │   └── feedback_spec.rb
│   │   ├── discussion_topic_summary_spec.rb
│   │   ├── enrollment
│   │   │   ├── batch_state_updater_spec.rb
│   │   │   ├── query_builder_spec.rb
│   │   │   └── recent_activity_spec.rb
│   │   ├── enrollment_spec.rb
│   │   ├── enrollment_state_spec.rb
│   │   ├── enrollment_term_spec.rb
│   │   ├── eportfolio_category_spec.rb
│   │   ├── eportfolio_entry_spec.rb
│   │   ├── eportfolio_spec.rb
│   │   ├── epub_export_spec.rb
│   │   ├── epub_exports
│   │   │   ├── course_epub_exports_presenter_spec.rb
│   │   │   └── create_service_spec.rb
│   │   ├── error_report_spec.rb
│   │   ├── estimated_duration_spec.rb
│   │   ├── exporters
│   │   │   ├── quizzes2_exporter_spec.rb
│   │   │   ├── user_data_exporter_spec.rb
│   │   │   └── zip_exporter_spec.rb
│   │   ├── external_feed_spec.rb
│   │   ├── external_integration_key_spec.rb
│   │   ├── external_tool_collaboration_spec.rb
│   │   ├── favorite_spec.rb
│   │   ├── feature_flag_spec.rb
│   │   ├── folder_spec.rb
│   │   ├── google_docs_collaboration_spec.rb
│   │   ├── gradebook_csv_spec.rb
│   │   ├── gradebook_filter_spec.rb
│   │   ├── gradebook_upload_spec.rb
│   │   ├── grading_period_group_spec.rb
│   │   ├── grading_period_permissions_spec.rb
│   │   ├── grading_period_spec.rb
│   │   ├── grading_standard_spec.rb
│   │   ├── group_and_membership_importer_spec.rb
│   │   ├── group_categories
│   │   │   ├── params_policy_spec.rb
│   │   │   └── params_spec.rb
│   │   ├── group_category_spec.rb
│   │   ├── group_leadership_spec.rb
│   │   ├── group_membership_spec.rb
│   │   ├── group_spec.rb
│   │   ├── ignore_spec.rb
│   │   ├── importers
│   │   │   ├── assessment_question_importer_spec.rb
│   │   │   ├── assignment_group_importer_spec.rb
│   │   │   ├── assignment_importer_spec.rb
│   │   │   ├── attachment_importer_spec.rb
│   │   │   ├── calendar_event_importer_spec.rb
│   │   │   ├── context_external_tool_importer_spec.rb
│   │   │   ├── context_module_importer_spec.rb
│   │   │   ├── course_content_importer_spec.rb
│   │   │   ├── discussion_topic_importer_spec.rb
│   │   │   ├── external_feed_importer_spec.rb
│   │   │   ├── group_importer_spec.rb
│   │   │   ├── learning_outcome_group_importer_spec.rb
│   │   │   ├── learning_outcomes_importer_spec.rb
│   │   │   ├── lti_resource_link_importer_spec.rb
│   │   │   ├── media_track_importers_spec.rb
│   │   │   ├── quiz_importer_spec.rb
│   │   │   ├── rubric_importer_spec.rb
│   │   │   ├── tool_profile_importer_spec.rb
│   │   │   └── wiki_page_importer_spec.rb
│   │   ├── importers_spec.rb
│   │   ├── incoming_mail
│   │   │   ├── message_handler_spec.rb
│   │   │   └── reply_to_address_spec.rb
│   │   ├── kaltura_media_file_handler_spec.rb
│   │   ├── late_policy_spec.rb
│   │   ├── learning_outcome_group_spec.rb
│   │   ├── learning_outcome_result_spec.rb
│   │   ├── learning_outcome_spec.rb
│   │   ├── live_assessments
│   │   │   ├── assessment_spec.rb
│   │   │   └── submission_spec.rb
│   │   ├── llm_config_spec.rb
│   │   ├── lti
│   │   │   ├── app_collator_spec.rb
│   │   │   ├── app_launch_collator_spec.rb
│   │   │   ├── asset_processor_eula_acceptance_spec.rb
│   │   │   ├── asset_processor_spec.rb
│   │   │   ├── asset_report_spec.rb
│   │   │   ├── asset_spec.rb
│   │   │   ├── content_migration_service
│   │   │   │   ├── exporter_spec.rb
│   │   │   │   └── importer_spec.rb
│   │   │   ├── content_migration_service_spec.rb
│   │   │   ├── context_control_spec.rb
│   │   │   ├── ims
│   │   │   │   └── registration_spec.rb
│   │   │   ├── launch_spec.rb
│   │   │   ├── line_item_spec.rb
│   │   │   ├── link_spec.rb
│   │   │   ├── lti_account_creator_spec.rb
│   │   │   ├── lti_advantage_adapter_spec.rb
│   │   │   ├── lti_assignment_creator_spec.rb
│   │   │   ├── lti_context_creator_spec.rb
│   │   │   ├── lti_integration_spec.rb
│   │   │   ├── lti_outbound_adapter_spec.rb
│   │   │   ├── lti_tool_creator_spec.rb
│   │   │   ├── lti_user_creator_spec.rb
│   │   │   ├── message_handler_spec.rb
│   │   │   ├── navigation_cache_spec.rb
│   │   │   ├── notice_handler_spec.rb
│   │   │   ├── overlay_spec.rb
│   │   │   ├── pns
│   │   │   │   ├── lti_asset_processor_submission_notice_builder_spec.rb
│   │   │   │   ├── lti_context_copy_notice_builder_spec.rb
│   │   │   │   └── notice_builder_spec.rb
│   │   │   ├── product_family_spec.rb
│   │   │   ├── registration_account_binding_spec.rb
│   │   │   ├── registration_request_service_spec.rb
│   │   │   ├── registration_spec.rb
│   │   │   ├── resource_handler_spec.rb
│   │   │   ├── resource_link_spec.rb
│   │   │   ├── resource_placement_spec.rb
│   │   │   ├── result_spec.rb
│   │   │   ├── tool_configuration_spec.rb
│   │   │   ├── tool_consumer_profile_creator_spec.rb
│   │   │   ├── tool_consumer_profile_spec.rb
│   │   │   ├── tool_proxy_binding_spec.rb
│   │   │   ├── tool_proxy_service_spec.rb
│   │   │   ├── tool_proxy_spec.rb
│   │   │   └── tool_setting_spec.rb
│   │   ├── lti_conference_spec.rb
│   │   ├── mailer_spec.rb
│   │   ├── master_courses
│   │   │   ├── child_subscription_spec.rb
│   │   │   ├── collection_restrictor_spec.rb
│   │   │   ├── folder_helper_spec.rb
│   │   │   ├── master_content_tag_spec.rb
│   │   │   ├── master_migration_spec.rb
│   │   │   ├── master_template_spec.rb
│   │   │   └── restrictor_spec.rb
│   │   ├── media_object_spec.rb
│   │   ├── media_source_fetcher_spec.rb
│   │   ├── media_track_spec.rb
│   │   ├── mention_spec.rb
│   │   ├── message_spec.rb
│   │   ├── messages
│   │   │   ├── assignment_resubmitted
│   │   │   │   ├── email_presenter_spec.rb
│   │   │   │   ├── sms_presenter_spec.rb
│   │   │   │   └── summary_presenter_spec.rb
│   │   │   ├── assignment_submitted
│   │   │   │   ├── email_presenter_spec.rb
│   │   │   │   ├── sms_presenter_spec.rb
│   │   │   │   └── summary_presenter_spec.rb
│   │   │   ├── assignment_submitted_late
│   │   │   │   ├── email_presenter_spec.rb
│   │   │   │   ├── sms_presenter_spec.rb
│   │   │   │   └── summary_presenter_spec.rb
│   │   │   ├── name_helper_spec.rb
│   │   │   └── submission_comment_for_teacher
│   │   │       ├── annotation_presenter_spec.rb
│   │   │       ├── email_presenter_spec.rb
│   │   │       ├── message_spec.rb
│   │   │       ├── sms_presenter_spec.rb
│   │   │       └── summary_presenter_spec.rb
│   │   ├── microsoft_sync
│   │   │   ├── group_spec.rb
│   │   │   ├── partial_sync_change_spec.rb
│   │   │   └── user_mapping_spec.rb
│   │   ├── moderated_grading
│   │   │   ├── null_provisional_grade_spec.rb
│   │   │   ├── provisional_grade_spec.rb
│   │   │   └── selection_spec.rb
│   │   ├── moderation_grader_spec.rb
│   │   ├── notification_endpoint_spec.rb
│   │   ├── notification_failure_processor_spec.rb
│   │   ├── notification_finder_spec.rb
│   │   ├── notification_policy_override_spec.rb
│   │   ├── notification_policy_spec.rb
│   │   ├── notification_spec.rb
│   │   ├── notifier_spec.rb
│   │   ├── observer_alert_spec.rb
│   │   ├── observer_alert_threshold_spec.rb
│   │   ├── observer_enrollment_spec.rb
│   │   ├── observer_pairing_code_spec.rb
│   │   ├── one_time_password_spec.rb
│   │   ├── originality_report_spec.rb
│   │   ├── outcome_calculation_method_spec.rb
│   │   ├── outcome_friendly_description_spec.rb
│   │   ├── outcome_import_error_spec.rb
│   │   ├── outcome_import_spec.rb
│   │   ├── outcome_proficiency_rating_spec.rb
│   │   ├── outcome_proficiency_spec.rb
│   │   ├── outcomes_service
│   │   │   ├── migration_extractor_spec.rb
│   │   │   ├── migration_service_spec.rb
│   │   │   └── service_spec.rb
│   │   ├── page_view
│   │   │   ├── csv_report_spec.rb
│   │   │   └── pv4_client_spec.rb
│   │   ├── page_view_spec.rb
│   │   ├── planner_note_spec.rb
│   │   ├── planner_override_spec.rb
│   │   ├── plugin_setting_spec.rb
│   │   ├── polling
│   │   │   ├── poll_choice_spec.rb
│   │   │   ├── poll_session_spec.rb
│   │   │   ├── poll_spec.rb
│   │   │   └── poll_submission_spec.rb
│   │   ├── post_policy_spec.rb
│   │   ├── profile_spec.rb
│   │   ├── progress_spec.rb
│   │   ├── pseudonym_session_spec.rb
│   │   ├── pseudonym_spec.rb
│   │   ├── quiz_migration_alert_spec.rb
│   │   ├── quizzes
│   │   │   ├── log_auditing
│   │   │   │   ├── event_aggregator_spec.rb
│   │   │   │   ├── question_answered_event_extractor_spec.rb
│   │   │   │   └── question_answered_event_optimizer_spec.rb
│   │   │   ├── outstanding_quiz_submission_manager_spec.rb
│   │   │   ├── quiz_eligibility_spec.rb
│   │   │   ├── quiz_extension_spec.rb
│   │   │   ├── quiz_group_spec.rb
│   │   │   ├── quiz_outcome_result_builder_spec.rb
│   │   │   ├── quiz_question
│   │   │   │   ├── answer_group_spec.rb
│   │   │   │   ├── answer_parsers
│   │   │   │   │   ├── answer_parser_spec.rb
│   │   │   │   │   ├── answer_parser_spec_helper.rb
│   │   │   │   │   ├── calculated_spec.rb
│   │   │   │   │   ├── essay_spec.rb
│   │   │   │   │   ├── fill_in_multiple_blanks_spec.rb
│   │   │   │   │   ├── matching_spec.rb
│   │   │   │   │   ├── missing_word_spec.rb
│   │   │   │   │   ├── multiple_answers_spec.rb
│   │   │   │   │   ├── multiple_choice_spec.rb
│   │   │   │   │   ├── multiple_dropdowns_spec.rb
│   │   │   │   │   ├── numerical_spec.rb
│   │   │   │   │   ├── short_answer_spec.rb
│   │   │   │   │   └── true_false_spec.rb
│   │   │   │   ├── answer_serializers
│   │   │   │   │   ├── answer_serializer_spec.rb
│   │   │   │   │   ├── essay_spec.rb
│   │   │   │   │   ├── fill_in_multiple_blanks_spec.rb
│   │   │   │   │   ├── matching_spec.rb
│   │   │   │   │   ├── multiple_answers_spec.rb
│   │   │   │   │   ├── multiple_choice_spec.rb
│   │   │   │   │   ├── multiple_dropdowns_spec.rb
│   │   │   │   │   ├── numerical_spec.rb
│   │   │   │   │   ├── short_answer_spec.rb
│   │   │   │   │   └── support
│   │   │   │   │       ├── answer_serializers_specs.rb
│   │   │   │   │       ├── id_answer_serializers_specs.rb
│   │   │   │   │       └── textual_answer_serializers_specs.rb
│   │   │   │   ├── calculated_question_spec.rb
│   │   │   │   ├── essay_question_spec.rb
│   │   │   │   ├── file_upload_answer_spec.rb
│   │   │   │   ├── file_upload_question_spec.rb
│   │   │   │   ├── fill_in_multiple_blanks_question_spec.rb
│   │   │   │   ├── match_group_spec.rb
│   │   │   │   ├── matching_question_spec.rb
│   │   │   │   ├── multiple_answers_question_spec.rb
│   │   │   │   ├── multiple_choice_question_spec.rb
│   │   │   │   ├── multiple_dropdowns_question_spec.rb
│   │   │   │   ├── numerical_question_spec.rb
│   │   │   │   ├── question_data_spec.rb
│   │   │   │   ├── raw_fields_spec.rb
│   │   │   │   ├── short_answer_question_spec.rb
│   │   │   │   ├── text_only_question_spec.rb
│   │   │   │   ├── unknown_question_spec.rb
│   │   │   │   └── user_answer_spec.rb
│   │   │   ├── quiz_question_builder_spec.rb
│   │   │   ├── quiz_question_regrade_spec.rb
│   │   │   ├── quiz_question_spec.rb
│   │   │   ├── quiz_regrade_run_spec.rb
│   │   │   ├── quiz_regrade_spec.rb
│   │   │   ├── quiz_regrader
│   │   │   │   ├── answer_spec.rb
│   │   │   │   ├── attempt_version_spec.rb
│   │   │   │   ├── regrader_spec.rb
│   │   │   │   └── submission_spec.rb
│   │   │   ├── quiz_sortables_spec.rb
│   │   │   ├── quiz_spec.rb
│   │   │   ├── quiz_statistics
│   │   │   │   ├── common.rb
│   │   │   │   ├── item_analysis
│   │   │   │   │   ├── common.rb
│   │   │   │   │   ├── item_spec.rb
│   │   │   │   │   └── summary_spec.rb
│   │   │   │   ├── item_analysis_spec.rb
│   │   │   │   └── student_analysis_spec.rb
│   │   │   ├── quiz_statistics_service_spec.rb
│   │   │   ├── quiz_statistics_spec.rb
│   │   │   ├── quiz_submission
│   │   │   │   └── question_reference_data_fixer_spec.rb
│   │   │   ├── quiz_submission_attempt_spec.rb
│   │   │   ├── quiz_submission_event_spec.rb
│   │   │   ├── quiz_submission_history_spec.rb
│   │   │   ├── quiz_submission_service_spec.rb
│   │   │   ├── quiz_submission_spec.rb
│   │   │   ├── quiz_submission_zipper_spec.rb
│   │   │   ├── quiz_user_finder_spec.rb
│   │   │   ├── quiz_user_messager_spec.rb
│   │   │   ├── quiz_user_messager_spec_helper.rb
│   │   │   ├── submission_grader_spec.rb
│   │   │   └── submission_manager_spec.rb
│   │   ├── quizzes_next
│   │   │   ├── export_service_spec.rb
│   │   │   ├── importers
│   │   │   │   └── course_content_importer_spec.rb
│   │   │   └── service_spec.rb
│   │   ├── release_notes_spec.rb
│   │   ├── role_override_spec.rb
│   │   ├── role_spec.rb
│   │   ├── root_account_resolver_spec.rb
│   │   ├── rubric_assessment_export_spec.rb
│   │   ├── rubric_assessment_import_spec.rb
│   │   ├── rubric_assessment_spec.rb
│   │   ├── rubric_association_spec.rb
│   │   ├── rubric_criterion_spec.rb
│   │   ├── rubric_import_spec.rb
│   │   ├── rubric_spec.rb
│   │   ├── scheduled_smart_alert_spec.rb
│   │   ├── score_metadata_spec.rb
│   │   ├── score_spec.rb
│   │   ├── setting_spec.rb
│   │   ├── sharded_bookmarked_collection_spec.rb
│   │   ├── shared_brand_config_spec.rb
│   │   ├── sis_batch_roll_back_data_spec.rb
│   │   ├── sis_batch_spec.rb
│   │   ├── sis_pseudonym_spec.rb
│   │   ├── speed_grader
│   │   │   ├── assignment_spec.rb
│   │   │   └── student_group_selection_spec.rb
│   │   ├── split_users_spec.rb
│   │   ├── standard_grade_status_spec.rb
│   │   ├── stream_item_instance_spec.rb
│   │   ├── stream_item_spec.rb
│   │   ├── student_enrollment_spec.rb
│   │   ├── student_view_enrollment_spec.rb
│   │   ├── student_visibility
│   │   │   └── student_visibility_common.rb
│   │   ├── sub_assignment_spec.rb
│   │   ├── submission_comment_interaction_spec.rb
│   │   ├── submission_comment_spec.rb
│   │   ├── submission_draft_attachment_spec.rb
│   │   ├── submission_draft_spec.rb
│   │   ├── submission_spec.rb
│   │   ├── submission_version_spec.rb
│   │   ├── ta_enrollment_spec.rb
│   │   ├── teacher_enrollment_spec.rb
│   │   ├── temporary_enrollment_pairing_spec.rb
│   │   ├── terms_of_service_spec.rb
│   │   ├── usage_rights_spec.rb
│   │   ├── user_account_association_spec.rb
│   │   ├── user_learning_object_scopes_spec.rb
│   │   ├── user_observer_spec.rb
│   │   ├── user_preference_value_spec.rb
│   │   ├── user_profile_spec.rb
│   │   ├── user_service_spec.rb
│   │   ├── user_spec.rb
│   │   ├── users
│   │   │   ├── access_verifier_spec.rb
│   │   │   └── creation_notify_policy_spec.rb
│   │   ├── web_conference_spec.rb
│   │   ├── web_conference_spec_helper.rb
│   │   ├── web_zip_export_spec.rb
│   │   ├── wiki_page_lookup_spec.rb
│   │   ├── wiki_page_spec.rb
│   │   ├── wiki_pages
│   │   │   └── scoped_to_user_spec.rb
│   │   ├── wiki_spec.rb
│   │   └── wimba_conference_spec.rb
│   ├── observers
│   │   ├── live_events_observer_spec.rb
│   │   └── stream_item_cache_spec.rb
│   ├── openapi
│   │   └── lti
│   │       ├── accounts.yaml
│   │       ├── authorize_redirect.yaml
│   │       ├── courses.yaml
│   │       ├── developer_keys.yaml
│   │       ├── groups.yaml
│   │       ├── ims
│   │       │   └── dynamic_registration.yaml
│   │       ├── register.yaml
│   │       ├── registration_token.yaml
│   │       ├── registrations.yaml
│   │       └── security.yaml
│   ├── outcome_alignments_spec_helper.rb
│   ├── plagiarism_platform_spec_helper.rb
│   ├── presenters
│   │   ├── assignment_presenter_spec.rb
│   │   ├── authentication_providers_presenter_spec.rb
│   │   ├── course_for_menu_presenter_spec.rb
│   │   ├── course_pace_presenter_spec.rb
│   │   ├── course_pacing
│   │   │   ├── pace_contexts_presenter_spec.rb
│   │   │   ├── pace_presenter_spec.rb
│   │   │   ├── section_pace_presenter_spec.rb
│   │   │   └── student_enrollment_pace_presenter_spec.rb
│   │   ├── discussion_topic_presenter_spec.rb
│   │   ├── grade_summary_assignment_presenter_spec.rb
│   │   ├── grade_summary_presenter_spec.rb
│   │   ├── grades_presenter_spec.rb
│   │   ├── grading_period_grade_summary_presenter_spec.rb
│   │   ├── mark_done_presenter_spec.rb
│   │   ├── override_list_presenter_spec.rb
│   │   ├── override_tooltip_presenter_spec.rb
│   │   ├── quizzes
│   │   │   └── take_quiz_presenter_spec.rb
│   │   ├── section_tab_presenter_spec.rb
│   │   ├── submission
│   │   │   ├── show_presenter_spec.rb
│   │   │   └── upload_presenter_spec.rb
│   │   └── to_do_list_presenter_spec.rb
│   ├── quiz_spec_helper.rb
│   ├── rcov.opts
│   ├── requests
│   │   ├── discussion_topics_spec.rb
│   │   ├── gradebooks_spec.rb
│   │   ├── pace_contexts_spec.rb
│   │   ├── quiz_ip_filters_spec.rb
│   │   ├── section_paces_spec.rb
│   │   └── student_enrollment_paces_spec.rb
│   ├── rspec_mock_extensions.rb
│   ├── selenium
│   │   ├── a11y_and_i18n
│   │   │   ├── dyslexic_font_spec.rb
│   │   │   ├── high_contrast_spec.rb
│   │   │   ├── i18n_js_spec.rb
│   │   │   └── localized-timezone-lists_spec.rb
│   │   ├── accessibility_checker
│   │   │   └── accessibility_checker_app_spec.rb
│   │   ├── add_people
│   │   │   └── add_people_spec.rb
│   │   ├── admin
│   │   │   ├── account_admin_auth_providers_spec.rb
│   │   │   ├── account_admin_calendar_settings_spec.rb
│   │   │   ├── account_admin_developer_keys_spec.rb
│   │   │   ├── account_admin_grading_schemes_spec.rb
│   │   │   ├── account_admin_question_bank_content_spec.rb
│   │   │   ├── account_admin_question_banks_spec.rb
│   │   │   ├── account_admin_quizzes_spec.rb
│   │   │   ├── account_admin_rubrics_spec.rb
│   │   │   ├── account_admin_settings_spec.rb
│   │   │   ├── account_admin_sis_imports_spec.rb
│   │   │   ├── account_admin_statistics_spec.rb
│   │   │   ├── account_admin_terms_spec.rb
│   │   │   ├── account_direct_share_import_spec.rb
│   │   │   ├── accounts_spec.rb
│   │   │   ├── admin_authentication_providers_spec.rb
│   │   │   ├── admin_avatars_spec.rb
│   │   │   ├── admin_settings_announcements_spec.rb
│   │   │   ├── admin_settings_tab_spec.rb
│   │   │   ├── admin_sub_accounts_spec.rb
│   │   │   ├── admin_tools_spec.rb
│   │   │   ├── analytics_2
│   │   │   │   ├── analytics_2.0_spec.rb
│   │   │   │   └── student_context_tray_spec.rb
│   │   │   ├── assignments_admin_spec.rb
│   │   │   ├── duplications
│   │   │   │   └── discussion_duplications_spec.rb
│   │   │   ├── new_course_search_spec.rb
│   │   │   ├── new_user_search_spec.rb
│   │   │   ├── pages
│   │   │   │   ├── account_calendar_settings_page.rb
│   │   │   │   ├── account_content_share_page.rb
│   │   │   │   ├── admin_account_page.rb
│   │   │   │   ├── admin_developer_keys_page.rb
│   │   │   │   ├── course_page.rb
│   │   │   │   ├── edit_existing_user_modal_page.rb
│   │   │   │   ├── masquerade_page.rb
│   │   │   │   ├── new_course_add_course_modal.rb
│   │   │   │   ├── new_course_add_people_modal.rb
│   │   │   │   ├── new_course_search_page.rb
│   │   │   │   ├── new_user_edit_modal_page.rb
│   │   │   │   ├── new_user_search_page.rb
│   │   │   │   ├── permissions_page.rb
│   │   │   │   └── student_context_tray_page.rb
│   │   │   ├── permissions_index_page_v2_spec.rb
│   │   │   ├── site_admin_jobs_spec.rb
│   │   │   └── sub_accounts
│   │   │       ├── grading_schemes_spec.rb
│   │   │       ├── question_banks_spec.rb
│   │   │       ├── rubrics_spec.rb
│   │   │       ├── settings_spec.rb
│   │   │       └── statistics_spec.rb
│   │   ├── announcements
│   │   │   ├── announcement_helpers.rb
│   │   │   ├── announcement_permission_spec.rb
│   │   │   ├── announcements_index_v2_spec.rb
│   │   │   ├── announcements_student_spec.rb
│   │   │   ├── announcements_teacher_spec.rb
│   │   │   ├── global_announcements_spec.rb
│   │   │   └── pages
│   │   │       ├── announcement_index_page.rb
│   │   │       ├── announcement_new_edit_page.rb
│   │   │       └── external_feed_page.rb
│   │   ├── assignments
│   │   │   ├── accessibility_assignments_spec.rb
│   │   │   ├── assignment_allowed_attempts_spec.rb
│   │   │   ├── assignment_edit_spec.rb
│   │   │   ├── assignments_anonymous_moderated_spec.rb
│   │   │   ├── assignments_batch_edit_dates_spec.rb
│   │   │   ├── assignments_create_edit_assign_to_spec.rb
│   │   │   ├── assignments_create_edit_no_tray_assign_to_spec.rb
│   │   │   ├── assignments_direct_share_import_spec.rb
│   │   │   ├── assignments_discussion_spec.rb
│   │   │   ├── assignments_external_tool_spec.rb
│   │   │   ├── assignments_grading_type_spec.rb
│   │   │   ├── assignments_group_spec.rb
│   │   │   ├── assignments_index_assign_to_spec.rb
│   │   │   ├── assignments_index_menu_tools_spec.rb
│   │   │   ├── assignments_index_peer_review_spec.rb
│   │   │   ├── assignments_moderated_spec.rb
│   │   │   ├── assignments_multiple_grading_periods_spec.rb
│   │   │   ├── assignments_peer_reviews_spec.rb
│   │   │   ├── assignments_quick_add_spec.rb
│   │   │   ├── assignments_quiz_lti_spec.rb
│   │   │   ├── assignments_quizzes_spec.rb
│   │   │   ├── assignments_rubrics_spec.rb
│   │   │   ├── assignments_show_assign_to_spec.rb
│   │   │   ├── assignments_spec.rb
│   │   │   ├── assignments_student_observer_spec.rb
│   │   │   ├── assignments_student_spec.rb
│   │   │   ├── assignments_submissions_student_groups_spec.rb
│   │   │   ├── assignments_submissions_student_spec.rb
│   │   │   ├── assignments_submissions_teacher_groups_spec.rb
│   │   │   ├── assignments_submissions_teacher_spec.rb
│   │   │   ├── assignments_turn_it_in_spec.rb
│   │   │   ├── modules_spec.rb
│   │   │   ├── page_objects
│   │   │   │   ├── assignment_create_edit_page.rb
│   │   │   │   ├── assignment_page.rb
│   │   │   │   ├── assignments_index_page.rb
│   │   │   │   ├── course_modules_page.rb
│   │   │   │   └── submission_detail_page.rb
│   │   │   ├── speed_grader
│   │   │   │   ├── graded_discussion_nav_buttons_spec.rb
│   │   │   │   └── graded_discussion_spec.rb
│   │   │   └── submission_types_spec.rb
│   │   ├── assignments_v2
│   │   │   ├── assignment_locked_spec.rb
│   │   │   ├── page_objects
│   │   │   │   ├── student_assignment_page_v2.rb
│   │   │   │   ├── teacher_assignment_edit_page_v2.rb
│   │   │   │   └── teacher_assignment_page_v2.rb
│   │   │   ├── student_assignment_spec.rb
│   │   │   ├── student_comment_spec.rb
│   │   │   ├── teacher_assignment_edit_spec.rb
│   │   │   └── teacher_assignment_spec.rb
│   │   ├── authorization
│   │   │   ├── application_spec.rb
│   │   │   ├── auth_spec.rb
│   │   │   ├── oauth_spec.rb
│   │   │   └── pages
│   │   │       └── logout_page.rb
│   │   ├── block_editor
│   │   │   ├── block_editor_keyboard_nav_spec.rb
│   │   │   ├── block_editor_spec.rb
│   │   │   ├── block_editor_templates_spec.rb
│   │   │   ├── block_editor_top_bar_spec.rb
│   │   │   ├── block_toolbar_breadcrumb_spec.rb
│   │   │   ├── columns_section_spec.rb
│   │   │   └── pages
│   │   │       └── block_editor_page.rb
│   │   ├── browser_operations
│   │   │   ├── alerts_spec.rb
│   │   │   ├── brandable_css_js_spec.rb
│   │   │   ├── browser_spec.rb
│   │   │   ├── cdn_spec.rb
│   │   │   ├── communication_channels_spec.rb
│   │   │   └── flash_notifications_spec.rb
│   │   ├── calendar
│   │   │   ├── calendar2_24hour_time_spec.rb
│   │   │   ├── calendar2_agenda_spec.rb
│   │   │   ├── calendar2_event_create_spec.rb
│   │   │   ├── calendar2_general_spec.rb
│   │   │   ├── calendar2_month_spec.rb
│   │   │   ├── calendar2_new_scheduler_spec.rb
│   │   │   ├── calendar2_new_scheduler_teacher_spec.rb
│   │   │   ├── calendar2_other_calendars_spec.rb
│   │   │   ├── calendar2_recurring_events_spec.rb
│   │   │   ├── calendar2_scheduler_student_spec.rb
│   │   │   ├── calendar2_scheduler_teacher_spec.rb
│   │   │   ├── calendar2_sidebar_spec.rb
│   │   │   ├── calendar2_student_spec.rb
│   │   │   ├── calendar2_week_spec.rb
│   │   │   ├── calendar2_with_planner_notes_spec.rb
│   │   │   └── pages
│   │   │       ├── calendar_edit_page.rb
│   │   │       ├── calendar_other_calendars_page.rb
│   │   │       ├── calendar_page.rb
│   │   │       ├── calendar_recurrence_modal_page.rb
│   │   │       └── scheduler_page.rb
│   │   ├── client_apps
│   │   │   └── canvas_quizzes_spec.rb
│   │   ├── collaborations
│   │   │   ├── collaborations_form_student_spec.rb
│   │   │   ├── collaborations_form_teacher_spec.rb
│   │   │   ├── collaborations_student_spec.rb
│   │   │   └── collaborations_teacher_spec.rb
│   │   ├── common.rb
│   │   ├── conditional_release
│   │   │   ├── conditional_release_spec.rb
│   │   │   └── page_objects
│   │   │       └── conditional_release_objects.rb
│   │   ├── conferences
│   │   │   ├── big_blue_button_conference_spec.rb
│   │   │   └── conference_spec.rb
│   │   ├── content_migrations
│   │   │   ├── content_exports_spec.rb
│   │   │   ├── content_migrations_spec.rb
│   │   │   ├── course_copy_spec.rb
│   │   │   ├── new_content_migrations_spec.rb
│   │   │   ├── new_course_copy_spec.rb
│   │   │   └── page_objects
│   │   │       ├── content_migration_page.rb
│   │   │       ├── course_copy_page.rb
│   │   │       ├── new_content_migration_page.rb
│   │   │       ├── new_content_migration_progress_item.rb
│   │   │       ├── new_course_copy_page.rb
│   │   │       ├── new_select_content_page.rb
│   │   │       └── select_content_page.rb
│   │   ├── context_modules
│   │   │   ├── context_modules_estimated_duration_spec.rb
│   │   │   ├── context_modules_external_tools_spec.rb
│   │   │   ├── context_modules_menu_tools_spec.rb
│   │   │   ├── context_modules_observer_spec.rb
│   │   │   ├── context_modules_progressions_spec.rb
│   │   │   ├── context_modules_spec.rb
│   │   │   ├── context_modules_student_spec.rb
│   │   │   ├── context_modules_teacher_a11y_spec.rb
│   │   │   ├── context_modules_teacher_edit_dialog_spec.rb
│   │   │   ├── context_modules_teacher_homepage_spec.rb
│   │   │   ├── context_modules_teacher_regressions_spec.rb
│   │   │   ├── context_modules_teacher_spec.rb
│   │   │   ├── module_direct_share_import_spec.rb
│   │   │   ├── page_objects
│   │   │   │   ├── modules_index_page.rb
│   │   │   │   └── modules_settings_tray.rb
│   │   │   ├── performance_update
│   │   │   │   ├── context_modules_spec.rb
│   │   │   │   ├── context_modules_student_spec.rb
│   │   │   │   └── context_modules_teacher_spec.rb
│   │   │   ├── selective_release
│   │   │   │   ├── module_selective_release_item_assign_to_spec.rb
│   │   │   │   ├── module_selective_release_student_spec.rb
│   │   │   │   └── module_selective_release_teacher_spec.rb
│   │   │   └── shared_examples
│   │   │       ├── context_modules_teacher_shared_examples.rb
│   │   │       ├── module_item_selective_release_assign_to_shared_examples.rb
│   │   │       ├── module_selective_release_shared_examples.rb
│   │   │       └── modules_performance_shared_examples.rb
│   │   ├── context_modules_v2
│   │   │   ├── page_objects
│   │   │   │   └── modules2_index_page.rb
│   │   │   ├── students
│   │   │   │   └── course_modules2_student_spec.rb
│   │   │   └── teachers
│   │   │       └── course_modules2_teacher_spec.rb
│   │   ├── conversations
│   │   │   ├── conversations_message_sending_spec.rb
│   │   │   ├── conversations_replying_spec.rb
│   │   │   ├── conversations_search_and_select_spec.rb
│   │   │   ├── conversations_spec.rb
│   │   │   └── conversations_submission_comments_spec.rb
│   │   ├── course_paces
│   │   │   ├── coursepaces_landing_page_spec.rb
│   │   │   ├── coursepaces_mastercourses_spec.rb
│   │   │   ├── coursepaces_modal_blackout_spec.rb
│   │   │   ├── coursepaces_modal_edittray_spec.rb
│   │   │   ├── coursepaces_modal_projections_spec.rb
│   │   │   ├── coursepaces_modal_spec.rb
│   │   │   ├── coursepaces_search_and_sort_spec.rb
│   │   │   └── pages
│   │   │       ├── coursepaces_common_page.rb
│   │   │       ├── coursepaces_landing_page.rb
│   │   │       └── coursepaces_page.rb
│   │   ├── course_wiki_pages
│   │   │   ├── course_wiki_page_assign_to_spec.rb
│   │   │   ├── course_wiki_page_create_edit_assign_to_spec.rb
│   │   │   ├── course_wiki_page_index_assign_to_spec.rb
│   │   │   ├── course_wiki_page_student_spec.rb
│   │   │   ├── course_wiki_page_teacher_spec.rb
│   │   │   ├── page_objects
│   │   │   │   ├── wiki_index_page.rb
│   │   │   │   └── wiki_page.rb
│   │   │   ├── wiki_direct_share_import_spec.rb
│   │   │   └── wiki_page_accessibility_spec.rb
│   │   ├── courses
│   │   │   ├── all_courses_spec.rb
│   │   │   ├── course_index_spec.rb
│   │   │   ├── course_sections_spec.rb
│   │   │   ├── course_settings_spec.rb
│   │   │   ├── course_smart_search_spec.rb
│   │   │   ├── course_statistics_spec.rb
│   │   │   ├── course_wizard_spec.rb
│   │   │   ├── courses_original_spec.rb
│   │   │   ├── courses_spec.rb
│   │   │   ├── cross_listing_spec.rb
│   │   │   ├── large_enrollments_spec.rb
│   │   │   └── pages
│   │   │       ├── course_index_page.rb
│   │   │       ├── course_left_nav_page_component.rb
│   │   │       ├── course_settings_navigation_page_component.rb
│   │   │       ├── course_settings_page.rb
│   │   │       ├── course_wizard_page_component.rb
│   │   │       └── courses_home_page.rb
│   │   ├── dashboard
│   │   │   ├── dashboard_coming_up_spec.rb
│   │   │   ├── dashboard_sidebar_spec.rb
│   │   │   ├── dashboard_spec.rb
│   │   │   ├── dashboard_teacher_spec.rb
│   │   │   ├── dashboard_todo_spec.rb
│   │   │   ├── dashcards_spec.rb
│   │   │   ├── elementary
│   │   │   │   ├── k5_course_dashboard_student_spec.rb
│   │   │   │   ├── k5_course_dashboard_teacher_spec.rb
│   │   │   │   ├── k5_course_grades_student_spec.rb
│   │   │   │   ├── k5_dashboard_admin_spec.rb
│   │   │   │   ├── k5_dashboard_observer_spec.rb
│   │   │   │   ├── k5_dashboard_schedule_student_spec.rb
│   │   │   │   ├── k5_dashboard_student_spec.rb
│   │   │   │   ├── k5_dashboard_teacher_spec.rb
│   │   │   │   ├── k5_dashboard_teacher_todo_spec.rb
│   │   │   │   ├── k5_important_dates_observer_spec.rb
│   │   │   │   ├── k5_important_dates_student_spec.rb
│   │   │   │   └── k5_important_dates_teacher_spec.rb
│   │   │   ├── pages
│   │   │   │   ├── dashboard_page.rb
│   │   │   │   ├── k5_dashboard_common_page.rb
│   │   │   │   ├── k5_dashboard_page.rb
│   │   │   │   ├── k5_grades_tab_page.rb
│   │   │   │   ├── k5_important_dates_section_page.rb
│   │   │   │   ├── k5_modules_tab_page.rb
│   │   │   │   ├── k5_resource_tab_page.rb
│   │   │   │   ├── k5_schedule_tab_page.rb
│   │   │   │   ├── k5_todo_tab_page.rb
│   │   │   │   └── student_planner_page.rb
│   │   │   ├── planner
│   │   │   │   ├── student_planner_assignments_spec.rb
│   │   │   │   ├── student_planner_graded_ungraded_discussion_spec.rb
│   │   │   │   ├── student_planner_spec.rb
│   │   │   │   ├── student_planner_sub_assignments_spec.rb
│   │   │   │   ├── teacher_planner_spec.rb
│   │   │   │   └── tutorials_spec.rb
│   │   │   ├── recent_activity
│   │   │   │   └── dashboard_spec.rb
│   │   │   └── shared_examples
│   │   │       ├── k5_announcements_shared_examples.rb
│   │   │       ├── k5_important_dates_shared_examples.rb
│   │   │       ├── k5_navigation_tabs_shared_examples.rb
│   │   │       ├── k5_schedule_shared_examples.rb
│   │   │       └── k5_subject_grades_shared_examples.rb
│   │   ├── differentiated_assignments
│   │   │   ├── da_assignments_spec.rb
│   │   │   ├── da_calendar_dashboard_spec.rb
│   │   │   ├── da_modules_spec.rb
│   │   │   ├── da_quizzes_spec.rb
│   │   │   └── refactored_specs
│   │   │       ├── assignments_da_index_student_observer_spec.rb
│   │   │       └── assignments_da_index_teacher_ta_spec.rb
│   │   ├── discussions
│   │   │   ├── discussion_group_submit_spec.rb
│   │   │   ├── discussion_helpers.rb
│   │   │   ├── discussion_index_menu_tools_spec.rb
│   │   │   ├── discussion_permission_spec.rb
│   │   │   ├── discussion_topic_navigation_shortcuts_spec.rb
│   │   │   ├── discussion_topic_search_spec.rb
│   │   │   ├── discussion_topic_show_spec.rb
│   │   │   ├── discussions_direct_share_import_spec.rb
│   │   │   ├── discussions_edit_page_spec.rb
│   │   │   ├── discussions_index_page_student_v2_spec.rb
│   │   │   ├── discussions_index_page_teacher_v2_spec.rb
│   │   │   ├── discussions_new_page_spec.rb
│   │   │   ├── discussions_overrides_spec.rb
│   │   │   ├── discussions_post_grades_to_sis_spec.rb
│   │   │   ├── discussions_reply_attachment_spec.rb
│   │   │   ├── discussions_split_screen_spec.rb
│   │   │   ├── discussions_threaded_spec.rb
│   │   │   ├── insight
│   │   │   │   └── discussion_insight_spec.rb
│   │   │   ├── pages
│   │   │   │   ├── discussion_page.rb
│   │   │   │   └── discussions_index_page.rb
│   │   │   └── rcs
│   │   │       ├── discussions_index_page_any_user_spec.rb
│   │   │       ├── discussions_index_page_student_spec.rb
│   │   │       ├── discussions_show_page_any_user_spec.rb
│   │   │       └── discussions_show_page_specific_user_spec.rb
│   │   ├── enrollment
│   │   │   ├── new_enrollment_ui_spec.rb
│   │   │   ├── pages
│   │   │   │   └── new_enrollment_page_object_model.rb
│   │   │   ├── self_enrollment_spec.rb
│   │   │   └── temporary_enrollment_spec.rb
│   │   ├── files
│   │   │   ├── files_show_spec.rb
│   │   │   ├── new_files_folders_spec.rb
│   │   │   ├── new_files_spec.rb
│   │   │   ├── new_files_student_spec.rb
│   │   │   └── new_files_tools_spec.rb
│   │   ├── files_v2
│   │   │   ├── files_folders_spec.rb
│   │   │   ├── files_spec.rb
│   │   │   ├── files_student_spec.rb
│   │   │   ├── files_toggle_spec.rb
│   │   │   ├── files_tools_spec.rb
│   │   │   └── pages
│   │   │       └── files_page.rb
│   │   ├── force_failure_spec.rb
│   │   ├── grades
│   │   │   ├── enhanced_srgb
│   │   │   │   ├── srgb_anonymous_moderated_spec.rb
│   │   │   │   ├── srgb_global_checkboxes_spec.rb
│   │   │   │   ├── srgb_grading_spec.rb
│   │   │   │   ├── srgb_spec.rb
│   │   │   │   └── srgb_student_information_spec.rb
│   │   │   ├── grade_override
│   │   │   │   └── grade_override_spec.rb
│   │   │   ├── grade_validation
│   │   │   │   └── grade_validation_spec.rb
│   │   │   ├── gradebook
│   │   │   │   ├── assignments_omit_from_final_grade_spec.rb
│   │   │   │   ├── concluded_unconcluded_spec.rb
│   │   │   │   ├── excuse_assignment_spec.rb
│   │   │   │   ├── gradebook_a11y_spec.rb
│   │   │   │   ├── gradebook_anonymous_moderated_spec.rb
│   │   │   │   ├── gradebook_arrange_by_assignment_group_spec.rb
│   │   │   │   ├── gradebook_arrange_by_due_date_spec.rb
│   │   │   │   ├── gradebook_assignment_column_options_spec.rb
│   │   │   │   ├── gradebook_commenting_spec.rb
│   │   │   │   ├── gradebook_complete_incomplete_spec.rb
│   │   │   │   ├── gradebook_concluded_courses_and_enrollments_spec.rb
│   │   │   │   ├── gradebook_controls_spec.rb
│   │   │   │   ├── gradebook_custom_column_spec.rb
│   │   │   │   ├── gradebook_differentiated_assignments_spec.rb
│   │   │   │   ├── gradebook_enhanced_filters_spec.rb
│   │   │   │   ├── gradebook_filters_spec.rb
│   │   │   │   ├── gradebook_grade_detail_spec.rb
│   │   │   │   ├── gradebook_grade_edit_spec.rb
│   │   │   │   ├── gradebook_group_weight_spec.rb
│   │   │   │   ├── gradebook_late_policy_spec.rb
│   │   │   │   ├── gradebook_letter_grade_spec.rb
│   │   │   │   ├── gradebook_message_students_who_spec.rb
│   │   │   │   ├── gradebook_mgp_spec.rb
│   │   │   │   ├── gradebook_pagination_spec.rb
│   │   │   │   ├── gradebook_pass_fail_assignment_spec.rb
│   │   │   │   ├── gradebook_permissions_spec.rb
│   │   │   │   ├── gradebook_post_grades_to_sis_spec.rb
│   │   │   │   ├── gradebook_post_policy_spec.rb
│   │   │   │   ├── gradebook_spec.rb
│   │   │   │   ├── gradebook_student_column_spec.rb
│   │   │   │   ├── gradebook_total_column_options_spec.rb
│   │   │   │   ├── gradebook_turnitin_spec.rb
│   │   │   │   ├── gradebook_uploads_spec.rb
│   │   │   │   ├── gradebook_view_options_spec.rb
│   │   │   │   ├── multiple_grading_periods_spec.rb
│   │   │   │   └── student_grades_late_policies_spec.rb
│   │   │   ├── gradebook_history
│   │   │   │   ├── gbhistory_calendar_spec.rb
│   │   │   │   ├── gbhistory_pagination_spec.rb
│   │   │   │   └── gradebook_history_spec.rb
│   │   │   ├── grading_standards
│   │   │   │   ├── grading_periods_course_spec.rb
│   │   │   │   ├── grading_standards_mgp_spec.rb
│   │   │   │   └── grading_standards_spec.rb
│   │   │   ├── grading_statuses
│   │   │   │   └── grading_statuses_settings_spec.rb
│   │   │   ├── integration
│   │   │   │   ├── a_gradebook_shared_example.rb
│   │   │   │   ├── grading_period_conditions.rb
│   │   │   │   ├── weight_conditions.rb
│   │   │   │   ├── weighting_setup.rb
│   │   │   │   ├── weights_on_global_grades_spec.rb
│   │   │   │   ├── weights_on_gradebook_spec.rb
│   │   │   │   └── weights_on_student_grades_page_spec.rb
│   │   │   ├── moderation
│   │   │   │   ├── moderate_page_large_students_spec.rb
│   │   │   │   ├── moderate_submissions_with_graded_rubrics_spec.rb
│   │   │   │   └── moderated_marking_spec.rb
│   │   │   ├── pages
│   │   │   │   ├── enhanced_srgb_page.rb
│   │   │   │   ├── global_grades_page.rb
│   │   │   │   ├── gradebook
│   │   │   │   │   └── settings.rb
│   │   │   │   ├── gradebook_cells_page.rb
│   │   │   │   ├── gradebook_grade_detail_tray_page.rb
│   │   │   │   ├── gradebook_history_page.rb
│   │   │   │   ├── gradebook_individual_view_page.rb
│   │   │   │   ├── gradebook_page.rb
│   │   │   │   ├── grading_curve_page.rb
│   │   │   │   ├── grading_statuses_page.rb
│   │   │   │   ├── hide_grades_tray_page.rb
│   │   │   │   ├── mgp_page.rb
│   │   │   │   ├── moderate_page.rb
│   │   │   │   ├── post_grades_tray_page.rb
│   │   │   │   ├── speedgrader_page.rb
│   │   │   │   ├── srgb_page.rb
│   │   │   │   ├── student_grades_page.rb
│   │   │   │   └── student_interactions_report_page.rb
│   │   │   ├── rubric
│   │   │   │   └── rubrics_teacher_spec.rb
│   │   │   ├── setup
│   │   │   │   ├── assignment_grade_type_setup.rb
│   │   │   │   ├── gb_history_search_setup.rb
│   │   │   │   ├── gradebook_setup.rb
│   │   │   │   └── n_submissions_setup.rb
│   │   │   ├── speedgrader
│   │   │   │   ├── sg_teacher_section_switch_spec.rb
│   │   │   │   ├── speedgrader_anonymous_moderated_marking_spec.rb
│   │   │   │   ├── speedgrader_audit_trail_spec.rb
│   │   │   │   ├── speedgrader_comment_library_spec.rb
│   │   │   │   ├── speedgrader_comments_spec.rb
│   │   │   │   ├── speedgrader_discussion_submissions_spec.rb
│   │   │   │   ├── speedgrader_grade_display_spec.rb
│   │   │   │   ├── speedgrader_mgp_spec.rb
│   │   │   │   ├── speedgrader_moderated_grading_spec.rb
│   │   │   │   ├── speedgrader_post_policy_spec.rb
│   │   │   │   ├── speedgrader_quiz_submissions_spec.rb
│   │   │   │   ├── speedgrader_rubric_spec.rb
│   │   │   │   ├── speedgrader_spec.rb
│   │   │   │   ├── speedgrader_status_menu_spec.rb
│   │   │   │   ├── speedgrader_student_group_filter_spec.rb
│   │   │   │   ├── speedgrader_teacher_spec.rb
│   │   │   │   └── speedgrader_teacher_submission_spec.rb
│   │   │   ├── student_grades_page
│   │   │   │   ├── student_grades_page_assignment_details_spec.rb
│   │   │   │   ├── student_grades_page_observer_spec.rb
│   │   │   │   ├── student_grades_page_spec.rb
│   │   │   │   └── students_grades_page_arrange_by_spec.rb
│   │   │   └── student_grades_summary
│   │   │       ├── global_grades_spec.rb
│   │   │       ├── grades_public_spec.rb
│   │   │       └── grades_spec.rb
│   │   ├── graphiql
│   │   │   └── graphiql_spec.rb
│   │   ├── groups
│   │   │   ├── groups_admin_spec.rb
│   │   │   ├── groups_navigation_spec.rb
│   │   │   ├── groups_pages_student_spec.rb
│   │   │   ├── groups_pages_teacher_spec.rb
│   │   │   ├── groups_student_as_teacher_spec.rb
│   │   │   ├── groups_student_spec.rb
│   │   │   ├── groups_teacher_spec.rb
│   │   │   └── manage_new_groups_spec.rb
│   │   ├── helpers
│   │   │   ├── accessibility
│   │   │   │   └── accessibility_common.rb
│   │   │   ├── accounts_auth_providers_common.rb
│   │   │   ├── admin_settings_common.rb
│   │   │   ├── announcements_common.rb
│   │   │   ├── assignment_overrides.rb
│   │   │   ├── assignments_common.rb
│   │   │   ├── basic
│   │   │   │   ├── question_banks_specs.rb
│   │   │   │   ├── rcs
│   │   │   │   │   └── settings_specs.rb
│   │   │   │   ├── settings_specs.rb
│   │   │   │   └── statistics_specs.rb
│   │   │   ├── blueprint_common.rb
│   │   │   ├── calendar2_common.rb
│   │   │   ├── collaborations_common.rb
│   │   │   ├── collaborations_specs_common.rb
│   │   │   ├── color_common.rb
│   │   │   ├── conferences_common.rb
│   │   │   ├── context_modules_common.rb
│   │   │   ├── conversations_common.rb
│   │   │   ├── course_common.rb
│   │   │   ├── dashboard_common.rb
│   │   │   ├── developer_keys_common.rb
│   │   │   ├── differentiated_assignments
│   │   │   │   ├── da_assignment.rb
│   │   │   │   ├── da_common.rb
│   │   │   │   ├── da_course_modules_module.rb
│   │   │   │   ├── da_discussion.rb
│   │   │   │   ├── da_homework_assignee_module.rb
│   │   │   │   ├── da_homework_assignments_module.rb
│   │   │   │   ├── da_homework_discussions_module.rb
│   │   │   │   ├── da_homework_module.rb
│   │   │   │   ├── da_homework_quizzes_module.rb
│   │   │   │   ├── da_module.rb
│   │   │   │   ├── da_quiz.rb
│   │   │   │   ├── da_sections_module.rb
│   │   │   │   ├── da_users_module.rb
│   │   │   │   └── da_wrappable.rb
│   │   │   ├── differentiated_assignments.rb
│   │   │   ├── discussions_common.rb
│   │   │   ├── eportfolios_common.rb
│   │   │   ├── files_common.rb
│   │   │   ├── google_drive_common.rb
│   │   │   ├── gradebook_common.rb
│   │   │   ├── grading_schemes_common.rb
│   │   │   ├── groups_common.rb
│   │   │   ├── groups_shared_examples.rb
│   │   │   ├── items_assign_to_tray.rb
│   │   │   ├── legacy_announcements_common.rb
│   │   │   ├── manage_groups_common.rb
│   │   │   ├── notifications_common.rb
│   │   │   ├── offline_contents_common.rb
│   │   │   ├── outcome_common.rb
│   │   │   ├── profile_common.rb
│   │   │   ├── public_courses_context.rb
│   │   │   ├── quiz_questions_common.rb
│   │   │   ├── quizzes_common.rb
│   │   │   ├── rubrics_common.rb
│   │   │   ├── scheduler_common.rb
│   │   │   ├── shared_examples_common.rb
│   │   │   ├── sis_grade_passback_common.rb
│   │   │   ├── spec_components
│   │   │   │   ├── spec_components_assignable_module.rb
│   │   │   │   ├── spec_components_assignment.rb
│   │   │   │   ├── spec_components_course_module.rb
│   │   │   │   ├── spec_components_discussion.rb
│   │   │   │   └── spec_components_quiz.rb
│   │   │   ├── speed_grader_common.rb
│   │   │   ├── submissions_common.rb
│   │   │   ├── theme_editor_common.rb
│   │   │   ├── wiki_and_tiny_common.rb
│   │   │   └── wiki_pages_shared_examples.rb
│   │   ├── lti
│   │   │   ├── apps_page_spec.rb
│   │   │   └── postmessage_listener_spec.rb
│   │   ├── master_courses
│   │   │   ├── add_remove_associations_spec.rb
│   │   │   ├── blueprint_assignments_spec.rb
│   │   │   ├── blueprint_associations_spec.rb
│   │   │   ├── blueprint_banner_spec.rb
│   │   │   ├── blueprint_course_settings_spec.rb
│   │   │   ├── blueprint_courses_sync_history_spec.rb
│   │   │   ├── blueprint_discussions_spec.rb
│   │   │   ├── blueprint_external_tools_spec.rb
│   │   │   ├── blueprint_files_spec.rb
│   │   │   ├── blueprint_lock_spec.rb
│   │   │   ├── blueprint_modules_spec.rb
│   │   │   ├── blueprint_pages_spec.rb
│   │   │   ├── blueprint_quizzes_spec.rb
│   │   │   ├── blueprint_setting_spec.rb
│   │   │   ├── blueprint_sidebar_spec.rb
│   │   │   ├── blueprint_teacher_history_spec.rb
│   │   │   ├── child_course_assignments_spec.rb
│   │   │   ├── child_course_pages_spec.rb
│   │   │   ├── child_course_quizzes_spec.rb
│   │   │   ├── child_course_settings_spec.rb
│   │   │   ├── course_picker_spec.rb
│   │   │   └── master_course_pages_spec.rb
│   │   ├── miscellaneous
│   │   │   ├── content_participation_counts_spec.rb
│   │   │   ├── content_security_policy_spec.rb
│   │   │   ├── enhanceable_content_spec.rb
│   │   │   ├── help_dialog_spec.rb
│   │   │   ├── interactions_report_student_spec.rb
│   │   │   ├── jquery_spec.rb
│   │   │   ├── jquery_ui_spec.rb
│   │   │   ├── layout_spec.rb
│   │   │   ├── login_logout_spec.rb
│   │   │   ├── new_user_tutorial_spec.rb
│   │   │   ├── notifications_spec.rb
│   │   │   ├── student_view_toggle_spec.rb
│   │   │   ├── terms_of_use_spec.rb
│   │   │   └── theme_editor_spec.rb
│   │   ├── navigation
│   │   │   ├── links_spec.rb
│   │   │   ├── navigation_spec.rb
│   │   │   ├── new_navigation_spec.rb
│   │   │   └── new_ui_spec.rb
│   │   ├── new_login
│   │   │   ├── forgot_password_page_spec.rb
│   │   │   ├── otp_page_spec.rb
│   │   │   ├── registration
│   │   │   │   ├── parent_registration_page_spec.rb
│   │   │   │   ├── registration_landing_page_spec.rb
│   │   │   │   ├── student_registration_page_spec.rb
│   │   │   │   └── teacher_registration_page_spec.rb
│   │   │   └── sign_in_page_spec.rb
│   │   ├── offline_contents
│   │   │   └── offline_contents_spec.rb
│   │   ├── outcomes
│   │   │   ├── account_admin_course_outcomes_spec.rb
│   │   │   ├── account_admin_state_outcomes_spec.rb
│   │   │   ├── outcome_gradebook_spec.rb
│   │   │   ├── outcome_spec.rb
│   │   │   ├── outcome_student_spec.rb
│   │   │   ├── outcome_teacher_spec.rb
│   │   │   ├── pages
│   │   │   │   └── improved_outcome_management_page.rb
│   │   │   ├── sub_account_outcomes_spec.rb
│   │   │   └── user_outcome_results_spec.rb
│   │   ├── past_global_announcements
│   │   │   ├── pages
│   │   │   │   └── past_global_announcements_page.rb
│   │   │   └── past_global_announcements_spec.rb
│   │   ├── people
│   │   │   ├── differentiation_tag_management_spec.rb
│   │   │   ├── pages
│   │   │   │   ├── course_groups_page.rb
│   │   │   │   └── course_people_modal.rb
│   │   │   ├── people_settings_spec.rb
│   │   │   ├── people_spec.rb
│   │   │   ├── user_content_student_spec.rb
│   │   │   └── users_spec.rb
│   │   ├── performance
│   │   │   └── grades
│   │   │       └── gradebook_performance_spec.rb
│   │   ├── plugins
│   │   │   ├── default_plugins_spec.rb
│   │   │   ├── plugins_spec.rb
│   │   │   └── sessions_timeout_spec.rb
│   │   ├── profile
│   │   │   ├── profile_admin_spec.rb
│   │   │   ├── profile_communications_spec.rb
│   │   │   ├── profile_spec.rb
│   │   │   ├── profile_student_spec.rb
│   │   │   ├── profile_teacher_spec.rb
│   │   │   └── qr_for_mobile_login_spec.rb
│   │   ├── quizzes
│   │   │   ├── page_objects
│   │   │   │   ├── quizzes_edit_page.rb
│   │   │   │   ├── quizzes_index_page.rb
│   │   │   │   └── quizzes_landing_page.rb
│   │   │   ├── quizzes_accessibility_spec.rb
│   │   │   ├── quizzes_auto_submit_quiz_spec.rb
│   │   │   ├── quizzes_availability_student_spec.rb
│   │   │   ├── quizzes_create_quiz_teacher_spec.rb
│   │   │   ├── quizzes_direct_share_import_spec.rb
│   │   │   ├── quizzes_edit_assign_to_no_tray_spec.rb
│   │   │   ├── quizzes_edit_quiz_teacher_spec.rb
│   │   │   ├── quizzes_grading_student_spec.rb
│   │   │   ├── quizzes_grading_teacher_spec.rb
│   │   │   ├── quizzes_index_assign_to_spec.rb
│   │   │   ├── quizzes_index_menu_tools_spec.rb
│   │   │   ├── quizzes_log_auditing_spec.rb
│   │   │   ├── quizzes_observer_spec.rb
│   │   │   ├── quizzes_one_question_at_a_time_spec.rb
│   │   │   ├── quizzes_public_spec.rb
│   │   │   ├── quizzes_publish_quiz_student_spec.rb
│   │   │   ├── quizzes_publish_quiz_teacher_spec.rb
│   │   │   ├── quizzes_question_banks_spec.rb
│   │   │   ├── quizzes_question_creation_regressions_spec.rb
│   │   │   ├── quizzes_question_creation_spec.rb
│   │   │   ├── quizzes_question_html_answers_spec.rb
│   │   │   ├── quizzes_question_reordering_spec.rb
│   │   │   ├── quizzes_restrictions_student_spec.rb
│   │   │   ├── quizzes_restrictions_teacher_spec.rb
│   │   │   ├── quizzes_show_assign_to_spec.rb
│   │   │   ├── quizzes_stats_spec.rb
│   │   │   ├── quizzes_student_spec.rb
│   │   │   ├── quizzes_student_with_draft_state_spec.rb
│   │   │   ├── quizzes_take_quiz_student_spec.rb
│   │   │   ├── quizzes_taking_spec.rb
│   │   │   ├── quizzes_teacher_questions_spec.rb
│   │   │   ├── quizzes_teacher_regressions_spec.rb
│   │   │   ├── quizzes_teacher_spec.rb
│   │   │   ├── quizzes_teacher_students_spec.rb
│   │   │   ├── quizzes_teacher_with_draft_state_spec.rb
│   │   │   ├── quizzes_term_course_section_hierarchy_spec.rb
│   │   │   ├── quizzes_timed_without_submission_spec.rb
│   │   │   ├── quizzes_unpublish_quiz_teacher_spec.rb
│   │   │   ├── quizzes_validate_attempts_spec.rb
│   │   │   └── varied_due_dates
│   │   │       ├── quizzes_vdd_index_page_observer_spec.rb
│   │   │       ├── quizzes_vdd_index_page_student_spec.rb
│   │   │       ├── quizzes_vdd_index_page_ta_spec.rb
│   │   │       ├── quizzes_vdd_index_page_teacher_spec.rb
│   │   │       ├── quizzes_vdd_show_page_observer_spec.rb
│   │   │       ├── quizzes_vdd_show_page_student_spec.rb
│   │   │       ├── quizzes_vdd_show_page_ta_spec.rb
│   │   │       └── quizzes_vdd_show_page_teacher_spec.rb
│   │   ├── rcs
│   │   │   ├── alerts_spec.rb
│   │   │   ├── canvadoc_spec.rb
│   │   │   ├── discussion_group_submit_spec.rb
│   │   │   ├── discussions_post_grades_to_sis_spec.rb
│   │   │   ├── eportfolios_content_spec.rb
│   │   │   ├── eportfolios_spec.rb
│   │   │   ├── equation_spec.rb
│   │   │   ├── pages
│   │   │   │   ├── rce_next_page.rb
│   │   │   │   └── rcs_sidebar_page.rb
│   │   │   ├── rce_lite_spec.rb
│   │   │   ├── rce_next_autosave_spec.rb
│   │   │   ├── rce_next_spec.rb
│   │   │   ├── rce_next_toolbar_spec.rb
│   │   │   └── user_content_post_processing_spec.rb
│   │   ├── rubrics
│   │   │   ├── pages
│   │   │   │   ├── rubrics_assessment_tray.rb
│   │   │   │   ├── rubrics_form_page.rb
│   │   │   │   └── rubrics_index_page.rb
│   │   │   ├── peer_review_rubrics_spec.rb
│   │   │   ├── rubrics_form_spec.rb
│   │   │   ├── rubrics_index_spec.rb
│   │   │   └── speedgrader_rubrics_spec.rb
│   │   ├── sections
│   │   │   ├── section_teacher_tabs_spec.rb
│   │   │   └── sections_teacher_spec.rb
│   │   ├── shared_components
│   │   │   ├── commons_fav_tray.rb
│   │   │   ├── copy_to_tray_page.rb
│   │   │   └── send_to_dialog_page.rb
│   │   ├── sis
│   │   │   └── admin_settings_tab_spec.rb
│   │   ├── syllabus
│   │   │   ├── pages
│   │   │   │   └── syllabus_page.rb
│   │   │   ├── syllabus_features_spec.rb
│   │   │   └── syllabus_teacher_spec.rb
│   │   ├── test_setup
│   │   │   ├── JSErrorCollector.xpi
│   │   │   ├── common_helper_methods
│   │   │   │   ├── custom_alert_actions.rb
│   │   │   │   ├── custom_date_helpers.rb
│   │   │   │   ├── custom_page_loaders.rb
│   │   │   │   ├── custom_screen_actions.rb
│   │   │   │   ├── custom_search_context_methods.rb
│   │   │   │   ├── custom_selenium_actions.rb
│   │   │   │   ├── custom_validators.rb
│   │   │   │   ├── custom_wait_methods.rb
│   │   │   │   ├── login_and_session_methods.rb
│   │   │   │   ├── other_helper_methods.rb
│   │   │   │   └── state_poller.rb
│   │   │   ├── custom_selenium_rspec_matchers.rb
│   │   │   ├── patches
│   │   │   │   └── selenium
│   │   │   │       └── webdriver
│   │   │   │           └── remote
│   │   │   │               └── w3c
│   │   │   │                   └── bridge.rb
│   │   │   ├── selenium_driver_setup.rb
│   │   │   ├── selenium_extensions.rb
│   │   │   └── spec_friendly_web_server.rb
│   │   └── wiki
│   │       ├── wiki_and_tiny_student_files_rcenext_spec.rb
│   │       ├── wiki_and_tiny_student_spec.rb
│   │       ├── wiki_and_tiny_teacher_spec.rb
│   │       └── wiki_pages_spec.rb
│   ├── serializers
│   │   ├── attachment_serializer_spec.rb
│   │   ├── canvas
│   │   │   └── canvas_api_serializer_spec.rb
│   │   ├── late_policy_serializer_spec.rb
│   │   ├── live_events
│   │   │   ├── event_serializer_provider_spec.rb
│   │   │   └── external_tool_serializer_spec.rb
│   │   ├── lti
│   │   │   ├── ims
│   │   │   │   ├── line_items_serializer_spec.rb
│   │   │   │   ├── names_and_roles_serializer_spec.rb
│   │   │   │   └── results_serializer_spec.rb
│   │   │   └── tool_configuration_serializer_spec.rb
│   │   ├── progress_serializer_spec.rb
│   │   ├── quizzes
│   │   │   ├── quiz_api_serializer_spec.rb
│   │   │   ├── quiz_extension_serializer_spec.rb
│   │   │   ├── quiz_report_serializer_spec.rb
│   │   │   ├── quiz_serializer_spec.rb
│   │   │   └── quiz_statistics_serializer_spec.rb
│   │   └── quizzes_next
│   │       └── quiz_serializer_spec.rb
│   ├── services
│   │   ├── assignment_visibility
│   │   │   └── assignment_visibility_service_spec.rb
│   │   ├── auto_grade_comments_service_spec.rb
│   │   ├── auto_grade_service_spec.rb
│   │   ├── checkpoints
│   │   │   ├── adhoc_override_creator_service_spec.rb
│   │   │   ├── assignment_aggregator_service_spec.rb
│   │   │   ├── date_override_creator_service_spec.rb
│   │   │   ├── discussion_checkpoint_creator_service_spec.rb
│   │   │   ├── discussion_checkpoint_deleter_service_spec.rb
│   │   │   ├── discussion_checkpoint_updater_service_spec.rb
│   │   │   ├── group_override_creator_service_spec.rb
│   │   │   ├── section_override_creator_service_spec.rb
│   │   │   └── submission_aggregator_service_spec.rb
│   │   ├── course_pacing
│   │   │   ├── course_pace_service_spec.rb
│   │   │   ├── pace_contexts_service_spec.rb
│   │   │   ├── pace_service_spec.rb
│   │   │   ├── section_pace_service_spec.rb
│   │   │   └── student_enrollment_pace_service_spec.rb
│   │   ├── courses
│   │   │   └── off_pace
│   │   │       └── students
│   │   │           ├── reporter_spec.rb
│   │   │           └── validator_spec.rb
│   │   ├── differentiation_tag
│   │   │   ├── adhoc_override_creator_service_spec.rb
│   │   │   ├── converters
│   │   │   │   ├── context_module_override_converter_spec.rb
│   │   │   │   └── general_assignment_override_converter_spec.rb
│   │   │   └── override_converter_service_spec.rb
│   │   ├── flamegraphs
│   │   │   └── flamegraph_service_spec.rb
│   │   ├── inbox
│   │   │   ├── entities
│   │   │   │   └── inbox_settings_spec.rb
│   │   │   ├── inbox_service_spec.rb
│   │   │   └── repositories
│   │   │       └── inbox_settings_repository_spec.rb
│   │   ├── k5
│   │   │   ├── enablement_service_spec.rb
│   │   │   └── user_service_spec.rb
│   │   ├── login
│   │   │   └── login_brand_config_filter_spec.rb
│   │   ├── lti
│   │   │   ├── account_binding_service_spec.rb
│   │   │   ├── asset_processor_notifier_spec.rb
│   │   │   ├── create_registration_service_spec.rb
│   │   │   ├── list_registration_service_spec.rb
│   │   │   ├── log_service_spec.rb
│   │   │   ├── platform_notification_service_spec.rb
│   │   │   ├── tool_finder_spec.rb
│   │   │   └── update_registration_service_spec.rb
│   │   ├── module_visibility
│   │   │   ├── module_visibility_service_spec.rb
│   │   │   └── repositories
│   │   │       └── module_visible_to_student_repository_spec.rb
│   │   ├── quiz_visibility
│   │   │   └── quiz_visibility_service_spec.rb
│   │   ├── submissions
│   │   │   └── what_if_grades_service_spec.rb
│   │   ├── ungraded_discussion_visibility
│   │   │   └── ungraded_discussion_visibility_service_spec.rb
│   │   ├── video_caption_service_spec.rb
│   │   └── wiki_page_visibility
│   │       └── wiki_page_visibility_service_spec.rb
│   ├── sharding_spec_helper.rb
│   ├── shared_examples
│   │   ├── account_grade_status.rb
│   │   ├── anonymous_moderated_marking
│   │   │   └── authorization.rb
│   │   ├── learning_outcome_context.rb
│   │   ├── multiple_grading_periods_within_controller.rb
│   │   ├── provisional_grades.rb
│   │   ├── redo_submission.rb
│   │   ├── soft_deletion.rb
│   │   └── update_submission.rb
│   ├── simple_cov_result_merger.rb
│   ├── spec.opts
│   ├── spec_helper.rb
│   ├── support
│   │   ├── action_dispatch
│   │   │   └── test_response.rb
│   │   ├── blank_slate_protection.rb
│   │   ├── boolean_translator.rb
│   │   ├── call_stack_utils.rb
│   │   ├── cdn_registry_stubs.rb
│   │   ├── crystalball.rb
│   │   ├── custom_matchers
│   │   │   ├── README.md
│   │   │   ├── and_fragment.rb
│   │   │   ├── and_query.rb
│   │   │   ├── match_ignoring_whitespace.rb
│   │   │   ├── match_path.rb
│   │   │   ├── not_change.rb
│   │   │   ├── not_eq.rb
│   │   │   └── not_have_key.rb
│   │   ├── external_tools.rb
│   │   ├── great_expectations.rb
│   │   ├── inst_access_env.rb
│   │   ├── jwt_env.rb
│   │   ├── key_storage_helper.rb
│   │   ├── microsoft_sync
│   │   │   ├── errors.rb
│   │   │   ├── graph_service_endpoints.rb
│   │   │   └── url_logger.rb
│   │   ├── mock_static_site.rb
│   │   ├── mock_static_sites
│   │   │   └── sample_site
│   │   │       ├── file.txt
│   │   │       └── index.html
│   │   ├── names_and_roles_matchers.rb
│   │   ├── onceler
│   │   │   ├── noop.rb
│   │   │   └── sharding.rb
│   │   ├── openapi_generator.rb
│   │   ├── outcome_import_context.rb
│   │   ├── request_helper.rb
│   │   ├── sorted_by_matcher.rb
│   │   ├── spec_time_limit.rb
│   │   ├── test_database_utils.rb
│   │   └── verifiers_test_utils.rb
│   └── views
│       ├── accounts
│       │   ├── _sis_batch_counts.html.erb_spec.rb
│       │   └── settings.html.erb_spec.rb
│       ├── announcements
│       │   └── index.html.erb_spec.rb
│       ├── assignments
│       │   ├── _assignments_list_right_side.html.erb_spec.rb
│       │   ├── _grade_assignment.html.erb_spec.rb
│       │   ├── _submission_sidebar.html.erb_spec.rb
│       │   ├── _syllabus_content.html.erb_spec.rb
│       │   ├── edit.html.erb_spec.rb
│       │   ├── redirect_page.html.erb_spec.rb
│       │   ├── show.html.erb_spec.rb
│       │   ├── syllabus.html.erb_spec.rb
│       │   └── text_entry_page.html.erb_spec.rb
│       ├── authentication_providers
│       │   └── index.html.erb_spec.rb
│       ├── calendars
│       │   ├── _event.html.erb_spec.rb
│       │   ├── _mini_calendar.html.erb_spec.rb
│       │   └── show.html.erb_spec.rb
│       ├── collaborations
│       │   └── index.html.erb_spec.rb
│       ├── communication_channels
│       │   └── confirm.html.erb_spec.rb
│       ├── conferences
│       │   └── index.html.erb_spec.rb
│       ├── context
│       │   ├── _roster_right_side.html.erb_spec.rb
│       │   └── undelete_index.html.erb_spec.rb
│       ├── context_modules
│       │   ├── _module_item_conditional_next.erb_spec.rb
│       │   ├── _tool_sequence_footer.html.erb_spec.rb
│       │   ├── index.html.erb_spec.rb
│       │   ├── items_html.erb_spec.rb
│       │   ├── module_html.erb_spec.rb
│       │   └── url_show.html.erb_spec.rb
│       ├── courses
│       │   ├── _recent_event.html.erb_spec.rb
│       │   ├── _recent_feedback.html.erb_spec.rb
│       │   ├── _to_do_list.html.erb_spec.rb
│       │   ├── index.html.erb_spec.rb
│       │   ├── settings.html.erb_spec.rb
│       │   ├── settings_sidebar.html.erb_spec.rb
│       │   └── statistics.html.erb_spec.rb
│       ├── discussion_topics
│       │   ├── _entry.html.erb_spec.rb
│       │   └── show.html.erb_spec.rb
│       ├── enrollment_terms
│       │   └── index.html.erb_spec.rb
│       ├── eportfolios
│       │   ├── _page_section.html.erb_spec.rb
│       │   ├── show.html.erb_spec.rb
│       │   └── user_index.html.erb_spec.rb
│       ├── errors
│       │   └── index.html.erb_spec.rb
│       ├── files
│       │   ├── _nested_content.html.erb_spec.rb
│       │   └── show.html.erb_spec.rb
│       ├── form_options_helper_spec.rb
│       ├── gradebooks
│       │   ├── _grading_box.html.erb_spec.rb
│       │   ├── blank_submission.html.erb_spec.rb
│       │   ├── grade_summary.html.erb_spec.rb
│       │   ├── grade_summary_list.html.erb_spec.rb
│       │   ├── show_submissions_upload.html.erb_spec.rb
│       │   ├── speed_grader.html.erb_spec.rb
│       │   └── submissions_zip_upload.html.erb_spec.rb
│       ├── groups
│       │   ├── index.html.erb_spec.rb
│       │   └── show.html.erb_spec.rb
│       ├── layouts
│       │   └── application.html.erb_spec.rb
│       ├── login
│       │   ├── canvas
│       │   │   ├── new.html.erb_spec.rb
│       │   │   └── new_login.html.erb_spec.rb
│       │   └── otp
│       │       └── new.html.erb_spec.rb
│       ├── lti
│       │   └── full_width_launch.html.erb_spec.rb
│       ├── plugins
│       │   └── show.html.erb_spec.rb
│       ├── profile
│       │   ├── _email_select.html.erb_spec.rb
│       │   ├── _sms_select.html.erb_spec.rb
│       │   ├── _ways_to_contact.html.erb_spec.rb
│       │   └── profile.html.erb_spec.rb
│       ├── pseudonyms
│       │   └── confirm_change_password.html.erb_spec.rb
│       ├── quizzes
│       │   ├── quiz_submissions
│       │   │   └── show.html.erb_spec.rb
│       │   └── quizzes
│       │       ├── _display_answer.html.erb_spec.rb
│       │       ├── _display_question.html.erb_spec.rb
│       │       ├── _form_answer.html.erb_spec.rb
│       │       ├── _form_question.html.erb_spec.rb
│       │       ├── _multi_answer.html.erb_spec.rb
│       │       ├── _question_group.html.erb_spec.rb
│       │       ├── _quiz_edit.html.erb_spec.rb
│       │       ├── _quiz_right_side.html.erb_spec.rb
│       │       ├── _quiz_submission.html.erb_spec.rb
│       │       ├── _single_answer.html.erb_spec.rb
│       │       ├── _take_quiz_right_side.html.erb_spec.rb
│       │       ├── history.html.erb_spec.rb
│       │       ├── moderate.html.erb_spec.rb
│       │       ├── new.html.erb_spec.rb
│       │       ├── show.html.erb_spec.rb
│       │       ├── submission_versions.html.erb_spec.rb
│       │       └── take_quiz.html.erb_spec.rb
│       ├── sections
│       │   └── show.html.erb_spec.rb
│       ├── shared
│       │   ├── _auth_type_icon.html.erb_spec.rb
│       │   ├── _discussion_entry.html.erb_spec.rb
│       │   ├── _flash_notices.html.erb_spec.rb
│       │   ├── _grading_standard.html.erb_spec.rb
│       │   ├── _javascript_init.html.erb_spec.rb
│       │   ├── _new_nav_header.html.erb_spec.rb
│       │   ├── _originality_score_icon.html.erb_spec.rb
│       │   ├── _right_side.html.erb_spec.rb
│       │   ├── _rubric.html.erb_spec.rb
│       │   ├── _select_content_dialog.html.erb_spec.rb
│       │   ├── _user_lists.html.erb_spec.rb
│       │   ├── errors
│       │   │   ├── 400_message.html.erb_spec.rb
│       │   │   ├── 404_message.html.erb_spec.rb
│       │   │   ├── 500_message.html.erb_spec.rb
│       │   │   └── _error_form.html.erb_spec.rb
│       │   └── unauthorized.html.erb_spec.rb
│       ├── submissions
│       │   ├── show.html.erb_spec.rb
│       │   └── show_preview.html.erb_spec.rb
│       ├── terms
│       │   └── index.html.erb_spec.rb
│       ├── users
│       │   ├── _logins.html.erb_spec.rb
│       │   ├── _name.html.erb_spec.rb
│       │   ├── grades.html.erb_spec.rb
│       │   ├── new.html.erb_spec.rb
│       │   ├── show.html.erb_spec.rb
│       │   └── user_dashboard.html.erb_spec.rb
│       └── views_helper.rb
├── tmp
├── tree.txt
├── tsconfig.json
├── ui
│   ├── api.d.ts
│   ├── boot
│   │   ├── index.js
│   │   └── initializers
│   │       ├── __tests__
│   │       │   ├── configureDateTime.test.js
│   │       │   ├── configureDateTimeWithI18n.t3st.js
│   │       │   ├── enableDTNPI.test.js
│   │       │   ├── initMutexes.test.js
│   │       │   ├── installNodeDecorations.test.tsx
│   │       │   ├── router.test.tsx
│   │       │   └── setupCSP.test.js
│   │       ├── addBrowserClasses.js
│   │       ├── enableDTNPI.ts
│   │       ├── enableDTNPI.utils.ts
│   │       ├── expandAdminLinkMenusOnClick.js
│   │       ├── fakeRequireJSFallback.js
│   │       ├── initMutexes.js
│   │       ├── initSentry.ts
│   │       ├── installNodeDecorations.ts
│   │       ├── jst
│   │       │   ├── incompleteRegistrationWarning.handlebars
│   │       │   └── incompleteRegistrationWarning.handlebars.json
│   │       ├── monitorLtiMessages.ts
│   │       ├── ping.js
│   │       ├── renderRailsFlashNotifications.js
│   │       ├── router.tsx
│   │       ├── runOnEveryPageButDontBlockAnythingElse.jsx
│   │       ├── sanitizeCSSOverflow.js
│   │       ├── setWebpackCdnHost.js
│   │       ├── setupCSP.js
│   │       ├── showBadgeCounts.js
│   │       ├── toggleICSuperToggleWidgetsOnEnterKeyEvent.js
│   │       ├── trackPageViews.ts
│   │       ├── ujsLinks.js
│   │       └── warnOnIncompleteRegistration.js
│   ├── engine
│   │   ├── capabilities
│   │   │   ├── I18n
│   │   │   │   └── index.ts
│   │   │   ├── IntlPolyfills
│   │   │   │   └── index.ts
│   │   │   └── index.ts
│   │   ├── engine.d.ts
│   │   ├── index.ts
│   │   └── package.json
│   ├── ext
│   │   ├── custom_fullcalendar_locales
│   │   │   └── ga.js
│   │   ├── custom_moment_locales
│   │   │   ├── ca.js
│   │   │   ├── cy.js
│   │   │   ├── de.js
│   │   │   ├── fa.js
│   │   │   ├── he.js
│   │   │   ├── ht_ht.js
│   │   │   ├── hy_am.js
│   │   │   ├── ja.js
│   │   │   ├── mi_nz.js
│   │   │   ├── pl.js
│   │   │   ├── sl.js
│   │   │   └── zh_cn.js
│   │   └── custom_timezone_locales
│   │       ├── ar_SA.js
│   │       ├── ca_ES.js
│   │       ├── cy_GB.js
│   │       ├── da_DK.js
│   │       ├── de_DE.js
│   │       ├── el_GR.js
│   │       ├── fa_IR.js
│   │       ├── fr_CA.js
│   │       ├── fr_FR.js
│   │       ├── ga_IE.js
│   │       ├── he_IL.js
│   │       ├── hi_IN.js
│   │       ├── ht_HT.js
│   │       ├── hy_AM.js
│   │       ├── id_ID.js
│   │       ├── is_IS.js
│   │       ├── mi_NZ.js
│   │       ├── ms_MY.js
│   │       ├── nn_NO.js
│   │       ├── pl_PL.js
│   │       ├── th_TH.js
│   │       ├── tr_TR.js
│   │       └── uk_UA.js
│   ├── featureBundles.ts
│   ├── features
│   │   ├── acceptable_use_policy
│   │   │   ├── components
│   │   │   │   ├── AcceptableUsePolicy.module.css
│   │   │   │   ├── AcceptableUsePolicy.tsx
│   │   │   │   └── __tests__
│   │   │   │       └── AcceptableUsePolicy.test.tsx
│   │   │   ├── hooks
│   │   │   │   ├── __tests__
│   │   │   │   │   └── useAUPContent.test.ts
│   │   │   │   └── useAUPContent.ts
│   │   │   ├── layouts
│   │   │   │   ├── AUPLayout.tsx
│   │   │   │   └── __tests__
│   │   │   │       └── AUPLayout.test.tsx
│   │   │   ├── package.json
│   │   │   └── routes
│   │   │       ├── AUPRoutes.tsx
│   │   │       └── __tests__
│   │   │           └── AUPRoutes.test.tsx
│   │   ├── accessibility_checker
│   │   │   ├── index.tsx
│   │   │   └── react
│   │   │       ├── components
│   │   │       │   ├── AccessibilityCheckerApp
│   │   │       │   │   └── AccessibilityCheckerApp.tsx
│   │   │       │   └── AccessibilityIssuesModal
│   │   │       │       └── AccessibilityIssuesModal.tsx
│   │   │       ├── index.tsx
│   │   │       └── types.ts
│   │   ├── account_admin_tools
│   │   │   ├── backbone
│   │   │   │   ├── collections
│   │   │   │   │   ├── AccountUserCollection.js
│   │   │   │   │   ├── AuthLoggingCollection.js
│   │   │   │   │   ├── CommMessageCollection.js
│   │   │   │   │   ├── CourseLoggingCollection.js
│   │   │   │   │   └── GradeChangeLoggingCollection.js
│   │   │   │   ├── models
│   │   │   │   │   ├── AccountUser.js
│   │   │   │   │   ├── CourseEvent.js
│   │   │   │   │   ├── CourseRestore.js
│   │   │   │   │   ├── UserRestore.js
│   │   │   │   │   └── __tests__
│   │   │   │   │       ├── CourseRestore.test.js
│   │   │   │   │       └── UserRestore.test.js
│   │   │   │   └── views
│   │   │   │       ├── AdminToolsView.js
│   │   │   │       ├── AuthLoggingContentPaneView.js
│   │   │   │       ├── AuthLoggingItemView.js
│   │   │   │       ├── CommMessageItemView.js
│   │   │   │       ├── CommMessagesContentPaneView.js
│   │   │   │       ├── CourseLoggingContentView.jsx
│   │   │   │       ├── CourseLoggingItemView.js
│   │   │   │       ├── CourseSearchResultsView.js
│   │   │   │       ├── GradeChangeLoggingContentView.jsx
│   │   │   │       ├── GradeChangeLoggingItemView.js
│   │   │   │       ├── GraphQLMutationContentView.jsx
│   │   │   │       ├── LoggingContentPaneView.js
│   │   │   │       ├── RestoreContentPaneView.jsx
│   │   │   │       ├── UserDateRangeSearchFormView.jsx
│   │   │   │       ├── UserSearchResultsView.js
│   │   │   │       ├── UserView.js
│   │   │   │       └── __tests__
│   │   │   │           ├── AdminToolsView.test.js
│   │   │   │           ├── CourseSearchResultsView.test.js
│   │   │   │           └── UserSearchResultsView.test.js
│   │   │   ├── index.jsx
│   │   │   ├── jst
│   │   │   │   ├── AdminTools.handlebars
│   │   │   │   ├── AdminTools.handlebars.json
│   │   │   │   ├── CourseSearchResults.handlebars
│   │   │   │   ├── CourseSearchResults.handlebars.json
│   │   │   │   ├── RestoreContentPane.handlebars
│   │   │   │   ├── RestoreContentPane.handlebars.json
│   │   │   │   ├── UserSearchResults.handlebars
│   │   │   │   ├── UserSearchResults.handlebars.json
│   │   │   │   ├── authLoggingContentPane.handlebars
│   │   │   │   ├── authLoggingContentPane.handlebars.json
│   │   │   │   ├── authLoggingItem.handlebars
│   │   │   │   ├── authLoggingItem.handlebars.json
│   │   │   │   ├── authLoggingSearchResults.handlebars
│   │   │   │   ├── authLoggingSearchResults.handlebars.json
│   │   │   │   ├── commMessageItem.handlebars
│   │   │   │   ├── commMessageItem.handlebars.json
│   │   │   │   ├── commMessagesContentPane.handlebars
│   │   │   │   ├── commMessagesContentPane.handlebars.json
│   │   │   │   ├── commMessagesSearchOverview.handlebars
│   │   │   │   ├── commMessagesSearchOverview.handlebars.json
│   │   │   │   ├── commMessagesSearchResults.handlebars
│   │   │   │   ├── commMessagesSearchResults.handlebars.json
│   │   │   │   ├── courseLoggingContent.handlebars
│   │   │   │   ├── courseLoggingContent.handlebars.json
│   │   │   │   ├── courseLoggingItem.handlebars
│   │   │   │   ├── courseLoggingItem.handlebars.json
│   │   │   │   ├── courseLoggingResults.handlebars
│   │   │   │   ├── courseLoggingResults.handlebars.json
│   │   │   │   ├── gradeChangeLoggingContent.handlebars
│   │   │   │   ├── gradeChangeLoggingContent.handlebars.json
│   │   │   │   ├── gradeChangeLoggingItem.handlebars
│   │   │   │   ├── gradeChangeLoggingItem.handlebars.json
│   │   │   │   ├── gradeChangeLoggingResults.handlebars
│   │   │   │   ├── gradeChangeLoggingResults.handlebars.json
│   │   │   │   ├── loggingContentPane.handlebars
│   │   │   │   ├── loggingContentPane.handlebars.json
│   │   │   │   ├── user.handlebars
│   │   │   │   ├── user.handlebars.json
│   │   │   │   ├── userDateRangeSearchForm.handlebars
│   │   │   │   ├── userDateRangeSearchForm.handlebars.json
│   │   │   │   ├── usersList.handlebars
│   │   │   │   └── usersList.handlebars.json
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── BouncedEmailsView.jsx
│   │   │       ├── CourseActivityDetails.tsx
│   │   │       ├── CourseActivityForm.tsx
│   │   │       ├── EntitySearchForm.tsx
│   │   │       ├── GradeChangeActivityForm.tsx
│   │   │       ├── MutationAuditLog.tsx
│   │   │       ├── UserDateRangeSearch.tsx
│   │   │       └── __tests__
│   │   │           ├── CourseActivityDetails.test.tsx
│   │   │           ├── CourseActivityForm.test.tsx
│   │   │           ├── EntitySearchForm.test.tsx
│   │   │           ├── GradeChangeActivityForm.test.tsx
│   │   │           ├── MutationAuditLog.test.jsx
│   │   │           └── UserDateRangeSearch.test.tsx
│   │   ├── account_calendar_settings
│   │   │   ├── index.tsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── components
│   │   │       │   ├── AccountCalendarItem.tsx
│   │   │       │   ├── AccountCalendarItemToggleGroup.tsx
│   │   │       │   ├── AccountCalendarSettings.tsx
│   │   │       │   ├── AccountList.tsx
│   │   │       │   ├── AccountTree.tsx
│   │   │       │   ├── ConfirmationModal.tsx
│   │   │       │   ├── FilterControls.tsx
│   │   │       │   ├── Footer.tsx
│   │   │       │   ├── SubscriptionDropDown.tsx
│   │   │       │   └── __tests__
│   │   │       │       ├── AccountCalendarSettings.test.tsx
│   │   │       │       ├── AccountList.test.tsx
│   │   │       │       ├── AccountTree.test.tsx
│   │   │       │       ├── ConfirmationModal.test.tsx
│   │   │       │       ├── FilterControls.test.tsx
│   │   │       │       ├── Footer.test.tsx
│   │   │       │       ├── SubscriptionDropDown.test.tsx
│   │   │       │       └── fixtures.ts
│   │   │       ├── theme.ts
│   │   │       ├── types.ts
│   │   │       └── utils.ts
│   │   ├── account_course_user_search
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── actions
│   │   │       │   ├── TabActions.js
│   │   │       │   ├── UserActions.js
│   │   │       │   └── __tests__
│   │   │       │       └── actions.spec.js
│   │   │       ├── components
│   │   │       │   ├── CoursesList.jsx
│   │   │       │   ├── CoursesListHeader.jsx
│   │   │       │   ├── CoursesListRow.jsx
│   │   │       │   ├── CoursesPane.jsx
│   │   │       │   ├── CoursesToolbar.jsx
│   │   │       │   ├── CreateDSRModal.jsx
│   │   │       │   ├── CreateOrUpdateUserModal.jsx
│   │   │       │   ├── NewCourseModal.tsx
│   │   │       │   ├── SRSearchMessage.jsx
│   │   │       │   ├── SearchMessage.jsx
│   │   │       │   ├── SearchableSelect.jsx
│   │   │       │   ├── UserLink.tsx
│   │   │       │   ├── UsersList.jsx
│   │   │       │   ├── UsersListHeader.jsx
│   │   │       │   ├── UsersListRow.jsx
│   │   │       │   ├── UsersPane.jsx
│   │   │       │   ├── UsersToolbar.jsx
│   │   │       │   └── __tests__
│   │   │       │       ├── CoursesList.test.jsx
│   │   │       │       ├── CoursesListRow.test.jsx
│   │   │       │       ├── CoursesPane.test.jsx
│   │   │       │       ├── CoursesToolbar.test.jsx
│   │   │       │       ├── CreateDSRModal.test.jsx
│   │   │       │       ├── NewCourseModal.test.tsx
│   │   │       │       ├── SRSearchMessage.test.jsx
│   │   │       │       ├── SearchMessage.test.jsx
│   │   │       │       ├── SearchableSelect.test.jsx
│   │   │       │       ├── UsersListSpec.test.jsx
│   │   │       │       ├── UsersPane.test.jsx
│   │   │       │       └── UsersToolbar.test.jsx
│   │   │       ├── helpers
│   │   │       │   ├── __tests__
│   │   │       │   │   └── permissionFilter.spec.js
│   │   │       │   └── permissionFilter.js
│   │   │       ├── index.jsx
│   │   │       ├── reducers
│   │   │       │   ├── __tests__
│   │   │       │   │   └── rootReducer.test.js
│   │   │       │   └── rootReducer.js
│   │   │       ├── router.js
│   │   │       └── store
│   │   │           ├── AccountsTreeStore.js
│   │   │           ├── CoursesStore.js
│   │   │           ├── TermsStore.js
│   │   │           ├── UsersStore.js
│   │   │           ├── __tests__
│   │   │           │   ├── CoursesStore.test.js
│   │   │           │   ├── UsersStore.test.js
│   │   │           │   └── createStore.test.js
│   │   │           ├── configureStore.js
│   │   │           ├── createStore.js
│   │   │           ├── initialState.js
│   │   │           └── tabList.js
│   │   ├── account_grading_settings
│   │   │   ├── components
│   │   │   │   ├── account_grading_status
│   │   │   │   │   ├── AccountStatusManagement.tsx
│   │   │   │   │   ├── ColorPicker.tsx
│   │   │   │   │   ├── CustomStatusItem.tsx
│   │   │   │   │   ├── CustomStatusNewItem.tsx
│   │   │   │   │   ├── EditStatusPopover.tsx
│   │   │   │   │   ├── StandardStatusItem.tsx
│   │   │   │   │   └── __tests__
│   │   │   │   │       ├── AccountStatusManagement.test.tsx
│   │   │   │   │       └── fixtures.ts
│   │   │   │   └── grading_period
│   │   │   │       ├── AccountGradingPeriod.jsx
│   │   │   │       ├── EditGradingPeriodSetForm.jsx
│   │   │   │       ├── EnrollmentTermInput.jsx
│   │   │   │       ├── EnrollmentTermsDropdown.jsx
│   │   │   │       ├── GradingPeriodForm.jsx
│   │   │   │       ├── GradingPeriodSet.jsx
│   │   │   │       ├── GradingPeriodSetCollection.jsx
│   │   │   │       ├── NewGradingPeriodSetForm.jsx
│   │   │   │       ├── SearchGradingPeriodsField.jsx
│   │   │   │       ├── __tests__
│   │   │   │       │   └── AccountGradingPeriod.test.jsx
│   │   │   │       └── enrollmentTermsApi.js
│   │   │   ├── graphql
│   │   │   │   ├── mutations
│   │   │   │   │   └── GradingStatusMutations.ts
│   │   │   │   └── queries
│   │   │   │       └── GradingStatusQueries.ts
│   │   │   ├── hooks
│   │   │   │   └── useAccountGradingStatuses.tsx
│   │   │   ├── package.json
│   │   │   ├── pages
│   │   │   │   ├── AccountGradingPeriods.tsx
│   │   │   │   ├── AccountGradingSchemes.tsx
│   │   │   │   ├── AccountGradingStatuses.tsx
│   │   │   │   └── TabLayout.tsx
│   │   │   ├── routes
│   │   │   │   └── accountGradingSettingsRoutes.tsx
│   │   │   ├── types
│   │   │   │   ├── accountStatusMutations.ts
│   │   │   │   ├── accountStatusQueries.ts
│   │   │   │   └── tabLayout.ts
│   │   │   └── utils
│   │   │       └── accountStatusUtils.ts
│   │   ├── account_grading_standards
│   │   │   ├── __tests__
│   │   │   │   └── enrollmentTermsApi.test.js
│   │   │   ├── enrollmentTermsApi.js
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── AccountGradingPeriod.jsx
│   │   │       ├── AccountTabContainer.jsx
│   │   │       ├── EditGradingPeriodSetForm.jsx
│   │   │       ├── EnrollmentTermInput.jsx
│   │   │       ├── EnrollmentTermsDropdown.jsx
│   │   │       ├── GradingPeriodForm.jsx
│   │   │       ├── GradingPeriodSet.jsx
│   │   │       ├── GradingPeriodSetCollection.jsx
│   │   │       ├── NewGradingPeriodSetForm.jsx
│   │   │       ├── SearchGradingPeriodsField.jsx
│   │   │       └── __tests__
│   │   │           ├── AccountTabContainer.test.jsx
│   │   │           ├── EditGradingPeriodSetForm.test.jsx
│   │   │           ├── EnrollmentTermInput.test.jsx
│   │   │           ├── EnrollmentTermsDropdown.test.jsx
│   │   │           ├── GradingPeriodForm.test.jsx
│   │   │           ├── GradingPeriodSet1.test.jsx
│   │   │           ├── GradingPeriodSet2.test.jsx
│   │   │           ├── GradingPeriodSet3.test.jsx
│   │   │           ├── GradingPeriodSet4.test.jsx
│   │   │           └── SearchGradingPeriodsField.test.jsx
│   │   ├── account_manage
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── AccountList.tsx
│   │   │       ├── AccountListRoute.tsx
│   │   │       ├── AccountNavigation.tsx
│   │   │       └── __tests__
│   │   │           ├── AccountList.test.tsx
│   │   │           └── AccountNavigation.test.tsx
│   │   ├── account_notification_settings
│   │   │   ├── graphql
│   │   │   │   ├── Mutations.js
│   │   │   │   └── Queries.js
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── AccountNotificationSettingsManager.jsx
│   │   │       ├── AccountNotificationSettingsQuery.jsx
│   │   │       ├── AccountNotificationSettingsView.jsx
│   │   │       ├── __tests__
│   │   │       │   └── AccountNotificationSettingsView.test.jsx
│   │   │       └── index.jsx
│   │   ├── account_search
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── account_settings
│   │   │   ├── index.jsx
│   │   │   ├── jquery
│   │   │   │   ├── __tests__
│   │   │   │   │   └── accountSettings.test.js
│   │   │   │   ├── global_announcements.js
│   │   │   │   └── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── AccountSettingsRoute.tsx
│   │   │       ├── __tests__
│   │   │       │   ├── ReportDescription.test.tsx
│   │   │       │   ├── RunReportForm.test.tsx
│   │   │       │   ├── __snapshots__
│   │   │       │   │   └── actions.test.js.snap
│   │   │       │   ├── actions.test.js
│   │   │       │   ├── index.test.js
│   │   │       │   └── reducers.test.js
│   │   │       ├── account_reports
│   │   │       │   ├── ReportDescription.tsx
│   │   │       │   └── RunReportForm.tsx
│   │   │       ├── actions.js
│   │   │       ├── components
│   │   │       │   ├── OpenRegistrationWarning.tsx
│   │   │       │   ├── QuizIPFilters.tsx
│   │   │       │   ├── RQDModal.tsx
│   │   │       │   ├── SecurityPanel.jsx
│   │   │       │   ├── ServiceDescriptionModal.tsx
│   │   │       │   ├── Whitelist.jsx
│   │   │       │   └── __tests__
│   │   │       │       ├── QuizIPFilters.test.tsx
│   │   │       │       ├── SecurityPanel.test.jsx
│   │   │       │       ├── Whitelist.test.jsx
│   │   │       │       └── utils.jsx
│   │   │       ├── course_creation_settings
│   │   │       │   ├── CourseCreationSettings.jsx
│   │   │       │   └── __tests__
│   │   │       │       └── CourseCreationSettings.test.jsx
│   │   │       ├── custom_emoji_deny_list
│   │   │       │   ├── CustomEmojiDenyList.jsx
│   │   │       │   └── __tests__
│   │   │       │       └── CustomEmojiDenyList.test.jsx
│   │   │       ├── custom_help_link_settings
│   │   │       │   ├── CustomHelpLink.jsx
│   │   │       │   ├── CustomHelpLinkAction.jsx
│   │   │       │   ├── CustomHelpLinkConstants.js
│   │   │       │   ├── CustomHelpLinkForm.jsx
│   │   │       │   ├── CustomHelpLinkHiddenInputs.jsx
│   │   │       │   ├── CustomHelpLinkIconInput.jsx
│   │   │       │   ├── CustomHelpLinkIcons.jsx
│   │   │       │   ├── CustomHelpLinkMenu.jsx
│   │   │       │   ├── CustomHelpLinkPropTypes.js
│   │   │       │   ├── CustomHelpLinkSettings.jsx
│   │   │       │   └── __tests__
│   │   │       │       ├── CustomHelpLink.test.jsx
│   │   │       │       ├── CustomHelpLinkForm.test.jsx
│   │   │       │       └── CustomHelpLinkSettings.test.jsx
│   │   │       ├── index.jsx
│   │   │       ├── internal_settings
│   │   │       │   ├── InternalSettings.tsx
│   │   │       │   ├── InternalSettingsManager.tsx
│   │   │       │   ├── InternalSettingsQuery.tsx
│   │   │       │   ├── InternalSettingsView.tsx
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── InternalSettingsView.test.tsx
│   │   │       │   │   └── table
│   │   │       │   │       ├── EditableCodeValue.test.tsx
│   │   │       │   │       └── InternalSettingActionButtons.test.tsx
│   │   │       │   ├── graphql
│   │   │       │   │   ├── Mutations.ts
│   │   │       │   │   └── Queries.ts
│   │   │       │   ├── table
│   │   │       │   │   ├── EditableCodeValue.tsx
│   │   │       │   │   ├── InternalSettingActionButtons.tsx
│   │   │       │   │   └── InternalSettingsTable.tsx
│   │   │       │   └── types.ts
│   │   │       ├── notification_settings
│   │   │       │   ├── __tests__
│   │   │       │   │   └── index.test.tsx
│   │   │       │   └── index.tsx
│   │   │       ├── quotas
│   │   │       │   ├── DefaultAccountQuotas.tsx
│   │   │       │   ├── ManuallySettableQuotas.tsx
│   │   │       │   ├── QuotasTabContent.tsx
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── DefaultAccountQuotas.test.tsx
│   │   │       │   │   └── ManuallySettableQuotas.test.tsx
│   │   │       │   └── common.ts
│   │   │       ├── reducers.js
│   │   │       └── store.js
│   │   ├── account_statistics
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── index.js
│   │   │   └── package.json
│   │   ├── act_as_modal
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── ActAsModal.jsx
│   │   │       ├── ActAsModalRoute.tsx
│   │   │       ├── __tests__
│   │   │       │   ├── ActAsModal.test.jsx
│   │   │       │   └── __snapshots__
│   │   │       │       └── ActAsModal.test.jsx.snap
│   │   │       └── svg
│   │   │           ├── ActAsMask.jsx
│   │   │           └── ActAsPanda.jsx
│   │   ├── admin_split
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── __tests__
│   │   │       │   └── index.test.jsx
│   │   │       └── index.jsx
│   │   ├── all_courses
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── analytics_hub
│   │   │   ├── index.jsx
│   │   │   └── package.json
│   │   ├── announcements
│   │   │   ├── images
│   │   │   │   └── announcements-airhorn.svg
│   │   │   ├── index.js
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── __tests__
│   │   │       │   ├── actions.test.js
│   │   │       │   ├── apiClient.test.js
│   │   │       │   ├── index.test.js
│   │   │       │   └── reducer.spec.js
│   │   │       ├── actions.js
│   │   │       ├── apiClient.js
│   │   │       ├── components
│   │   │       │   ├── AddExternalFeed.jsx
│   │   │       │   ├── AnnouncementEmptyState.jsx
│   │   │       │   ├── AnnouncementsIndex.jsx
│   │   │       │   ├── ConfirmDeleteModal.jsx
│   │   │       │   ├── ExternalFeedsTray.jsx
│   │   │       │   ├── IndexHeader.jsx
│   │   │       │   ├── RSSFeedList.jsx
│   │   │       │   └── __tests__
│   │   │       │       ├── AddExternalFeed.test.jsx
│   │   │       │       ├── AnnouncementEmptyState.test.jsx
│   │   │       │       ├── AnnouncementsIndex.test.jsx
│   │   │       │       ├── ConfirmDeleteModal.test.jsx
│   │   │       │       ├── ExternalFeedsTray.test.jsx
│   │   │       │       ├── IndexHeader.test.jsx
│   │   │       │       ├── IndexHeaderSpec.test.jsx
│   │   │       │       └── RSSFeedList.test.jsx
│   │   │       ├── index.jsx
│   │   │       ├── propTypes.js
│   │   │       ├── reducer.js
│   │   │       └── store.js
│   │   ├── announcements_on_home_page
│   │   │   ├── index.jsx
│   │   │   └── package.json
│   │   ├── assignment_edit
│   │   │   ├── backbone
│   │   │   │   └── views
│   │   │   │       ├── EditHeaderView.jsx
│   │   │   │       ├── EditView.jsx
│   │   │   │       ├── TurnitinSettingsDialog.jsx
│   │   │   │       └── __tests__
│   │   │   │           ├── EditHeaderView.test.js
│   │   │   │           ├── EditView1.test.jsx
│   │   │   │           ├── EditView2.test.jsx
│   │   │   │           ├── EditView3.test.jsx
│   │   │   │           ├── EditView4.test.jsx
│   │   │   │           ├── EditView5.test.jsx
│   │   │   │           └── EditView6.test.jsx
│   │   │   ├── index.js
│   │   │   ├── jst
│   │   │   │   ├── EditHeaderView.handlebars
│   │   │   │   ├── EditHeaderView.handlebars.json
│   │   │   │   ├── EditView.handlebars
│   │   │   │   ├── EditView.handlebars.json
│   │   │   │   ├── TurnitinSettingsDialog.handlebars
│   │   │   │   ├── TurnitinSettingsDialog.handlebars.json
│   │   │   │   ├── VeriCiteSettingsDialog.handlebars
│   │   │   │   ├── VeriCiteSettingsDialog.handlebars.json
│   │   │   │   ├── _submission_types_form.handlebars
│   │   │   │   └── _submission_types_form.handlebars.json
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── AssetProcessors.tsx
│   │   │       ├── AssetProcessorsAddModal.tsx
│   │   │       ├── AssetProcessorsCards.tsx
│   │   │       ├── AssignmentConfigurationTools.jsx
│   │   │       ├── AssignmentSubmissionTypeContainer.tsx
│   │   │       ├── AssignmentSubmissionTypeSelectionLaunchButton.tsx
│   │   │       ├── AssignmentSubmissionTypeSelectionResourceLinkCard.tsx
│   │   │       ├── DefaultToolForm.jsx
│   │   │       ├── EditAssignment.jsx
│   │   │       ├── FinalGraderSelectMenu.jsx
│   │   │       ├── GraderCommentVisibilityCheckbox.jsx
│   │   │       ├── GraderCountNumberInput.jsx
│   │   │       ├── GraderNamesVisibleToFinalGraderCheckbox.jsx
│   │   │       ├── ModeratedGradingCheckbox.jsx
│   │   │       ├── ModeratedGradingFormFieldGroup.jsx
│   │   │       ├── OriginalityReportVisibilityPicker.jsx
│   │   │       ├── __tests__
│   │   │       │   ├── AssetProcessors.test.tsx
│   │   │       │   ├── AssetProcessorsAddModal1.test.tsx
│   │   │       │   ├── AssetProcessorsAddModal2.test.tsx
│   │   │       │   ├── AssignmentConfigurationTools.test.jsx
│   │   │       │   ├── AssignmentSubmissionTypeContainer.test.jsx
│   │   │       │   ├── AssignmentSubmissionTypeSelectionLaunchButton.test.jsx
│   │   │       │   ├── AssignmentSubmissionTypeSelectionResourceLinkCard.test.jsx
│   │   │       │   ├── DefaultToolForm.test.jsx
│   │   │       │   ├── EditAssignment.test.jsx
│   │   │       │   ├── FinalGraderSelectMenu.test.jsx
│   │   │       │   ├── GraderCommentVisibilityCheckbox.test.jsx
│   │   │       │   ├── GraderCountNumberInput.test.jsx
│   │   │       │   ├── GraderNamesVisibleToFinalGraderCheckbox.test.jsx
│   │   │       │   ├── ModeratedGradingCheckbox.test.jsx
│   │   │       │   ├── ModeratedGradingFormFieldGroup.test.jsx
│   │   │       │   ├── OriginalityReportVisibilityPicker.test.jsx
│   │   │       │   └── assetProcessorsTestHelpers.ts
│   │   │       ├── allowed_attempts
│   │   │       │   ├── AllowedAttempts.jsx
│   │   │       │   ├── AllowedAttemptsWithState.jsx
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── AllowedAttempts.test.jsx
│   │   │       │   │   └── useAllowedAttemptsState.test.js
│   │   │       │   └── useAllowedAttemptsState.js
│   │   │       ├── components
│   │   │       │   ├── TeacherCreateEditView.tsx
│   │   │       │   ├── TeacherCreateQuery.tsx
│   │   │       │   └── TeacherEditQuery.tsx
│   │   │       ├── hooks
│   │   │       │   ├── AssetProcessorsAddModalState.ts
│   │   │       │   ├── AssetProcessorsState.ts
│   │   │       │   ├── useAssetProcessorsToolsList.ts
│   │   │       │   └── usePostMessage.js
│   │   │       └── index.tsx
│   │   ├── assignment_grade_summary
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── ReducerHelpers.js
│   │   │       ├── __tests__
│   │   │       │   └── getEnv.spec.js
│   │   │       ├── assignment
│   │   │       │   ├── AssignmentActions.js
│   │   │       │   ├── AssignmentApi.js
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── AssignmentActions.test.js
│   │   │       │   │   ├── AssignmentApi.spec.js
│   │   │       │   │   └── assignmentReducer.spec.js
│   │   │       │   └── buildAssignmentReducer.js
│   │   │       ├── components
│   │   │       │   ├── FlashMessageHolder.js
│   │   │       │   ├── FocusableView.jsx
│   │   │       │   ├── GradersTable
│   │   │       │   │   ├── AcceptGradesButton.jsx
│   │   │       │   │   ├── __tests__
│   │   │       │   │   │   └── AcceptGradesButton.test.jsx
│   │   │       │   │   └── index.jsx
│   │   │       │   ├── GradesGrid
│   │   │       │   │   ├── GradeIndicator.jsx
│   │   │       │   │   ├── GradeSelect.jsx
│   │   │       │   │   ├── Grid.jsx
│   │   │       │   │   ├── GridRow.jsx
│   │   │       │   │   ├── PageNavigation.jsx
│   │   │       │   │   ├── __tests__
│   │   │       │   │   │   ├── GradeIndicator.test.jsx
│   │   │       │   │   │   ├── GradeSelect.test.jsx
│   │   │       │   │   │   ├── Grid.test.jsx
│   │   │       │   │   │   ├── GridRow.test.jsx
│   │   │       │   │   │   └── PageNavigation.test.jsx
│   │   │       │   │   └── index.jsx
│   │   │       │   ├── Header.jsx
│   │   │       │   ├── Layout.jsx
│   │   │       │   ├── PostToStudentsButton.jsx
│   │   │       │   ├── ReleaseButton.jsx
│   │   │       │   └── __tests__
│   │   │       │       ├── FlashMessageHolder.test.jsx
│   │   │       │       ├── FocusableView.test.jsx
│   │   │       │       ├── GradersTable.test.jsx
│   │   │       │       ├── GradesGrid.test.jsx
│   │   │       │       ├── Header.test.jsx
│   │   │       │       ├── Layout.test.jsx
│   │   │       │       ├── PostToStudentsButton.test.jsx
│   │   │       │       └── ReleaseButton.test.jsx
│   │   │       ├── configureStore.js
│   │   │       ├── getEnv.js
│   │   │       ├── grades
│   │   │       │   ├── GradeActions.js
│   │   │       │   ├── GradesApi.js
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── GradeActions.test.js
│   │   │       │   │   ├── GradesApi.spec.js
│   │   │       │   │   └── gradesReducer.spec.js
│   │   │       │   └── gradesReducer.js
│   │   │       ├── index.jsx
│   │   │       └── students
│   │   │           ├── StudentActions.js
│   │   │           ├── StudentsApi.js
│   │   │           ├── __tests__
│   │   │           │   ├── StudentsApi.spec.js
│   │   │           │   └── studentsReducer.spec.js
│   │   │           └── studentsReducer.js
│   │   ├── assignment_index
│   │   │   ├── __tests__
│   │   │   │   └── cache.spec.js
│   │   │   ├── backbone
│   │   │   │   ├── collections
│   │   │   │   │   ├── NeverDropCollection.js
│   │   │   │   │   ├── UniqueDropdownCollection.js
│   │   │   │   │   └── __tests__
│   │   │   │   │       ├── NeverDropCollection.spec.js
│   │   │   │   │       └── UniqueDropdownCollection.spec.js
│   │   │   │   ├── mixins
│   │   │   │   │   └── AssignmentKeyBindingsMixin.js
│   │   │   │   └── views
│   │   │   │       ├── AssignmentGroupListItemView.jsx
│   │   │   │       ├── AssignmentGroupListView.js
│   │   │   │       ├── AssignmentGroupWeightsView.jsx
│   │   │   │       ├── AssignmentListItemView.jsx
│   │   │   │       ├── AssignmentSettingsView.jsx
│   │   │   │       ├── AssignmentSyncSettingsView.js
│   │   │   │       ├── CreateAssignmentView.js
│   │   │   │       ├── CreateAssignmentViewAdapter.jsx
│   │   │   │       ├── CreateGroupView.jsx
│   │   │   │       ├── DeleteGroupView.jsx
│   │   │   │       ├── DraggableCollectionView.js
│   │   │   │       ├── IndexView.jsx
│   │   │   │       ├── NeverDropCollectionView.js
│   │   │   │       ├── NeverDropView.js
│   │   │   │       ├── SortableCollectionView.js
│   │   │   │       ├── ToggleShowByView.jsx
│   │   │   │       └── __tests__
│   │   │   │           ├── AssignmentGroupListItemView.test.js
│   │   │   │           ├── AssignmentIndex.test.js
│   │   │   │           ├── AssignmentListItemView.test.js
│   │   │   │           ├── AssignmentSettingsView.test.js
│   │   │   │           ├── AssignmentSyncSettingsView.spec.js
│   │   │   │           ├── CreateAssignmentView.test.js
│   │   │   │           ├── CreateAssignmentViewAdapter.test.jsx
│   │   │   │           ├── CreateGroupView1.test.js
│   │   │   │           ├── CreateGroupView2.test.js
│   │   │   │           ├── DeleteGroupView.test.js
│   │   │   │           ├── NeverDropCollectionView.test.js
│   │   │   │           └── ToggleShowByView.test.js
│   │   │   ├── cache.js
│   │   │   ├── helpers
│   │   │   │   ├── __tests__
│   │   │   │   │   └── deepLinkingHelper.spec.ts
│   │   │   │   └── deepLinkingHelper.ts
│   │   │   ├── index.jsx
│   │   │   ├── jst
│   │   │   │   ├── AssignmentGroupList.handlebars
│   │   │   │   ├── AssignmentGroupList.handlebars.json
│   │   │   │   ├── AssignmentGroupListItem.handlebars
│   │   │   │   ├── AssignmentGroupListItem.handlebars.json
│   │   │   │   ├── AssignmentGroupWeights.handlebars
│   │   │   │   ├── AssignmentGroupWeights.handlebars.json
│   │   │   │   ├── AssignmentListItem.handlebars
│   │   │   │   ├── AssignmentListItem.handlebars.json
│   │   │   │   ├── AssignmentSettings.handlebars
│   │   │   │   ├── AssignmentSettings.handlebars.json
│   │   │   │   ├── AssignmentSyncSettings.handlebars
│   │   │   │   ├── AssignmentSyncSettings.handlebars.json
│   │   │   │   ├── CreateAssignment.handlebars
│   │   │   │   ├── CreateAssignment.handlebars.json
│   │   │   │   ├── CreateGroup.handlebars
│   │   │   │   ├── CreateGroup.handlebars.json
│   │   │   │   ├── DeleteGroup.handlebars
│   │   │   │   ├── DeleteGroup.handlebars.json
│   │   │   │   ├── IndexView.handlebars
│   │   │   │   ├── IndexView.handlebars.json
│   │   │   │   ├── NeverDrop.handlebars
│   │   │   │   ├── NeverDrop.handlebars.json
│   │   │   │   ├── NeverDropCollection.handlebars
│   │   │   │   ├── NeverDropCollection.handlebars.json
│   │   │   │   ├── NoAssignmentsListItem.handlebars
│   │   │   │   ├── NoAssignmentsListItem.handlebars.json
│   │   │   │   ├── NoAssignmentsSearch.handlebars
│   │   │   │   ├── NoAssignmentsSearch.handlebars.json
│   │   │   │   ├── _assignmentListItemScore.handlebars
│   │   │   │   └── _assignmentListItemScore.handlebars.json
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── GroupRuleInput.tsx
│   │   │       ├── GroupWeightInput.tsx
│   │   │       ├── IndexCreate.tsx
│   │   │       ├── IndexMenu.tsx
│   │   │       ├── __tests__
│   │   │       │   ├── GroupRuleInput.test.tsx
│   │   │       │   ├── GroupWeightInput.test.tsx
│   │   │       │   └── IndexMenu.test.jsx
│   │   │       ├── actions
│   │   │       │   ├── IndexMenuActions.js
│   │   │       │   └── __tests__
│   │   │       │       └── IndexMenuActions.spec.js
│   │   │       ├── bulk_edit
│   │   │       │   ├── BulkAssignmentShape.js
│   │   │       │   ├── BulkDateInput.jsx
│   │   │       │   ├── BulkEdit.jsx
│   │   │       │   ├── BulkEditDateSelect.jsx
│   │   │       │   ├── BulkEditHeader.jsx
│   │   │       │   ├── BulkEditIndex.jsx
│   │   │       │   ├── BulkEditOverrideTitle.jsx
│   │   │       │   ├── BulkEditTable.jsx
│   │   │       │   ├── MoveDatesModal.jsx
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── BulkEdit.test.jsx
│   │   │       │   │   └── MoveDatesModal.test.jsx
│   │   │       │   ├── hooks
│   │   │       │   │   ├── useMonitorJobCompletion.js
│   │   │       │   │   └── useSaveAssignments.js
│   │   │       │   └── utils.js
│   │   │       ├── hooks
│   │   │       │   ├── __tests__
│   │   │       │   │   └── useNumberInputDriver.test.js
│   │   │       │   └── useNumberInputDriver.js
│   │   │       ├── reducers
│   │   │       │   ├── __tests__
│   │   │       │   │   └── IndexMenuReducer.spec.js
│   │   │       │   └── indexMenuReducer.js
│   │   │       └── stores
│   │   │           └── indexMenuStore.js
│   │   ├── assignment_show
│   │   │   ├── backbone
│   │   │   │   └── views
│   │   │   │       ├── SpeedgraderLinkView.js
│   │   │   │       └── __tests__
│   │   │   │           └── SpeedgraderLinkView.test.js
│   │   │   ├── index.jsx
│   │   │   └── package.json
│   │   ├── assignments_peer_reviews
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── FilterPeerReview.tsx
│   │   │       ├── ReviewsPerUserInput.tsx
│   │   │       └── __tests__
│   │   │           ├── FilterPeerReview.test.tsx
│   │   │           └── ReviewsPerUserInput.test.tsx
│   │   ├── assignments_show_student
│   │   │   ├── assignments_show_student.d.ts
│   │   │   ├── images
│   │   │   │   ├── ClosedDiscussions.svg
│   │   │   │   ├── Locked.svg
│   │   │   │   ├── Locked1.svg
│   │   │   │   ├── NoComments.svg
│   │   │   │   ├── NoReportsClipboard.svg
│   │   │   │   ├── PhotographerPanda.svg
│   │   │   │   ├── PreviewUnavailable.svg
│   │   │   │   ├── SubmissionChoice.svg
│   │   │   │   ├── Success.svg
│   │   │   │   ├── TakePhoto.svg
│   │   │   │   ├── UnavailablePeerReview.svg
│   │   │   │   ├── UnpublishedModule.svg
│   │   │   │   ├── UploadFile.svg
│   │   │   │   ├── bookmarks.svg
│   │   │   │   └── noCommentsPeerReview.svg
│   │   │   ├── index.js
│   │   │   ├── ltiTool.d.ts
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── AssignmentToggleDetails.jsx
│   │   │       ├── DateLocked.jsx
│   │   │       ├── FileList.jsx
│   │   │       ├── NeedsSubmissionPeerReview.jsx
│   │   │       ├── SVGWithTextPlaceholder.jsx
│   │   │       ├── Steps
│   │   │       │   ├── StepItem
│   │   │       │   │   ├── __tests__
│   │   │       │   │   │   └── index.test.jsx
│   │   │       │   │   └── index.jsx
│   │   │       │   ├── __tests__
│   │   │       │   │   └── index.test.jsx
│   │   │       │   └── index.jsx
│   │   │       ├── UnavailablePeerReview.jsx
│   │   │       ├── UnpublishedModule.jsx
│   │   │       ├── __tests__
│   │   │       │   ├── AssignmentToggleDetails.test.jsx
│   │   │       │   ├── DateLocked.test.jsx
│   │   │       │   ├── FileList.test.jsx
│   │   │       │   ├── SVGWithTextPlaceholder.test.jsx
│   │   │       │   ├── StudentViewIntegration1.test.jsx
│   │   │       │   ├── StudentViewIntegration2.test.jsx
│   │   │       │   ├── UnavailablePeerReview.test.jsx
│   │   │       │   └── UnpublishedModule.test.jsx
│   │   │       ├── apis
│   │   │       │   ├── ContextModuleApi.js
│   │   │       │   └── __tests__
│   │   │       │       └── ContextModuleApi.test.js
│   │   │       ├── components
│   │   │       │   ├── AssignmentDetails.jsx
│   │   │       │   ├── AssignmentGroupModuleNav.jsx
│   │   │       │   ├── AttemptInformation.tsx
│   │   │       │   ├── AttemptSelect.jsx
│   │   │       │   ├── AttemptTab.jsx
│   │   │       │   ├── AttemptType
│   │   │       │   │   ├── ExternalToolSubmission.jsx
│   │   │       │   │   ├── FilePreview.jsx
│   │   │       │   │   ├── FileUpload.jsx
│   │   │       │   │   ├── MediaAttempt.jsx
│   │   │       │   │   ├── MoreOptions
│   │   │       │   │   │   ├── CanvasFiles
│   │   │       │   │   │   │   ├── BreadcrumbLinkWithTip.jsx
│   │   │       │   │   │   │   ├── FileSelectTable.jsx
│   │   │       │   │   │   │   ├── TableFiles.jsx
│   │   │       │   │   │   │   ├── TableFolders.jsx
│   │   │       │   │   │   │   ├── TableHeader.jsx
│   │   │       │   │   │   │   └── index.jsx
│   │   │       │   │   │   ├── WebcamCapture.jsx
│   │   │       │   │   │   ├── __tests__
│   │   │       │   │   │   │   └── WebcamCapture.test.jsx
│   │   │       │   │   │   └── index.jsx
│   │   │       │   │   ├── StudentAnnotationAttempt.jsx
│   │   │       │   │   ├── TextEntry.jsx
│   │   │       │   │   ├── UrlEntry.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       ├── ExternalToolSubmission.test.jsx
│   │   │       │   │       ├── FilePreview.test.jsx
│   │   │       │   │       ├── FileUpload.test.jsx
│   │   │       │   │       ├── MediaAttempt.test.jsx
│   │   │       │   │       ├── MoreOptions.test.jsx
│   │   │       │   │       ├── StudentAnnotationAttempt.test.jsx
│   │   │       │   │       ├── TextEntry.test.jsx
│   │   │       │   │       └── UrlEntry.test.jsx
│   │   │       │   ├── CommentsTray
│   │   │       │   │   ├── CommentContent.jsx
│   │   │       │   │   ├── CommentRow.jsx
│   │   │       │   │   ├── CommentTextArea.jsx
│   │   │       │   │   ├── CommentsTrayBody.tsx
│   │   │       │   │   └── index.jsx
│   │   │       │   ├── ContentTabs.jsx
│   │   │       │   ├── Context.jsx
│   │   │       │   ├── ExternalToolOptions.jsx
│   │   │       │   ├── GradeDisplay.jsx
│   │   │       │   ├── Header.jsx
│   │   │       │   ├── LatePolicyStatusDisplay
│   │   │       │   │   ├── AccessibleTipContent.jsx
│   │   │       │   │   ├── LatePolicyToolTipContent.jsx
│   │   │       │   │   └── index.jsx
│   │   │       │   ├── LockedAssignment.jsx
│   │   │       │   ├── LoggedOutTabs.jsx
│   │   │       │   ├── LoginActionPrompt.jsx
│   │   │       │   ├── LtiToolIframe.tsx
│   │   │       │   ├── MarkAsDoneButton.jsx
│   │   │       │   ├── MissingPrereqs.jsx
│   │   │       │   ├── OriginalityReport.jsx
│   │   │       │   ├── PeerReviewNavigationLink.tsx
│   │   │       │   ├── PeerReviewPromptModal.tsx
│   │   │       │   ├── PeerReviewsCounter.jsx
│   │   │       │   ├── RubricTab.jsx
│   │   │       │   ├── RubricsQuery.tsx
│   │   │       │   ├── RubricsQuery.types.d.ts
│   │   │       │   ├── StepContainer.jsx
│   │   │       │   ├── StudentContent.jsx
│   │   │       │   ├── StudentFooter.jsx
│   │   │       │   ├── StudentViewQuery.jsx
│   │   │       │   ├── SubmissionHistoriesQuery.jsx
│   │   │       │   ├── SubmissionManager.jsx
│   │   │       │   ├── SubmissionTypeButton.jsx
│   │   │       │   ├── SubmissionWorkflowTracker.jsx
│   │   │       │   ├── ViewManager.jsx
│   │   │       │   ├── VisualOnFocusMessage.jsx
│   │   │       │   ├── __mocks__
│   │   │       │   │   └── AttemptSelect.jsx
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── AssignmentDetails.test.jsx
│   │   │       │   │   ├── AssignmentGroupModuleNav.test.jsx
│   │   │       │   │   ├── AttemptSelect.test.jsx
│   │   │       │   │   ├── AttemptTab1.test.jsx
│   │   │       │   │   ├── AttemptTab2.test.jsx
│   │   │       │   │   ├── CommentRow.test.jsx
│   │   │       │   │   ├── CommentsTextArea.test.jsx
│   │   │       │   │   ├── CommentsTray.test.jsx
│   │   │       │   │   ├── CommentsTrayBody.test.tsx
│   │   │       │   │   ├── ContentTabs.test.js
│   │   │       │   │   ├── ExternalToolOptions.test.jsx
│   │   │       │   │   ├── GradeDisplay.test.jsx
│   │   │       │   │   ├── Header.test.jsx
│   │   │       │   │   ├── LatePolicyStatusDisplay.test.jsx
│   │   │       │   │   ├── LoggedOutTabs.test.jsx
│   │   │       │   │   ├── LoginActionPrompt.test.jsx
│   │   │       │   │   ├── LtiToolIframe.test.tsx
│   │   │       │   │   ├── MarkAsDoneButton.test.jsx
│   │   │       │   │   ├── MissingPrereqs.test.jsx
│   │   │       │   │   ├── OriginalityReport.test.jsx
│   │   │       │   │   ├── PeerReviewNavigationLink.test.tsx
│   │   │       │   │   ├── PeerReviewPromptModal.test.tsx
│   │   │       │   │   ├── PeerReviewsCounter.test.jsx
│   │   │       │   │   ├── RubricTab.test.jsx
│   │   │       │   │   ├── RubricsQuery.test.jsx
│   │   │       │   │   ├── StepContainer.test.jsx
│   │   │       │   │   ├── StudentContent1.test.jsx
│   │   │       │   │   ├── StudentContent2.test.jsx
│   │   │       │   │   ├── StudentContent3.test.jsx
│   │   │       │   │   ├── StudentContent4.test.jsx
│   │   │       │   │   ├── StudentContent5.test.jsx
│   │   │       │   │   ├── StudentFooter.test.jsx
│   │   │       │   │   ├── SubmissionManager1.test.jsx
│   │   │       │   │   ├── SubmissionManager10.test.jsx
│   │   │       │   │   ├── SubmissionManager2.test.jsx
│   │   │       │   │   ├── SubmissionManager3.test.jsx
│   │   │       │   │   ├── SubmissionManager4.test.jsx
│   │   │       │   │   ├── SubmissionManager5.test.jsx
│   │   │       │   │   ├── SubmissionManager6.test.jsx
│   │   │       │   │   ├── SubmissionManager7.test.jsx
│   │   │       │   │   ├── SubmissionManager8.test.jsx
│   │   │       │   │   ├── SubmissionManager9.test.jsx
│   │   │       │   │   ├── SubmissionTypeButton.test.jsx
│   │   │       │   │   ├── SubmissionWorkflowTracker.test.jsx
│   │   │       │   │   ├── ViewManager.test.jsx
│   │   │       │   │   └── VisualOnFocusMessage.test.jsx
│   │   │       │   └── stores
│   │   │       │       ├── __tests__
│   │   │       │       │   └── index.test.ts
│   │   │       │       └── index.ts
│   │   │       ├── helpers
│   │   │       │   ├── PeerReviewHelpers.ts
│   │   │       │   ├── RubricHelpers.js
│   │   │       │   ├── SubmissionHelpers.js
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── RubricHelpers.test.js
│   │   │       │   │   ├── SubmissionHelpers.test.js
│   │   │       │   │   ├── elideString.test.js
│   │   │       │   │   └── ltiConfigHelper.test.ts
│   │   │       │   ├── elideString.js
│   │   │       │   └── ltiConfigHelper.ts
│   │   │       └── index.jsx
│   │   ├── assignments_show_teacher
│   │   │   ├── index.ts
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── components
│   │   │       │   ├── TeacherQuery.tsx
│   │   │       │   └── TeacherSavedView.tsx
│   │   │       └── index.tsx
│   │   ├── assignments_show_teacher_deprecated
│   │   │   ├── index.js
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── AssignentFieldValidator.js
│   │   │       ├── __tests__
│   │   │       │   └── AssignentFieldValidator.test.js
│   │   │       ├── api.js
│   │   │       ├── assignmentData.js
│   │   │       ├── components
│   │   │       │   ├── AddHorizontalRuleButton.jsx
│   │   │       │   ├── AssignmentDescription.jsx
│   │   │       │   ├── ConfirmDialog.jsx
│   │   │       │   ├── ContentTabs.jsx
│   │   │       │   ├── Details.jsx
│   │   │       │   ├── Editables
│   │   │       │   │   ├── AssignmentDate.jsx
│   │   │       │   │   ├── AssignmentGroup.jsx
│   │   │       │   │   ├── AssignmentModules.jsx
│   │   │       │   │   ├── AssignmentName.jsx
│   │   │       │   │   ├── AssignmentPoints.jsx
│   │   │       │   │   ├── AssignmentType.jsx
│   │   │       │   │   ├── EditableDateTime.jsx
│   │   │       │   │   ├── EditableHeading.jsx
│   │   │       │   │   ├── EditableNumber.jsx
│   │   │       │   │   ├── EditableRichText.jsx
│   │   │       │   │   ├── SelectableText.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       ├── AssignmentDate.test.jsx
│   │   │       │   │       ├── AssignmentGroup.test.jsx
│   │   │       │   │       ├── AssignmentModules.test.jsx
│   │   │       │   │       ├── AssignmentName.test.jsx
│   │   │       │   │       ├── AssignmentPoints.test.jsx
│   │   │       │   │       ├── AssignmentType.test.jsx
│   │   │       │   │       ├── EditableDateTime.test.jsx
│   │   │       │   │       ├── EditableHeading.test.jsx
│   │   │       │   │       ├── EditableNumber.test.jsx
│   │   │       │   │       ├── EditableRichText.test.jsx
│   │   │       │   │       └── SelectableText.test.jsx
│   │   │       │   ├── Header.jsx
│   │   │       │   ├── MessageStudentsWhoDialog.jsx
│   │   │       │   ├── MessageStudentsWhoForm.jsx
│   │   │       │   ├── Overrides
│   │   │       │   │   ├── EveryoneElse.jsx
│   │   │       │   │   ├── ExternalToolType.jsx
│   │   │       │   │   ├── FileType.jsx
│   │   │       │   │   ├── NonCanvasType.jsx
│   │   │       │   │   ├── OperatorType.jsx
│   │   │       │   │   ├── Override.jsx
│   │   │       │   │   ├── OverrideAssignTo.jsx
│   │   │       │   │   ├── OverrideAttempts.jsx
│   │   │       │   │   ├── OverrideDates.jsx
│   │   │       │   │   ├── OverrideDetail.jsx
│   │   │       │   │   ├── OverrideSubmissionTypes.jsx
│   │   │       │   │   ├── OverrideSummary.jsx
│   │   │       │   │   ├── Overrides.jsx
│   │   │       │   │   ├── SimpleType.jsx
│   │   │       │   │   ├── SubmitOptionShape.js
│   │   │       │   │   └── __tests__
│   │   │       │   │       ├── EveryoneElse.test.jsx
│   │   │       │   │       ├── Override.test.jsx
│   │   │       │   │       ├── OverrideAssignTo.test.jsx
│   │   │       │   │       ├── OverrideAttempts.test.jsx
│   │   │       │   │       ├── OverrideDates.test.jsx
│   │   │       │   │       ├── OverrideDetail.test.jsx
│   │   │       │   │       ├── OverrideSubmissionTypes.test.jsx
│   │   │       │   │       └── OverrideSummary.test.jsx
│   │   │       │   ├── StudentsTab
│   │   │       │   │   ├── Filters.jsx
│   │   │       │   │   ├── StudentSearchQuery.jsx
│   │   │       │   │   ├── StudentTray.jsx
│   │   │       │   │   ├── StudentsSearcher.jsx
│   │   │       │   │   ├── StudentsTable.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       ├── Filters.test.jsx
│   │   │       │   │       ├── StudentTray.test.jsx
│   │   │       │   │       ├── StudentsSearcher.test.jsx
│   │   │       │   │       └── StudentsTable.test.jsx
│   │   │       │   ├── TeacherFooter.jsx
│   │   │       │   ├── TeacherQuery.jsx
│   │   │       │   ├── TeacherView.jsx
│   │   │       │   ├── TeacherViewContext.jsx
│   │   │       │   ├── Toolbox.jsx
│   │   │       │   └── __tests__
│   │   │       │       ├── AddHorizontalRuleButton.test.jsx
│   │   │       │       ├── AssignmentDescription.test.jsx
│   │   │       │       ├── ConfirmDialog.test.jsx
│   │   │       │       ├── ContentTabs.test.jsx
│   │   │       │       ├── Details.test.jsx
│   │   │       │       ├── Header.test.jsx
│   │   │       │       ├── MessageStudentsWhoDialog.test.jsx
│   │   │       │       ├── TeacherQuery.test.js
│   │   │       │       ├── TeacherView.test.js
│   │   │       │       ├── Toolbox.test.jsx
│   │   │       │       ├── fixtures
│   │   │       │       │   └── AssignmentMockup.js
│   │   │       │       └── integration
│   │   │       │           ├── AssignmentGroup.test.jsx
│   │   │       │           ├── AssignmentModules.test.jsx
│   │   │       │           ├── DeleteDialog.test.js
│   │   │       │           ├── MessageStudentsWho.test.js
│   │   │       │           ├── TeacherView.test.jsx
│   │   │       │           └── integration-utils.jsx
│   │   │       ├── index.jsx
│   │   │       └── test-utils.js
│   │   ├── authentication_providers
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   ├── __tests__
│   │   │   │   │   └── AuthenticationProviders.test.js
│   │   │   │   ├── account_authorization_configs.jsx
│   │   │   │   ├── authentication_provider_debugging.js
│   │   │   │   └── index.js
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── AuthTypePicker.jsx
│   │   │       └── __tests__
│   │   │           └── AuthTypePicker.test.jsx
│   │   ├── available_pronouns_list
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── PronounsInput.jsx
│   │   │       └── __tests__
│   │   │           └── PronounsInput.test.jsx
│   │   ├── block_editor_iframe_content
│   │   │   ├── index.tsx
│   │   │   └── package.json
│   │   ├── blueprint_course_child
│   │   │   ├── index.js
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── apps
│   │   │       │   ├── ChildCourse.jsx
│   │   │       │   └── __tests__
│   │   │       │       └── ChildCourse.test.js
│   │   │       └── components
│   │   │           ├── ChangeLogRow.jsx
│   │   │           ├── ChildChangeLog.jsx
│   │   │           ├── ChildContent.jsx
│   │   │           ├── MasterChildStack.jsx
│   │   │           └── __tests__
│   │   │               ├── ChangeLogRow.test.jsx
│   │   │               ├── ChildChangeLog.test.jsx
│   │   │               ├── ChildContent.test.jsx
│   │   │               └── MasterChildStack.test.jsx
│   │   ├── blueprint_course_master
│   │   │   ├── index.js
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── __tests__
│   │   │       │   └── focusManager.test.js
│   │   │       ├── apps
│   │   │       │   ├── BlueprintCourse.jsx
│   │   │       │   └── __tests__
│   │   │       │       └── BlueprintCourse.test.js
│   │   │       ├── components
│   │   │       │   ├── AssociationsTable.jsx
│   │   │       │   ├── BlueprintAssociations.jsx
│   │   │       │   ├── BlueprintSidebar.jsx
│   │   │       │   ├── ConnectedBlueprintAssociations.js
│   │   │       │   ├── ConnectedSyncHistory.js
│   │   │       │   ├── ConnectedUnsyncedChanges.js
│   │   │       │   ├── CourseFilter.jsx
│   │   │       │   ├── CoursePicker.jsx
│   │   │       │   ├── CoursePickerTable.jsx
│   │   │       │   ├── CourseSidebar.jsx
│   │   │       │   ├── MigrationOptions.jsx
│   │   │       │   ├── MigrationSync.jsx
│   │   │       │   ├── SyncHistory.jsx
│   │   │       │   ├── UnsyncedChange.jsx
│   │   │       │   ├── UnsyncedChanges.jsx
│   │   │       │   └── __tests__
│   │   │       │       ├── AssociationsTable.test.jsx
│   │   │       │       ├── BlueprintAssociations.test.jsx
│   │   │       │       ├── BlueprintSidebar.test.jsx
│   │   │       │       ├── CourseFilter.test.jsx
│   │   │       │       ├── CoursePicker.test.jsx
│   │   │       │       ├── CoursePickerTable.test.jsx
│   │   │       │       ├── CourseSidebar.test.jsx
│   │   │       │       ├── MigrationOptions.test.jsx
│   │   │       │       ├── MigrationSync.test.jsx
│   │   │       │       ├── SyncHistory.test.jsx
│   │   │       │       ├── UnsyncedChanges.test.jsx
│   │   │       │       └── getSampleData.js
│   │   │       └── focusManager.js
│   │   ├── brand_configs
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── CollectionView.jsx
│   │   │       ├── ThemeCard.jsx
│   │   │       └── __tests__
│   │   │           ├── CollectionView.test.jsx
│   │   │           └── ThemeCard.test.jsx
│   │   ├── calendar
│   │   │   ├── CalendarDefaults.js
│   │   │   ├── CalendarEventFilter.js
│   │   │   ├── __tests__
│   │   │   │   ├── CalendarEventFilter.test.js
│   │   │   │   └── momentDateHelper.test.js
│   │   │   ├── backbone
│   │   │   │   └── views
│   │   │   │       ├── AgendaView.js
│   │   │   │       ├── CalendarHeader.jsx
│   │   │   │       ├── CalendarNavigator.jsx
│   │   │   │       ├── EditAssignmentDetails.js
│   │   │   │       ├── EditPlannerNoteDetails.js
│   │   │   │       ├── EditToDoItemDetails.js
│   │   │   │       └── __tests__
│   │   │   │           ├── AgendaView.test.js
│   │   │   │           ├── CalendarHeader.test.js
│   │   │   │           ├── CalendarNavigator.test.js
│   │   │   │           ├── EditAssignmentDetails.test.js
│   │   │   │           ├── EditPlannerNoteDetails.test.js
│   │   │   │           ├── calendarAssignments.js
│   │   │   │           └── calendarEvents.js
│   │   │   ├── ext
│   │   │   │   ├── loadFullCalendarLocaleData.js
│   │   │   │   └── patches-to-fullcalendar.js
│   │   │   ├── fcMomentHandlebarsHelpers.js
│   │   │   ├── index.jsx
│   │   │   ├── jquery
│   │   │   │   ├── ContextSelector.js
│   │   │   │   ├── EditAppointmentGroupDetails.js
│   │   │   │   ├── EditApptCalendarEventDialog.js
│   │   │   │   ├── EditCalendarEventDetails.jsx
│   │   │   │   ├── EditEventDetailsDialog.js
│   │   │   │   ├── MiniCalendar.js
│   │   │   │   ├── ShowEventDetailsDialog.jsx
│   │   │   │   ├── TimeBlockList.js
│   │   │   │   ├── TimeBlockRow.js
│   │   │   │   ├── UndatedEventsList.js
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── Calendar.test.js
│   │   │   │   │   ├── EditAppointmentGroupDetails.test.js
│   │   │   │   │   ├── TimeBlockList.test.js
│   │   │   │   │   └── TimeBlockRow.test.js
│   │   │   │   ├── index.js
│   │   │   │   └── sidebar.jsx
│   │   │   ├── jst
│   │   │   │   ├── TimeBlockRow.handlebars
│   │   │   │   ├── TimeBlockRow.handlebars.json
│   │   │   │   ├── agendaView.handlebars
│   │   │   │   ├── agendaView.handlebars.json
│   │   │   │   ├── calendarApp.handlebars
│   │   │   │   ├── calendarApp.handlebars.json
│   │   │   │   ├── calendarHeader.handlebars
│   │   │   │   ├── calendarHeader.handlebars.json
│   │   │   │   ├── calendarNavigator.handlebars
│   │   │   │   ├── calendarNavigator.handlebars.json
│   │   │   │   ├── contextList.handlebars
│   │   │   │   ├── contextList.handlebars.json
│   │   │   │   ├── contextSelector.handlebars
│   │   │   │   ├── contextSelector.handlebars.json
│   │   │   │   ├── contextSelectorItem.handlebars
│   │   │   │   ├── contextSelectorItem.handlebars.json
│   │   │   │   ├── deleteItem.handlebars
│   │   │   │   ├── deleteItem.handlebars.json
│   │   │   │   ├── editAppointmentGroup.handlebars
│   │   │   │   ├── editAppointmentGroup.handlebars.json
│   │   │   │   ├── editApptCalendarEvent.handlebars
│   │   │   │   ├── editApptCalendarEvent.handlebars.json
│   │   │   │   ├── editAssignment.handlebars
│   │   │   │   ├── editAssignment.handlebars.json
│   │   │   │   ├── editAssignmentOverride.handlebars
│   │   │   │   ├── editAssignmentOverride.handlebars.json
│   │   │   │   ├── editEvent.handlebars
│   │   │   │   ├── editEvent.handlebars.json
│   │   │   │   ├── editPlannerNote.handlebars
│   │   │   │   ├── editPlannerNote.handlebars.json
│   │   │   │   ├── editToDoItem.handlebars
│   │   │   │   ├── editToDoItem.handlebars.json
│   │   │   │   ├── eventDetails.handlebars
│   │   │   │   ├── eventDetails.handlebars.json
│   │   │   │   ├── genericSelect.handlebars
│   │   │   │   ├── genericSelect.handlebars.json
│   │   │   │   ├── genericSelectOptions.handlebars
│   │   │   │   ├── genericSelectOptions.handlebars.json
│   │   │   │   ├── reservationOverLimitDialog.handlebars
│   │   │   │   ├── reservationOverLimitDialog.handlebars.json
│   │   │   │   ├── undatedEvents.handlebars
│   │   │   │   └── undatedEvents.handlebars.json
│   │   │   ├── momentDateHelper.js
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── AccountCalendarsModal.jsx
│   │   │       ├── AccountCalendarsResultsArea.jsx
│   │   │       ├── CalendarEventDetailsForm.jsx
│   │   │       ├── CalendarHeaderComponent.tsx
│   │   │       ├── CalendarNavigatorComponent.tsx
│   │   │       ├── __tests__
│   │   │       │   ├── AccountCalendarsModal.test.jsx
│   │   │       │   ├── CalendarEventDetailsForm1.test.jsx
│   │   │       │   ├── CalendarEventDetailsForm2.test.jsx
│   │   │       │   ├── CalendarEventDetailsForm3.test.jsx
│   │   │       │   └── mocks.js
│   │   │       └── scheduler
│   │   │           ├── __tests__
│   │   │           │   ├── actions.spec.js
│   │   │           │   └── reducer.spec.js
│   │   │           ├── actions.js
│   │   │           ├── components
│   │   │           │   ├── FindAppointment.jsx
│   │   │           │   └── __tests__
│   │   │           │       └── FindAppointment.test.jsx
│   │   │           ├── reducer.js
│   │   │           └── store
│   │   │               ├── configureStore.js
│   │   │               └── initialState.js
│   │   ├── calendar_appointment_group_edit
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── AppointmentGroupList.jsx
│   │   │       ├── ContextSelector.jsx
│   │   │       ├── EditPage.jsx
│   │   │       ├── TimeBlockSelectRow.jsx
│   │   │       ├── TimeBlockSelector.jsx
│   │   │       └── __tests__
│   │   │           ├── AppointmentGroupList.test.jsx
│   │   │           ├── ContextSelector.test.jsx
│   │   │           ├── EditPage.test.jsx
│   │   │           ├── TimeBlockSelectRow.test.jsx
│   │   │           └── TimeBlockSelector.test.jsx
│   │   ├── canvas_career
│   │   │   └── index.jsx
│   │   ├── change_password
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── ConfirmChangePassword.tsx
│   │   │       └── __tests__
│   │   │           └── ConfirmChangePassword.test.tsx
│   │   ├── choose_mastery_path
│   │   │   ├── index.js
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── __tests__
│   │   │       │   └── reducer.spec.js
│   │   │       ├── actions.js
│   │   │       ├── api-client.js
│   │   │       ├── components
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── assignment.test.jsx
│   │   │       │   │   ├── chooseMasteryPath.test.jsx
│   │   │       │   │   ├── pathOption.test.jsx
│   │   │       │   │   └── selectButton.test.jsx
│   │   │       │   ├── assignment.jsx
│   │   │       │   ├── choose-mastery-path.jsx
│   │   │       │   ├── path-option.jsx
│   │   │       │   └── select-button.jsx
│   │   │       ├── index.jsx
│   │   │       ├── reducer.js
│   │   │       ├── shapes
│   │   │       │   ├── assignment-shape.js
│   │   │       │   ├── category-shape.js
│   │   │       │   └── option-shape.js
│   │   │       └── store.js
│   │   ├── collaborations
│   │   │   ├── backbone
│   │   │   │   ├── collections
│   │   │   │   │   └── CollaboratorCollection.js
│   │   │   │   └── views
│   │   │   │       ├── CollaborationFormView.js
│   │   │   │       ├── CollaborationView.js
│   │   │   │       ├── CollaborationsPage.js
│   │   │   │       ├── CollaboratorPickerView.js
│   │   │   │       ├── ListView.js
│   │   │   │       ├── MemberListView.js
│   │   │   │       └── __tests__
│   │   │   │           └── CollaborationView.test.js
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   ├── __tests__
│   │   │   │   │   └── Collaborations.test.js
│   │   │   │   └── index.js
│   │   │   ├── jst
│   │   │   │   ├── CollaboratorPicker.handlebars
│   │   │   │   ├── CollaboratorPicker.handlebars.json
│   │   │   │   ├── EditIframe.handlebars
│   │   │   │   ├── EditIframe.handlebars.json
│   │   │   │   ├── collaborator.handlebars
│   │   │   │   ├── collaborator.handlebars.json
│   │   │   │   ├── edit.handlebars
│   │   │   │   └── edit.handlebars.json
│   │   │   └── package.json
│   │   ├── conferences
│   │   │   ├── backbone
│   │   │   │   ├── collections
│   │   │   │   │   └── ConferenceCollection.js
│   │   │   │   ├── models
│   │   │   │   │   └── Conference.js
│   │   │   │   └── views
│   │   │   │       ├── ConcludedConferenceView.js
│   │   │   │       ├── ConferenceView.jsx
│   │   │   │       ├── EditConferenceView.js
│   │   │   │       └── __tests__
│   │   │   │           ├── ConferenceView.test.jsx
│   │   │   │           └── EditConferenceView.spec.js
│   │   │   ├── images
│   │   │   │   ├── meet.svg
│   │   │   │   ├── teams.svg
│   │   │   │   └── zoom.svg
│   │   │   ├── index.jsx
│   │   │   ├── jst
│   │   │   │   ├── concludedConference.handlebars
│   │   │   │   ├── concludedConference.handlebars.json
│   │   │   │   ├── editConferenceForm.handlebars
│   │   │   │   ├── editConferenceForm.handlebars.json
│   │   │   │   ├── newConference.handlebars
│   │   │   │   ├── newConference.handlebars.json
│   │   │   │   ├── userSettingOptions.handlebars
│   │   │   │   └── userSettingOptions.handlebars.json
│   │   │   ├── package.json
│   │   │   ├── react
│   │   │   │   ├── components
│   │   │   │   │   ├── BBBModalOptions
│   │   │   │   │   │   ├── BBBModalOptions.jsx
│   │   │   │   │   │   ├── BBBModalOptions.stories.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── BBBModalOptions.test.jsx
│   │   │   │   │   ├── BaseModalOptions
│   │   │   │   │   │   ├── BaseModalOptions.jsx
│   │   │   │   │   │   ├── BaseModalOptions.stories.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── BaseModalOptions.test.jsx
│   │   │   │   │   ├── ConferenceAddressBook
│   │   │   │   │   │   ├── ConferenceAddressBook.jsx
│   │   │   │   │   │   ├── ConferenceAddressBook.stories.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── ConferenceAddressBook.test.jsx
│   │   │   │   │   ├── VideoConferenceModal
│   │   │   │   │   │   ├── VideoConferenceModal.jsx
│   │   │   │   │   │   ├── VideoConferenceModal.stories.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── VideoConferenceModal.test.jsx
│   │   │   │   │   └── VideoConferenceTypeSelect
│   │   │   │   │       ├── VideoConferenceTypeSelect.jsx
│   │   │   │   │       ├── VideoConferenceTypeSelect.stories.jsx
│   │   │   │   │       └── __tests__
│   │   │   │   │           └── VideoConferenceTypeSelect.test.jsx
│   │   │   │   └── renderAlternatives.jsx
│   │   │   └── util
│   │   │       └── constants.js
│   │   ├── confetti
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── confirm_email
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── content_exports
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── index.js
│   │   │   └── package.json
│   │   ├── content_migrations
│   │   │   ├── __tests__
│   │   │   │   └── processMigrationContentItem.test.js
│   │   │   ├── backbone
│   │   │   │   ├── collections
│   │   │   │   │   ├── ContentCheckboxCollection.js
│   │   │   │   │   ├── ContentMigrationIssueCollection.js
│   │   │   │   │   ├── ProgressingContentMigrationCollection.js
│   │   │   │   │   └── __tests__
│   │   │   │   │       ├── ContentCheckboxCollection.spec.js
│   │   │   │   │       └── ContentMigrationIssueCollection.spec.js
│   │   │   │   ├── models
│   │   │   │   │   ├── ContentCheckbox.js
│   │   │   │   │   └── ProgressingContentMigration.js
│   │   │   │   └── views
│   │   │   │       ├── CanvasExportView.js
│   │   │   │       ├── CheckingCheckboxesForTree.js
│   │   │   │       ├── CommonCartridgeView.js
│   │   │   │       ├── ContentCheckboxView.js
│   │   │   │       ├── ContentMigrationIssueView.js
│   │   │   │       ├── CopyCourseView.js
│   │   │   │       ├── ExpandCollapseContentSelectTreeItems.js
│   │   │   │       ├── ExternalToolContentView.js
│   │   │   │       ├── MigrationConverterView.jsx
│   │   │   │       ├── MoodleZipView.js
│   │   │   │       ├── NavigationForTree.js
│   │   │   │       ├── ProgressBarView.js
│   │   │   │       ├── ProgressStatusView.js
│   │   │   │       ├── ProgressingContentMigrationView.js
│   │   │   │       ├── QTIZipView.js
│   │   │   │       ├── ScrollPositionForTree.js
│   │   │   │       ├── SelectContentView.js
│   │   │   │       ├── SourceLinkView.js
│   │   │   │       ├── ZipFilesView.js
│   │   │   │       ├── __tests__
│   │   │   │       │   ├── ContentCheckboxView.test.js
│   │   │   │       │   ├── CopyCourseView.test.js
│   │   │   │       │   ├── MigrationConverterView.test.js
│   │   │   │       │   ├── NavigationForTree.spec.js
│   │   │   │       │   ├── ProgressStatusView.test.js
│   │   │   │       │   └── SelectContentView.test.js
│   │   │   │       └── subviews
│   │   │   │           ├── CourseFindSelectView.js
│   │   │   │           ├── ExternalToolLaunchView.js
│   │   │   │           ├── FolderPickerView.js
│   │   │   │           └── __tests__
│   │   │   │               ├── CourseFindSelectView.test.js
│   │   │   │               └── ExternalToolLaunchView.test.js
│   │   │   ├── index.js
│   │   │   ├── instui_setup.tsx
│   │   │   ├── jst
│   │   │   │   ├── CanvasExport.handlebars
│   │   │   │   ├── CanvasExport.handlebars.json
│   │   │   │   ├── CommonCartridge.handlebars
│   │   │   │   ├── CommonCartridge.handlebars.json
│   │   │   │   ├── ContentCheckbox.handlebars
│   │   │   │   ├── ContentCheckbox.handlebars.json
│   │   │   │   ├── ContentCheckboxCollection.handlebars
│   │   │   │   ├── ContentCheckboxCollection.handlebars.json
│   │   │   │   ├── ContentMigrationIssue.handlebars
│   │   │   │   ├── ContentMigrationIssue.handlebars.json
│   │   │   │   ├── CopyCourse.handlebars
│   │   │   │   ├── CopyCourse.handlebars.json
│   │   │   │   ├── ExternalToolContent.handlebars
│   │   │   │   ├── ExternalToolContent.handlebars.json
│   │   │   │   ├── MigrationConverter.handlebars
│   │   │   │   ├── MigrationConverter.handlebars.json
│   │   │   │   ├── MoodleZip.handlebars
│   │   │   │   ├── MoodleZip.handlebars.json
│   │   │   │   ├── ProgressBar.handlebars
│   │   │   │   ├── ProgressBar.handlebars.json
│   │   │   │   ├── ProgressStatus.handlebars
│   │   │   │   ├── ProgressStatus.handlebars.json
│   │   │   │   ├── ProgressingContentMigration.handlebars
│   │   │   │   ├── ProgressingContentMigration.handlebars.json
│   │   │   │   ├── ProgressingContentMigrationCollection.handlebars
│   │   │   │   ├── ProgressingContentMigrationCollection.handlebars.json
│   │   │   │   ├── ProgressingIssues.handlebars
│   │   │   │   ├── ProgressingIssues.handlebars.json
│   │   │   │   ├── QTIZip.handlebars
│   │   │   │   ├── QTIZip.handlebars.json
│   │   │   │   ├── SelectContent.handlebars
│   │   │   │   ├── SelectContent.handlebars.json
│   │   │   │   ├── SourceLink.handlebars
│   │   │   │   ├── SourceLink.handlebars.json
│   │   │   │   ├── ZipFiles.handlebars
│   │   │   │   ├── ZipFiles.handlebars.json
│   │   │   │   ├── autocomplete_item.handlebars
│   │   │   │   ├── autocomplete_item.handlebars.json
│   │   │   │   └── subviews
│   │   │   │       ├── CourseFindSelect.handlebars
│   │   │   │       ├── CourseFindSelect.handlebars.json
│   │   │   │       ├── ExternalToolLaunch.handlebars
│   │   │   │       ├── ExternalToolLaunch.handlebars.json
│   │   │   │       ├── FolderPicker.handlebars
│   │   │   │       └── FolderPicker.handlebars.json
│   │   │   ├── package.json
│   │   │   ├── processMigrationContentItem.js
│   │   │   ├── react
│   │   │   │   ├── __tests__
│   │   │   │   │   └── app.test.tsx
│   │   │   │   ├── app.tsx
│   │   │   │   ├── components
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   ├── action_button.test.tsx
│   │   │   │   │   │   ├── completion_progress_bar.test.tsx
│   │   │   │   │   │   ├── content_selection_modal.test.tsx
│   │   │   │   │   │   ├── migration_row.test.tsx
│   │   │   │   │   │   ├── migrations_form.test.tsx
│   │   │   │   │   │   ├── migrations_table.test.tsx
│   │   │   │   │   │   ├── source_link.test.tsx
│   │   │   │   │   │   ├── status_pill.test.tsx
│   │   │   │   │   │   └── utils.test.ts
│   │   │   │   │   ├── action_button.tsx
│   │   │   │   │   ├── completion_progress_bar.tsx
│   │   │   │   │   ├── content_selection_modal.tsx
│   │   │   │   │   ├── migration_row.tsx
│   │   │   │   │   ├── migrations_form.tsx
│   │   │   │   │   ├── migrations_table.tsx
│   │   │   │   │   ├── migrator_forms
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── angel_importer.test.tsx
│   │   │   │   │   │   │   ├── blackboard_importer.test.tsx
│   │   │   │   │   │   │   ├── canvas_cartridge.test.tsx
│   │   │   │   │   │   │   ├── common_cartridge.test.tsx
│   │   │   │   │   │   │   ├── course_copy.test.tsx
│   │   │   │   │   │   │   ├── d2l_importer.test.tsx
│   │   │   │   │   │   │   ├── external_tool_importer.test.tsx
│   │   │   │   │   │   │   ├── file_input.test.tsx
│   │   │   │   │   │   │   ├── import_clear_label.test.tsx
│   │   │   │   │   │   │   ├── import_in_progress_label.test.tsx
│   │   │   │   │   │   │   ├── import_label.test.tsx
│   │   │   │   │   │   │   ├── moodle_zip.test.tsx
│   │   │   │   │   │   │   ├── qti_zip.test.tsx
│   │   │   │   │   │   │   ├── question_bank_selector.test.tsx
│   │   │   │   │   │   │   ├── shared_form_cases.tsx
│   │   │   │   │   │   │   └── zip_file.test.tsx
│   │   │   │   │   │   ├── angel_importer.tsx
│   │   │   │   │   │   ├── blackboard_importer.tsx
│   │   │   │   │   │   ├── canvas_cartridge.tsx
│   │   │   │   │   │   ├── common_cartridge.tsx
│   │   │   │   │   │   ├── common_components
│   │   │   │   │   │   │   └── async_course_search_select.tsx
│   │   │   │   │   │   ├── course_copy.tsx
│   │   │   │   │   │   ├── d2l_importer.tsx
│   │   │   │   │   │   ├── external_tool_importer.tsx
│   │   │   │   │   │   ├── file_input.tsx
│   │   │   │   │   │   ├── import_clear_label.tsx
│   │   │   │   │   │   ├── import_in_progress_label.tsx
│   │   │   │   │   │   ├── import_label.tsx
│   │   │   │   │   │   ├── moodle_zip.tsx
│   │   │   │   │   │   ├── qti_zip.tsx
│   │   │   │   │   │   ├── question_bank_selector.tsx
│   │   │   │   │   │   ├── types.ts
│   │   │   │   │   │   └── zip_file.tsx
│   │   │   │   │   ├── source_link.tsx
│   │   │   │   │   ├── status_pill.tsx
│   │   │   │   │   ├── types.ts
│   │   │   │   │   └── utils.ts
│   │   │   │   └── hooks
│   │   │   │       ├── __tests__
│   │   │   │       │   └── form_handler_hooks.test.tsx
│   │   │   │       └── form_handler_hooks.ts
│   │   │   └── setup.js
│   │   ├── content_notices
│   │   │   ├── index.jsx
│   │   │   └── package.json
│   │   ├── content_shares
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── ContentHeading.jsx
│   │   │       ├── CourseImportPanel.jsx
│   │   │       ├── PreviewModal.jsx
│   │   │       ├── ReceivedContentView.jsx
│   │   │       ├── ReceivedTable.jsx
│   │   │       └── __tests__
│   │   │           ├── ContentHeading.test.jsx
│   │   │           ├── CourseImportPanel.test.jsx
│   │   │           ├── PreviewModal.test.jsx
│   │   │           ├── ReceivedContentView.test.jsx
│   │   │           ├── ReceivedTable.test.jsx
│   │   │           └── test-utils.js
│   │   ├── context_media_object_inline
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── context_module_progressions
│   │   │   ├── backbone
│   │   │   │   └── views
│   │   │   │       ├── ProgressionModuleView.js
│   │   │   │       └── ProgressionStudentView.js
│   │   │   ├── index.jsx
│   │   │   ├── jst
│   │   │   │   ├── ProgressionModuleCollection.handlebars
│   │   │   │   ├── ProgressionModuleCollection.handlebars.json
│   │   │   │   ├── ProgressionModuleView.handlebars
│   │   │   │   ├── ProgressionModuleView.handlebars.json
│   │   │   │   ├── ProgressionStudentView.handlebars
│   │   │   │   ├── ProgressionStudentView.handlebars.json
│   │   │   │   ├── ProgressionsIndex.handlebars
│   │   │   │   └── ProgressionsIndex.handlebars.json
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       └── components
│   │   │           └── ProgressionModuleHeader.tsx
│   │   ├── context_modules
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── ModulesHomePage.jsx
│   │   │       └── __tests__
│   │   │           └── ModulesHomePage.test.jsx
│   │   ├── context_modules_publish_icon
│   │   │   ├── index.tsx
│   │   │   └── package.json
│   │   ├── context_modules_publish_menu
│   │   │   ├── index.tsx
│   │   │   └── package.json
│   │   ├── context_modules_v2
│   │   │   ├── index.tsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── ModulesContainer.tsx
│   │   │       ├── ModulesStudentContainer.tsx
│   │   │       ├── components
│   │   │       │   ├── CompletionRequirementInfo.tsx
│   │   │       │   ├── DueDateLabel.tsx
│   │   │       │   ├── ModuleItemSupplementalInfo.tsx
│   │   │       │   └── __tests__
│   │   │       │       ├── CompletionRequirementInfo.test.tsx
│   │   │       │       ├── DueDateLabel.test.tsx
│   │   │       │       └── ModuleItemSupplementalInfo.test.tsx
│   │   │       ├── componentsStudents
│   │   │       │   ├── ModuleHeaderStudent.tsx
│   │   │       │   ├── ModuleItemListStudent.tsx
│   │   │       │   ├── ModuleItemStudent.tsx
│   │   │       │   ├── ModuleListStudent.tsx
│   │   │       │   ├── ModulePageActionHeaderStudent.tsx
│   │   │       │   └── ModuleStudent.tsx
│   │   │       ├── componentsTeacher
│   │   │       │   ├── AddItemModalComponents
│   │   │       │   │   ├── AddItemModal.tsx
│   │   │       │   │   ├── AddItemTypeSelector.tsx
│   │   │       │   │   ├── CreateLearningObjectForm.tsx
│   │   │       │   │   ├── ExternalItemForm.tsx
│   │   │       │   │   └── IndentSelector.tsx
│   │   │       │   ├── BlueprintLockIcon.tsx
│   │   │       │   ├── EditItemModal.tsx
│   │   │       │   ├── ManageModuleContent
│   │   │       │   │   ├── ManageModuleContentTray.tsx
│   │   │       │   │   ├── ModuleSelect.tsx
│   │   │       │   │   ├── PositionSelect.tsx
│   │   │       │   │   ├── ReferenceSelect.tsx
│   │   │       │   │   └── TrayFooter.tsx
│   │   │       │   ├── Module.tsx
│   │   │       │   ├── ModuleActionMenu.tsx
│   │   │       │   ├── ModuleHeader.tsx
│   │   │       │   ├── ModuleHeaderActionPanel.tsx
│   │   │       │   ├── ModuleItem.tsx
│   │   │       │   ├── ModuleItemActionMenu.tsx
│   │   │       │   ├── ModuleItemActionPanel.tsx
│   │   │       │   ├── ModuleItemList.tsx
│   │   │       │   ├── ModuleItemTitle.tsx
│   │   │       │   ├── ModulePageActionHeader.tsx
│   │   │       │   ├── ModulesList.tsx
│   │   │       │   └── __tests__
│   │   │       │       ├── BlueprintLockIcon.test.tsx
│   │   │       │       ├── EditItemModal.test.tsx
│   │   │       │       ├── ModuleItemActionMenu.test.tsx
│   │   │       │       ├── ModuleItemActionPanel.test.tsx
│   │   │       │       └── ModuleItemTitle.test.tsx
│   │   │       ├── dnd
│   │   │       │   └── types.ts
│   │   │       ├── handlers
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── addItemHandlers.test.tsx
│   │   │       │   │   ├── dataMocks.ts
│   │   │       │   │   ├── editItemHandlers.test.tsx
│   │   │       │   │   └── manageModuleContentsHandlers.test.tsx
│   │   │       │   ├── addItemHandlers.ts
│   │   │       │   ├── editItemHandlers.ts
│   │   │       │   ├── manageModuleContentsHandlers.ts
│   │   │       │   ├── moduleActionHandlers.ts
│   │   │       │   ├── moduleItemActionHandlers.ts
│   │   │       │   └── modulePageActionHandlers.tsx
│   │   │       ├── hooks
│   │   │       │   ├── mutations
│   │   │       │   │   ├── useReorderModuleItems.ts
│   │   │       │   │   └── useReorderModules.ts
│   │   │       │   ├── queries
│   │   │       │   │   ├── useAssignmentGroups.ts
│   │   │       │   │   ├── useCourseFolders.ts
│   │   │       │   │   ├── useModuleItemContent.ts
│   │   │       │   │   ├── useModuleItems.ts
│   │   │       │   │   └── useModules.ts
│   │   │       │   └── useModuleContext.tsx
│   │   │       └── utils
│   │   │           ├── assignToUtils.tsx
│   │   │           ├── dndUtils.ts
│   │   │           ├── types.d.ts
│   │   │           └── utils.tsx
│   │   ├── context_prior_users
│   │   │   └── index.jsx
│   │   ├── context_roster_groups
│   │   │   └── index.jsx
│   │   ├── context_roster_usage
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── context_roster_user
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── StudentLastAttended.jsx
│   │   │       ├── __tests__
│   │   │       │   └── StudentLastAttended.test.jsx
│   │   │       └── index.jsx
│   │   ├── context_roster_user_services
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── context_undelete_item
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── conversations
│   │   │   └── react
│   │   │       ├── ConversationStatusFilter.jsx
│   │   │       └── __tests__
│   │   │           └── ConversationStatusFilter.test.jsx
│   │   ├── copy_course
│   │   │   ├── index.js
│   │   │   ├── legacyLoader.js
│   │   │   ├── package.json
│   │   │   ├── react
│   │   │   │   ├── App.tsx
│   │   │   │   ├── components
│   │   │   │   │   ├── CourseCopy.tsx
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   └── CourseCopy.test.tsx
│   │   │   │   │   └── form
│   │   │   │   │       ├── CopyCourseForm.tsx
│   │   │   │   │       ├── __tests__
│   │   │   │   │       │   ├── CopyCourseForm1.test.tsx
│   │   │   │   │       │   └── CopyCourseForm2.test.tsx
│   │   │   │   │       └── formComponents
│   │   │   │   │           ├── ConfiguredDateInput.tsx
│   │   │   │   │           ├── ConfiguredSelectInput.tsx
│   │   │   │   │           ├── ConfiguredTextInput.tsx
│   │   │   │   │           ├── CreateCourseCancelLabel.tsx
│   │   │   │   │           ├── CreateCourseInProgressLabel.tsx
│   │   │   │   │           ├── CreateCourseLabel.tsx
│   │   │   │   │           └── __tests__
│   │   │   │   │               ├── ConfiguredDateInput.test.tsx
│   │   │   │   │               ├── ConfiguredSelectInput.test.tsx
│   │   │   │   │               ├── ConfiguredTextInput.test.tsx
│   │   │   │   │               ├── CreateCourseCancelLabel.test.tsx
│   │   │   │   │               ├── CreateCourseInProgressLabel.test.tsx
│   │   │   │   │               └── CreateCourseLabel.test.tsx
│   │   │   │   ├── mutations
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   └── createCourseCopyMutation.test.ts
│   │   │   │   │   └── createCourseCopyMutation.ts
│   │   │   │   ├── queries
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   ├── courseQuery.test.ts
│   │   │   │   │   │   └── termsQuery.test.tsx
│   │   │   │   │   ├── courseQuery.ts
│   │   │   │   │   └── termsQuery.ts
│   │   │   │   └── types.ts
│   │   │   └── reactLoader.tsx
│   │   ├── copy_warnings_modal
│   │   │   ├── index.tsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── CopyWarningsModal.tsx
│   │   │       └── __test__
│   │   │           └── CopyWarningsModal.test.tsx
│   │   ├── course
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── index.js
│   │   │   └── package.json
│   │   ├── course_grading_standards
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── CourseTabContainer.jsx
│   │   │       ├── __tests__
│   │   │       │   ├── CourseTabContainer.test.jsx
│   │   │       │   ├── GradingPeriod.test.jsx
│   │   │       │   ├── GradingPeriodCollection.test.jsx
│   │   │       │   └── GradingPeriodTemplate.test.jsx
│   │   │       ├── gradingPeriod.jsx
│   │   │       ├── gradingPeriodCollection.jsx
│   │   │       └── gradingPeriodTemplate.jsx
│   │   ├── course_link_validator
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── LinkValidator.jsx
│   │   │       ├── ValidatorResults.jsx
│   │   │       ├── ValidatorResultsRow.jsx
│   │   │       └── __tests__
│   │   │           └── LinkValidator.test.jsx
│   │   ├── course_list
│   │   │   ├── index.jsx
│   │   │   └── package.json
│   │   ├── course_notification_settings
│   │   │   ├── index.jsx
│   │   │   └── package.json
│   │   ├── course_paces
│   │   │   ├── constants.ts
│   │   │   ├── images
│   │   │   │   ├── PandaShowingPaces.svg
│   │   │   │   └── PandaUsingPaces.svg
│   │   │   ├── index.tsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── __tests__
│   │   │       │   ├── app.test.tsx
│   │   │       │   ├── fixtures.ts
│   │   │       │   └── utils.tsx
│   │   │       ├── actions
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── course_paces.test.ts
│   │   │       │   │   └── pace_contexts.test.ts
│   │   │       │   ├── bulk_edit_students_actions.ts
│   │   │       │   ├── course_pace_items.ts
│   │   │       │   ├── course_paces.ts
│   │   │       │   ├── pace_contexts.ts
│   │   │       │   └── ui.ts
│   │   │       ├── api
│   │   │       │   ├── blackout_dates_api.ts
│   │   │       │   ├── course_pace_api.ts
│   │   │       │   ├── course_reports_api.ts
│   │   │       │   └── pace_contexts_api.ts
│   │   │       ├── app.tsx
│   │   │       ├── components
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── bulk_edit_students.test.tsx
│   │   │       │   │   ├── bulk_edit_students_table.test.tsx
│   │   │       │   │   ├── content.test.tsx
│   │   │       │   │   ├── errors.test.tsx
│   │   │       │   │   ├── footer.test.tsx
│   │   │       │   │   ├── pace_contexts_table.test.tsx
│   │   │       │   │   ├── pace_download_modal.test.tsx
│   │   │       │   │   ├── search.test.tsx
│   │   │       │   │   ├── unpublished_changes_indicator.test.tsx
│   │   │       │   │   └── unpublished_changes_tray_contents.test.tsx
│   │   │       │   ├── body.tsx
│   │   │       │   ├── bulk_edit_students.tsx
│   │   │       │   ├── bulk_edit_students_table.tsx
│   │   │       │   ├── content.tsx
│   │   │       │   ├── course_pace_table
│   │   │       │   │   ├── __tests__
│   │   │       │   │   │   ├── assignment_row.test.tsx
│   │   │       │   │   │   ├── blackout_date_row.test.tsx
│   │   │       │   │   │   ├── flaggable_number_input.test.tsx
│   │   │       │   │   │   └── module.test.tsx
│   │   │       │   │   ├── assignment_row.tsx
│   │   │       │   │   ├── blackout_date_row.tsx
│   │   │       │   │   ├── course_pace_empty.tsx
│   │   │       │   │   ├── course_pace_table.tsx
│   │   │       │   │   ├── flaggable_number_input.tsx
│   │   │       │   │   └── module.tsx
│   │   │       │   ├── errors.stories.tsx
│   │   │       │   ├── errors.tsx
│   │   │       │   ├── footer.tsx
│   │   │       │   ├── header
│   │   │       │   │   ├── __tests__
│   │   │       │   │   │   ├── header.test.tsx
│   │   │       │   │   │   └── pace_picker.test.tsx
│   │   │       │   │   ├── blueprint_lock.tsx
│   │   │       │   │   ├── header.tsx
│   │   │       │   │   ├── pace_picker.tsx
│   │   │       │   │   ├── projected_dates
│   │   │       │   │   │   ├── __tests__
│   │   │       │   │   │   │   └── projected_dates.test.tsx
│   │   │       │   │   │   └── projected_dates.tsx
│   │   │       │   │   ├── settings
│   │   │       │   │   │   ├── MainMenu.tsx
│   │   │       │   │   │   ├── SettingsMenu.tsx
│   │   │       │   │   │   ├── SkipSelectedDaysMenu.tsx
│   │   │       │   │   │   ├── WeightedAssignmentsTray.tsx
│   │   │       │   │   │   ├── __tests__
│   │   │       │   │   │   │   ├── settings.test.tsx
│   │   │       │   │   │   │   └── weighted_assignments_tray.test.tsx
│   │   │       │   │   │   └── settings.tsx
│   │   │       │   │   └── unpublished_warning_modal.tsx
│   │   │       │   ├── no_results.tsx
│   │   │       │   ├── pace_contexts_table.tsx
│   │   │       │   ├── pace_download_modal.tsx
│   │   │       │   ├── pace_modal
│   │   │       │   │   ├── CourseStats.tsx
│   │   │       │   │   ├── TimeSelection.tsx
│   │   │       │   │   ├── __tests__
│   │   │       │   │   │   ├── course_stats.test.tsx
│   │   │       │   │   │   ├── heading.test.tsx
│   │   │       │   │   │   ├── pace_modal.test.tsx
│   │   │       │   │   │   ├── stats.test.tsx
│   │   │       │   │   │   └── time_selection.test.tsx
│   │   │       │   │   ├── heading.tsx
│   │   │       │   │   ├── index.tsx
│   │   │       │   │   └── stats.tsx
│   │   │       │   ├── remove_pace_warning_modal.tsx
│   │   │       │   ├── reset_pace_warning_modal.tsx
│   │   │       │   ├── search.tsx
│   │   │       │   ├── unpublished_changes_indicator.tsx
│   │   │       │   └── unpublished_changes_tray_contents.tsx
│   │   │       ├── reducers
│   │   │       │   ├── __tests__
│   │   │       │   │   └── course_paces.test.ts
│   │   │       │   ├── bulk_edit_students_reducer.ts
│   │   │       │   ├── course.ts
│   │   │       │   ├── course_pace_items.ts
│   │   │       │   ├── course_paces.ts
│   │   │       │   ├── enrollments.ts
│   │   │       │   ├── original.ts
│   │   │       │   ├── pace_contexts.ts
│   │   │       │   ├── reducers.ts
│   │   │       │   ├── sections.ts
│   │   │       │   └── ui.ts
│   │   │       ├── shared
│   │   │       │   ├── actions
│   │   │       │   │   └── blackout_dates.ts
│   │   │       │   ├── api
│   │   │       │   │   └── backend_serializer.ts
│   │   │       │   ├── components
│   │   │       │   │   ├── __tests__
│   │   │       │   │   │   ├── blackout_dates.test.tsx
│   │   │       │   │   │   ├── blackout_dates_modal.test.tsx
│   │   │       │   │   │   ├── course_pace_date_input.test.tsx
│   │   │       │   │   │   └── new_blackout_dates_form.test.tsx
│   │   │       │   │   ├── blackout_dates.tsx
│   │   │       │   │   ├── blackout_dates_modal.tsx
│   │   │       │   │   ├── blackout_dates_table.tsx
│   │   │       │   │   ├── course_pace_date_input.tsx
│   │   │       │   │   └── new_blackout_dates_form.tsx
│   │   │       │   ├── create_store.ts
│   │   │       │   ├── reducers
│   │   │       │   │   └── blackout_dates.ts
│   │   │       │   └── types.ts
│   │   │       ├── types.ts
│   │   │       └── utils
│   │   │           ├── __tests__
│   │   │           │   ├── change_tracking.test.ts
│   │   │           │   ├── date_helpers.test.ts
│   │   │           │   ├── slide_transition.test.tsx
│   │   │           │   └── utils.test.ts
│   │   │           ├── blackout-dates-lined.svg
│   │   │           ├── change_tracking.ts
│   │   │           ├── constants.tsx
│   │   │           ├── date_stuff
│   │   │           │   ├── date_helpers.ts
│   │   │           │   └── pace_due_dates_calculator.ts
│   │   │           ├── slide_transition.tsx
│   │   │           └── utils.tsx
│   │   ├── course_people
│   │   │   ├── graphql
│   │   │   │   ├── Mocks.js
│   │   │   │   └── Queries.js
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   ├── react
│   │   │   │   ├── components
│   │   │   │   │   ├── AvatarLink
│   │   │   │   │   │   ├── AvatarLink.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── AvatarLink.test.jsx
│   │   │   │   │   ├── NameLink
│   │   │   │   │   │   ├── NameLink.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── NameLink.test.jsx
│   │   │   │   │   ├── RosterCard
│   │   │   │   │   │   ├── RosterCard.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── RosterCard.test.jsx
│   │   │   │   │   ├── RosterTableLastActivity
│   │   │   │   │   │   ├── RosterTableLastActivity.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── RosterTableLastActivity.test.jsx
│   │   │   │   │   ├── RosterTableRoles
│   │   │   │   │   │   ├── RosterTableRoles.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── RosterTableRoles.test.jsx
│   │   │   │   │   ├── RosterTableRowMenuButton
│   │   │   │   │   │   ├── RosterTableRowMenuButton.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── RosterTableRowMenuButton.test.jsx
│   │   │   │   │   └── StatusPill
│   │   │   │   │       ├── StatusPill.jsx
│   │   │   │   │       └── __tests__
│   │   │   │   │           └── StatusPill.test.jsx
│   │   │   │   ├── containers
│   │   │   │   │   ├── CoursePeople.jsx
│   │   │   │   │   ├── RosterCardView
│   │   │   │   │   │   ├── RosterCardView.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── RosterCardView.test.jsx
│   │   │   │   │   ├── RosterTable
│   │   │   │   │   │   ├── RosterTable.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── RosterTable.test.jsx
│   │   │   │   │   └── __tests__
│   │   │   │   │       └── CoursePeople.test.jsx
│   │   │   │   └── index.jsx
│   │   │   └── util
│   │   │       ├── constants.js
│   │   │       ├── test-constants.js
│   │   │       └── utils.js
│   │   ├── course_people_new
│   │   │   ├── graphql
│   │   │   │   ├── Mocks.js
│   │   │   │   └── Queries.tsx
│   │   │   ├── images
│   │   │   │   └── NotFound.svg
│   │   │   ├── index.tsx
│   │   │   ├── package.json
│   │   │   ├── react
│   │   │   │   ├── CoursePeople.tsx
│   │   │   │   ├── CoursePeopleApp.tsx
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── CoursePeople.test.tsx
│   │   │   │   │   └── CoursePeopleApp.test.tsx
│   │   │   │   ├── components
│   │   │   │   │   ├── FilterPeople
│   │   │   │   │   │   ├── PeopleFilter.tsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── PeopleFilter.test.tsx
│   │   │   │   │   ├── PageHeader
│   │   │   │   │   │   ├── CoursePeopleHeader.tsx
│   │   │   │   │   │   ├── CoursePeopleOptionsMenu.tsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       ├── CoursePeopleHeader.test.tsx
│   │   │   │   │   │       └── CoursePeopleOptionsMenu.test.tsx
│   │   │   │   │   ├── RosterTable
│   │   │   │   │   │   ├── RosterTable.tsx
│   │   │   │   │   │   ├── RosterTableHeader.tsx
│   │   │   │   │   │   ├── RosterTableRow.tsx
│   │   │   │   │   │   ├── StatusPill.tsx
│   │   │   │   │   │   ├── UserLastActivity.tsx
│   │   │   │   │   │   ├── UserLink.tsx
│   │   │   │   │   │   ├── UserMenu.tsx
│   │   │   │   │   │   ├── UserRole.tsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       ├── RosterTable.test.tsx
│   │   │   │   │   │       ├── RosterTableHeader.test.tsx
│   │   │   │   │   │       ├── RosterTableRow.test.tsx
│   │   │   │   │   │       ├── StatusPill.test.tsx
│   │   │   │   │   │       ├── UserLastActivity.test.tsx
│   │   │   │   │   │       ├── UserLink.test.tsx
│   │   │   │   │   │       ├── UserMenu.test.tsx
│   │   │   │   │   │       └── UserRole.test.tsx
│   │   │   │   │   └── SearchPeople
│   │   │   │   │       ├── NoPeopleFound.tsx
│   │   │   │   │       ├── PeopleSearchBar.tsx
│   │   │   │   │       └── __tests__
│   │   │   │   │           ├── NoPeopleFound.test.tsx
│   │   │   │   │           └── PeopleSearchBar.test.tsx
│   │   │   │   ├── contexts
│   │   │   │   │   └── CoursePeopleContext.tsx
│   │   │   │   └── hooks
│   │   │   │       ├── __tests__
│   │   │   │       │   ├── useCoursePeopleQuery.test.tsx
│   │   │   │       │   └── useSearch.test.tsx
│   │   │   │       ├── useCoursePeopleContext.tsx
│   │   │   │       ├── useCoursePeopleQuery.tsx
│   │   │   │       └── useSearch.tsx
│   │   │   ├── types.d.ts
│   │   │   └── util
│   │   │       ├── __tests__
│   │   │       │   └── utils.test.ts
│   │   │       ├── constants.ts
│   │   │       └── utils.ts
│   │   ├── course_settings
│   │   │   ├── backbone
│   │   │   │   └── views
│   │   │   │       └── NavigationView.js
│   │   │   ├── index.tsx
│   │   │   ├── jquery
│   │   │   │   ├── __tests__
│   │   │   │   │   └── courseSettingsHelper.test.js
│   │   │   │   ├── course_settings_helper.js
│   │   │   │   └── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── CourseSettingsRoute.tsx
│   │   │       ├── __tests__
│   │   │       │   ├── actions.test.js
│   │   │       │   ├── helpers.spec.js
│   │   │       │   └── reducers.spec.js
│   │   │       ├── actions.js
│   │   │       ├── components
│   │   │       │   ├── BlueprintLockOptions.jsx
│   │   │       │   ├── CSPSelectionBox.jsx
│   │   │       │   ├── CourseApps.tsx
│   │   │       │   ├── CourseAvailabilityOptions.jsx
│   │   │       │   ├── CourseColorSelector.jsx
│   │   │       │   ├── CourseDefaultDueTime.tsx
│   │   │       │   ├── CourseImagePicker.jsx
│   │   │       │   ├── CourseImageSelector.jsx
│   │   │       │   ├── CourseImageSelector.stories.jsx
│   │   │       │   ├── CourseTemplateDetails.jsx
│   │   │       │   ├── ExpandableLockOptions.jsx
│   │   │       │   ├── ExpandableLockOptions.stories.jsx
│   │   │       │   ├── LockCheckList.jsx
│   │   │       │   ├── QuantitativeDataOptions.jsx
│   │   │       │   └── __tests__
│   │   │       │       ├── BlueprintLockOptions.test.jsx
│   │   │       │       ├── CSPSelectionBox.test.jsx
│   │   │       │       ├── CourseAvailabilityOptions.test.jsx
│   │   │       │       ├── CourseColorSelector.test.jsx
│   │   │       │       ├── CourseDefaultDueTime.test.tsx
│   │   │       │       ├── CourseImagePicker.test.jsx
│   │   │       │       ├── CourseImageSelector.test.jsx
│   │   │       │       ├── CourseTemplateDetails.test.jsx
│   │   │       │       ├── ExpandableLockOptions.test.jsx
│   │   │       │       ├── LockCheckList.test.jsx
│   │   │       │       └── QuantitativeDataOptions.test.jsx
│   │   │       ├── helpers.js
│   │   │       ├── reducer.js
│   │   │       ├── renderCSPSelectionBox.jsx
│   │   │       └── store
│   │   │           ├── configureStore.js
│   │   │           └── initialState.js
│   │   ├── course_show
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── behaviors
│   │   │   │       └── openAsDialog.js
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       └── show.jsx
│   │   ├── course_show_secondary
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── course_statistics
│   │   │   ├── backbone
│   │   │   │   └── views
│   │   │   │       ├── RecentStudentCollectionView.js
│   │   │   │       └── RecentStudentView.js
│   │   │   ├── index.js
│   │   │   ├── jst
│   │   │   │   ├── recentStudent.handlebars
│   │   │   │   └── recentStudent.handlebars.json
│   │   │   └── package.json
│   │   ├── course_wizard
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── Checklist.jsx
│   │   │       ├── ChecklistItem.jsx
│   │   │       ├── CourseWizard.jsx
│   │   │       ├── InfoFrame.jsx
│   │   │       └── ListItems.js
│   │   ├── courses
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── current_groups
│   │   │   ├── index.jsx
│   │   │   └── package.json
│   │   ├── dashboard
│   │   │   ├── backbone
│   │   │   │   └── views
│   │   │   │       └── DashboardView.js
│   │   │   ├── index.jsx
│   │   │   ├── jquery
│   │   │   │   └── util
│   │   │   │       └── newCourseForm.js
│   │   │   ├── jst
│   │   │   │   ├── show_more_link.handlebars
│   │   │   │   └── show_more_link.handlebars.json
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── DashboardHeader.jsx
│   │   │       ├── DashboardOptionsMenu.jsx
│   │   │       ├── DashboardWrapper.tsx
│   │   │       └── __tests__
│   │   │           ├── DashboardHeader.test.jsx
│   │   │           └── DashboardOptionsMenu.test.jsx
│   │   ├── deep_linking_response
│   │   │   ├── index.ts
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── DeepLinkingResponse.tsx
│   │   │       └── __tests__
│   │   │           └── DeepLinkingResponse.test.jsx
│   │   ├── developer_keys_v2
│   │   │   ├── global.d.ts
│   │   │   ├── index.js
│   │   │   ├── model
│   │   │   │   ├── LtiPlacements.ts
│   │   │   │   ├── LtiPrivacyLevel.ts
│   │   │   │   ├── LtiRegistration.ts
│   │   │   │   └── api
│   │   │   │       ├── DeveloperKey.ts
│   │   │   │       └── LtiToolConfiguration.ts
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── ActionButtons.jsx
│   │   │       ├── AdminTable.jsx
│   │   │       ├── App.jsx
│   │   │       ├── DeveloperKey.jsx
│   │   │       ├── InheritanceStateControl.jsx
│   │   │       ├── InheritedTable.jsx
│   │   │       ├── ManualConfigurationForm
│   │   │       │   ├── AdditionalSettings.jsx
│   │   │       │   ├── Placement.jsx
│   │   │       │   ├── Placements.jsx
│   │   │       │   ├── RequiredValues.jsx
│   │   │       │   ├── Services.jsx
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── AdditionalSettings.test.jsx
│   │   │       │   │   ├── Placement.test.jsx
│   │   │       │   │   ├── Placements.test.jsx
│   │   │       │   │   ├── RequiredValues.test.jsx
│   │   │       │   │   ├── Services.test.jsx
│   │   │       │   │   └── index.test.jsx
│   │   │       │   └── index.jsx
│   │   │       ├── NewKeyButtons.tsx
│   │   │       ├── NewKeyForm.tsx
│   │   │       ├── NewKeyModal.tsx
│   │   │       ├── NewKeyTrigger.jsx
│   │   │       ├── RegistrationSettings
│   │   │       │   ├── RegistrationOverlayForm.tsx
│   │   │       │   ├── RegistrationOverlayState.ts
│   │   │       │   ├── RegistrationPrivacyField.tsx
│   │   │       │   └── RegistrationSettings.tsx
│   │   │       ├── Scope.jsx
│   │   │       ├── Scopes.jsx
│   │   │       ├── ScopesGroup.jsx
│   │   │       ├── ScopesList.jsx
│   │   │       ├── ScopesMethod.jsx
│   │   │       ├── ToolConfigurationForm.jsx
│   │   │       ├── __tests__
│   │   │       │   ├── ActionButtons.test.jsx
│   │   │       │   ├── AdminTable.test.jsx
│   │   │       │   ├── App.test.jsx
│   │   │       │   ├── AppSpec1.test.jsx
│   │   │       │   ├── AppSpec2.test.jsx
│   │   │       │   ├── DeveloperKey.test.jsx
│   │   │       │   ├── InheritanceStateControl.test.jsx
│   │   │       │   ├── InheritedTable.test.jsx
│   │   │       │   ├── NewKeyForm.test.tsx
│   │   │       │   ├── NewKeyModal1.test.jsx
│   │   │       │   ├── NewKeyModal2.test.jsx
│   │   │       │   ├── NewKeyTrigger.test.jsx
│   │   │       │   ├── Scope.test.jsx
│   │   │       │   ├── Scopes.test.jsx
│   │   │       │   ├── ScopesGroup.test.jsx
│   │   │       │   ├── ScopesList.test.jsx
│   │   │       │   ├── ScopesMethod.test.jsx
│   │   │       │   ├── ToolConfigurationForm.test.jsx
│   │   │       │   └── fixtures
│   │   │       │       └── responses.js
│   │   │       ├── actions
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── developerKeysActions.test.js
│   │   │       │   │   └── ltiKeyActions.test.js
│   │   │       │   └── developerKeysActions.ts
│   │   │       ├── dynamic_registration
│   │   │       │   ├── DynamicRegistrationModal.tsx
│   │   │       │   ├── DynamicRegistrationState.ts
│   │   │       │   ├── __tests__
│   │   │       │   │   └── DynamicRegistrationModal.test.tsx
│   │   │       │   ├── developerKeyApi.ts
│   │   │       │   └── registrationApi.ts
│   │   │       ├── reducers
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── activateReducer.spec.js
│   │   │       │   │   ├── deactivateReducer.spec.js
│   │   │       │   │   ├── deleteReducer.spec.js
│   │   │       │   │   ├── listDeveloperKeysReducer.test.js
│   │   │       │   │   ├── listScopesReducer.test.js
│   │   │       │   │   ├── makeInvisibleReducer.spec.js
│   │   │       │   │   └── makeVisibleReducer.spec.js
│   │   │       │   ├── activateReducer.ts
│   │   │       │   ├── createOrEditReducer.ts
│   │   │       │   ├── deactivateReducer.ts
│   │   │       │   ├── deleteReducer.ts
│   │   │       │   ├── listDeveloperKeysReducer.ts
│   │   │       │   ├── listScopesReducer.ts
│   │   │       │   ├── makeInvisibleReducer.ts
│   │   │       │   ├── makeReducer.ts
│   │   │       │   └── makeVisibleReducer.ts
│   │   │       ├── router.jsx
│   │   │       └── store
│   │   │           └── store.ts
│   │   ├── discussion_topic
│   │   │   ├── __tests__
│   │   │   │   └── walk.spec.js
│   │   │   ├── array-walk.js
│   │   │   ├── backbone
│   │   │   │   ├── EntryEditor.js
│   │   │   │   ├── MarkAsReadWatcher.js
│   │   │   │   ├── Reply.js
│   │   │   │   ├── collections
│   │   │   │   │   └── EntryCollection.js
│   │   │   │   ├── models
│   │   │   │   │   ├── DiscussionFilterState.js
│   │   │   │   │   ├── Entry.js
│   │   │   │   │   ├── SideCommentDiscussionTopic.js
│   │   │   │   │   ├── Topic.js
│   │   │   │   │   └── __tests__
│   │   │   │   │       ├── Entry.test.js
│   │   │   │   │       └── Topic.spec.js
│   │   │   │   └── views
│   │   │   │       ├── DiscussionFilterResultsView.js
│   │   │   │       ├── DiscussionToolbarView.jsx
│   │   │   │       ├── DiscussionTopicToolbarView.js
│   │   │   │       ├── EntriesView.js
│   │   │   │       ├── EntryCollectionView.js
│   │   │   │       ├── EntryView.js
│   │   │   │       ├── FilterEntryView.js
│   │   │   │       ├── TopicView.jsx
│   │   │   │       └── __tests__
│   │   │   │           ├── DiscussionTopicToolbarView.test.js
│   │   │   │           ├── EntryView.test.js
│   │   │   │           └── TopicView.test.jsx
│   │   │   ├── index.jsx
│   │   │   ├── jst
│   │   │   │   ├── EntryCollectionView.handlebars
│   │   │   │   ├── EntryCollectionView.handlebars.json
│   │   │   │   ├── _author_link.handlebars
│   │   │   │   ├── _author_link.handlebars.json
│   │   │   │   ├── _deleted_entry.handlebars
│   │   │   │   ├── _deleted_entry.handlebars.json
│   │   │   │   ├── _entry_content.handlebars
│   │   │   │   ├── _entry_content.handlebars.json
│   │   │   │   ├── _reply_attachment.handlebars
│   │   │   │   ├── _reply_attachment.handlebars.json
│   │   │   │   ├── _reply_form.handlebars
│   │   │   │   ├── _reply_form.handlebars.json
│   │   │   │   ├── entryStats.handlebars
│   │   │   │   ├── entryStats.handlebars.json
│   │   │   │   ├── entry_with_replies.handlebars
│   │   │   │   ├── entry_with_replies.handlebars.json
│   │   │   │   ├── noResults.handlebars
│   │   │   │   ├── noResults.handlebars.json
│   │   │   │   ├── pageNav.handlebars
│   │   │   │   ├── pageNav.handlebars.json
│   │   │   │   ├── results_entry.handlebars
│   │   │   │   └── results_entry.handlebars.json
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── DiscussionTopicKeyboardShortcutModal.jsx
│   │   │       ├── KeyboardShortcutModal.jsx
│   │   │       └── __tests__
│   │   │           ├── DiscussionTopicKeyboardShortcutModal.test.jsx
│   │   │           └── KeyboardShortcutModal.test.jsx
│   │   ├── discussion_topic_edit
│   │   │   ├── backbone
│   │   │   │   └── views
│   │   │   │       ├── EditView.jsx
│   │   │   │       ├── PostToSisSelector.js
│   │   │   │       └── __tests__
│   │   │   │           ├── EditView1.test.js
│   │   │   │           ├── EditView2.test.js
│   │   │   │           ├── EditView3.test.js
│   │   │   │           ├── EditView4.test.js
│   │   │   │           └── utils.js
│   │   │   ├── index.jsx
│   │   │   ├── jst
│   │   │   │   ├── EditView.handlebars
│   │   │   │   ├── EditView.handlebars.json
│   │   │   │   ├── PostToSisSelector.handlebars
│   │   │   │   ├── PostToSisSelector.handlebars.json
│   │   │   │   ├── _publishedButton.handlebars
│   │   │   │   └── _publishedButton.handlebars.json
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── AnonymousPostSelector
│   │   │       │   ├── AnonymousPostSelector.jsx
│   │   │       │   ├── AnonymousPostSelector.stories.jsx
│   │   │       │   └── __tests__
│   │   │       │       └── AnonymousPostSelector.test.jsx
│   │   │       ├── DiscussionFormOptions.tsx
│   │   │       ├── SectionsAutocomplete.jsx
│   │   │       ├── __tests__
│   │   │       │   └── SectionsAutocomplete.test.jsx
│   │   │       └── proptypes
│   │   │           └── sectionShape.js
│   │   ├── discussion_topic_edit_v2
│   │   │   ├── graphql
│   │   │   │   ├── Assignment.js
│   │   │   │   ├── AssignmentGroup.js
│   │   │   │   ├── AssignmentOverride.js
│   │   │   │   ├── Attachment.js
│   │   │   │   ├── ContextModule.js
│   │   │   │   ├── Course.js
│   │   │   │   ├── DiscussionTopic.js
│   │   │   │   ├── Group.js
│   │   │   │   ├── GroupSet.js
│   │   │   │   ├── Mutations.js
│   │   │   │   ├── Queries.js
│   │   │   │   ├── Section.js
│   │   │   │   └── UsageRights.js
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── __tests__
│   │   │       │   └── DiscussionTopicEdit.test.jsx
│   │   │       ├── components
│   │   │       │   ├── DiscussionOptions
│   │   │       │   │   ├── AnonymousSelector.tsx
│   │   │       │   │   ├── AssignedTo.jsx
│   │   │       │   │   ├── AssignmentDueDate.jsx
│   │   │       │   │   ├── AssignmentDueDate.stories.jsx
│   │   │       │   │   ├── AssignmentGroupSelect.tsx
│   │   │       │   │   ├── CheckpointsSettings.tsx
│   │   │       │   │   ├── DisplayGradeAs.tsx
│   │   │       │   │   ├── GradedDiscussionOptions.tsx
│   │   │       │   │   ├── ItemAssignToTrayWrapper.jsx
│   │   │       │   │   ├── NonGradedDateOptions.tsx
│   │   │       │   │   ├── PeerReviewOptions.jsx
│   │   │       │   │   ├── PointsPossible.tsx
│   │   │       │   │   ├── SyncToSisCheckbox.tsx
│   │   │       │   │   ├── UsageRights.jsx
│   │   │       │   │   ├── ViewSettings.tsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       ├── AssignedTo.test.jsx
│   │   │       │   │       ├── AssignmentAssignedInfo.test.jsx
│   │   │       │   │       ├── AssignmentGroupSelect.test.jsx
│   │   │       │   │       ├── CheckpointsSettings.test.jsx
│   │   │       │   │       ├── DisplayGradeAs.test.jsx
│   │   │       │   │       ├── GradedDiscussionOptions.test.jsx
│   │   │       │   │       ├── PeerReviewOptions.test.jsx
│   │   │       │   │       ├── PointsPossible.test.jsx
│   │   │       │   │       ├── UsageRights.test.jsx
│   │   │       │   │       └── ViewSettings.test.jsx
│   │   │       │   ├── DiscussionTopicForm
│   │   │       │   │   ├── DiscussionTopicForm.jsx
│   │   │       │   │   ├── DiscussionTopicForm.stories.jsx
│   │   │       │   │   ├── DiscussionTopicFormViewSelector.tsx
│   │   │       │   │   ├── FormControlButtons.tsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       ├── DiscussionTopicForm1.test.jsx
│   │   │       │   │       ├── DiscussionTopicForm2.test.jsx
│   │   │       │   │       ├── DiscussionTopicForm3.test.jsx
│   │   │       │   │       ├── DiscussionTopicForm4.test.jsx
│   │   │       │   │       ├── DiscussionTopicForm5.test.jsx
│   │   │       │   │       └── DiscussionTopicFormViewSelector.test.jsx
│   │   │       │   ├── GroupCategoryModal
│   │   │       │   │   ├── GroupCategoryModal.jsx
│   │   │       │   │   ├── GroupCategoryModal.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── GroupCategoryModal.test.jsx
│   │   │       │   ├── MissingSectionsWarningModal
│   │   │       │   │   ├── MissingSectionsWarningModal.tsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── MissingSectionsWarningModal.test.jsx
│   │   │       │   ├── SavingDiscussionTopicOverlay
│   │   │       │   │   └── SavingDiscussionTopicOverlay.tsx
│   │   │       │   └── SendEditNotificationModal
│   │   │       │       ├── SendEditNotificationModal.tsx
│   │   │       │       └── index.tsx
│   │   │       ├── containers
│   │   │       │   ├── DiscussionTopicFormContainer
│   │   │       │   │   ├── DiscussionTopicFormContainer.jsx
│   │   │       │   │   └── DiscussionTopicFormContainer.stories.jsx
│   │   │       │   └── usageRights
│   │   │       │       └── UsageRightsContainer.jsx
│   │   │       ├── index.jsx
│   │   │       └── util
│   │   │           ├── __tests__
│   │   │           │   ├── payloadPreparations.test.js
│   │   │           │   └── utils.test.js
│   │   │           ├── constants.jsx
│   │   │           ├── formValidation.js
│   │   │           ├── payloadPreparations.js
│   │   │           ├── setUsageRights.ts
│   │   │           ├── usageRightsConstants.js
│   │   │           └── utils.js
│   │   ├── discussion_topic_insights
│   │   │   ├── graphql
│   │   │   │   └── Queries.ts
│   │   │   ├── images
│   │   │   │   └── no-discussion.svg
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── DiscussionInsightsPage.tsx
│   │   │       ├── components
│   │   │       │   ├── DiscussionInsights
│   │   │       │   │   ├── DiscussionInsights.tsx
│   │   │       │   │   ├── Placeholder.tsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── DiscussionInsights.test.tsx
│   │   │       │   ├── FilterDropDown
│   │   │       │   │   └── FilterDropDown.tsx
│   │   │       │   ├── InsightsActionBar
│   │   │       │   │   └── InsightsActionBar.tsx
│   │   │       │   ├── InsightsHeader
│   │   │       │   │   └── InsightsHeader.tsx
│   │   │       │   ├── InsightsModal
│   │   │       │   │   ├── DisagreeFeedback.tsx
│   │   │       │   │   ├── EvaluationFeedback.tsx
│   │   │       │   │   └── ReviewModal.tsx
│   │   │       │   ├── InsightsSearchBar
│   │   │       │   │   └── InsightsSearchBar.tsx
│   │   │       │   ├── InsightsTable
│   │   │       │   │   ├── InsightsTable.tsx
│   │   │       │   │   ├── PaginatedTable.tsx
│   │   │       │   │   ├── SimpleTable.tsx
│   │   │       │   │   └── SortableTable.tsx
│   │   │       │   └── NewActivityInfo
│   │   │       │       └── NewActivityInfo.tsx
│   │   │       ├── hooks
│   │   │       │   ├── useFetchInsights.ts
│   │   │       │   ├── useInsightStore.ts
│   │   │       │   └── useUpdateEntry.ts
│   │   │       ├── index.jsx
│   │   │       └── utils.tsx
│   │   ├── discussion_topics_index
│   │   │   ├── images
│   │   │   │   ├── closed-comments.svg
│   │   │   │   ├── pinned.svg
│   │   │   │   └── unpinned.svg
│   │   │   ├── index.js
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── __tests__
│   │   │       │   ├── actions.test.js
│   │   │       │   ├── index.test.js
│   │   │       │   ├── reducer.spec.js
│   │   │       │   └── sampleData.js
│   │   │       ├── actions.js
│   │   │       ├── apiClient.js
│   │   │       ├── components
│   │   │       │   ├── DisallowThreadedFixAlert.jsx
│   │   │       │   ├── DiscussionBackgrounds.jsx
│   │   │       │   ├── DiscussionContainer.jsx
│   │   │       │   ├── DiscussionManageMenu.jsx
│   │   │       │   ├── DiscussionRow.jsx
│   │   │       │   ├── DiscussionSettings.jsx
│   │   │       │   ├── DiscussionsDeleteModal.jsx
│   │   │       │   ├── DiscussionsIndex.jsx
│   │   │       │   ├── IndexHeader.jsx
│   │   │       │   └── __tests__
│   │   │       │       ├── DisallowThreadedFixAlert.test.jsx
│   │   │       │       ├── DiscussionBackgrounds.test.jsx
│   │   │       │       ├── DiscussionContainer.test.jsx
│   │   │       │       ├── DiscussionRow1.test.jsx
│   │   │       │       ├── DiscussionRow2.test.jsx
│   │   │       │       ├── DiscussionRow3.test.jsx
│   │   │       │       ├── DiscussionRow4.test.jsx
│   │   │       │       ├── DiscussionRow5.test.jsx
│   │   │       │       ├── DiscussionSettings.test.jsx
│   │   │       │       ├── DiscussionsIndex.test.jsx
│   │   │       │       └── IndexHeader.test.jsx
│   │   │       ├── index.jsx
│   │   │       ├── propTypes.js
│   │   │       ├── proptypes
│   │   │       │   └── discussion.js
│   │   │       ├── reducers
│   │   │       │   ├── allDiscussionsReducer.js
│   │   │       │   ├── closedForCommentsDiscussionReducer.js
│   │   │       │   ├── copyToReducer.js
│   │   │       │   ├── courseSettingsReducer.js
│   │   │       │   ├── deleteFocusReducer.js
│   │   │       │   ├── deleteReducerMap.js
│   │   │       │   ├── duplicationReducerMap.js
│   │   │       │   ├── isSavingSettingsReducer.js
│   │   │       │   ├── isSettingsModalOpenReducer.js
│   │   │       │   ├── pinnedDiscussionReducer.js
│   │   │       │   ├── sendToReducer.js
│   │   │       │   ├── unpinnedDiscussionReducer.js
│   │   │       │   └── userSettingsReducer.js
│   │   │       ├── rootReducer.js
│   │   │       ├── store.js
│   │   │       └── utils.js
│   │   ├── discussion_topics_post
│   │   │   ├── graphql
│   │   │   │   ├── AdhocStudents.js
│   │   │   │   ├── AnonymousUser.js
│   │   │   │   ├── AssessmentRequest.js
│   │   │   │   ├── Assignment.js
│   │   │   │   ├── AssignmentOverride.js
│   │   │   │   ├── Attachment.js
│   │   │   │   ├── Checkpoint.js
│   │   │   │   ├── ChildTopic.js
│   │   │   │   ├── Course.js
│   │   │   │   ├── Discussion.js
│   │   │   │   ├── DiscussionEntry.js
│   │   │   │   ├── DiscussionEntryPermissions.js
│   │   │   │   ├── DiscussionEntryVersion.js
│   │   │   │   ├── DiscussionPermissions.js
│   │   │   │   ├── Group.js
│   │   │   │   ├── GroupSet.js
│   │   │   │   ├── Mocks.js
│   │   │   │   ├── Mutations.js
│   │   │   │   ├── PageInfo.js
│   │   │   │   ├── PeerReviews.js
│   │   │   │   ├── Queries.js
│   │   │   │   ├── RootTopic.js
│   │   │   │   ├── Section.js
│   │   │   │   ├── Submission.js
│   │   │   │   ├── User.js
│   │   │   │   └── mswHandlers.js
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── DiscussionTopicManager.jsx
│   │   │       ├── KeyboardShortcuts
│   │   │       │   ├── DiscussionTopicKeyboardShortcutModal.jsx
│   │   │       │   ├── KeyboardShortcutModal.jsx
│   │   │       │   ├── __tests__
│   │   │       │   │   └── KeyboardShortcutModal.test.jsx
│   │   │       │   └── useKeyboardShortcut.js
│   │   │       ├── __tests__
│   │   │       │   ├── DiscussionsAttachment.test.jsx
│   │   │       │   ├── DiscussionsSplitScreenView.test.jsx
│   │   │       │   ├── SequentialDiscussionFooter.test.js
│   │   │       │   └── TranslationTriggerModal.test.jsx
│   │   │       ├── components
│   │   │       │   ├── AssignmentAvailabilityContainer
│   │   │       │   │   ├── AssignmentAvailabilityContainer.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── AssignmentAvailabilityContainer.test.jsx
│   │   │       │   ├── AssignmentAvailabilityWindow
│   │   │       │   │   ├── AssignmentAvailabilityWindow.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── AssignmentAvailabilityWindow.test.jsx
│   │   │       │   ├── AssignmentContext
│   │   │       │   │   ├── AssignmentContext.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── AssignmentContext.test.jsx
│   │   │       │   ├── AssignmentDueDate
│   │   │       │   │   ├── AssignmentDueDate.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── AssignmentDueDate.test.jsx
│   │   │       │   ├── AssignmentMultipleAvailabilityWindows
│   │   │       │   │   ├── AssignmentMultipleAvailabilityWindows.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── AssignmentMultipleAvailabilityWindows.test.jsx
│   │   │       │   ├── AssignmentSingleAvailabilityWindow
│   │   │       │   │   ├── AssignmentSingleAvailabilityWindow.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── AssignmentSingleAvailabilityWindow.test.jsx
│   │   │       │   ├── AuthorInfo
│   │   │       │   │   ├── AuthorInfo.jsx
│   │   │       │   │   ├── AuthorInfo.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── AuthorInfo.test.jsx
│   │   │       │   ├── BackButton
│   │   │       │   │   ├── BackButton.jsx
│   │   │       │   │   ├── BackButton.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── BackButton.test.jsx
│   │   │       │   ├── CheckpointsTray
│   │   │       │   │   └── CheckpointsTray.jsx
│   │   │       │   ├── DeletedPostMessage
│   │   │       │   │   ├── DeletedPostMessage.jsx
│   │   │       │   │   ├── DeletedPostMessage.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── DeletedPostMessage.test.jsx
│   │   │       │   ├── DiscussionAvailabilityContainer
│   │   │       │   │   ├── DiscussionAvailabilityContainer.jsx
│   │   │       │   │   ├── DiscussionAvailabilityContainer.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── DiscussionAvailabilityContainer.test.jsx
│   │   │       │   ├── DiscussionAvailabilityTray
│   │   │       │   │   ├── DiscussionAvailabilityTray.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── DiscussionAvailabilityTray.test.jsx
│   │   │       │   ├── DiscussionDetails
│   │   │       │   │   ├── DiscussionDetails.jsx
│   │   │       │   │   ├── DiscussionDetails.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── DiscussionDetails.test.jsx
│   │   │       │   ├── DiscussionEdit
│   │   │       │   │   ├── DiscussionEdit.jsx
│   │   │       │   │   ├── PositionCursorHook.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── DiscussionEdit.test.jsx
│   │   │       │   ├── DiscussionEntryVersionHistory
│   │   │       │   │   ├── DiscussionEntryVersionHistory.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── DiscussionEntryVersionHistory.test.jsx
│   │   │       │   ├── DiscussionPostToolbar
│   │   │       │   │   ├── DiscussionPostButtonsToolbar.jsx
│   │   │       │   │   ├── DiscussionPostSearchTool.jsx
│   │   │       │   │   ├── DiscussionPostToolbar.jsx
│   │   │       │   │   ├── DiscussionPostToolbar.stories.jsx
│   │   │       │   │   ├── ExpandCollapseThreadsButton.jsx
│   │   │       │   │   ├── SortOrderDropDown.tsx
│   │   │       │   │   ├── SplitScreenButton.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       ├── DiscussionPostToolbar.test.jsx
│   │   │       │   │       └── SortOrderDropDown.test.tsx
│   │   │       │   ├── DiscussionSummary
│   │   │       │   │   ├── DiscussionSummary.tsx
│   │   │       │   │   ├── DiscussionSummaryGenerateButton.tsx
│   │   │       │   │   ├── DiscussionSummaryRatings.tsx
│   │   │       │   │   ├── DiscussionSummaryUsagePill.tsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       ├── DiscussionSummary1.test.tsx
│   │   │       │   │       └── DiscussionSummary2.test.tsx
│   │   │       │   ├── DiscussionTopicAlertManager
│   │   │       │   │   ├── DiscussionTopicAlertManager.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── DiscussionTopicAlertManager.test.jsx
│   │   │       │   ├── DueDateTray
│   │   │       │   │   ├── DueDateTray.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── DueDateTray.test.jsx
│   │   │       │   ├── DueDatesForParticipantList
│   │   │       │   │   ├── DueDatesForParticipantList.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── DueDatesForParticipantList.test.jsx
│   │   │       │   ├── GroupsMenu
│   │   │       │   │   ├── GroupsMenu.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── GroupsMenu.test.jsx
│   │   │       │   ├── Highlight
│   │   │       │   │   ├── Highlight.jsx
│   │   │       │   │   ├── ScrollToHighlight.js
│   │   │       │   │   └── __tests__
│   │   │       │   │       ├── Highlight.test.jsx
│   │   │       │   │       └── ScrollToHighlight.test.js
│   │   │       │   ├── InlineGrade
│   │   │       │   │   ├── InlineGrade.jsx
│   │   │       │   │   ├── InlineGrade.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── InlineGrade.test.jsx
│   │   │       │   ├── LoadingSpinner
│   │   │       │   │   └── LoadingSpinner.jsx
│   │   │       │   ├── LockedDiscussion
│   │   │       │   │   ├── LockedDiscussion.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── LockedDiscussion.test.jsx
│   │   │       │   ├── NoResultsFound
│   │   │       │   │   ├── NoResultsFound.jsx
│   │   │       │   │   ├── NoResultsFound.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── NoResultsFound.test.jsx
│   │   │       │   ├── PeerReview
│   │   │       │   │   ├── PeerReview.jsx
│   │   │       │   │   ├── PeerReview.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── PeerReview.test.jsx
│   │   │       │   ├── PodcastFeed
│   │   │       │   │   ├── PodcastFeed.jsx
│   │   │       │   │   ├── PodcastFeed.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── PodcastFeed.test.jsx
│   │   │       │   ├── PostMessage
│   │   │       │   │   ├── PostMessage.jsx
│   │   │       │   │   ├── PostMessage.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── PostMessage.test.jsx
│   │   │       │   ├── PostToolbar
│   │   │       │   │   ├── PostToolbar.jsx
│   │   │       │   │   ├── PostToolbar.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── PostToolbar.test.jsx
│   │   │       │   ├── ReplyInfo
│   │   │       │   │   ├── ReplyInfo.jsx
│   │   │       │   │   ├── ReplyInfo.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── ReplyInfo.test.jsx
│   │   │       │   ├── ReplyPreview
│   │   │       │   │   ├── ReplyPreview.jsx
│   │   │       │   │   ├── ReplyPreview.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── ReplyPreview.test.jsx
│   │   │       │   ├── ReportReply
│   │   │       │   │   ├── ReportReply.jsx
│   │   │       │   │   ├── ReportReply.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── ReportReply.test.jsx
│   │   │       │   ├── ReportsSummaryBadge
│   │   │       │   │   ├── ReportsSummaryBadge.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── ReportsSummaryBadge.test.jsx
│   │   │       │   ├── RolePillContainer
│   │   │       │   │   ├── RolePillContainer.jsx
│   │   │       │   │   ├── RolePillContainer.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── RolePillContainer.test.jsx
│   │   │       │   ├── SearchResultsCount
│   │   │       │   │   ├── SearchResultsCount.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── SearchResultsCount.test.jsx
│   │   │       │   ├── SearchSpan
│   │   │       │   │   ├── SearchSpan.jsx
│   │   │       │   │   ├── SearchSpan.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── SearchSpanText.test.jsx
│   │   │       │   ├── ShowMoreRepliesButton
│   │   │       │   │   ├── ShowMoreRepliesButton.jsx
│   │   │       │   │   ├── ShowMoreRepliesButton.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── ShowMoreRepliesButton.test.jsx
│   │   │       │   ├── SwitchToIndividualPostsLink
│   │   │       │   │   └── SwitchToIndividualPostsLink.jsx
│   │   │       │   ├── ThreadActions
│   │   │       │   │   ├── ThreadActions.jsx
│   │   │       │   │   ├── ThreadActions.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── ThreadActions.test.jsx
│   │   │       │   ├── ThreadPagination
│   │   │       │   │   ├── ThreadPagination.jsx
│   │   │       │   │   ├── ThreadPagination.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── ThreadPagination.test.jsx
│   │   │       │   ├── ThreadingToolbar
│   │   │       │   │   ├── Expansion.jsx
│   │   │       │   │   ├── Expansion.stories.jsx
│   │   │       │   │   ├── Like.jsx
│   │   │       │   │   ├── Like.stories.jsx
│   │   │       │   │   ├── MarkAsRead.jsx
│   │   │       │   │   ├── Reply.jsx
│   │   │       │   │   ├── Reply.stories.jsx
│   │   │       │   │   ├── SpeedGraderNavigator.jsx
│   │   │       │   │   ├── ThreadingToolbar.jsx
│   │   │       │   │   ├── ThreadingToolbar.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       ├── Expansion.test.jsx
│   │   │       │   │       ├── Like.test.jsx
│   │   │       │   │       ├── MarkAsRead.test.jsx
│   │   │       │   │       ├── Reply.test.jsx
│   │   │       │   │       ├── SpeedGraderNavigator.test.jsx
│   │   │       │   │       └── ThreadingToolbar.test.jsx
│   │   │       │   ├── TranslationControls
│   │   │       │   │   ├── TranslationControls.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── TranslationControls.test.jsx
│   │   │       │   ├── TranslationTriggerModal
│   │   │       │   │   ├── TranslationTriggerModal.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── TranslationTriggerModal.test.jsx
│   │   │       │   └── TrayDisplayer
│   │   │       │       ├── TrayDisplayer.jsx
│   │   │       │       └── __tests__
│   │   │       │           └── TrayDisplayer.test.jsx
│   │   │       ├── containers
│   │   │       │   ├── DiscussionEntryContainer
│   │   │       │   │   ├── DiscussionEntryContainer.jsx
│   │   │       │   │   ├── DiscussionEntryContainer.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── DiscussionEntryContainer.test.jsx
│   │   │       │   ├── DiscussionThreadContainer
│   │   │       │   │   ├── DiscussionThreadContainer.jsx
│   │   │       │   │   ├── DiscussionThreadContainer.stories.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── DiscussionThreadContainer.test.jsx
│   │   │       │   ├── DiscussionTopicContainer
│   │   │       │   │   ├── DiscussionInsightsButton.tsx
│   │   │       │   │   ├── DiscussionTopicContainer.jsx
│   │   │       │   │   ├── DiscussionTopicContainer.stories.jsx
│   │   │       │   │   ├── SummarizeButton.tsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── DiscussionTopicContainer.test.jsx
│   │   │       │   ├── DiscussionTopicRepliesContainer
│   │   │       │   │   ├── DiscussionTopicRepliesContainer.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── DiscussionTopicRepliesContainer.test.jsx
│   │   │       │   ├── DiscussionTopicTitleContainer
│   │   │       │   │   ├── DiscussionTopicTitleContainer.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── DiscussionTopicTitleContainer.test.jsx
│   │   │       │   ├── DiscussionTopicToolbarContainer
│   │   │       │   │   └── DiscussionTopicToolbarContainer.jsx
│   │   │       │   ├── DiscussionTranslationModuleContainer
│   │   │       │   │   ├── DiscussionTranslationModuleContainer.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── DiscussionTranslationModuleContainer.test.jsx
│   │   │       │   ├── SplitScreenThreadsContainer
│   │   │       │   │   ├── SplitScreenThreadsContainer.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       └── SplitScreenThreadsContainer.test.jsx
│   │   │       │   ├── SplitScreenViewContainer
│   │   │       │   │   ├── SplitScreenParent.jsx
│   │   │       │   │   ├── SplitScreenViewContainer.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       ├── SplitScreenParent.test.jsx
│   │   │       │   │       └── SplitScreenViewContainer.test.jsx
│   │   │       │   └── StickyToolbarWrapper
│   │   │       │       └── StickyToolbarWrapper.tsx
│   │   │       ├── hooks
│   │   │       │   ├── useCreateDiscussionEntry.js
│   │   │       │   ├── useHighlightStore.tsx
│   │   │       │   ├── useNavigateEntries.js
│   │   │       │   ├── useSpeedGrader.js
│   │   │       │   ├── useStudentEntries.js
│   │   │       │   └── useUpdateDiscussionThread.js
│   │   │       ├── index.jsx
│   │   │       └── utils
│   │   │           ├── constants.jsx
│   │   │           └── index.js
│   │   ├── edit_calendar_event
│   │   │   ├── backbone
│   │   │   │   ├── models
│   │   │   │   │   ├── CalendarEvent.jsx
│   │   │   │   │   └── __tests__
│   │   │   │   │       └── CalendarEvent.test.js
│   │   │   │   └── views
│   │   │   │       ├── EditEventView.jsx
│   │   │   │       └── __tests__
│   │   │   │           └── EditEventView.test.js
│   │   │   ├── index.js
│   │   │   ├── jst
│   │   │   │   ├── editCalendarEventFull.handlebars
│   │   │   │   └── editCalendarEventFull.handlebars.json
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       └── components
│   │   │           └── EditCalendarEventHeader.tsx
│   │   ├── edit_rubric
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── enhanced_individual_gradebook
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   ├── queries
│   │   │   │   └── Queries.tsx
│   │   │   ├── react
│   │   │   │   ├── components
│   │   │   │   │   ├── AssignmentInformation
│   │   │   │   │   │   ├── CurveGradesModal.tsx
│   │   │   │   │   │   ├── DefaultGradeModal.tsx
│   │   │   │   │   │   ├── MessageStudentsWhoModal.tsx
│   │   │   │   │   │   ├── SubmissionDownloadModal.tsx
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── AssignmentInformation.test.tsx
│   │   │   │   │   │   │   └── fixtures.ts
│   │   │   │   │   │   ├── downloadSubmissionsDialog.js
│   │   │   │   │   │   └── index.tsx
│   │   │   │   │   ├── ContentSelection
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── ContentSelection.test.tsx
│   │   │   │   │   │   │   └── fixtures.ts
│   │   │   │   │   │   └── index.tsx
│   │   │   │   │   ├── ContentSelectionLearningMastery
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── ContentSelection.test.tsx
│   │   │   │   │   │   │   └── fixtures.ts
│   │   │   │   │   │   └── index.tsx
│   │   │   │   │   ├── EnhancedIndividualGradebook.tsx
│   │   │   │   │   ├── EnhancedIndividualGradebookWrapper.tsx
│   │   │   │   │   ├── GlobalSettings
│   │   │   │   │   │   ├── AllowFinalGradeOverrideCheckbox.tsx
│   │   │   │   │   │   ├── CheckboxTemplate.tsx
│   │   │   │   │   │   ├── GradebookScoreExport.tsx
│   │   │   │   │   │   ├── HideStudentNamesCheckbox.tsx
│   │   │   │   │   │   ├── IncludeUngradedAssignmentsCheckbox.tsx
│   │   │   │   │   │   ├── ShowConcludedEnrollmentsCheckbox.tsx
│   │   │   │   │   │   ├── ShowNotesColumnCheckbox.tsx
│   │   │   │   │   │   ├── ShowTotalGradeAsPointsCheckbox.tsx
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   └── GlobalSettings.test.tsx
│   │   │   │   │   │   └── index.tsx
│   │   │   │   │   ├── GlobalSettingsLearningMastery
│   │   │   │   │   │   └── index.tsx
│   │   │   │   │   ├── GradingResults
│   │   │   │   │   │   ├── CheckpointGradeInputs.tsx
│   │   │   │   │   │   ├── DefaultGradeInput.tsx
│   │   │   │   │   │   ├── SubmissionDetailModal.tsx
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── GradingResults.test.tsx
│   │   │   │   │   │   │   └── fixtures.ts
│   │   │   │   │   │   └── index.tsx
│   │   │   │   │   ├── LearningMasteryTabsView.tsx
│   │   │   │   │   ├── OutcomeInformation
│   │   │   │   │   │   └── index.tsx
│   │   │   │   │   ├── OutcomeResult
│   │   │   │   │   │   ├── OutcomeResultQuery.ts
│   │   │   │   │   │   └── index.tsx
│   │   │   │   │   ├── StudentInformation
│   │   │   │   │   │   ├── AssignmentGroupScores.tsx
│   │   │   │   │   │   ├── FinalGradeOverrideContainer.tsx
│   │   │   │   │   │   ├── GradingPeriodScores.tsx
│   │   │   │   │   │   ├── Notes.tsx
│   │   │   │   │   │   ├── RowScore.tsx
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   └── StudentInformation.test.tsx
│   │   │   │   │   │   └── index.tsx
│   │   │   │   │   └── __tests__
│   │   │   │   │       ├── EnhancedIndividualGradebook.test.tsx
│   │   │   │   │       ├── EnhancedIndividualGradebookWrapper.test.tsx
│   │   │   │   │       ├── LearningMasteryTabsView.test.tsx
│   │   │   │   │       └── fixtures.ts
│   │   │   │   └── hooks
│   │   │   │       ├── useAssignmentGroupsQuery.tsx
│   │   │   │       ├── useAssignmentsQuery.tsx
│   │   │   │       ├── useComments.tsx
│   │   │   │       ├── useContentDropdownOptions.tsx
│   │   │   │       ├── useCourseOutcomeMasteryScales.tsx
│   │   │   │       ├── useCurrentStudentInfo.tsx
│   │   │   │       ├── useCustomColumns.tsx
│   │   │   │       ├── useDefaultGrade.tsx
│   │   │   │       ├── useEnrollmentsQuery.tsx
│   │   │   │       ├── useExportGradebook.tsx
│   │   │   │       ├── useGradebookNotes.tsx
│   │   │   │       ├── useGradebookQuery.tsx
│   │   │   │       ├── useOutcomesQuery.tsx
│   │   │   │       ├── useSectionsQuery.tsx
│   │   │   │       ├── useSubmissionsQuery.tsx
│   │   │   │       └── useSubmitScore.tsx
│   │   │   ├── types
│   │   │   │   ├── gradebook.d.ts
│   │   │   │   ├── index.ts
│   │   │   │   └── queries.d.ts
│   │   │   └── utils
│   │   │       ├── gradeInputUtils.ts
│   │   │       └── gradebookUtils.ts
│   │   ├── eportfolio
│   │   │   ├── index.ts
│   │   │   ├── jquery
│   │   │   │   ├── __tests__
│   │   │   │   │   └── eportfolioSection.test.js
│   │   │   │   ├── eportfolio_section.ts
│   │   │   │   └── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── CreatePortfolioForm.tsx
│   │   │       ├── PageContainer.tsx
│   │   │       ├── PageEditModal.tsx
│   │   │       ├── PageList.tsx
│   │   │       ├── PageNameContainer.tsx
│   │   │       ├── PortfolioPortal.tsx
│   │   │       ├── PortfolioSettingsModal.tsx
│   │   │       ├── SectionContainer.tsx
│   │   │       ├── SectionEditModal.tsx
│   │   │       ├── SectionList.tsx
│   │   │       ├── SubmissionList.tsx
│   │   │       ├── SubmissionModal.tsx
│   │   │       ├── __tests__
│   │   │       │   ├── CreatePortfolioForm.test.tsx
│   │   │       │   ├── PageEditModal.test.tsx
│   │   │       │   ├── PageList.test.tsx
│   │   │       │   ├── PageNameContainer.test.tsx
│   │   │       │   ├── PortfolioSettingsModal.test.tsx
│   │   │       │   ├── SectionEditModal.test.tsx
│   │   │       │   ├── SectionList.test.tsx
│   │   │       │   ├── SubmissionList.test.tsx
│   │   │       │   └── SubmissionModal.test.tsx
│   │   │       ├── types.ts
│   │   │       └── utils.ts
│   │   ├── eportfolio_moderation
│   │   │   ├── index.ts
│   │   │   └── package.json
│   │   ├── eportfolios_wizard_box
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── epub_exports
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── App.jsx
│   │   │       ├── CourseList.jsx
│   │   │       ├── CourseListItem.jsx
│   │   │       ├── CourseStore.js
│   │   │       ├── DownloadLink.jsx
│   │   │       ├── GenerateLink.jsx
│   │   │       └── __tests__
│   │   │           ├── App.test.jsx
│   │   │           ├── CourseEpubExportStore.test.js
│   │   │           ├── CourseList.test.jsx
│   │   │           ├── CourseListItem.test.jsx
│   │   │           ├── DownloadLink.test.jsx
│   │   │           └── GenerateLink.test.jsx
│   │   ├── error_form
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── external_apps
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── components
│   │   │       │   ├── AddApp.jsx
│   │   │       │   ├── AddExternalToolButton.jsx
│   │   │       │   ├── AppDetails.jsx
│   │   │       │   ├── AppFilters.jsx
│   │   │       │   ├── AppList.jsx
│   │   │       │   ├── AppTile.tsx
│   │   │       │   ├── ConfigOptionField.jsx
│   │   │       │   ├── Configurations.jsx
│   │   │       │   ├── ConfigureExternalToolButton.jsx
│   │   │       │   ├── ConfirmationForm.jsx
│   │   │       │   ├── DeleteExternalToolButton.jsx
│   │   │       │   ├── DeploymentIdButton.jsx
│   │   │       │   ├── DuplicateConfirmationForm.jsx
│   │   │       │   ├── EditExternalToolButton.jsx
│   │   │       │   ├── ExternalToolMigrationInfo.jsx
│   │   │       │   ├── ExternalToolPlacementButton.jsx
│   │   │       │   ├── ExternalToolPlacementList.jsx
│   │   │       │   ├── ExternalToolsTable.jsx
│   │   │       │   ├── ExternalToolsTableRow.jsx
│   │   │       │   ├── Header.jsx
│   │   │       │   ├── Lti2Edit.jsx
│   │   │       │   ├── Lti2Iframe.jsx
│   │   │       │   ├── Lti2Permissions.jsx
│   │   │       │   ├── Lti2ReregistrationUpdateModal.jsx
│   │   │       │   ├── ManageAppListButton.jsx
│   │   │       │   ├── ManageUpdateExternalToolButton.jsx
│   │   │       │   ├── ReregisterExternalToolButton.jsx
│   │   │       │   ├── Root.jsx
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── AddApp.test.jsx
│   │   │       │   │   ├── AddExternalToolButton.test.jsx
│   │   │       │   │   ├── AppDetails.test.jsx
│   │   │       │   │   ├── AppFilters.test.jsx
│   │   │       │   │   ├── AppList.test.jsx
│   │   │       │   │   ├── ConfigurationForm.test.tsx
│   │   │       │   │   ├── ConfigurationFormLti13.test.tsx
│   │   │       │   │   ├── ConfigurationFormManual.test.tsx
│   │   │       │   │   ├── ConfigurationFormUrl.test.tsx
│   │   │       │   │   ├── ConfigurationFormXml.test.tsx
│   │   │       │   │   ├── Configurations.test.jsx
│   │   │       │   │   ├── ConfigureExternalToolButton.test.jsx
│   │   │       │   │   ├── ConfirmationForm.test.jsx
│   │   │       │   │   ├── ConfirmationForm.test.tsx
│   │   │       │   │   ├── ConfirmationFormLti2.test.tsx
│   │   │       │   │   ├── DeleteExternalToolButton.test.jsx
│   │   │       │   │   ├── DuplicateConfirmationForm.test.jsx
│   │   │       │   │   ├── EditExternalToolButton.test.jsx
│   │   │       │   │   ├── ExternalToolPlacementButton.test.jsx
│   │   │       │   │   ├── ExternalToolPlacementButton2.test.jsx
│   │   │       │   │   ├── ExternalToolPlacementList.test.jsx
│   │   │       │   │   ├── ExternalToolsTable.test.jsx
│   │   │       │   │   ├── ExternalToolsTableRow.test.jsx
│   │   │       │   │   ├── Lti2Edit.test.jsx
│   │   │       │   │   ├── Lti2Iframe.test.jsx
│   │   │       │   │   ├── Lti2Permissions.test.tsx
│   │   │       │   │   ├── ManageAppListButton.test.jsx
│   │   │       │   │   └── ReregisterExternalToolButton.test.jsx
│   │   │       │   └── configuration_forms
│   │   │       │       ├── ConfigurationForm.jsx
│   │   │       │       ├── ConfigurationFormLti13.jsx
│   │   │       │       ├── ConfigurationFormLti2.tsx
│   │   │       │       ├── ConfigurationFormManual.tsx
│   │   │       │       ├── ConfigurationFormUrl.tsx
│   │   │       │       ├── ConfigurationFormXml.tsx
│   │   │       │       ├── ConfigurationTypeSelector.jsx
│   │   │       │       ├── MembershipServiceAccess.tsx
│   │   │       │       ├── __tests__
│   │   │       │       │   └── ConfigurationForm.test.jsx
│   │   │       │       └── types.ts
│   │   │       ├── lib
│   │   │       │   ├── AppCenterStore.js
│   │   │       │   ├── ExternalAppsStore.js
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── AppCenterStore.test.js
│   │   │       │   │   ├── ExternalAppsStore.test.js
│   │   │       │   │   ├── classMunger.spec.js
│   │   │       │   │   ├── fetchToolConfiguration.test.js
│   │   │       │   │   ├── install13Tool.test.js
│   │   │       │   │   └── toolConfigurationError.test.js
│   │   │       │   ├── classMunger.js
│   │   │       │   ├── createStoreJestCompatible.js
│   │   │       │   ├── fetchToolConfiguration.js
│   │   │       │   ├── install13Tool.js
│   │   │       │   └── toolConfigurationError.js
│   │   │       ├── mixins
│   │   │       │   └── InputMixin.jsx
│   │   │       └── router.jsx
│   │   ├── external_content_cancel
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── external_content_success
│   │   │   ├── index.jsx
│   │   │   └── package.json
│   │   ├── external_tool_redirect
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── RedirectReturnContainer.js
│   │   │   └── package.json
│   │   ├── external_tools_show
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── tool_inline.js
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       └── index.tsx
│   │   ├── file
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── file_inline.js
│   │   │   └── package.json
│   │   ├── file_not_found
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── FileNotFound.jsx
│   │   │       └── __tests__
│   │   │           └── FileNotFound.test.jsx
│   │   ├── file_preview
│   │   │   ├── index.tsx
│   │   │   └── package.json
│   │   ├── file_show
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── files
│   │   │   ├── MasterCourseLock.jsx
│   │   │   ├── RootFoldersFinder.js
│   │   │   ├── __tests__
│   │   │   │   └── router.spec.js
│   │   │   ├── index.js
│   │   │   ├── openMoveDialog.jsx
│   │   │   ├── package.json
│   │   │   ├── react
│   │   │   │   ├── components
│   │   │   │   │   ├── BBTreeBrowser.jsx
│   │   │   │   │   ├── BreadcrumbCollapsedContainer.jsx
│   │   │   │   │   ├── Breadcrumbs.jsx
│   │   │   │   │   ├── ColumnHeaders.jsx
│   │   │   │   │   ├── DragFeedback.jsx
│   │   │   │   │   ├── FileUpload.jsx
│   │   │   │   │   ├── FilesApp.jsx
│   │   │   │   │   ├── FilesUsage.jsx
│   │   │   │   │   ├── FolderChild.jsx
│   │   │   │   │   ├── FolderTree.jsx
│   │   │   │   │   ├── ItemCog.jsx
│   │   │   │   │   ├── LoadingIndicator.jsx
│   │   │   │   │   ├── MoveDialog.jsx
│   │   │   │   │   ├── NoResults.jsx
│   │   │   │   │   ├── SearchResults.jsx
│   │   │   │   │   ├── ShowFolder.jsx
│   │   │   │   │   ├── Toolbar.jsx
│   │   │   │   │   ├── UploadButton.jsx
│   │   │   │   │   └── __tests__
│   │   │   │   │       ├── BreadcrumbCollapsedContainer.test.jsx
│   │   │   │   │       ├── Breadcrumbs.test.jsx
│   │   │   │   │       ├── ColumnHeaders.test.jsx
│   │   │   │   │       ├── DragFeedback.test.jsx
│   │   │   │   │       ├── FileUpload.test.jsx
│   │   │   │   │       ├── FilesUsage.test.jsx
│   │   │   │   │       ├── ItemCog.test.jsx
│   │   │   │   │       ├── LoadingIndicator.test.jsx
│   │   │   │   │       ├── NoResults.test.jsx
│   │   │   │   │       ├── SearchResults.test.jsx
│   │   │   │   │       ├── ShowFolder.test.jsx
│   │   │   │   │       ├── Toolbar.test.tsx
│   │   │   │   │       └── UploadButton.test.jsx
│   │   │   │   └── legacy
│   │   │   │       ├── components
│   │   │   │       │   ├── Breadcrumbs.jsx
│   │   │   │       │   ├── ColumnHeaders.jsx
│   │   │   │       │   ├── FilesApp.js
│   │   │   │       │   ├── FilesUsage.js
│   │   │   │       │   ├── FolderChild.jsx
│   │   │   │       │   ├── FolderTree.jsx
│   │   │   │       │   ├── MoveDialog.js
│   │   │   │       │   ├── SearchResults.js
│   │   │   │       │   └── ShowFolder.js
│   │   │   │       ├── mixins
│   │   │   │       │   ├── MultiselectableMixin.js
│   │   │   │       │   └── dndMixin.jsx
│   │   │   │       ├── modules
│   │   │   │       │   ├── BBTreeBrowserView.js
│   │   │   │       │   └── FocusStore.js
│   │   │   │       └── util
│   │   │   │           ├── deleteStuff.js
│   │   │   │           ├── downloadStuffAsAZip.js
│   │   │   │           ├── getAllPages.js
│   │   │   │           ├── moveStuff.jsx
│   │   │   │           └── updateAPIQuerySortParams.js
│   │   │   └── router.jsx
│   │   ├── files_v2
│   │   │   ├── fixtures
│   │   │   │   ├── fakeData.tsx
│   │   │   │   └── fileContexts.ts
│   │   │   ├── index.tsx
│   │   │   ├── interfaces
│   │   │   │   ├── File.ts
│   │   │   │   └── FileFolderTable.ts
│   │   │   ├── package.json
│   │   │   ├── react
│   │   │   │   ├── __tests__
│   │   │   │   │   └── createMockContext.tsx
│   │   │   │   ├── components
│   │   │   │   │   ├── AllMyFilesTable
│   │   │   │   │   │   ├── AllContextsNameLink.tsx
│   │   │   │   │   │   ├── AllMyFilesTable.tsx
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── AllContextsNameLink.test.tsx
│   │   │   │   │   │   │   └── AllMyFilesTable.test.tsx
│   │   │   │   │   │   └── index.tsx
│   │   │   │   │   ├── FileFolderTable
│   │   │   │   │   │   ├── ActionMenuButton.tsx
│   │   │   │   │   │   ├── BlueprintIconButton.tsx
│   │   │   │   │   │   ├── Breadcrumbs.tsx
│   │   │   │   │   │   ├── BulkActionButtons.tsx
│   │   │   │   │   │   ├── ColumnHeaderText.tsx
│   │   │   │   │   │   ├── DeleteModal
│   │   │   │   │   │   │   ├── DeleteModal.tsx
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   └── DeleteModal.test.tsx
│   │   │   │   │   │   │   └── index.tsx
│   │   │   │   │   │   ├── DirectShareCourseTray
│   │   │   │   │   │   │   ├── DirectShareCoursePanel.tsx
│   │   │   │   │   │   │   ├── DirectShareCourseTray.tsx
│   │   │   │   │   │   │   ├── ModulePositionPicker.tsx
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── DirectShareCoursePanel.test.tsx
│   │   │   │   │   │   │   │   ├── DirectShareCourseTray.test.tsx
│   │   │   │   │   │   │   │   └── ModulePositionPicker.test.tsx
│   │   │   │   │   │   │   └── index.tsx
│   │   │   │   │   │   ├── DirectShareUserTray
│   │   │   │   │   │   │   ├── ContentShareUserSearchSelector.tsx
│   │   │   │   │   │   │   ├── DirectShareUserPanel.tsx
│   │   │   │   │   │   │   ├── DirectShareUserTray.tsx
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── ContentShareUserSearchSelector.test.tsx
│   │   │   │   │   │   │   │   ├── DirectShareUserPanel.test.tsx
│   │   │   │   │   │   │   │   └── DirectShareUserTray.test.tsx
│   │   │   │   │   │   │   └── index.tsx
│   │   │   │   │   │   ├── DisabledActionsInfoButton.tsx
│   │   │   │   │   │   ├── FileFolderTable.tsx
│   │   │   │   │   │   ├── FileFolderTableUtils.tsx
│   │   │   │   │   │   ├── FilePreview.tsx
│   │   │   │   │   │   ├── FilePreviewIframe.tsx
│   │   │   │   │   │   ├── FilePreviewModal.tsx
│   │   │   │   │   │   ├── FilePreviewNavigationButtons.tsx
│   │   │   │   │   │   ├── FilePreviewTray
│   │   │   │   │   │   │   ├── CommonFileInfo.tsx
│   │   │   │   │   │   │   ├── FilePreviewTray.tsx
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── CommonFileInfo.test.tsx
│   │   │   │   │   │   │   │   ├── FilePreviewTray.test.tsx
│   │   │   │   │   │   │   │   └── fixtures.ts
│   │   │   │   │   │   │   └── index.tsx
│   │   │   │   │   │   ├── FileTableUpload.tsx
│   │   │   │   │   │   ├── ModifiedByLink.tsx
│   │   │   │   │   │   ├── MoveModal
│   │   │   │   │   │   │   ├── FolderTreeBrowser.tsx
│   │   │   │   │   │   │   ├── MoveModal.tsx
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── FolderTreeBrowser.test.tsx
│   │   │   │   │   │   │   │   ├── MoveModal.test.tsx
│   │   │   │   │   │   │   │   └── utils.test.tsx
│   │   │   │   │   │   │   ├── hooks.tsx
│   │   │   │   │   │   │   ├── index.tsx
│   │   │   │   │   │   │   └── utils.tsx
│   │   │   │   │   │   ├── NameLink.tsx
│   │   │   │   │   │   ├── NoFilePreviewAvailable.tsx
│   │   │   │   │   │   ├── NoResultsFound.tsx
│   │   │   │   │   │   ├── PermissionsModal
│   │   │   │   │   │   │   ├── AvailabilitySelect.tsx
│   │   │   │   │   │   │   ├── DateRangeSelect.tsx
│   │   │   │   │   │   │   ├── PermissionsModal.tsx
│   │   │   │   │   │   │   ├── PermissionsModalBody.tsx
│   │   │   │   │   │   │   ├── PermissionsModalFooter.tsx
│   │   │   │   │   │   │   ├── PermissionsModalHeader.tsx
│   │   │   │   │   │   │   ├── PermissionsModalUtils.tsx
│   │   │   │   │   │   │   ├── VisibilitySelect.tsx
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── DateRangeSelect.test.tsx
│   │   │   │   │   │   │   │   ├── PermissionsModal1.test.tsx
│   │   │   │   │   │   │   │   ├── PermissionsModal2.test.tsx
│   │   │   │   │   │   │   │   ├── PermissionsModal3.test.tsx
│   │   │   │   │   │   │   │   └── PermissionsModalUtils.test.tsx
│   │   │   │   │   │   │   └── index.tsx
│   │   │   │   │   │   ├── PublishIconButton.tsx
│   │   │   │   │   │   ├── RenderTableBody.tsx
│   │   │   │   │   │   ├── RenderTableHead.tsx
│   │   │   │   │   │   ├── RightsIconButton.tsx
│   │   │   │   │   │   ├── SubTableContent.tsx
│   │   │   │   │   │   ├── UpdatedAtDate.tsx
│   │   │   │   │   │   ├── UsageRightsModal
│   │   │   │   │   │   │   ├── UsageRightsModal.tsx
│   │   │   │   │   │   │   ├── UsageRightsModalUtils.tsx
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   └── UsageRightsModal.test.tsx
│   │   │   │   │   │   │   └── index.tsx
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── ActionMenuButton.test.tsx
│   │   │   │   │   │   │   ├── BlueprintIconButton.test.tsx
│   │   │   │   │   │   │   ├── Breadcrumbs.test.tsx
│   │   │   │   │   │   │   ├── BulkActionButtons.test.tsx
│   │   │   │   │   │   │   ├── ColumnHeaderText.test.tsx
│   │   │   │   │   │   │   ├── DisabledActionsInfoButton.test.tsx
│   │   │   │   │   │   │   ├── FileFolderTable.test.tsx
│   │   │   │   │   │   │   ├── FileFolderTableSorting.test.tsx
│   │   │   │   │   │   │   ├── FilePreview.test.tsx
│   │   │   │   │   │   │   ├── FilePreviewIframe.test.tsx
│   │   │   │   │   │   │   ├── FilePreviewModal.test.tsx
│   │   │   │   │   │   │   ├── FileTableUpload.test.tsx
│   │   │   │   │   │   │   ├── NameLink.test.tsx
│   │   │   │   │   │   │   ├── NoFilePreviewAvailable.test.tsx
│   │   │   │   │   │   │   ├── NoResultsFound.test.tsx
│   │   │   │   │   │   │   ├── PublishIconButton.test.tsx
│   │   │   │   │   │   │   ├── RightsIconButton.test.tsx
│   │   │   │   │   │   │   ├── SubTableContent.test.tsx
│   │   │   │   │   │   │   ├── fixtures.tsx
│   │   │   │   │   │   │   └── testUtils.tsx
│   │   │   │   │   │   └── index.tsx
│   │   │   │   │   ├── FilesApp.tsx
│   │   │   │   │   ├── FilesErrorBoundary.tsx
│   │   │   │   │   ├── FilesGenericErrorPage.tsx
│   │   │   │   │   ├── FilesHeader
│   │   │   │   │   │   ├── CreateFolderButton.tsx
│   │   │   │   │   │   ├── CreateFolderModal.tsx
│   │   │   │   │   │   ├── CurrentDownloads.tsx
│   │   │   │   │   │   ├── CurrentUploads.tsx
│   │   │   │   │   │   ├── ExternalToolsButton.tsx
│   │   │   │   │   │   ├── FilesHeader.tsx
│   │   │   │   │   │   ├── TopLevelButtons.tsx
│   │   │   │   │   │   ├── UploadButton
│   │   │   │   │   │   │   ├── FileOptions.ts
│   │   │   │   │   │   │   ├── FileRenameForm.tsx
│   │   │   │   │   │   │   ├── UploadButton.tsx
│   │   │   │   │   │   │   ├── ZipFileOptionsForm.tsx
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── FileRenameForm.test.tsx
│   │   │   │   │   │   │   │   ├── UploadButton.test.tsx
│   │   │   │   │   │   │   │   └── ZipFileOptionsForm.test.tsx
│   │   │   │   │   │   │   └── index.tsx
│   │   │   │   │   │   ├── UploadProgress.tsx
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── CreateFolderButton.test.tsx
│   │   │   │   │   │   │   ├── CreateFolderModal.test.tsx
│   │   │   │   │   │   │   ├── CurrentDownloads.test.tsx
│   │   │   │   │   │   │   ├── CurrentUploads.test.tsx
│   │   │   │   │   │   │   ├── ExternalToolsButton.test.tsx
│   │   │   │   │   │   │   ├── FilesHeader.test.tsx
│   │   │   │   │   │   │   ├── TopLevelButtons.test.tsx
│   │   │   │   │   │   │   └── UploadProgress.test.tsx
│   │   │   │   │   │   └── index.tsx
│   │   │   │   │   ├── FilesUsageBar.tsx
│   │   │   │   │   ├── RenameModal.tsx
│   │   │   │   │   ├── SearchBar.tsx
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   ├── FilesApp.test.tsx
│   │   │   │   │   │   ├── FilesUsageBar.test.tsx
│   │   │   │   │   │   ├── RenameModal.test.tsx
│   │   │   │   │   │   └── SearchBar.test.tsx
│   │   │   │   │   └── shared
│   │   │   │   │       ├── FileFolderInfo.tsx
│   │   │   │   │       ├── SearchItemSelector.tsx
│   │   │   │   │       └── TrayWrapper.tsx
│   │   │   │   ├── contexts
│   │   │   │   │   ├── FileManagementContext.tsx
│   │   │   │   │   ├── RowFocusContext.tsx
│   │   │   │   │   └── RowsContext.tsx
│   │   │   │   ├── hooks
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   └── useSearchTerm.test.tsx
│   │   │   │   │   ├── useGetFolders.ts
│   │   │   │   │   ├── useGetPaginatedFiles.ts
│   │   │   │   │   ├── useGetQuota.ts
│   │   │   │   │   └── useSearchTerm.ts
│   │   │   │   ├── layouts
│   │   │   │   │   ├── FilesLayout.tsx
│   │   │   │   │   ├── FooterLayout.tsx
│   │   │   │   │   ├── HeaderLayout.tsx
│   │   │   │   │   └── TableControlsLayout.tsx
│   │   │   │   └── queries
│   │   │   │       ├── __tests__
│   │   │   │       │   └── folders.test.tsx
│   │   │   │       └── folders.tsx
│   │   │   ├── routes
│   │   │   │   ├── ReThrowRouteError.tsx
│   │   │   │   └── router.tsx
│   │   │   └── utils
│   │   │       ├── __tests__
│   │   │       │   ├── apiUtils.test.ts
│   │   │       │   ├── downloadUtils.test.ts
│   │   │       │   ├── fileFolderUtils.test.ts
│   │   │       │   ├── fileUtils.test.ts
│   │   │       │   ├── folderUtils.test.ts
│   │   │       │   └── trayUtils.test.ts
│   │   │       ├── apiUtils.ts
│   │   │       ├── downloadUtils.ts
│   │   │       ├── fileFolderUtils.tsx
│   │   │       ├── fileFolderWrappers.ts
│   │   │       ├── fileUtils.ts
│   │   │       ├── filesEnvUtils.ts
│   │   │       ├── folderUtils.ts
│   │   │       └── trayUtils.ts
│   │   ├── grade_summary
│   │   │   ├── backbone
│   │   │   │   ├── collections
│   │   │   │   │   ├── OutcomeResultCollection.js
│   │   │   │   │   ├── OutcomeSummaryCollection.js
│   │   │   │   │   ├── WrappedCollection.js
│   │   │   │   │   └── __tests__
│   │   │   │   │       └── OutcomeResultCollection.spec.js
│   │   │   │   ├── models
│   │   │   │   │   ├── Group.js
│   │   │   │   │   └── Section.js
│   │   │   │   └── views
│   │   │   │       ├── AlignmentView.js
│   │   │   │       ├── GroupView.js
│   │   │   │       ├── IndividualStudentView.jsx
│   │   │   │       ├── OutcomeDetailView.js
│   │   │   │       ├── OutcomeDialogView.js
│   │   │   │       ├── OutcomeLineGraphView.js
│   │   │   │       ├── OutcomePopoverView.js
│   │   │   │       ├── OutcomeSummaryView.js
│   │   │   │       ├── OutcomeView.js
│   │   │   │       ├── ProgressBarView.js
│   │   │   │       ├── SectionView.js
│   │   │   │       └── __tests__
│   │   │   │           ├── OutcomeDetailView.test.js
│   │   │   │           ├── OutcomeDialogView.test.js
│   │   │   │           ├── OutcomeLineGraphView.test.js
│   │   │   │           ├── OutcomePopoverView.test.js
│   │   │   │           └── OutcomeView.test.js
│   │   │   ├── graphql
│   │   │   │   ├── Assignment.js
│   │   │   │   ├── AssignmentGroup.js
│   │   │   │   ├── GradingPeriod.js
│   │   │   │   ├── GradingPeriodGroup.js
│   │   │   │   ├── GradingStandard.js
│   │   │   │   ├── Mutations.js
│   │   │   │   ├── ScoreStatistic.js
│   │   │   │   ├── Submission.js
│   │   │   │   ├── SubmissionComment.js
│   │   │   │   └── queries.js
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── GradeSummary1.test.js
│   │   │   │   │   ├── GradeSummary2.test.js
│   │   │   │   │   ├── GradeSummary3.test.js
│   │   │   │   │   ├── GradeSummary4.test.js
│   │   │   │   │   ├── GradeSummary5.test.js
│   │   │   │   │   ├── GradeSummary6.test.js
│   │   │   │   │   └── GradeSummary7.test.js
│   │   │   │   └── index.jsx
│   │   │   ├── jst
│   │   │   │   ├── accessibleLineGraph.handlebars
│   │   │   │   ├── accessibleLineGraph.handlebars.json
│   │   │   │   ├── alignment.handlebars
│   │   │   │   ├── alignment.handlebars.json
│   │   │   │   ├── group.handlebars
│   │   │   │   ├── group.handlebars.json
│   │   │   │   ├── individual_student_view.handlebars
│   │   │   │   ├── individual_student_view.handlebars.json
│   │   │   │   ├── outcome.handlebars
│   │   │   │   ├── outcome.handlebars.json
│   │   │   │   ├── outcome_detail.handlebars
│   │   │   │   ├── outcome_detail.handlebars.json
│   │   │   │   ├── progress_bar.handlebars
│   │   │   │   ├── progress_bar.handlebars.json
│   │   │   │   ├── section.handlebars
│   │   │   │   └── section.handlebars.json
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── ClearBadgeCountsButton.tsx
│   │   │       ├── GradeSummary
│   │   │       │   ├── AssignmentTable.jsx
│   │   │       │   ├── AssignmentTable.stories.jsx
│   │   │       │   ├── AssignmentTableRows
│   │   │       │   │   ├── AssignmentGroupRow.jsx
│   │   │       │   │   ├── AssignmentRow.jsx
│   │   │       │   │   ├── GradingPeriodRow.jsx
│   │   │       │   │   ├── RubricRow.jsx
│   │   │       │   │   ├── ScoreDistributionRow.jsx
│   │   │       │   │   ├── TotalRow.jsx
│   │   │       │   │   └── __tests__
│   │   │       │   │       ├── AssignmentRow.test.jsx
│   │   │       │   │       ├── RubricRow.test.jsx
│   │   │       │   │       └── ScoreDistributionRow.test.jsx
│   │   │       │   ├── GradeSummaryContainer.jsx
│   │   │       │   ├── GradeSummaryManager.jsx
│   │   │       │   ├── ScoreDistributionGraph.jsx
│   │   │       │   ├── SubmissionComment.jsx
│   │   │       │   ├── SubmissionComment.stories.jsx
│   │   │       │   ├── WhatIfGrade.jsx
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── AssignmentTable.test.jsx
│   │   │       │   │   ├── SubmissionComment.test.jsx
│   │   │       │   │   └── utils.test.jsx
│   │   │       │   ├── constants.js
│   │   │       │   ├── context.jsx
│   │   │       │   ├── gradeCalculatorConversions.js
│   │   │       │   └── utils.jsx
│   │   │       ├── SelectMenu.jsx
│   │   │       ├── SelectMenuGroup.jsx
│   │   │       ├── SubmissionAttempts.tsx
│   │   │       ├── SubmissionCommentsTray.tsx
│   │   │       ├── __tests__
│   │   │       │   ├── ClearBadgeCountButton.test.tsx
│   │   │       │   ├── SelectMenu.test.tsx
│   │   │       │   ├── SelectMenuGroup.test.tsx
│   │   │       │   ├── SubmissionAttempts.test.tsx
│   │   │       │   └── SubmissionCommentsTray.test.tsx
│   │   │       └── stores
│   │   │           └── index.ts
│   │   ├── gradebook
│   │   │   ├── index.tsx
│   │   │   ├── jquery
│   │   │   │   ├── GradeDisplayWarningDialog.js
│   │   │   │   ├── GradebookKeyboardNav.ts
│   │   │   │   ├── PostGradesFrameDialog.ts
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── PostGradesFrameDialog.spec.js
│   │   │   │   │   └── slickgrid.long_text_editor.test.js
│   │   │   │   └── slickgrid.long_text_editor.ts
│   │   │   ├── jst
│   │   │   │   ├── GradeDisplayWarningDialog.handlebars
│   │   │   │   ├── GradeDisplayWarningDialog.handlebars.json
│   │   │   │   ├── PostGradesFrameDialog.handlebars
│   │   │   │   └── PostGradesFrameDialog.handlebars.json
│   │   │   ├── package.json
│   │   │   ├── react
│   │   │   │   ├── AssignmentPostingPolicyTray
│   │   │   │   │   ├── Api.ts
│   │   │   │   │   ├── Layout.tsx
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   ├── Api.spec.js
│   │   │   │   │   │   ├── AssignmentPostingPolicyTray.test.jsx
│   │   │   │   │   │   ├── Layout.test.jsx
│   │   │   │   │   │   ├── PostPolicies.test.jsx
│   │   │   │   │   │   └── PostPolicyApi.spec.js
│   │   │   │   │   └── index.tsx
│   │   │   │   ├── LatePolicyApplicator.ts
│   │   │   │   ├── SISGradePassback
│   │   │   │   │   ├── AssignmentCorrectionRow.tsx
│   │   │   │   │   ├── PostGradesApp.tsx
│   │   │   │   │   ├── PostGradesDialog.tsx
│   │   │   │   │   ├── PostGradesDialogCorrectionsPage.tsx
│   │   │   │   │   ├── PostGradesDialogNeedsGradingPage.tsx
│   │   │   │   │   ├── PostGradesDialogSummaryPage.tsx
│   │   │   │   │   ├── PostGradesStore.ts
│   │   │   │   │   └── assignmentUtils.ts
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── LatePolicy.test.js
│   │   │   │   │   └── LatePolicyApplicator.spec.js
│   │   │   │   ├── default_gradebook
│   │   │   │   │   ├── AsyncComponents.tsx
│   │   │   │   │   ├── CourseSettings
│   │   │   │   │   │   └── index.ts
│   │   │   │   │   ├── CurveGradesDialogManager.ts
│   │   │   │   │   ├── FinalGradeOverrides
│   │   │   │   │   │   ├── FinalGradeOverride.utils.ts
│   │   │   │   │   │   ├── FinalGradeOverrideDatastore.ts
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── FinalGradeOverrideDatastore.test.ts
│   │   │   │   │   │   │   ├── FinalGradeOverrideUtils.test.ts
│   │   │   │   │   │   │   └── index.test.ts
│   │   │   │   │   │   └── index.ts
│   │   │   │   │   ├── Gradebook.sorting.ts
│   │   │   │   │   ├── Gradebook.tsx
│   │   │   │   │   ├── Gradebook.utils.ts
│   │   │   │   │   ├── GradebookData.tsx
│   │   │   │   │   ├── GradebookGrid
│   │   │   │   │   │   ├── Columns
│   │   │   │   │   │   │   └── index.ts
│   │   │   │   │   │   ├── Events.ts
│   │   │   │   │   │   ├── Grid.utils.ts
│   │   │   │   │   │   ├── GridSupport
│   │   │   │   │   │   │   ├── Columns.ts
│   │   │   │   │   │   │   ├── Events.ts
│   │   │   │   │   │   │   ├── GridEvent.ts
│   │   │   │   │   │   │   ├── GridHelper.ts
│   │   │   │   │   │   │   ├── Navigation.ts
│   │   │   │   │   │   │   ├── State.ts
│   │   │   │   │   │   │   ├── Style.ts
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── Columns.test.js
│   │   │   │   │   │   │   │   ├── GridEvent.test.js
│   │   │   │   │   │   │   │   ├── GridHelper.test.js
│   │   │   │   │   │   │   │   ├── Navigation.test.js
│   │   │   │   │   │   │   │   ├── SlickGridSpecHelper.js
│   │   │   │   │   │   │   │   ├── State.test.js
│   │   │   │   │   │   │   │   └── Style.test.js
│   │   │   │   │   │   │   └── index.ts
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── Columns.spec.js
│   │   │   │   │   │   │   ├── Grid.utils.test.ts
│   │   │   │   │   │   │   └── editors
│   │   │   │   │   │   │       ├── AssignmentCellEditor
│   │   │   │   │   │   │       │   └── AssignmentRowCellPropFactory.test.js
│   │   │   │   │   │   │       ├── CellEditorFactory.spec.js
│   │   │   │   │   │   │       └── TotalGradeOverrideCellEditor.test.jsx
│   │   │   │   │   │   ├── editors
│   │   │   │   │   │   │   ├── AssignmentCellEditor
│   │   │   │   │   │   │   │   ├── AssignmentRowCell.tsx
│   │   │   │   │   │   │   │   ├── AssignmentRowCellPropFactory.ts
│   │   │   │   │   │   │   │   ├── ReadOnlyCell.tsx
│   │   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   │   ├── AssignmentCellEditor.test.jsx
│   │   │   │   │   │   │   │   │   ├── AssignmentRowCell.test.jsx
│   │   │   │   │   │   │   │   │   └── ReadOnlyCell.test.jsx
│   │   │   │   │   │   │   │   └── index.ts
│   │   │   │   │   │   │   ├── AssignmentGradeInput
│   │   │   │   │   │   │   │   ├── CompleteIncompleteGradeInput.tsx
│   │   │   │   │   │   │   │   ├── GradingSchemeGradeInput.tsx
│   │   │   │   │   │   │   │   ├── TextGradeInput.tsx
│   │   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   │   ├── CompleteIncompleteGradeInput.test.jsx
│   │   │   │   │   │   │   │   │   ├── GradeInput.test.jsx
│   │   │   │   │   │   │   │   │   └── GradingSchemeGradeInput.test.jsx
│   │   │   │   │   │   │   │   └── index.tsx
│   │   │   │   │   │   │   ├── CellEditorComponent.ts
│   │   │   │   │   │   │   ├── CellEditorFactory.ts
│   │   │   │   │   │   │   ├── GradeInput
│   │   │   │   │   │   │   │   ├── GradeInput.tsx
│   │   │   │   │   │   │   │   ├── PropTypes.ts
│   │   │   │   │   │   │   │   ├── TextGradeInput.tsx
│   │   │   │   │   │   │   │   └── __tests__
│   │   │   │   │   │   │   │       └── TotalGradeOverrideInput.test.jsx
│   │   │   │   │   │   │   ├── InvalidGradeIndicator.tsx
│   │   │   │   │   │   │   ├── ReactCellEditor.ts
│   │   │   │   │   │   │   ├── SimilarityIndicator.tsx
│   │   │   │   │   │   │   └── TotalGradeOverrideCellEditor
│   │   │   │   │   │   │       ├── EditableCell.tsx
│   │   │   │   │   │   │       ├── ReadOnlyCell.tsx
│   │   │   │   │   │   │       ├── TotalGradeOverrideCellPropFactory.ts
│   │   │   │   │   │   │       ├── __tests__
│   │   │   │   │   │   │       │   ├── EditableCell.test.jsx
│   │   │   │   │   │   │       │   ├── ReadOnlyCell.test.jsx
│   │   │   │   │   │   │       │   └── TotalGradeOverrideCellPropFactory.test.ts
│   │   │   │   │   │   │       └── index.tsx
│   │   │   │   │   │   ├── formatters
│   │   │   │   │   │   │   ├── AssignmentCellFormatter.ts
│   │   │   │   │   │   │   ├── AssignmentGroupCellFormatter.ts
│   │   │   │   │   │   │   ├── CellFormatterFactory.ts
│   │   │   │   │   │   │   ├── CellStyles.ts
│   │   │   │   │   │   │   ├── CustomColumnCellFormatter.ts
│   │   │   │   │   │   │   ├── StudentCellFormatter.ts
│   │   │   │   │   │   │   ├── StudentCellFormatter.utils.ts
│   │   │   │   │   │   │   ├── StudentFirstNameCellFormatter.ts
│   │   │   │   │   │   │   ├── StudentLastNameCellFormatter.ts
│   │   │   │   │   │   │   ├── TotalGradeCellFormatter.ts
│   │   │   │   │   │   │   ├── TotalGradeOverrideCellFormatter.ts
│   │   │   │   │   │   │   └── __tests__
│   │   │   │   │   │   │       ├── AssignmentCellFormatter.test.js
│   │   │   │   │   │   │       ├── AssignmentGroupCellFormatter.test.js
│   │   │   │   │   │   │       ├── CellStyles.spec.js
│   │   │   │   │   │   │       ├── CustomColumnCellFormatter.spec.js
│   │   │   │   │   │   │       ├── StudentCellFormatter.test.js
│   │   │   │   │   │   │       ├── StudentFirstNameCellFormatter.test.js
│   │   │   │   │   │   │       ├── StudentLastNameCellFormatter.test.js
│   │   │   │   │   │   │       ├── TotalGradeCellFormatter.test.js
│   │   │   │   │   │   │       └── TotalGradeOverrideCellFormatter.test.js
│   │   │   │   │   │   ├── headers
│   │   │   │   │   │   │   ├── AssignmentColumnHeader.tsx
│   │   │   │   │   │   │   ├── AssignmentColumnHeaderRenderer.tsx
│   │   │   │   │   │   │   ├── AssignmentGroupColumnHeader.tsx
│   │   │   │   │   │   │   ├── AssignmentGroupColumnHeaderRenderer.tsx
│   │   │   │   │   │   │   ├── ColumnHeader.tsx
│   │   │   │   │   │   │   ├── ColumnHeaderRenderer.tsx
│   │   │   │   │   │   │   ├── CustomColumnHeader.tsx
│   │   │   │   │   │   │   ├── CustomColumnHeaderRenderer.tsx
│   │   │   │   │   │   │   ├── SecondaryDetailLine.tsx
│   │   │   │   │   │   │   ├── StudentColumnHeader.tsx
│   │   │   │   │   │   │   ├── StudentColumnHeaderRenderer.tsx
│   │   │   │   │   │   │   ├── StudentColumnHeaderRenderer.utils.ts
│   │   │   │   │   │   │   ├── StudentFirstNameColumnHeader.tsx
│   │   │   │   │   │   │   ├── StudentLastNameColumnHeader.tsx
│   │   │   │   │   │   │   ├── TotalGradeColumnHeader.tsx
│   │   │   │   │   │   │   ├── TotalGradeColumnHeaderRenderer.tsx
│   │   │   │   │   │   │   ├── TotalGradeOverrideColumnHeader.tsx
│   │   │   │   │   │   │   ├── TotalGradeOverrideColumnHeaderRenderer.tsx
│   │   │   │   │   │   │   └── __tests__
│   │   │   │   │   │   │       ├── AssignmentColumnHeader1.test.jsx
│   │   │   │   │   │   │       ├── AssignmentColumnHeader2.test.jsx
│   │   │   │   │   │   │       ├── AssignmentColumnHeader3.test.jsx
│   │   │   │   │   │   │       ├── AssignmentColumnHeaderRenderer.test.jsx
│   │   │   │   │   │   │       ├── AssignmentGroupColumnHeader.test.jsx
│   │   │   │   │   │   │       ├── AssignmentGroupColumnHeaderRenderer.test.jsx
│   │   │   │   │   │   │       ├── ColumnHeaderRenderer.test.js
│   │   │   │   │   │   │       ├── ColumnHeaderSpecHelpers.js
│   │   │   │   │   │   │       ├── CustomColumnHeader1.test.jsx
│   │   │   │   │   │   │       ├── CustomColumnHeaderRendererSpec.test.js
│   │   │   │   │   │   │       ├── StudentColumnHeader2.test.jsx
│   │   │   │   │   │   │       ├── StudentColumnHeader3.test.jsx
│   │   │   │   │   │   │       ├── StudentColumnHeader4.test.jsx
│   │   │   │   │   │   │       ├── StudentColumnHeader5.test.jsx
│   │   │   │   │   │   │       ├── StudentColumnHeaderRenderer.test.jsx
│   │   │   │   │   │   │       ├── TotalGradeColumnHeader.test.jsx
│   │   │   │   │   │   │       └── TotalGradeColumnHeaderRenderer.test.jsx
│   │   │   │   │   │   └── index.ts
│   │   │   │   │   ├── PerformanceControls.ts
│   │   │   │   │   ├── PostPolicies
│   │   │   │   │   │   ├── PostPolicyApi.ts
│   │   │   │   │   │   └── index.tsx
│   │   │   │   │   ├── RubricAssessmentExport
│   │   │   │   │   │   ├── RubricAssessmentExportModal.tsx
│   │   │   │   │   │   └── useAssignmentRubricAssessments.tsx
│   │   │   │   │   ├── RubricAssessmentImport
│   │   │   │   │   │   ├── RubricAssessmentImportFailuresModal.tsx
│   │   │   │   │   │   ├── RubricAssessmentImportTable.tsx
│   │   │   │   │   │   ├── RubricAssessmentImportTray.tsx
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   └── RubricAssessmentImport.test.tsx
│   │   │   │   │   │   └── index.tsx
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   ├── AssignmentActions.spec.js
│   │   │   │   │   │   ├── CourseSettings
│   │   │   │   │   │   │   └── index.test.js
│   │   │   │   │   │   ├── CurveGradesDialogManager.test.js
│   │   │   │   │   │   ├── GradeInput
│   │   │   │   │   │   │   ├── CompleteIncomplete.test.jsx
│   │   │   │   │   │   │   ├── GradeInputDriver.js
│   │   │   │   │   │   │   ├── GradingScheme.test.jsx
│   │   │   │   │   │   │   ├── Percentage.test.jsx
│   │   │   │   │   │   │   └── Points.test.jsx
│   │   │   │   │   │   ├── Gradebook.sorting.test.ts
│   │   │   │   │   │   ├── Gradebook.utils.1.test.ts
│   │   │   │   │   │   ├── Gradebook.utils.2.test.ts
│   │   │   │   │   │   ├── Gradebook.utils.3.test.ts
│   │   │   │   │   │   ├── Gradebook.utils.4.test.ts
│   │   │   │   │   │   ├── GradebookColumnFiltering.test.js
│   │   │   │   │   │   ├── GradebookColumnOrdering.1.test.js
│   │   │   │   │   │   ├── GradebookColumnOrdering.2.test.js
│   │   │   │   │   │   ├── GradebookColumnOrdering.3.test.js
│   │   │   │   │   │   ├── GradebookColumnWidth.test.js
│   │   │   │   │   │   ├── GradebookData.test.js
│   │   │   │   │   │   ├── GradebookData.test.tsx
│   │   │   │   │   │   ├── GradebookFilters.test.js
│   │   │   │   │   │   ├── GradebookFilters1.test.jsx
│   │   │   │   │   │   ├── GradebookFilters2.test.jsx
│   │   │   │   │   │   ├── GradebookFilters3.test.jsx
│   │   │   │   │   │   ├── GradebookGrading.test.jsx
│   │   │   │   │   │   ├── GradebookGrading2Spec.bak
│   │   │   │   │   │   ├── GradebookGrid.test.js
│   │   │   │   │   │   ├── GradebookGrid2Spec.bak
│   │   │   │   │   │   ├── GradebookGridColumnsSpec.bak
│   │   │   │   │   │   ├── GradebookHeaderComponent1.test.js
│   │   │   │   │   │   ├── GradebookHeaderComponent2.test.js
│   │   │   │   │   │   ├── GradebookInit.test.js
│   │   │   │   │   │   ├── GradebookMenus.test.jsx
│   │   │   │   │   │   ├── GradebookNotes1.test.js
│   │   │   │   │   │   ├── GradebookNotes2.test.js
│   │   │   │   │   │   ├── GradebookSearch.test.js
│   │   │   │   │   │   ├── GradebookSettings.test.jsx
│   │   │   │   │   │   ├── GradebookSettings2.test.jsx
│   │   │   │   │   │   ├── GradebookSort1.test.js
│   │   │   │   │   │   ├── GradebookSort2.test.js
│   │   │   │   │   │   ├── GradebookSort3.test.js
│   │   │   │   │   │   ├── GradebookSort4.test.js
│   │   │   │   │   │   ├── GradebookSort5.test.js
│   │   │   │   │   │   ├── GradebookSpecHelper.ts
│   │   │   │   │   │   ├── GradebookTotals.test.js
│   │   │   │   │   │   ├── PerformanceControls.spec.js
│   │   │   │   │   │   ├── StudentTray.test.js
│   │   │   │   │   │   ├── SubmissionComments.test.js
│   │   │   │   │   │   ├── SubmissionStateMap.spec.js
│   │   │   │   │   │   ├── SubmissionTray.test.jsx
│   │   │   │   │   │   ├── SubmissionTrayRadioInputGroup.test.tsx
│   │   │   │   │   │   ├── assignment-groups
│   │   │   │   │   │   │   └── AssignmentGroups.test.js
│   │   │   │   │   │   ├── context-modules
│   │   │   │   │   │   │   └── ContextModules.test.js
│   │   │   │   │   │   ├── custom-columns
│   │   │   │   │   │   │   └── CustomColumns.test.js
│   │   │   │   │   │   ├── data-loading
│   │   │   │   │   │   │   └── ContentLoadStates.spec.js
│   │   │   │   │   │   ├── fixtures.ts
│   │   │   │   │   │   ├── grading-period-assignments
│   │   │   │   │   │   │   └── GradingPeriodAssignments.test.js
│   │   │   │   │   │   ├── sections
│   │   │   │   │   │   │   └── Sections.spec.js
│   │   │   │   │   │   ├── students
│   │   │   │   │   │   │   └── Students.test.js
│   │   │   │   │   │   └── submissions
│   │   │   │   │   │       └── Submissions.test.js
│   │   │   │   │   ├── apis
│   │   │   │   │   │   ├── GradebookApi.ts
│   │   │   │   │   │   ├── GradebookSettingsModalApi.ts
│   │   │   │   │   │   ├── SubmissionCommentApi.ts
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       ├── GradebookApi.test.js
│   │   │   │   │   │       ├── GradebookSettingsModalApi.test.ts
│   │   │   │   │   │       ├── SubmissionCommentApi.test.js
│   │   │   │   │   │       └── saveSettings.test.js
│   │   │   │   │   ├── components
│   │   │   │   │   │   ├── ActionMenu.tsx
│   │   │   │   │   │   ├── AdvancedTabPanel.tsx
│   │   │   │   │   │   ├── AnonymousSpeedGraderAlert.tsx
│   │   │   │   │   │   ├── ApplyScoreToUngradedModal.tsx
│   │   │   │   │   │   ├── Carousel.tsx
│   │   │   │   │   │   ├── EnhancedActionMenu.tsx
│   │   │   │   │   │   ├── ExportProgressBar.tsx
│   │   │   │   │   │   ├── FilterDateModal.tsx
│   │   │   │   │   │   ├── FilterDropdown.tsx
│   │   │   │   │   │   ├── FilterNav.tsx
│   │   │   │   │   │   ├── FilterNav.utils.tsx
│   │   │   │   │   │   ├── FilterNavPopover.tsx
│   │   │   │   │   │   ├── FilterTray.tsx
│   │   │   │   │   │   ├── FilterTrayFilter.tsx
│   │   │   │   │   │   ├── FilterTrayFilterPreset.tsx
│   │   │   │   │   │   ├── GradeInput
│   │   │   │   │   │   │   └── CompleteIncompleteGradeInput.tsx
│   │   │   │   │   │   ├── GradeInput.tsx
│   │   │   │   │   │   ├── GradeOverrideTrayRadioInputGroup.tsx
│   │   │   │   │   │   ├── GradePostingPolicyTabPanel.tsx
│   │   │   │   │   │   ├── GradebookGrid.tsx
│   │   │   │   │   │   ├── GradebookSettingsModal.tsx
│   │   │   │   │   │   ├── GridColor.tsx
│   │   │   │   │   │   ├── InputsForCheckpoints.tsx
│   │   │   │   │   │   ├── LatePoliciesTabPanel.tsx
│   │   │   │   │   │   ├── LatePolicyGrade.tsx
│   │   │   │   │   │   ├── MultiSelectSearchInput.tsx
│   │   │   │   │   │   ├── PostGradesFrameModal.tsx
│   │   │   │   │   │   ├── SimilarityIcon.tsx
│   │   │   │   │   │   ├── SimilarityScore.tsx
│   │   │   │   │   │   ├── StatusColorListItem.tsx
│   │   │   │   │   │   ├── StatusColorPanel.tsx
│   │   │   │   │   │   ├── StatusesModal.tsx
│   │   │   │   │   │   ├── SubmissionCommentCreateForm.tsx
│   │   │   │   │   │   ├── SubmissionCommentForm.tsx
│   │   │   │   │   │   ├── SubmissionCommentListItem.tsx
│   │   │   │   │   │   ├── SubmissionCommentUpdateForm.tsx
│   │   │   │   │   │   ├── SubmissionStatus
│   │   │   │   │   │   │   └── Message.tsx
│   │   │   │   │   │   ├── SubmissionStatus.tsx
│   │   │   │   │   │   ├── SubmissionTray.tsx
│   │   │   │   │   │   ├── SubmissionTrayRadioInput.tsx
│   │   │   │   │   │   ├── SubmissionTrayRadioInputGroup.tsx
│   │   │   │   │   │   ├── TotalGradeOverrideTray.tsx
│   │   │   │   │   │   ├── ViewOptionsMenu.tsx
│   │   │   │   │   │   ├── ViewOptionsTabPanel.tsx
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── ActionMenu.test.tsx
│   │   │   │   │   │   │   ├── AdvancedTabPanel.test.jsx
│   │   │   │   │   │   │   ├── AnonymousSpeedGraderAlert.test.jsx
│   │   │   │   │   │   │   ├── ApplyScoreToUngradedModal.test.tsx
│   │   │   │   │   │   │   ├── Carousel.test.tsx
│   │   │   │   │   │   │   ├── EnhancedActionMenu.test.tsx
│   │   │   │   │   │   │   ├── ExportProgressBar.test.tsx
│   │   │   │   │   │   │   ├── FilterDateModal.test.tsx
│   │   │   │   │   │   │   ├── FilterNav1.test.tsx
│   │   │   │   │   │   │   ├── FilterNav2.test.tsx
│   │   │   │   │   │   │   ├── FilterNavCondition.test.tsx
│   │   │   │   │   │   │   ├── FilterNavFilterPreset.test.tsx
│   │   │   │   │   │   │   ├── FilterTray.test.tsx
│   │   │   │   │   │   │   ├── GradeInputDriver.jsx
│   │   │   │   │   │   │   ├── GradePostingPolicyTabPanel.test.jsx
│   │   │   │   │   │   │   ├── Gradebook.test.tsx
│   │   │   │   │   │   │   ├── GradebookSettingsModal.test.tsx
│   │   │   │   │   │   │   ├── GridColor.test.tsx
│   │   │   │   │   │   │   ├── LatePoliciesTabPanel.test.tsx
│   │   │   │   │   │   │   ├── LatePoliciesTabPanelPercentageNumberInput.test.jsx
│   │   │   │   │   │   │   ├── LatePolicyGrade.test.tsx
│   │   │   │   │   │   │   ├── MultiSelectSearchInput.test.tsx
│   │   │   │   │   │   │   ├── PostGradesFrameModal.test.tsx
│   │   │   │   │   │   │   ├── SimilarityIcon.test.jsx
│   │   │   │   │   │   │   ├── SimilarityIndicator.test.jsx
│   │   │   │   │   │   │   ├── SimilarityScore.test.jsx
│   │   │   │   │   │   │   ├── SpeedGraderAlert.test.jsx
│   │   │   │   │   │   │   ├── StatusColorListItem.test.jsx
│   │   │   │   │   │   │   ├── StatusColorPanel.test.tsx
│   │   │   │   │   │   │   ├── StatusesModal.test.tsx
│   │   │   │   │   │   │   ├── SubmissionCommentCreateForm.test.tsx
│   │   │   │   │   │   │   ├── SubmissionCommentListItem.test.tsx
│   │   │   │   │   │   │   ├── SubmissionCommentUpdateForm.test.tsx
│   │   │   │   │   │   │   ├── SubmissionStatus
│   │   │   │   │   │   │   │   └── Message.test.jsx
│   │   │   │   │   │   │   ├── SubmissionStatus.test.jsx
│   │   │   │   │   │   │   ├── SubmissionTray.test.tsx
│   │   │   │   │   │   │   ├── SubmissionTrayRadioInput.test.tsx
│   │   │   │   │   │   │   ├── TotalGradeOverrideTray.test.tsx
│   │   │   │   │   │   │   ├── ViewOptionsMenu.test.tsx
│   │   │   │   │   │   │   ├── ViewOptionsTabPanel.test.tsx
│   │   │   │   │   │   │   └── helpers.tsx
│   │   │   │   │   │   └── content-filters
│   │   │   │   │   │       ├── AssignmentGroupFilter.tsx
│   │   │   │   │   │       ├── GradingPeriodFilter.tsx
│   │   │   │   │   │       ├── ModuleFilter.tsx
│   │   │   │   │   │       ├── StudentGroupFilter.tsx
│   │   │   │   │   │       └── __tests__
│   │   │   │   │   │           ├── AssignmentGroupFilter.test.jsx
│   │   │   │   │   │           ├── ContentFilter.test.jsx
│   │   │   │   │   │           ├── GradingPeriodFilter.test.jsx
│   │   │   │   │   │           ├── ModuleFilter.test.jsx
│   │   │   │   │   │           ├── SectionFilter.test.jsx
│   │   │   │   │   │           └── StudentGroupFilter.test.jsx
│   │   │   │   │   ├── constants
│   │   │   │   │   │   ├── ViewOptions.ts
│   │   │   │   │   │   ├── colors.ts
│   │   │   │   │   │   ├── filterTypes.ts
│   │   │   │   │   │   ├── statuses.ts
│   │   │   │   │   │   └── studentRowHeaderConstants.ts
│   │   │   │   │   ├── gradebook.d.ts
│   │   │   │   │   ├── grid.d.ts
│   │   │   │   │   ├── hooks
│   │   │   │   │   │   └── useFinalGradeOverrideCustomStatus.tsx
│   │   │   │   │   ├── initialState.ts
│   │   │   │   │   ├── propTypes
│   │   │   │   │   │   └── CommentPropTypes.ts
│   │   │   │   │   ├── queries
│   │   │   │   │   │   └── Queries.ts
│   │   │   │   │   └── stores
│   │   │   │   │       ├── StudentDatastore.ts
│   │   │   │   │       ├── __tests__
│   │   │   │   │       │   ├── StudentDatastore.spec.js
│   │   │   │   │       │   ├── assignmentsState.test.ts
│   │   │   │   │       │   ├── customColumnsState.test.ts
│   │   │   │   │       │   ├── filtersState.test.ts
│   │   │   │   │       │   ├── finalGradeOverrides.test.ts
│   │   │   │   │       │   ├── modulesState.test.ts
│   │   │   │   │       │   ├── sisOverridesState.test.ts
│   │   │   │   │       │   └── studentsState.test.ts
│   │   │   │   │       ├── assignmentsState.ts
│   │   │   │   │       ├── customColumnsState.ts
│   │   │   │   │       ├── filtersState.ts
│   │   │   │   │       ├── finalGradeOverrides.ts
│   │   │   │   │       ├── index.ts
│   │   │   │   │       ├── modulesState.ts
│   │   │   │   │       ├── rubricAssessmentExportState.ts
│   │   │   │   │       ├── rubricAssessmentImportState.ts
│   │   │   │   │       ├── sisOverridesState.ts
│   │   │   │   │       ├── studentsState.ts
│   │   │   │   │       └── studentsState.utils.ts
│   │   │   │   └── shared
│   │   │   │       ├── EnterGradesAsSetting.ts
│   │   │   │       ├── GradebookExportManager.ts
│   │   │   │       ├── MessageStudentsWhoDialog.ts
│   │   │   │       ├── MessageStudentsWithObserversModal.tsx
│   │   │   │       ├── ReuploadSubmissionsDialogManager.ts
│   │   │   │       ├── ScoreToUngradedManager.tsx
│   │   │   │       ├── SetDefaultGradeDialogManager.ts
│   │   │   │       ├── __tests__
│   │   │   │       │   ├── EnterGradesAsSetting.spec.js
│   │   │   │       │   ├── GradebookExportManager1.test.js
│   │   │   │       │   ├── GradebookExportManager2.test.js
│   │   │   │       │   ├── ReuploadSubmissionsDialogManager.test.js
│   │   │   │       │   ├── ScoreToUngradedManager.test.tsx
│   │   │   │       │   └── SetDefaultGradeDialogManager.test.js
│   │   │   │       └── helpers
│   │   │   │           ├── ScoreToGradeHelper.ts
│   │   │   │           ├── TextMeasure.ts
│   │   │   │           ├── __tests__
│   │   │   │           │   ├── ScoreToGradeHelper.spec.js
│   │   │   │           │   ├── TextMeasure.test.js
│   │   │   │           │   └── assignmentHelper.spec.js
│   │   │   │           └── assignmentHelper.ts
│   │   │   └── util
│   │   │       ├── DateUtils.ts
│   │   │       ├── NumberCompare.ts
│   │   │       └── __tests__
│   │   │           └── DateUtils.test.ts
│   │   ├── gradebook_history
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── GradebookHistoryApp.tsx
│   │   │       ├── SearchForm.jsx
│   │   │       ├── SearchResults.jsx
│   │   │       ├── SearchResultsRow.jsx
│   │   │       ├── __tests__
│   │   │       │   ├── Fixtures.js
│   │   │       │   ├── GradebookHistoryApp.test.jsx
│   │   │       │   ├── SearchForm.test.jsx
│   │   │       │   ├── SearchFormComponent.test.tsx
│   │   │       │   ├── SearchResults.test.jsx
│   │   │       │   └── SearchResultsComponent.test.tsx
│   │   │       ├── actions
│   │   │       │   ├── HistoryActions.js
│   │   │       │   ├── SearchFormActions.js
│   │   │       │   ├── SearchResultsActions.js
│   │   │       │   └── __tests__
│   │   │       │       ├── HistoryActions.spec.js
│   │   │       │       └── SearchFormActions.test.js
│   │   │       ├── api
│   │   │       │   ├── AssignmentApi.js
│   │   │       │   ├── HistoryApi.js
│   │   │       │   ├── UserApi.js
│   │   │       │   └── __tests__
│   │   │       │       ├── AssignmentApi.test.js
│   │   │       │       ├── HistoryApi.test.js
│   │   │       │       └── UserApi.test.js
│   │   │       ├── environment.js
│   │   │       ├── reducers
│   │   │       │   ├── HistoryReducer.js
│   │   │       │   ├── Reducer.js
│   │   │       │   ├── SearchFormReducer.js
│   │   │       │   └── __tests__
│   │   │       │       ├── HistoryReducer.spec.js
│   │   │       │       ├── Reducer.spec.js
│   │   │       │       └── SearchFormReducer.spec.js
│   │   │       └── store
│   │   │           └── GradebookHistoryStore.js
│   │   ├── gradebook_uploads
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── GradebookUploads.test.js
│   │   │   │   │   ├── ProcessGradebookUpload.test.js
│   │   │   │   │   ├── __mocks__
│   │   │   │   │   │   └── jquery-ui.js
│   │   │   │   │   ├── formatter.test.js
│   │   │   │   │   ├── override-scores.test.js
│   │   │   │   │   ├── resolution.test.js
│   │   │   │   │   └── wait_for_processing.test.js
│   │   │   │   ├── index.js
│   │   │   │   ├── process_gradebook_upload.js
│   │   │   │   └── wait_for_processing.js
│   │   │   └── package.json
│   │   ├── graphiql
│   │   │   ├── CustomArgs.js
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       └── GraphiQLApp.jsx
│   │   ├── group_submission_reminder
│   │   │   ├── index.jsx
│   │   │   └── package.json
│   │   ├── groups
│   │   │   ├── index.jsx
│   │   │   └── package.json
│   │   ├── horizon_toggle
│   │   │   ├── index.tsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── HorizonAccount.tsx
│   │   │       ├── HorizonEnabled.tsx
│   │   │       ├── HorizonModal
│   │   │       │   ├── HorizonAccountModal.tsx
│   │   │       │   ├── InitHorizonModal.tsx
│   │   │       │   └── __tests__
│   │   │       │       └── HorizonAccountModal.test.tsx
│   │   │       ├── HorizonToggleContext.ts
│   │   │       ├── LoadingContainer.tsx
│   │   │       ├── Main.tsx
│   │   │       ├── RevertAccount.tsx
│   │   │       ├── __tests__
│   │   │       │   ├── HorizonAccount.test.tsx
│   │   │       │   ├── Main.test.tsx
│   │   │       │   └── RevertAccount.test.tsx
│   │   │       ├── contents
│   │   │       │   ├── Assignments.tsx
│   │   │       │   ├── Collaborations.tsx
│   │   │       │   ├── ContentChanges.tsx
│   │   │       │   ├── ContentItems.tsx
│   │   │       │   ├── ContentPublished.tsx
│   │   │       │   ├── ContentUnsupported.tsx
│   │   │       │   ├── Discussions.tsx
│   │   │       │   ├── Groups.tsx
│   │   │       │   ├── Outcomes.tsx
│   │   │       │   ├── Quizzes.tsx
│   │   │       │   └── __tests__
│   │   │       │       ├── Assignments.test.tsx
│   │   │       │       ├── Collaborations.test.tsx
│   │   │       │       ├── ContentChanges.test.tsx
│   │   │       │       ├── ContentItems.test.tsx
│   │   │       │       ├── ContentPublished.test.tsx
│   │   │       │       ├── ContentUnsupported.test.tsx
│   │   │       │       ├── Discussions.test.tsx
│   │   │       │       ├── Groups.test.tsx
│   │   │       │       ├── Outcomes.test.tsx
│   │   │       │       └── Quizzes.test.tsx
│   │   │       ├── hooks
│   │   │       │   └── useCanvasCareer.ts
│   │   │       └── types.ts
│   │   ├── inbox
│   │   │   ├── graphql
│   │   │   │   ├── Assignment.js
│   │   │   │   ├── Attachment.js
│   │   │   │   ├── Conversation.js
│   │   │   │   ├── ConversationMessage.js
│   │   │   │   ├── ConversationParticipant.js
│   │   │   │   ├── Course.js
│   │   │   │   ├── Enrollment.js
│   │   │   │   ├── Group.js
│   │   │   │   ├── MediaComment.js
│   │   │   │   ├── MediaSource.js
│   │   │   │   ├── MediaTrack.js
│   │   │   │   ├── Mutations.js
│   │   │   │   ├── PageInfo.js
│   │   │   │   ├── Queries.js
│   │   │   │   ├── SubmissionComment.js
│   │   │   │   ├── User.js
│   │   │   │   └── mswHandlers.js
│   │   │   ├── inboxModel.d.ts
│   │   │   ├── index.tsx
│   │   │   ├── package.json
│   │   │   ├── react
│   │   │   │   ├── components
│   │   │   │   │   ├── AddressBook
│   │   │   │   │   │   ├── AddressBook.jsx
│   │   │   │   │   │   ├── AddressBook.stories.jsx
│   │   │   │   │   │   ├── AddressBookItem.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       ├── AddressBook1.test.jsx
│   │   │   │   │   │       ├── AddressBook2.test.jsx
│   │   │   │   │   │       ├── AddressBook3.test.jsx
│   │   │   │   │   │       └── AddressBookItem.test.jsx
│   │   │   │   │   ├── ComposeActionButtons
│   │   │   │   │   │   ├── ComposeActionButtons.jsx
│   │   │   │   │   │   ├── ComposeActionButtons.stories.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── ComposeActionButtons.test.jsx
│   │   │   │   │   ├── ComposeInputWrapper
│   │   │   │   │   │   └── ComposeInputWrapper.tsx
│   │   │   │   │   ├── ConversationListHolder
│   │   │   │   │   │   ├── ConversationListHolder.jsx
│   │   │   │   │   │   ├── ConversationListHolder.stories.jsx
│   │   │   │   │   │   ├── ConversationListItem.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       ├── ConversationListHolder.test.jsx
│   │   │   │   │   │       └── ConversationListItem.test.jsx
│   │   │   │   │   ├── CourseSelect
│   │   │   │   │   │   ├── CourseSelect.jsx
│   │   │   │   │   │   ├── CourseSelect.stories.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── CourseSelect.test.jsx
│   │   │   │   │   ├── IndividualMessageCheckbox
│   │   │   │   │   │   ├── IndividualMessageCheckbox.jsx
│   │   │   │   │   │   ├── IndividualMessageCheckbox.stories.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── IndividualMessageCheckbox.test.jsx
│   │   │   │   │   ├── MailboxSelectionDropdown
│   │   │   │   │   │   ├── MailboxSelectionDropdown.stories.jsx
│   │   │   │   │   │   ├── MailboxSelectionDropdown.tsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── MailboxSelectionDropdown.test.jsx
│   │   │   │   │   ├── ManageUserLabels
│   │   │   │   │   │   ├── ManageUserLabels.jsx
│   │   │   │   │   │   ├── ManageUserLabels.stories.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── ManageUserLabels.test.jsx
│   │   │   │   │   ├── MediaUploadModal
│   │   │   │   │   │   ├── MediaUploadModal.jsx
│   │   │   │   │   │   ├── MediaUploadModal.stories.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── MediaUploadModal.test.jsx
│   │   │   │   │   ├── MessageActionButtons
│   │   │   │   │   │   ├── MessageActionButtons.jsx
│   │   │   │   │   │   ├── MessageActionButtons.stories.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── MessageActionButtons.test.jsx
│   │   │   │   │   ├── MessageBody
│   │   │   │   │   │   ├── MessageBody.stories.jsx
│   │   │   │   │   │   ├── MessageBody.tsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── MessageBody.test.jsx
│   │   │   │   │   ├── MessageDetailActions
│   │   │   │   │   │   ├── MessageDetailActions.jsx
│   │   │   │   │   │   ├── MessageDetailActions.stories.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── MessageDetailActions.test.jsx
│   │   │   │   │   ├── MessageDetailHeader
│   │   │   │   │   │   ├── MessageDetailHeader.jsx
│   │   │   │   │   │   ├── MessageDetailHeader.stories.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── MessageDetailHeader.test.jsx
│   │   │   │   │   ├── MessageDetailItem
│   │   │   │   │   │   ├── MediaPlayer.jsx
│   │   │   │   │   │   ├── MessageDetailItem.jsx
│   │   │   │   │   │   ├── MessageDetailItem.stories.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── MessageDetailItem.test.jsx
│   │   │   │   │   ├── MessageDetailMediaAttachment
│   │   │   │   │   │   ├── MessageDetailMediaAttachment.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── MessageDetailMediaAttachment.test.jsx
│   │   │   │   │   ├── MessageDetailParticipants
│   │   │   │   │   │   ├── MessageDetailParticipants.jsx
│   │   │   │   │   │   ├── MessageDetailParticipants.stories.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── MessageDetailParticipants.test.jsx
│   │   │   │   │   ├── NoSelectedConversation
│   │   │   │   │   │   ├── NoSelectedConversation.jsx
│   │   │   │   │   │   ├── NoSelectedConversation.stories.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── NoSelectedConversation.test.jsx
│   │   │   │   │   ├── PastMessages
│   │   │   │   │   │   ├── PastMessages.jsx
│   │   │   │   │   │   ├── PastMessages.stories.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── PastMessages.test.jsx
│   │   │   │   │   ├── SubjectInput
│   │   │   │   │   │   ├── SubjectInput.jsx
│   │   │   │   │   │   ├── SubjectInput.stories.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── SubjectInput.test.jsx
│   │   │   │   │   └── TranslationControls
│   │   │   │   │       ├── TranslationControls.tsx
│   │   │   │   │       ├── TranslationOptions.tsx
│   │   │   │   │       └── __tests__
│   │   │   │   │           ├── TranslationControls.test.tsx
│   │   │   │   │           └── TranslationOptions.test.tsx
│   │   │   │   ├── containers
│   │   │   │   │   ├── AddressBookContainer
│   │   │   │   │   │   ├── AddressBookContainer.jsx
│   │   │   │   │   │   ├── AddressBookContainer.stories.js
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── AddressBookContainer.test.jsx
│   │   │   │   │   ├── CanvasInbox.jsx
│   │   │   │   │   ├── ComposeModalContainer
│   │   │   │   │   │   ├── ComposeModalContainer.jsx
│   │   │   │   │   │   ├── ComposeModalManager.jsx
│   │   │   │   │   │   ├── HeaderInputs.jsx
│   │   │   │   │   │   ├── ModalBody.jsx
│   │   │   │   │   │   ├── ModalHeader.jsx
│   │   │   │   │   │   ├── ModalSpinner.tsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       ├── HeaderInputs.test.jsx
│   │   │   │   │   │       └── ModalBody.test.tsx
│   │   │   │   │   ├── ConversationListContainer.jsx
│   │   │   │   │   ├── InboxSettingsModalContainer
│   │   │   │   │   │   ├── InboxSettingsModalContainer.tsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       └── InboxSettingsModalContainer.test.jsx
│   │   │   │   │   ├── MessageDetailContainer
│   │   │   │   │   │   ├── MessageDetailContainer.jsx
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       ├── MessageDetailContainer.comments.test.jsx
│   │   │   │   │   │       ├── MessageDetailContainer.inputs.test.jsx
│   │   │   │   │   │       └── MessageDetailContainer.rendering.test.jsx
│   │   │   │   │   ├── MessageListActionContainer.jsx
│   │   │   │   │   └── __tests__
│   │   │   │   │       ├── CanvasInbox.test.jsx
│   │   │   │   │       ├── ComposeModalContainer1.test.jsx
│   │   │   │   │       ├── ComposeModalContainer2.test.jsx
│   │   │   │   │       ├── ConversationListContainer.test.jsx
│   │   │   │   │       └── MessageListActionContainer.test.jsx
│   │   │   │   ├── hooks
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   ├── useInboxSettingsValidate.test.ts
│   │   │   │   │   │   └── useTranslationDisplay.test.ts
│   │   │   │   │   ├── useInboxSettingsValidate.ts
│   │   │   │   │   ├── useTranslationContext.ts
│   │   │   │   │   └── useTranslationDisplay.ts
│   │   │   │   ├── index.jsx
│   │   │   │   └── utils
│   │   │   │       ├── constants.jsx
│   │   │   │       └── inbox_translator.ts
│   │   │   ├── svg
│   │   │   │   └── inbox-empty.svg
│   │   │   └── util
│   │   │       ├── constants.jsx
│   │   │       ├── courses_helper.js
│   │   │       ├── utils.js
│   │   │       └── waitForApolloLoading.js
│   │   ├── inlined_preview
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── inst_fs_service_worker
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── job_stats
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       └── components
│   │   │           ├── JobStats.jsx
│   │   │           ├── JobStatsTable.jsx
│   │   │           ├── StuckList.jsx
│   │   │           ├── StuckModal.jsx
│   │   │           └── __tests__
│   │   │               ├── JobStats.test.jsx
│   │   │               └── MockJobsAPI.js
│   │   ├── jobs
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── index.js
│   │   │   └── package.json
│   │   ├── jobs_v2
│   │   │   ├── graphql
│   │   │   │   └── Queries.js
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── __tests__
│   │   │       │   ├── MockJobsApi.js
│   │   │       │   └── jobs_v2.test.jsx
│   │   │       ├── components
│   │   │       │   ├── DateOptionsModal.jsx
│   │   │       │   ├── GroupsTable.jsx
│   │   │       │   ├── InfoColumn.jsx
│   │   │       │   ├── JobDetails.jsx
│   │   │       │   ├── JobLookup.jsx
│   │   │       │   ├── JobsHeader.jsx
│   │   │       │   ├── JobsTable.jsx
│   │   │       │   ├── OrphanedStrandIndicator.jsx
│   │   │       │   ├── RefreshWidget.jsx
│   │   │       │   ├── RequeueButton.jsx
│   │   │       │   ├── SearchBox.jsx
│   │   │       │   ├── SectionRefreshHeader.jsx
│   │   │       │   ├── SortColumnHeader.jsx
│   │   │       │   ├── StrandManager.jsx
│   │   │       │   ├── TagThrottle.jsx
│   │   │       │   └── __tests__
│   │   │       │       ├── MockSettingsApi.jsx
│   │   │       │       ├── OrphanedStrandIndicator.test.jsx
│   │   │       │       ├── RequeueButton.test.jsx
│   │   │       │       ├── StrandManager.test.jsx
│   │   │       │       └── TagThrottle.test.jsx
│   │   │       ├── index.jsx
│   │   │       └── reducer.js
│   │   ├── k5_course
│   │   │   ├── images
│   │   │   │   ├── empty-grades.svg
│   │   │   │   ├── empty-home.svg
│   │   │   │   └── empty-modules.svg
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── EmptyCourse.jsx
│   │   │       ├── EmptyHome.jsx
│   │   │       ├── EmptyModules.jsx
│   │   │       ├── GradeDetails.jsx
│   │   │       ├── GradeRow.jsx
│   │   │       ├── GradesEmptyPage.jsx
│   │   │       ├── GradesPage.jsx
│   │   │       ├── GradingPeriodSelect.jsx
│   │   │       ├── K5Course.jsx
│   │   │       ├── OverviewPage.jsx
│   │   │       └── __tests__
│   │   │           ├── GradeRow.test.jsx
│   │   │           ├── GradesPage.1.test.jsx
│   │   │           ├── GradesPage.2.test.jsx
│   │   │           ├── GradingPeriodSelect.test.jsx
│   │   │           ├── K5Course.test.jsx
│   │   │           ├── OverviewPage.test.jsx
│   │   │           └── mocks.js
│   │   ├── k5_dashboard
│   │   │   ├── images
│   │   │   │   ├── empty-todos.svg
│   │   │   │   └── important-dates.svg
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── EmptyTodos.jsx
│   │   │       ├── FilterCalendarsModal.jsx
│   │   │       ├── GradesPage.jsx
│   │   │       ├── GradesSummary.jsx
│   │   │       ├── GradingPeriodSelect.jsx
│   │   │       ├── HomeroomAnnouncementsLayout.jsx
│   │   │       ├── HomeroomPage.jsx
│   │   │       ├── ImportantDateItem.jsx
│   │   │       ├── ImportantDateSection.jsx
│   │   │       ├── ImportantDates.jsx
│   │   │       ├── ImportantDatesEmpty.jsx
│   │   │       ├── K5Dashboard.jsx
│   │   │       ├── K5DashboardCard.jsx
│   │   │       ├── Todo.jsx
│   │   │       ├── TodosPage.jsx
│   │   │       └── __tests__
│   │   │           ├── FilterCalendarsModal.test.jsx
│   │   │           ├── GradesPage.test.jsx
│   │   │           ├── GradesSummary.test.jsx
│   │   │           ├── GradingPeriodSelect.test.jsx
│   │   │           ├── HomeroomAnnouncementsLayout.test.jsx
│   │   │           ├── HomeroomPage.test.jsx
│   │   │           ├── ImportantDateItem.test.jsx
│   │   │           ├── ImportantDates.test.jsx
│   │   │           ├── K5Dashboard1.test.jsx
│   │   │           ├── K5Dashboard2.test.jsx
│   │   │           ├── K5Dashboard3.test.jsx
│   │   │           ├── K5DashboardCard.test.jsx
│   │   │           ├── K5DashboardTabs.test.jsx
│   │   │           ├── Todo.test.jsx
│   │   │           ├── TodosPage.test.jsx
│   │   │           ├── k5DashboardObserver.test.jsx
│   │   │           ├── k5DashboardPlanner.test.jsx
│   │   │           └── mocks.js
│   │   ├── k5_theme
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── ldap_cert_upload
│   │   │   ├── index.tsx
│   │   │   ├── package.json
│   │   │   ├── react
│   │   │   │   └── components
│   │   │   │       └── CertUploadForm.tsx
│   │   │   └── utils
│   │   │       └── certUtils.ts
│   │   ├── ldap_settings_test
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── index.js
│   │   │   └── package.json
│   │   ├── learning_mastery
│   │   │   ├── backbone
│   │   │   │   └── views
│   │   │   │       ├── CheckboxView.js
│   │   │   │       ├── OutcomeGradebookView.jsx
│   │   │   │       ├── SectionMenuView.js
│   │   │   │       └── __tests__
│   │   │   │           ├── CheckboxView.test.js
│   │   │   │           └── SectionMenuView.test.js
│   │   │   ├── index.js
│   │   │   ├── jst
│   │   │   │   ├── checkbox_view.handlebars
│   │   │   │   ├── checkbox_view.handlebars.json
│   │   │   │   ├── outcome_gradebook.handlebars
│   │   │   │   ├── outcome_gradebook.handlebars.json
│   │   │   │   ├── section_to_show_menu.handlebars
│   │   │   │   └── section_to_show_menu.handlebars.json
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── LearningMastery.jsx
│   │   │       └── __tests__
│   │   │           └── LearningMastery.test.js
│   │   ├── learning_mastery_v2
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── ExportCSVButton.jsx
│   │   │       ├── Gradebook.jsx
│   │   │       ├── OutcomeDescriptionModal.jsx
│   │   │       ├── OutcomeHeader.jsx
│   │   │       ├── ProficiencyFilter.jsx
│   │   │       ├── ProficiencyRating.jsx
│   │   │       ├── ScoresGrid.jsx
│   │   │       ├── StudentCell.jsx
│   │   │       ├── StudentHeader.jsx
│   │   │       ├── StudentOutcomeScore.jsx
│   │   │       ├── __tests__
│   │   │       │   ├── ExportCSVButton.test.jsx
│   │   │       │   ├── Gradebook.test.jsx
│   │   │       │   ├── OutcomeDescriptionModal.test.jsx
│   │   │       │   ├── OutcomeHeader.test.jsx
│   │   │       │   ├── ProficiencyFilter.test.jsx
│   │   │       │   ├── ProficiencyRating.test.jsx
│   │   │       │   ├── ScoresGrid.test.jsx
│   │   │       │   ├── StudentCell.test.jsx
│   │   │       │   ├── StudentHeader.test.jsx
│   │   │       │   ├── StudentOutcomeScore.test.jsx
│   │   │       │   ├── icons.test.jsx
│   │   │       │   └── index.test.jsx
│   │   │       ├── apiClient.js
│   │   │       ├── constants.js
│   │   │       ├── hooks
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── useCSVExport.test.js
│   │   │       │   │   └── useRollups.test.js
│   │   │       │   ├── useCSVExport.js
│   │   │       │   └── useRollups.js
│   │   │       ├── icons.js
│   │   │       ├── index.jsx
│   │   │       └── shapes.js
│   │   ├── learning_outcomes
│   │   │   ├── __tests__
│   │   │   │   └── ContentView.test.js
│   │   │   ├── backbone
│   │   │   │   └── views
│   │   │   │       └── ToolbarView.js
│   │   │   ├── index.js
│   │   │   ├── jst
│   │   │   │   ├── mainInstructions.handlebars
│   │   │   │   └── mainInstructions.handlebars.json
│   │   │   └── package.json
│   │   ├── license_help
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── locale
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── login
│   │   │   ├── index.ts
│   │   │   └── package.json
│   │   ├── lti_collaborations
│   │   │   ├── index.js
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── Collaboration.jsx
│   │   │       ├── CollaborationsApp.jsx
│   │   │       ├── CollaborationsList.jsx
│   │   │       ├── CollaborationsNavigation.jsx
│   │   │       ├── CollaborationsToolLaunch.jsx
│   │   │       ├── DeleteConfirmation.jsx
│   │   │       ├── GettingStartedCollaborations.jsx
│   │   │       ├── LoadMore.jsx
│   │   │       ├── LoadingSpinner.jsx
│   │   │       ├── NewCollaborationsDropDown.jsx
│   │   │       ├── __tests__
│   │   │       │   ├── Collaboration.test.jsx
│   │   │       │   ├── CollaborationsApp.test.jsx
│   │   │       │   ├── CollaborationsList.test.jsx
│   │   │       │   ├── CollaborationsNavigation.test.jsx
│   │   │       │   ├── CollaborationsToolLaunch.test.jsx
│   │   │       │   ├── DeleteConfirmation.test.jsx
│   │   │       │   ├── GettingStartedCollaborations.test.jsx
│   │   │       │   ├── LoadMore.test.jsx
│   │   │       │   ├── NewCollaborationsDropDown.test.jsx
│   │   │       │   ├── NewCollaborationsDropDown2.test.jsx
│   │   │       │   ├── actions.test.js
│   │   │       │   └── router.test.js
│   │   │       ├── actions.js
│   │   │       ├── reducers
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── createCollaborationReducer.spec.js
│   │   │       │   │   ├── listCollaborationsReducer.spec.js
│   │   │       │   │   ├── ltiCollaboratorsReducer.spec.js
│   │   │       │   │   └── updateCollaborationReducer.spec.js
│   │   │       │   ├── createCollaborationReducer.js
│   │   │       │   ├── deleteCollaborationReducer.js
│   │   │       │   ├── listCollaborationsReducer.js
│   │   │       │   ├── ltiCollaboratorsReducer.js
│   │   │       │   └── updateCollaborationReducer.js
│   │   │       ├── router.jsx
│   │   │       └── store.js
│   │   ├── lti_registrations
│   │   │   ├── common
│   │   │   │   └── lib
│   │   │   │       ├── apiResult
│   │   │   │       │   ├── ApiResult.ts
│   │   │   │       │   ├── WithApiResultState.ts
│   │   │   │       │   ├── __tests__
│   │   │   │       │   │   ├── matchApiResultState.test.ts
│   │   │   │       │   │   └── useApiResult.test.ts
│   │   │   │       │   ├── matchApiResultState.ts
│   │   │   │       │   └── useApiResult.ts
│   │   │   │       ├── compact.ts
│   │   │   │       ├── filterEmptyString.ts
│   │   │   │       ├── toUndefined.ts
│   │   │   │       ├── useZodParams
│   │   │   │       │   ├── ParamsParseResult.ts
│   │   │   │       │   ├── Readme.md
│   │   │   │       │   ├── __tests__
│   │   │   │       │   │   ├── useZodParams.test.ts
│   │   │   │       │   │   └── useZodSearchParams.test.ts
│   │   │   │       │   ├── useZodParams.ts
│   │   │   │       │   └── useZodSearchParams.ts
│   │   │   │       └── validators
│   │   │   │           ├── isValidDomainName.ts
│   │   │   │           ├── isValidHttpUrl.ts
│   │   │   │           └── isValidJson.ts
│   │   │   ├── discover
│   │   │   │   ├── ProductConfigureButton.tsx
│   │   │   │   ├── index.tsx
│   │   │   │   └── utils.ts
│   │   │   ├── global.d.ts
│   │   │   ├── index.tsx
│   │   │   ├── layout
│   │   │   │   ├── LtiAppsLayout.tsx
│   │   │   │   ├── LtiBreadcrumbsLayout.tsx
│   │   │   │   ├── constants.ts
│   │   │   │   └── useTopLevelPage.ts
│   │   │   ├── manage
│   │   │   │   ├── api
│   │   │   │   │   ├── PaginatedList.ts
│   │   │   │   │   ├── contextControls.ts
│   │   │   │   │   ├── deployments.ts
│   │   │   │   │   ├── developerKey.ts
│   │   │   │   │   ├── ltiImsRegistration.ts
│   │   │   │   │   ├── registrations.ts
│   │   │   │   │   └── sampleLtiRegistrations.ts
│   │   │   │   ├── dynamic_registration_wizard
│   │   │   │   │   ├── DynamicRegistrationOverlayState.ts
│   │   │   │   │   ├── DynamicRegistrationWizard.tsx
│   │   │   │   │   ├── DynamicRegistrationWizardService.ts
│   │   │   │   │   ├── DynamicRegistrationWizardState.ts
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   ├── DynamicRegistrationWizard.test.tsx
│   │   │   │   │   │   ├── IconConfirmationWrapper.test.tsx
│   │   │   │   │   │   ├── NamingConfirmationWrapper.test.tsx
│   │   │   │   │   │   ├── PermissionConfirmationWrapper.test.tsx
│   │   │   │   │   │   ├── PlacementsConfirmationWrapper.test.tsx
│   │   │   │   │   │   ├── PrivacyConfirmationWrapper.test.tsx
│   │   │   │   │   │   ├── ReviewScreenWrapper.test.tsx
│   │   │   │   │   │   └── helpers.ts
│   │   │   │   │   ├── components
│   │   │   │   │   │   ├── IconConfirmationWrapper.tsx
│   │   │   │   │   │   ├── NamingConfirmationWrapper.tsx
│   │   │   │   │   │   ├── PermissionConfirmationWrapper.tsx
│   │   │   │   │   │   ├── PlacementsConfirmationWrapper.tsx
│   │   │   │   │   │   ├── PrivacyConfirmationWrapper.tsx
│   │   │   │   │   │   └── ReviewScreenWrapper.tsx
│   │   │   │   │   ├── dynamicRegistrationWizardState.puml
│   │   │   │   │   └── hooks
│   │   │   │   │       └── useOverlayStore.ts
│   │   │   │   ├── index.tsx
│   │   │   │   ├── inherited_key_registration_wizard
│   │   │   │   │   ├── InheritedKeyRegistrationReview.tsx
│   │   │   │   │   ├── InheritedKeyRegistrationWizard.tsx
│   │   │   │   │   ├── InheritedKeyRegistrationWizardState.ts
│   │   │   │   │   ├── InheritedKeyService.ts
│   │   │   │   │   └── __tests__
│   │   │   │   │       └── InheritedKeyRegistrationWizard.test.tsx
│   │   │   │   ├── lti_1p3_registration_form
│   │   │   │   │   ├── EditLti1p3RegistrationWizard.tsx
│   │   │   │   │   ├── Lti1p3RegistrationWizard.tsx
│   │   │   │   │   ├── Lti1p3RegistrationWizardService.ts
│   │   │   │   │   ├── Lti1p3RegistrationWizardState.ts
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   ├── IconConfirmationWrapper.test.tsx
│   │   │   │   │   │   ├── LaunchSettingsConfirmationWrapper.test.tsx
│   │   │   │   │   │   ├── Lti1p3RegistrationOverlayState.test.ts
│   │   │   │   │   │   ├── Lti1p3RegistrationWizard.test.tsx
│   │   │   │   │   │   ├── NamingConfirmationWrapper.test.tsx
│   │   │   │   │   │   ├── OverrideURIsConfirmationWrapper.test.tsx
│   │   │   │   │   │   ├── PermissionConfirmationWrapper.test.tsx
│   │   │   │   │   │   ├── PlacementsConfirmationWrapper.test.tsx
│   │   │   │   │   │   ├── PrivacyConfirmationWrapper.test.tsx
│   │   │   │   │   │   ├── ReviewScreenWrapper.test.tsx
│   │   │   │   │   │   ├── helpers.ts
│   │   │   │   │   │   └── useValidateLaunchSettings.test.ts
│   │   │   │   │   ├── components
│   │   │   │   │   │   ├── IconConfirmationWrapper.tsx
│   │   │   │   │   │   ├── LaunchSettingsConfirmationWrapper.tsx
│   │   │   │   │   │   ├── NamingConfirmationWrapper.tsx
│   │   │   │   │   │   ├── OverrideURIsConfirmationWrapper.tsx
│   │   │   │   │   │   ├── PermissionConfirmationWrapper.tsx
│   │   │   │   │   │   ├── PlacementsConfirmationWrapper.tsx
│   │   │   │   │   │   ├── PrivacyConfirmationWrapper.tsx
│   │   │   │   │   │   ├── ReviewScreenWrapper.tsx
│   │   │   │   │   │   └── helpers.ts
│   │   │   │   │   └── hooks
│   │   │   │   │       └── useValidateLaunchSettings.ts
│   │   │   │   ├── model
│   │   │   │   │   ├── AccountId.ts
│   │   │   │   │   ├── DynamicRegistrationToken.ts
│   │   │   │   │   ├── DynamicRegistrationTokenUUID.ts
│   │   │   │   │   ├── LtiContextControl.ts
│   │   │   │   │   ├── LtiDeployment.ts
│   │   │   │   │   ├── LtiDeploymentId.ts
│   │   │   │   │   ├── LtiMessageType.ts
│   │   │   │   │   ├── LtiOverlay.ts
│   │   │   │   │   ├── LtiOverlayVersion.ts
│   │   │   │   │   ├── LtiPlacement.ts
│   │   │   │   │   ├── LtiPrivacyLevel.ts
│   │   │   │   │   ├── LtiRegistration.ts
│   │   │   │   │   ├── LtiRegistrationAccountBinding.ts
│   │   │   │   │   ├── LtiRegistrationId.ts
│   │   │   │   │   ├── PlacementOverlay.ts
│   │   │   │   │   ├── RegistrationOverlay.ts
│   │   │   │   │   ├── RegistrationOverlayState.ts
│   │   │   │   │   ├── UnifiedToolId.ts
│   │   │   │   │   ├── User.ts
│   │   │   │   │   ├── UserId.ts
│   │   │   │   │   ├── ZLtiOverlayId.ts
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   └── LtiRegistration.test.ts
│   │   │   │   │   ├── developer_key
│   │   │   │   │   │   ├── DeveloperKey.ts
│   │   │   │   │   │   ├── DeveloperKeyAccountBinding.ts
│   │   │   │   │   │   ├── DeveloperKeyAccountBindingId.ts
│   │   │   │   │   │   └── DeveloperKeyId.ts
│   │   │   │   │   ├── i18nLtiPlacement.ts
│   │   │   │   │   ├── i18nLtiPrivacyLevel.ts
│   │   │   │   │   ├── internal_lti_configuration
│   │   │   │   │   │   ├── InternalBaseLaunchSettings.ts
│   │   │   │   │   │   ├── InternalLtiConfiguration.ts
│   │   │   │   │   │   ├── LtiConfigurationOverlay.ts
│   │   │   │   │   │   ├── LtiDisplayType.ts
│   │   │   │   │   │   ├── LtiVisibility.ts
│   │   │   │   │   │   ├── PublicJwk.ts
│   │   │   │   │   │   └── placement_configuration
│   │   │   │   │   │       └── InternalPlacementConfiguration.ts
│   │   │   │   │   ├── ltiToolIcons.ts
│   │   │   │   │   ├── lti_ims_registration
│   │   │   │   │   │   ├── LtiImsMessage.ts
│   │   │   │   │   │   ├── LtiImsRegistration.ts
│   │   │   │   │   │   ├── LtiImsRegistrationId.ts
│   │   │   │   │   │   └── LtiImsToolConfiguration.ts
│   │   │   │   │   └── lti_tool_configuration
│   │   │   │   │       ├── Extension.ts
│   │   │   │   │       ├── LtiConfiguration.ts
│   │   │   │   │       ├── LtiPlacementConfig.ts
│   │   │   │   │       ├── LtiToolConfiguration.ts
│   │   │   │   │       ├── LtiToolConfigurationId.ts
│   │   │   │   │       └── PlatformSettings.ts
│   │   │   │   ├── pages
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   └── interactionHelpers.ts
│   │   │   │   │   ├── manage
│   │   │   │   │   │   ├── AppsSearchBar.tsx
│   │   │   │   │   │   ├── AppsTable.tsx
│   │   │   │   │   │   ├── ManagePage.tsx
│   │   │   │   │   │   ├── ManagePageLoadingState.ts
│   │   │   │   │   │   ├── ManageSearchParams.ts
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── AppsTable.test.tsx
│   │   │   │   │   │   │   ├── helpers.ts
│   │   │   │   │   │   │   └── managePageLoadingState.test.ts
│   │   │   │   │   │   └── managePageLoadingState.puml
│   │   │   │   │   └── tool_details
│   │   │   │   │       ├── ToolDetails.tsx
│   │   │   │   │       ├── __tests__
│   │   │   │   │       │   ├── ToolDetails.test.tsx
│   │   │   │   │       │   └── helpers.tsx
│   │   │   │   │       ├── access
│   │   │   │   │       │   └── ToolAccess.tsx
│   │   │   │   │       ├── configuration
│   │   │   │   │       │   ├── DynamicRegistrationConfigurationEdit.tsx
│   │   │   │   │       │   ├── IconConfirmationPerfWrapper.tsx
│   │   │   │   │       │   ├── NamingConfirmationPerfWrapper.tsx
│   │   │   │   │       │   ├── PermissionConfirmationPerfWrapper.tsx
│   │   │   │   │       │   ├── PlacementsConfirmationPerfWrapper.tsx
│   │   │   │   │       │   ├── PrivacyConfirmationPerfWrapper.tsx
│   │   │   │   │       │   ├── ToolConfigurationEdit.tsx
│   │   │   │   │       │   ├── ToolConfigurationFooter.tsx
│   │   │   │   │       │   ├── ToolConfigurationView.tsx
│   │   │   │   │       │   └── __tests__
│   │   │   │   │       │       ├── ToolConfigurationEdit.test.tsx
│   │   │   │   │       │       ├── ToolConfigurationView.test.tsx
│   │   │   │   │       │       └── helpers.tsx
│   │   │   │   │       ├── history
│   │   │   │   │       │   ├── ToolHistory.tsx
│   │   │   │   │       │   └── __tests__
│   │   │   │   │       │       └── ToolHistory.test.tsx
│   │   │   │   │       └── usage
│   │   │   │   │           └── ToolUsage.tsx
│   │   │   │   ├── registration_overlay
│   │   │   │   │   ├── Lti1p3RegistrationOverlayState.ts
│   │   │   │   │   ├── Lti1p3RegistrationOverlayStateHelpers.ts
│   │   │   │   │   ├── Lti1p3RegistrationOverlayStore.ts
│   │   │   │   │   └── validateLti1p3RegistrationOverlayState.ts
│   │   │   │   ├── registration_wizard
│   │   │   │   │   ├── JsonUrlWizardService.ts
│   │   │   │   │   ├── RegistrationModalBody.tsx
│   │   │   │   │   ├── RegistrationWizardModal.tsx
│   │   │   │   │   ├── RegistrationWizardModalState.tsx
│   │   │   │   │   └── __tests__
│   │   │   │   │       ├── RegistrationWizardModal.test.tsx
│   │   │   │   │       └── helpers.ts
│   │   │   │   └── registration_wizard_forms
│   │   │   │       ├── Footer.tsx
│   │   │   │       ├── Header.tsx
│   │   │   │       ├── IconConfirmation.tsx
│   │   │   │       ├── LaunchSettingsConfirmation.tsx
│   │   │   │       ├── NamingConfirmation.tsx
│   │   │   │       ├── OverrideURIsConfirmation.tsx
│   │   │   │       ├── PermissionConfirmation.tsx
│   │   │   │       ├── PlacementsConfirmation.tsx
│   │   │   │       ├── PrivacyConfirmation.tsx
│   │   │   │       ├── ResponsiveWrapper.tsx
│   │   │   │       └── ReviewScreen.tsx
│   │   │   ├── monitor
│   │   │   │   ├── Monitor.tsx
│   │   │   │   ├── api
│   │   │   │   │   ├── impact.ts
│   │   │   │   │   └── jwt.ts
│   │   │   │   ├── route.tsx
│   │   │   │   └── utils.ts
│   │   │   └── package.json
│   │   ├── manage_avatars
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── index.js
│   │   │   └── package.json
│   │   ├── manage_groups
│   │   │   ├── backbone
│   │   │   │   ├── mixins
│   │   │   │   │   ├── Filterable.js
│   │   │   │   │   └── __tests__
│   │   │   │   │       └── Filterable.spec.js
│   │   │   │   └── views
│   │   │   │       ├── AddUnassignedMenu.js
│   │   │   │       ├── AddUnassignedUsersView.js
│   │   │   │       ├── AssignToGroupMenu.js
│   │   │   │       ├── GroupCategoriesView.js
│   │   │   │       ├── GroupCategoryCloneView.jsx
│   │   │   │       ├── GroupCategoryDetailView.jsx
│   │   │   │       ├── GroupCategoryView.jsx
│   │   │   │       ├── GroupDetailView.jsx
│   │   │   │       ├── GroupUserView.jsx
│   │   │   │       ├── GroupUsersView.js
│   │   │   │       ├── GroupView.js
│   │   │   │       ├── GroupsView.js
│   │   │   │       ├── PopoverMenuView.js
│   │   │   │       ├── RandomlyAssignMembersView.js
│   │   │   │       ├── Scrollable.js
│   │   │   │       ├── UnassignedUsersView.js
│   │   │   │       └── __tests__
│   │   │   │           ├── AddUnassignedMenu.test.js
│   │   │   │           ├── AssignToGroupMenu.test.js
│   │   │   │           ├── GroupCategoriesView.test.js
│   │   │   │           ├── GroupCategoryEditView.test.js
│   │   │   │           ├── GroupCategoryView.test.js
│   │   │   │           ├── GroupView.test.jsx
│   │   │   │           ├── RandomlyAssignMembersView.test.js
│   │   │   │           └── UnassignedUsersView.test.js
│   │   │   ├── groupHasSubmissions.js
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   ├── __tests__
│   │   │   │   │   └── outerclick.test.js
│   │   │   │   └── outerclick.js
│   │   │   ├── jst
│   │   │   │   ├── addUnassignedMenu.handlebars
│   │   │   │   ├── addUnassignedMenu.handlebars.json
│   │   │   │   ├── addUnassignedUser.handlebars
│   │   │   │   ├── addUnassignedUser.handlebars.json
│   │   │   │   ├── addUnassignedUsers.handlebars
│   │   │   │   ├── addUnassignedUsers.handlebars.json
│   │   │   │   ├── assignToGroupMenu.handlebars
│   │   │   │   ├── assignToGroupMenu.handlebars.json
│   │   │   │   ├── group.handlebars
│   │   │   │   ├── group.handlebars.json
│   │   │   │   ├── groupCategories.handlebars
│   │   │   │   ├── groupCategories.handlebars.json
│   │   │   │   ├── groupCategory.handlebars
│   │   │   │   ├── groupCategory.handlebars.json
│   │   │   │   ├── groupCategoryClone.handlebars
│   │   │   │   ├── groupCategoryClone.handlebars.json
│   │   │   │   ├── groupCategoryDetail.handlebars
│   │   │   │   ├── groupCategoryDetail.handlebars.json
│   │   │   │   ├── groupCategoryTab.handlebars
│   │   │   │   ├── groupCategoryTab.handlebars.json
│   │   │   │   ├── groupDetail.handlebars
│   │   │   │   ├── groupDetail.handlebars.json
│   │   │   │   ├── groupUser.handlebars
│   │   │   │   ├── groupUser.handlebars.json
│   │   │   │   ├── groupUsers.handlebars
│   │   │   │   ├── groupUsers.handlebars.json
│   │   │   │   ├── groups.handlebars
│   │   │   │   ├── groups.handlebars.json
│   │   │   │   ├── randomlyAssignMembers.handlebars
│   │   │   │   └── randomlyAssignMembers.handlebars.json
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── GroupCategoryCloneModal.jsx
│   │   │       ├── GroupCategoryMessageAllUnassignedModal.jsx
│   │   │       ├── GroupCategoryProgress.jsx
│   │   │       ├── GroupImportModal.jsx
│   │   │       ├── GroupUserMenu.tsx
│   │   │       ├── __tests__
│   │   │       │   ├── GroupCategoryCloneModal.test.jsx
│   │   │       │   ├── GroupCategoryMessageAllUnassignedModal.test.jsx
│   │   │       │   ├── GroupImportModal.test.jsx
│   │   │       │   └── GroupUserMenu.test.jsx
│   │   │       └── apiClient.js
│   │   ├── media_player_iframe_content
│   │   │   ├── index.tsx
│   │   │   └── package.json
│   │   ├── messages
│   │   │   ├── index.js
│   │   │   ├── jst
│   │   │   │   ├── sendForm.handlebars
│   │   │   │   └── sendForm.handlebars.json
│   │   │   └── package.json
│   │   ├── mobile_login
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── moderate_quiz
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   ├── __tests__
│   │   │   │   │   └── openModerateStudentDialog.test.js
│   │   │   │   ├── index.js
│   │   │   │   ├── openModerateStudentDialog.js
│   │   │   │   └── quiz_timing.js
│   │   │   └── package.json
│   │   ├── module_dnd
│   │   │   ├── index.jsx
│   │   │   └── package.json
│   │   ├── module_sequence_footer
│   │   │   ├── index.js
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── __tests__
│   │   │       │   └── ModuleSequenceFooter.spec.js
│   │   │       └── index.jsx
│   │   ├── module_student_view_peer_reviews
│   │   │   ├── graphql
│   │   │   │   └── Queries.ts
│   │   │   ├── index.tsx
│   │   │   ├── package.json
│   │   │   ├── react
│   │   │   │   └── __tests__
│   │   │   │       └── assessment_requests.utils.tsx
│   │   │   ├── types.ts
│   │   │   └── utils
│   │   │       └── helper.ts
│   │   ├── nav_tourpoints
│   │   │   ├── index.tsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── TourContainer.tsx
│   │   │       ├── handleOpenTray.ts
│   │   │       ├── hooks
│   │   │       │   ├── __tests__
│   │   │       │   │   └── useLocalStorage.test.js
│   │   │       │   └── useLocalStorage.jsx
│   │   │       ├── tour.tsx
│   │   │       └── tours
│   │   │           ├── adminTour.tsx
│   │   │           ├── studentTour.tsx
│   │   │           └── teacherTour.tsx
│   │   ├── navigation_header
│   │   │   ├── index.tsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── LogoutButton.tsx
│   │   │       ├── MobileContextMenu.jsx
│   │   │       ├── MobileGlobalMenu.tsx
│   │   │       ├── MobileNavigation.tsx
│   │   │       ├── NavigationBadges.tsx
│   │   │       ├── NavigationHeaderRoute.tsx
│   │   │       ├── NewTabIndicator.tsx
│   │   │       ├── OldSideNav.tsx
│   │   │       ├── SideNav.tsx
│   │   │       ├── __tests__
│   │   │       │   ├── MobileContextMenu.test.jsx
│   │   │       │   ├── MobileGlobalMenu.test.tsx
│   │   │       │   ├── MobileNavigation.test.jsx
│   │   │       │   ├── NavigationBadges.test.tsx
│   │   │       │   ├── NewTabIndicator.test.jsx
│   │   │       │   ├── SideNav.test.tsx
│   │   │       │   ├── sideNavReducer.test.jsx
│   │   │       │   └── utils.test.ts
│   │   │       ├── hooks
│   │   │       │   └── useHoverIntent.ts
│   │   │       ├── lists
│   │   │       │   ├── AccountsList.tsx
│   │   │       │   ├── CoursesList.tsx
│   │   │       │   ├── GroupsList.tsx
│   │   │       │   ├── HistoryList.tsx
│   │   │       │   ├── ProfileTabsList.tsx
│   │   │       │   ├── ReleaseNotesList.tsx
│   │   │       │   ├── SplitCoursesList.tsx
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── HistoryList.test.tsx
│   │   │       │   │   └── ReleaseNotesList.test.tsx
│   │   │       │   └── utils.tsx
│   │   │       ├── queries
│   │   │       │   ├── __tests__
│   │   │       │   │   ├── coursesQuery.test.ts
│   │   │       │   │   └── groupsQuery.test.ts
│   │   │       │   ├── coursesQuery.ts
│   │   │       │   ├── groupsQuery.ts
│   │   │       │   ├── profileQuery.ts
│   │   │       │   ├── releaseNotesQuery.ts
│   │   │       │   └── unreadCountQuery.ts
│   │   │       ├── trays
│   │   │       │   ├── AccountsTray.tsx
│   │   │       │   ├── CoursesTray.tsx
│   │   │       │   ├── GroupsTray.tsx
│   │   │       │   ├── HelpTray.tsx
│   │   │       │   ├── HighContrastModeToggle.tsx
│   │   │       │   ├── HistoryTray.tsx
│   │   │       │   ├── ProfileTray.tsx
│   │   │       │   ├── UseDyslexicFontToggle.tsx
│   │   │       │   └── __tests__
│   │   │       │       ├── AccountsTray.test.tsx
│   │   │       │       ├── CoursesTray.test.tsx
│   │   │       │       ├── GroupsTray.test.tsx
│   │   │       │       ├── HelpTray.test.tsx
│   │   │       │       ├── HighContrastModeToggle.test.jsx
│   │   │       │       ├── ProfileTray.test.tsx
│   │   │       │       └── UseDyslexicFontToggle.test.jsx
│   │   │       └── utils.ts
│   │   ├── new_login
│   │   │   ├── assets
│   │   │   │   └── images
│   │   │   │       ├── apple.svg
│   │   │   │       ├── canvas-small.svg
│   │   │   │       ├── canvas.svg
│   │   │   │       ├── classlink.svg
│   │   │   │       ├── clever.svg
│   │   │   │       ├── facebook.svg
│   │   │   │       ├── github.svg
│   │   │   │       ├── google.svg
│   │   │   │       ├── instructure.svg
│   │   │   │       ├── linkedin.svg
│   │   │   │       ├── microsoft.svg
│   │   │   │       ├── parent.svg
│   │   │   │       ├── student.svg
│   │   │   │       ├── teacher.svg
│   │   │   │       └── x.svg
│   │   │   ├── context
│   │   │   │   ├── HelpTrayContext.tsx
│   │   │   │   ├── NewLoginContext.tsx
│   │   │   │   ├── NewLoginDataContext.tsx
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── HelpTrayContext.test.tsx
│   │   │   │   │   ├── NewLoginContext.test.tsx
│   │   │   │   │   └── NewLoginDataContext.test.tsx
│   │   │   │   └── index.ts
│   │   │   ├── hooks
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── useFetchNewLoginData.test.ts
│   │   │   │   │   ├── usePasswordValidator.test.ts
│   │   │   │   │   ├── useSafeBackNavigation.test.ts
│   │   │   │   │   └── useServerErrorsMap.test.ts
│   │   │   │   ├── index.ts
│   │   │   │   ├── useFetchNewLoginData.ts
│   │   │   │   ├── usePasswordValidator.ts
│   │   │   │   ├── useSafeBackNavigation.ts
│   │   │   │   └── useServerErrorsMap.ts
│   │   │   ├── layouts
│   │   │   │   ├── ContentLayout.module.css
│   │   │   │   ├── ContentLayout.tsx
│   │   │   │   ├── LoginLayout.tsx
│   │   │   │   └── __tests__
│   │   │   │       ├── ContentLayout.test.tsx
│   │   │   │       └── LoginLayout.test.tsx
│   │   │   ├── package.json
│   │   │   ├── pages
│   │   │   │   ├── ForgotPassword.tsx
│   │   │   │   ├── OtpForm.tsx
│   │   │   │   ├── SignIn.tsx
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── ForgotPassword.test.tsx
│   │   │   │   │   ├── OtpForm.test.tsx
│   │   │   │   │   └── SignIn.test.tsx
│   │   │   │   └── register
│   │   │   │       ├── Landing.tsx
│   │   │   │       ├── Parent.tsx
│   │   │   │       ├── Student.tsx
│   │   │   │       ├── Teacher.tsx
│   │   │   │       └── __tests__
│   │   │   │           ├── Landing.test.tsx
│   │   │   │           ├── Parent.test.tsx
│   │   │   │           ├── Student.test.tsx
│   │   │   │           └── Teacher.test.tsx
│   │   │   ├── routes
│   │   │   │   ├── NewLoginRoutes.tsx
│   │   │   │   ├── RegistrationRoutesMiddleware.tsx
│   │   │   │   ├── RenderGuard.tsx
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── NewLoginRoutes.test.tsx
│   │   │   │   │   ├── RegistrationRoutesMiddleware.test.tsx
│   │   │   │   │   └── RenderGuard.test.tsx
│   │   │   │   └── routes.ts
│   │   │   ├── services
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── auth.test.ts
│   │   │   │   │   ├── otp.test.ts
│   │   │   │   │   └── register.test.ts
│   │   │   │   ├── auth.ts
│   │   │   │   ├── index.ts
│   │   │   │   ├── otp.ts
│   │   │   │   └── register.ts
│   │   │   ├── shared
│   │   │   │   ├── ActionPrompt.tsx
│   │   │   │   ├── AppNavBar.tsx
│   │   │   │   ├── Background.tsx
│   │   │   │   ├── Card.tsx
│   │   │   │   ├── ErrorBoundary.tsx
│   │   │   │   ├── FooterLinks.tsx
│   │   │   │   ├── ForgotPasswordLink.tsx
│   │   │   │   ├── GlobalStyle.tsx
│   │   │   │   ├── HelpTray.tsx
│   │   │   │   ├── InstructureLogo.tsx
│   │   │   │   ├── Loading.tsx
│   │   │   │   ├── LoginAlert.tsx
│   │   │   │   ├── LoginLogo.tsx
│   │   │   │   ├── RememberMeCheckbox.tsx
│   │   │   │   ├── SSOButtons.tsx
│   │   │   │   ├── TermsAndPolicyCheckbox.tsx
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── ActionPrompt.test.tsx
│   │   │   │   │   ├── AppNavBar.test.tsx
│   │   │   │   │   ├── Background.test.tsx
│   │   │   │   │   ├── Card.test.tsx
│   │   │   │   │   ├── ErrorBoundary.test.tsx
│   │   │   │   │   ├── FooterLinks.test.tsx
│   │   │   │   │   ├── ForgotPasswordLink.test.tsx
│   │   │   │   │   ├── GlobalStyle.test.tsx
│   │   │   │   │   ├── InstructureLogo.test.tsx
│   │   │   │   │   ├── Loading.test.tsx
│   │   │   │   │   ├── LoginAlert.test.tsx
│   │   │   │   │   ├── LoginLogo.test.tsx
│   │   │   │   │   ├── RememberMeCheckbox.test.tsx
│   │   │   │   │   ├── SSOButtons.test.tsx
│   │   │   │   │   ├── TermsAndPolicyCheckbox.test.tsx
│   │   │   │   │   └── helpers.test.tsx
│   │   │   │   ├── helpers.ts
│   │   │   │   ├── index.ts
│   │   │   │   └── recaptcha
│   │   │   │       ├── ReCaptcha.tsx
│   │   │   │       ├── ReCaptchaSection.tsx
│   │   │   │       ├── ReCaptchaWrapper.tsx
│   │   │   │       ├── __tests__
│   │   │   │       │   ├── ReCaptcha.test.tsx
│   │   │   │       │   ├── ReCaptchaSection.test.tsx
│   │   │   │       │   └── ReCaptchaWrapper.test.tsx
│   │   │   │       └── index.ts
│   │   │   └── types
│   │   │       ├── api.ts
│   │   │       ├── data.ts
│   │   │       ├── index.ts
│   │   │       └── register.ts
│   │   ├── new_user_tutorial
│   │   │   ├── index.tsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── ConfirmEndTutorialDialog.jsx
│   │   │       ├── NewUserTutorialToggleButton.jsx
│   │   │       ├── __tests__
│   │   │       │   ├── ConfirmEndTutorialDialog.test.jsx
│   │   │       │   └── NewUserTutorialToggleButton.test.jsx
│   │   │       ├── trays
│   │   │       │   ├── AnnouncementsTray.jsx
│   │   │       │   ├── AssignmentsTray.jsx
│   │   │       │   ├── CollaborationsTray.jsx
│   │   │       │   ├── ConferencesTray.jsx
│   │   │       │   ├── DiscussionsTray.jsx
│   │   │       │   ├── FilesTray.jsx
│   │   │       │   ├── GradesTray.jsx
│   │   │       │   ├── HomeTray.jsx
│   │   │       │   ├── ImportTray.jsx
│   │   │       │   ├── ModulesTray.jsx
│   │   │       │   ├── NewAnalyticsTray.jsx
│   │   │       │   ├── OutcomesTray.jsx
│   │   │       │   ├── PagesTray.jsx
│   │   │       │   ├── PeopleTray.jsx
│   │   │       │   ├── QuizzesTray.jsx
│   │   │       │   ├── RubricsTray.jsx
│   │   │       │   ├── SettingsTray.jsx
│   │   │       │   ├── SyllabusTray.jsx
│   │   │       │   ├── TutorialTray.jsx
│   │   │       │   ├── TutorialTrayContent.jsx
│   │   │       │   ├── ZoomTray.jsx
│   │   │       │   └── __tests__
│   │   │       │       └── TutorialTray.test.jsx
│   │   │       └── util
│   │   │           ├── __tests__
│   │   │           │   ├── createTutorialStore.spec.js
│   │   │           │   └── getProperTray.spec.js
│   │   │           ├── createTutorialStore.js
│   │   │           └── getProperTray.js
│   │   ├── not_found_index
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── frogger
│   │   │       │   ├── OfficialNotFoundGame.jsx
│   │   │       │   ├── __tests__
│   │   │       │   │   └── Character.test.js
│   │   │       │   └── characters.js
│   │   │       ├── gameEntry.jsx
│   │   │       ├── slide_puzzle
│   │   │       │   ├── SlidePuzzle.tsx
│   │   │       │   └── StudiousPandaSource.ts
│   │   │       └── space_invaders
│   │   │           ├── SpaceInvaders.jsx
│   │   │           ├── coronavirus.png
│   │   │           ├── explodingParticle.js
│   │   │           ├── gameObject.js
│   │   │           ├── input.js
│   │   │           ├── playerShip.js
│   │   │           ├── ship.png
│   │   │           ├── spawners.js
│   │   │           ├── syringe.png
│   │   │           └── tp.png
│   │   ├── oauth2_confirm
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── index.js
│   │   │   └── package.json
│   │   ├── otp_login
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── outcome_alignment_v2
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── OutcomeAlignmentDeleteLink.jsx
│   │   │       └── __tests__
│   │   │           └── OutcomeAlignmentDeleteLink.test.jsx
│   │   ├── outcome_alignments
│   │   │   ├── index.jsx
│   │   │   └── package.json
│   │   ├── outcome_management
│   │   │   ├── helpers
│   │   │   │   ├── __tests__
│   │   │   │   │   └── getOutcomeGroupAncestorsWithSelf.test.js
│   │   │   │   └── getOutcomeGroupAncestorsWithSelf.js
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   ├── react
│   │   │   │   ├── Alignments
│   │   │   │   │   ├── AlignmentItem.jsx
│   │   │   │   │   ├── AlignmentItem.stories.jsx
│   │   │   │   │   ├── AlignmentOutcomeItem.jsx
│   │   │   │   │   ├── AlignmentOutcomeItem.stories.jsx
│   │   │   │   │   ├── AlignmentOutcomeItemList.jsx
│   │   │   │   │   ├── AlignmentOutcomeItemList.stories.jsx
│   │   │   │   │   ├── AlignmentStatItem.jsx
│   │   │   │   │   ├── AlignmentStatItem.stories.jsx
│   │   │   │   │   ├── AlignmentSummaryHeader.jsx
│   │   │   │   │   ├── AlignmentSummaryHeader.stories.jsx
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   ├── AlignmentItem.test.jsx
│   │   │   │   │   │   ├── AlignmentOutcomeItem.test.jsx
│   │   │   │   │   │   ├── AlignmentOutcomeItemList.test.jsx
│   │   │   │   │   │   ├── AlignmentStatItem.test.jsx
│   │   │   │   │   │   ├── AlignmentSummaryHeader.test.jsx
│   │   │   │   │   │   ├── index.test.jsx
│   │   │   │   │   │   └── testData.js
│   │   │   │   │   ├── index.jsx
│   │   │   │   │   └── propTypeShapes.js
│   │   │   │   ├── ConfirmMasteryModal.jsx
│   │   │   │   ├── ConfirmMasteryModal.stories.jsx
│   │   │   │   ├── CreateOutcomeModal.jsx
│   │   │   │   ├── CreateOutcomeModal.stories.jsx
│   │   │   │   ├── FindOutcomeItem.jsx
│   │   │   │   ├── FindOutcomesBillboard.jsx
│   │   │   │   ├── FindOutcomesModal.jsx
│   │   │   │   ├── FindOutcomesModal.stories.jsx
│   │   │   │   ├── FindOutcomesView.jsx
│   │   │   │   ├── FindOutcomesView.stories.jsx
│   │   │   │   ├── ImportConfirmBox.jsx
│   │   │   │   ├── ImportConfirmBox.stories.jsx
│   │   │   │   ├── Management
│   │   │   │   │   ├── GroupDescriptionModal.jsx
│   │   │   │   │   ├── GroupDescriptionModal.stories.jsx
│   │   │   │   │   ├── GroupEditForm.jsx
│   │   │   │   │   ├── GroupEditModal.jsx
│   │   │   │   │   ├── GroupEditModal.stories.jsx
│   │   │   │   │   ├── GroupMoveModal.jsx
│   │   │   │   │   ├── GroupMoveModal.stories.jsx
│   │   │   │   │   ├── GroupRemoveModal.jsx
│   │   │   │   │   ├── GroupRemoveModal.stories.jsx
│   │   │   │   │   ├── ManageOutcomeItem.jsx
│   │   │   │   │   ├── ManageOutcomeItem.stories.jsx
│   │   │   │   │   ├── ManageOutcomesBillboard.jsx
│   │   │   │   │   ├── ManageOutcomesBillboard.stories.jsx
│   │   │   │   │   ├── ManageOutcomesFooter.jsx
│   │   │   │   │   ├── ManageOutcomesFooter.stories.jsx
│   │   │   │   │   ├── ManageOutcomesView.jsx
│   │   │   │   │   ├── ManageOutcomesView.stories.jsx
│   │   │   │   │   ├── OutcomeDescription.jsx
│   │   │   │   │   ├── OutcomeDescription.stories.jsx
│   │   │   │   │   ├── OutcomeEditModal.jsx
│   │   │   │   │   ├── OutcomeEditModal.stories.jsx
│   │   │   │   │   ├── OutcomeGroupHeader.jsx
│   │   │   │   │   ├── OutcomeGroupHeader.stories.jsx
│   │   │   │   │   ├── OutcomeKebabMenu.jsx
│   │   │   │   │   ├── OutcomeKebabMenu.stories.jsx
│   │   │   │   │   ├── OutcomeManagementPanel.stories.jsx
│   │   │   │   │   ├── OutcomeMoveModal.jsx
│   │   │   │   │   ├── OutcomeMoveModal.stories.jsx
│   │   │   │   │   ├── OutcomeRemoveModal.jsx
│   │   │   │   │   ├── OutcomeRemoveModal.stories.jsx
│   │   │   │   │   ├── OutcomeSearchBar.jsx
│   │   │   │   │   ├── OutcomeSearchBar.stories.jsx
│   │   │   │   │   ├── OutcomesPopover.jsx
│   │   │   │   │   ├── OutcomesPopover.stories.jsx
│   │   │   │   │   ├── Ratings.jsx
│   │   │   │   │   ├── Ratings.stories.jsx
│   │   │   │   │   ├── TreeBrowser.jsx
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   ├── GroupDescriptionModal.test.jsx
│   │   │   │   │   │   ├── GroupEditForm.basic.test.jsx
│   │   │   │   │   │   ├── GroupEditForm.submit.test.jsx
│   │   │   │   │   │   ├── GroupEditModal.test.jsx
│   │   │   │   │   │   ├── GroupMoveModal.test.jsx
│   │   │   │   │   │   ├── GroupRemoveModal.test.jsx
│   │   │   │   │   │   ├── ManageOutcomeItem.test.jsx
│   │   │   │   │   │   ├── ManageOutcomesBillboard.test.jsx
│   │   │   │   │   │   ├── ManageOutcomesFooter.test.jsx
│   │   │   │   │   │   ├── ManageOutcomesView.test.jsx
│   │   │   │   │   │   ├── OutcomeDescription.test.jsx
│   │   │   │   │   │   ├── OutcomeEditModal.test.jsx
│   │   │   │   │   │   ├── OutcomeGroupHeader.test.jsx
│   │   │   │   │   │   ├── OutcomeKebabMenu.test.jsx
│   │   │   │   │   │   ├── OutcomeMoveModal.test.jsx
│   │   │   │   │   │   ├── OutcomeRemoveModal.test.jsx
│   │   │   │   │   │   ├── OutcomeSearchBar.test.jsx
│   │   │   │   │   │   ├── OutcomesPopover.test.jsx
│   │   │   │   │   │   ├── Ratings.test.jsx
│   │   │   │   │   │   ├── TreeBrowser.test.jsx
│   │   │   │   │   │   ├── helpers.js
│   │   │   │   │   │   └── index.test.jsx
│   │   │   │   │   ├── index.jsx
│   │   │   │   │   └── shapes.js
│   │   │   │   ├── ManagementHeader.jsx
│   │   │   │   ├── ManagementHeader.stories.jsx
│   │   │   │   ├── MasteryCalculation
│   │   │   │   │   ├── ProficiencyCalculation.jsx
│   │   │   │   │   ├── ProficiencyCalculation.stories.jsx
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   ├── ProficiencyCalculation.test.jsx
│   │   │   │   │   │   └── index.test.jsx
│   │   │   │   │   └── index.jsx
│   │   │   │   ├── MasteryScale
│   │   │   │   │   ├── ProficiencyRating.jsx
│   │   │   │   │   ├── ProficiencyRating.stories.jsx
│   │   │   │   │   ├── ProficiencyTable.jsx
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   ├── ProficiencyRating.test.jsx
│   │   │   │   │   │   ├── ProficiencyTable.test.jsx
│   │   │   │   │   │   ├── __snapshots__
│   │   │   │   │   │   │   └── ProficiencyRating.test.jsx.snap
│   │   │   │   │   │   └── index.test.jsx
│   │   │   │   │   └── index.jsx
│   │   │   │   ├── OutcomeManagement.jsx
│   │   │   │   ├── RoleList.jsx
│   │   │   │   ├── RoleList.stories.jsx
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── ConfirmMasteryModal.test.jsx
│   │   │   │   │   ├── CreateOutcomeModal1.test.jsx
│   │   │   │   │   ├── CreateOutcomeModal2.test.jsx
│   │   │   │   │   ├── FindOutcomeItem.test.jsx
│   │   │   │   │   ├── FindOutcomesBillboard.test.jsx
│   │   │   │   │   ├── FindOutcomesModal1.test.jsx
│   │   │   │   │   ├── FindOutcomesModal2.test.jsx
│   │   │   │   │   ├── FindOutcomesModal3.test.jsx
│   │   │   │   │   ├── FindOutcomesModal4.test.jsx
│   │   │   │   │   ├── FindOutcomesView.test.jsx
│   │   │   │   │   ├── ImportConfirmBox.test.jsx
│   │   │   │   │   ├── ManagementHeader.test.jsx
│   │   │   │   │   ├── OutcomeManagement.test.jsx
│   │   │   │   │   └── RoleList.test.jsx
│   │   │   │   └── shared
│   │   │   │       ├── AddContentItem.jsx
│   │   │   │       ├── AddContentItem.stories.jsx
│   │   │   │       ├── GroupActionDrillDown.jsx
│   │   │   │       ├── GroupSelectionDrillDown.jsx
│   │   │   │       ├── GroupSelectionDrillDown.stories.jsx
│   │   │   │       ├── LabeledRceField.jsx
│   │   │   │       ├── LabeledRceField.stories.jsx
│   │   │   │       ├── LabeledTextField.tsx
│   │   │   │       ├── OutcomesRceField.jsx
│   │   │   │       ├── SearchBreadcrumb.jsx
│   │   │   │       ├── TargetGroupSelector.jsx
│   │   │   │       ├── TargetGroupSelector.stories.jsx
│   │   │   │       ├── __tests__
│   │   │   │       │   ├── AddContentItem.test.jsx
│   │   │   │       │   ├── GroupActionDrillDown.test.jsx
│   │   │   │       │   ├── GroupSelectionDrillDown.test.jsx
│   │   │   │       │   ├── SearchBreadcrumb.test.jsx
│   │   │   │       │   ├── TargetGroupSelector.test.jsx
│   │   │   │       │   └── descriptionType.test.js
│   │   │   │       ├── descriptionType.js
│   │   │   │       └── requiredIf.js
│   │   │   └── validators
│   │   │       ├── __tests__
│   │   │       │   └── outcomeValidators.test.js
│   │   │       └── outcomeValidators.js
│   │   ├── page_views
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── PageViews.tsx
│   │   │       ├── PageViewsRoute.tsx
│   │   │       ├── PageViewsTable.tsx
│   │   │       ├── __tests__
│   │   │       │   ├── PageViews.test.tsx
│   │   │       │   └── PageViewsTable.test.tsx
│   │   │       └── utils.tsx
│   │   ├── password_complexity_configuration
│   │   │   ├── index.tsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── CustomForbiddenWordsSection.tsx
│   │   │       ├── ForbiddenWordsFileUpload.css
│   │   │       ├── ForbiddenWordsFileUpload.tsx
│   │   │       ├── NumberInputControlled.tsx
│   │   │       ├── PasswordComplexityConfiguration.tsx
│   │   │       ├── __tests__
│   │   │       │   ├── CustomForbiddenWordsSection.test.tsx
│   │   │       │   ├── ForbiddenWordsFileUpload.test.tsx
│   │   │       │   ├── NumberInputControlled.test.tsx
│   │   │       │   └── PasswordComplexityConfiguration.test.tsx
│   │   │       ├── apiClient.ts
│   │   │       └── types.ts
│   │   ├── past_global_alert
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── PastGlobalAlert.jsx
│   │   │       └── __tests__
│   │   │           └── PastGlobalAlert.test.jsx
│   │   ├── past_global_announcements
│   │   │   ├── images
│   │   │   │   └── NoResultsDesert.svg
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── AnnouncementFactory.jsx
│   │   │       ├── AnnouncementPagination.jsx
│   │   │       ├── PastGlobalAnnouncements.jsx
│   │   │       └── __tests__
│   │   │           └── PastGlobalAnnouncements.test.jsx
│   │   ├── pendo
│   │   │   ├── index.ts
│   │   │   ├── package.json
│   │   │   └── pendoAgent.d.ts
│   │   ├── permissions
│   │   │   ├── index.js
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── __tests__
│   │   │       │   ├── actions.test.js
│   │   │       │   ├── examples.js
│   │   │       │   ├── generateActionTemplates.test.js
│   │   │       │   ├── index.test.js
│   │   │       │   └── reducer.test.js
│   │   │       ├── actions.js
│   │   │       ├── apiClient.js
│   │   │       ├── components
│   │   │       │   ├── AddTray.jsx
│   │   │       │   ├── DetailsToggle.jsx
│   │   │       │   ├── GranularCheckbox.jsx
│   │   │       │   ├── PermissionButton.jsx
│   │   │       │   ├── PermissionTray.jsx
│   │   │       │   ├── PermissionsIndex.jsx
│   │   │       │   ├── PermissionsTable.jsx
│   │   │       │   ├── RoleTray.jsx
│   │   │       │   ├── RoleTrayTable.jsx
│   │   │       │   ├── RoleTrayTableRow.jsx
│   │   │       │   └── __tests__
│   │   │       │       ├── AddTray.test.jsx
│   │   │       │       ├── DetailsToggle.test.jsx
│   │   │       │       ├── GranularCheckbox.test.jsx
│   │   │       │       ├── PermissionButton.test.jsx
│   │   │       │       ├── PermissionTray.test.jsx
│   │   │       │       ├── PermissionsIndex.test.jsx
│   │   │       │       ├── PermissionsTable.test.jsx
│   │   │       │       ├── RoleTray.test.jsx
│   │   │       │       ├── RoleTrayTable.test.jsx
│   │   │       │       └── RoleTrayTableRow.test.jsx
│   │   │       ├── generateActionTemplates.js
│   │   │       ├── index.jsx
│   │   │       ├── reducer.js
│   │   │       ├── reducers
│   │   │       │   ├── activeAddTrayReducer.js
│   │   │       │   ├── activePermissionTrayReducer.js
│   │   │       │   ├── activeRoleTrayReducer.js
│   │   │       │   └── setFocusReducer.js
│   │   │       ├── store.js
│   │   │       └── templates
│   │   │           ├── allow_course_admin_actions.js
│   │   │           ├── become_user.js
│   │   │           ├── block_editor_global_template_editor.js
│   │   │           ├── block_editor_template_editor.js
│   │   │           ├── create_collaborations.js
│   │   │           ├── create_conferences.js
│   │   │           ├── create_forum.js
│   │   │           ├── generate_observer_pairing_code.js
│   │   │           ├── groupPermissionDescriptions.js
│   │   │           ├── import_outcomes.js
│   │   │           ├── import_sis.js
│   │   │           ├── lti_add_edit.js
│   │   │           ├── manage_account_banks.js
│   │   │           ├── manage_account_calendar.js
│   │   │           ├── manage_account_memberships.js
│   │   │           ├── manage_account_settings.js
│   │   │           ├── manage_alerts.js
│   │   │           ├── manage_assignments_and_quizzes.js
│   │   │           ├── manage_calendar.js
│   │   │           ├── manage_content.js
│   │   │           ├── manage_course_content.js
│   │   │           ├── manage_course_designer_enrollments.js
│   │   │           ├── manage_course_observer_enrollments.js
│   │   │           ├── manage_course_student_enrollments.js
│   │   │           ├── manage_course_ta_enrollments.js
│   │   │           ├── manage_course_teacher_enrollments.js
│   │   │           ├── manage_course_templates.js
│   │   │           ├── manage_course_visibility.js
│   │   │           ├── manage_courses.js
│   │   │           ├── manage_data_services.js
│   │   │           ├── manage_developer_keys.js
│   │   │           ├── manage_differentiation_tags.js
│   │   │           ├── manage_dsr_requests.js
│   │   │           ├── manage_feature_flags.js
│   │   │           ├── manage_files.js
│   │   │           ├── manage_grades.js
│   │   │           ├── manage_groups.js
│   │   │           ├── manage_impact.js
│   │   │           ├── manage_interaction_alerts.js
│   │   │           ├── manage_lti.js
│   │   │           ├── manage_master_courses.js
│   │   │           ├── manage_outcomes.js
│   │   │           ├── manage_proficiency_calculations.js
│   │   │           ├── manage_proficiency_scales.js
│   │   │           ├── manage_role_overrides.js
│   │   │           ├── manage_rubrics.js
│   │   │           ├── manage_sections.js
│   │   │           ├── manage_sis.js
│   │   │           ├── manage_storage_quotas.js
│   │   │           ├── manage_students.js
│   │   │           ├── manage_tags_add.js
│   │   │           ├── manage_tags_delete.js
│   │   │           ├── manage_tags_manage.js
│   │   │           ├── manage_temp_enroll.js
│   │   │           ├── manage_user_logins.js
│   │   │           ├── manage_user_observers.js
│   │   │           ├── manage_wiki.js
│   │   │           ├── moderate_forum.js
│   │   │           ├── moderate_user_content.js
│   │   │           ├── post_to_forum.js
│   │   │           ├── proxy_assignment_submission.js
│   │   │           ├── read_announcements.js
│   │   │           ├── read_course_content.js
│   │   │           ├── read_course_list.js
│   │   │           ├── read_email_addresses.js
│   │   │           ├── read_forum.js
│   │   │           ├── read_question_banks.js
│   │   │           ├── read_reports.js
│   │   │           ├── read_roster.js
│   │   │           ├── read_sis.js
│   │   │           ├── select_final_grade.js
│   │   │           ├── send_messages.js
│   │   │           ├── send_messages_all.js
│   │   │           ├── share_banks_with_subaccounts.js
│   │   │           ├── undelete_courses.js
│   │   │           ├── users_manage_access_tokens.js
│   │   │           ├── view_admin_analytics.js
│   │   │           ├── view_all_grades.js
│   │   │           ├── view_analytics.js
│   │   │           ├── view_analytics_hub.js
│   │   │           ├── view_audit_trail.js
│   │   │           ├── view_course_changes.js
│   │   │           ├── view_course_readiness.js
│   │   │           ├── view_feature_flags.js
│   │   │           ├── view_grade_changes.js
│   │   │           ├── view_group_pages.js
│   │   │           ├── view_notifications.js
│   │   │           ├── view_quiz_answer_audits.js
│   │   │           ├── view_statistics.js
│   │   │           ├── view_students_in_need.js
│   │   │           └── view_user_logins.js
│   │   ├── plugins
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── index.js
│   │   │   └── package.json
│   │   ├── prerequisites_lookup
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── profile
│   │   │   ├── index.jsx
│   │   │   ├── jquery
│   │   │   │   ├── communication_channels.jsx
│   │   │   │   └── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── AccessTokenDetails.css
│   │   │       ├── AccessTokenDetails.tsx
│   │   │       ├── ConfirmCommunicationChannel.tsx
│   │   │       ├── ConfirmEmailAddress.tsx
│   │   │       ├── NewAccessToken.tsx
│   │   │       ├── RegisterCommunication.tsx
│   │   │       ├── RegisterService.tsx
│   │   │       ├── ResendConfirmation.tsx
│   │   │       ├── __tests__
│   │   │       │   ├── AccessTokenDetails.test.tsx
│   │   │       │   ├── ConfirmCommunicationChannel.test.tsx
│   │   │       │   ├── ConfirmEmailAddress.test.tsx
│   │   │       │   ├── NewAccessToken.test.tsx
│   │   │       │   ├── RegisterCommunication.test.tsx
│   │   │       │   ├── RegisterService.test.tsx
│   │   │       │   └── ResendConfirmation.test.tsx
│   │   │       └── types.ts
│   │   ├── profile_show
│   │   │   ├── backbone
│   │   │   │   └── views
│   │   │   │       ├── ProfileShow.jsx
│   │   │   │       └── __tests__
│   │   │   │           └── ProfileShow.test.js
│   │   │   ├── index.js
│   │   │   ├── jst
│   │   │   │   ├── addLinkRow.handlebars
│   │   │   │   └── addLinkRow.handlebars.json
│   │   │   └── package.json
│   │   ├── progress_pill
│   │   │   ├── index.jsx
│   │   │   └── package.json
│   │   ├── public_javascripts_tests
│   │   │   ├── __tests__
│   │   │   │   └── index.test.ts
│   │   │   └── package.json
│   │   ├── qr_mobile_login
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── QRMobileLoginRoute.tsx
│   │   │       └── components
│   │   │           ├── QRMobileLogin.tsx
│   │   │           └── __tests__
│   │   │               └── QRMobileLogin.test.tsx
│   │   ├── question_bank
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   ├── __tests__
│   │   │   │   │   └── moveMultipleQuestionBanks.test.js
│   │   │   │   ├── addBank.js
│   │   │   │   ├── index.js
│   │   │   │   ├── loadBanks.js
│   │   │   │   └── moveMultipleQuestionBanks.js
│   │   │   ├── jst
│   │   │   │   ├── move_question.handlebars
│   │   │   │   └── move_question.handlebars.json
│   │   │   └── package.json
│   │   ├── question_banks
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── index.js
│   │   │   └── package.json
│   │   ├── quiz_history
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   ├── __tests__
│   │   │   │   │   └── GradingForm.test.js
│   │   │   │   ├── grading_form.js
│   │   │   │   └── quiz_history.js
│   │   │   └── package.json
│   │   ├── quiz_log_auditing
│   │   │   ├── actions.js
│   │   │   ├── backbone
│   │   │   │   ├── collections
│   │   │   │   │   ├── events.js
│   │   │   │   │   └── questions.js
│   │   │   │   ├── mixins
│   │   │   │   │   └── paginated_collection.js
│   │   │   │   └── models
│   │   │   │       ├── __tests__
│   │   │   │       │   └── question_answered_event_decorator.test.js
│   │   │   │       ├── event.js
│   │   │   │       ├── question.js
│   │   │   │       ├── question_answered_event_decorator.js
│   │   │   │       └── submission.js
│   │   │   ├── config
│   │   │   │   ├── environments
│   │   │   │   │   ├── development.js
│   │   │   │   │   └── production.js
│   │   │   │   └── initializers
│   │   │   │       ├── backbone.js
│   │   │   │       └── initializer.js
│   │   │   ├── config.js
│   │   │   ├── constants.js
│   │   │   ├── controller.js
│   │   │   ├── delegate.jsx
│   │   │   ├── dispatcher.js
│   │   │   ├── eslint.config.js
│   │   │   ├── index.js
│   │   │   ├── package.json
│   │   │   ├── react
│   │   │   │   ├── __tests__
│   │   │   │   │   └── index.test.js
│   │   │   │   ├── components
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   ├── button.test.jsx
│   │   │   │   │   │   ├── question_listing.test.jsx
│   │   │   │   │   │   └── session.test.jsx
│   │   │   │   │   ├── answer_matrix
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── cell.test.jsx
│   │   │   │   │   │   │   ├── emblem.test.jsx
│   │   │   │   │   │   │   ├── index.test.jsx
│   │   │   │   │   │   │   ├── inverted_table.test.jsx
│   │   │   │   │   │   │   ├── legend.test.jsx
│   │   │   │   │   │   │   ├── option.test.jsx
│   │   │   │   │   │   │   └── table.test.jsx
│   │   │   │   │   │   ├── cell.jsx
│   │   │   │   │   │   ├── emblem.jsx
│   │   │   │   │   │   ├── index.jsx
│   │   │   │   │   │   ├── inverted_table.jsx
│   │   │   │   │   │   ├── legend.jsx
│   │   │   │   │   │   ├── option.jsx
│   │   │   │   │   │   └── table.jsx
│   │   │   │   │   ├── button.jsx
│   │   │   │   │   ├── event_stream
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── event.test.jsx
│   │   │   │   │   │   │   └── index.test.jsx
│   │   │   │   │   │   ├── event.jsx
│   │   │   │   │   │   └── index.jsx
│   │   │   │   │   ├── question_inspector
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   └── index.test.jsx
│   │   │   │   │   │   ├── answer.jsx
│   │   │   │   │   │   ├── answers
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── essay.test.jsx
│   │   │   │   │   │   │   │   ├── fill_in_multiple_blanks.test.jsx
│   │   │   │   │   │   │   │   ├── matching.test.jsx
│   │   │   │   │   │   │   │   ├── multiple_answers.test.jsx
│   │   │   │   │   │   │   │   ├── multiple_choice.test.jsx
│   │   │   │   │   │   │   │   ├── multiple_dropdowns.test.jsx
│   │   │   │   │   │   │   │   └── no_answer.test.jsx
│   │   │   │   │   │   │   ├── essay.jsx
│   │   │   │   │   │   │   ├── fill_in_multiple_blanks.jsx
│   │   │   │   │   │   │   ├── matching.jsx
│   │   │   │   │   │   │   ├── multiple_answers.jsx
│   │   │   │   │   │   │   ├── multiple_choice.jsx
│   │   │   │   │   │   │   ├── multiple_dropdowns.jsx
│   │   │   │   │   │   │   └── no_answer.jsx
│   │   │   │   │   │   └── index.jsx
│   │   │   │   │   ├── question_listing.jsx
│   │   │   │   │   └── session.jsx
│   │   │   │   ├── index.js
│   │   │   │   ├── routes
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   ├── answer_matrix.test.jsx
│   │   │   │   │   │   ├── app.test.jsx
│   │   │   │   │   │   ├── event_stream.test.jsx
│   │   │   │   │   │   └── question.test.jsx
│   │   │   │   │   ├── answer_matrix.jsx
│   │   │   │   │   ├── app.jsx
│   │   │   │   │   ├── event_stream.jsx
│   │   │   │   │   ├── query.jsx
│   │   │   │   │   └── question.jsx
│   │   │   │   └── routes.jsx
│   │   │   └── stores
│   │   │       └── events.js
│   │   ├── quiz_migration_alerts
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── quiz_show
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── index.jsx
│   │   │   └── package.json
│   │   ├── quiz_statistics
│   │   │   ├── __tests__
│   │   │   │   └── fixtures
│   │   │   │       ├── quiz_reports.json
│   │   │   │       └── quiz_statistics_all_types.json
│   │   │   ├── actions.js
│   │   │   ├── backbone
│   │   │   │   ├── collections
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   ├── quiz_reports.test.js
│   │   │   │   │   │   └── quiz_statistics.test.js
│   │   │   │   │   ├── quiz_reports.js
│   │   │   │   │   └── quiz_statistics.js
│   │   │   │   └── models
│   │   │   │       ├── __tests__
│   │   │   │       │   ├── quiz_report.test.js
│   │   │   │       │   └── quiz_statistics.test.js
│   │   │   │       ├── quiz_report.js
│   │   │   │       ├── quiz_report_descriptor.js
│   │   │   │       ├── quiz_statistics.js
│   │   │   │       └── ratio_calculator.js
│   │   │   ├── config
│   │   │   │   ├── environments
│   │   │   │   │   ├── development.js
│   │   │   │   │   └── production.js
│   │   │   │   ├── initializer.js
│   │   │   │   └── initializers
│   │   │   │       └── backbone.js
│   │   │   ├── config.js
│   │   │   ├── constants.js
│   │   │   ├── controller.js
│   │   │   ├── delegate.jsx
│   │   │   ├── dispatcher.js
│   │   │   ├── eslint.config.js
│   │   │   ├── index.js
│   │   │   ├── package.json
│   │   │   ├── react
│   │   │   │   ├── __tests__
│   │   │   │   │   └── index.test.js
│   │   │   │   ├── components
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   ├── app.test.jsx
│   │   │   │   │   │   ├── correct_answer_donut.test.jsx
│   │   │   │   │   │   ├── popup.test.jsx
│   │   │   │   │   │   └── summary.test.jsx
│   │   │   │   │   ├── app.jsx
│   │   │   │   │   ├── correct_answer_donut.jsx
│   │   │   │   │   ├── discrimination_index
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── help.test.jsx
│   │   │   │   │   │   │   └── index.test.jsx
│   │   │   │   │   │   ├── help.jsx
│   │   │   │   │   │   └── index.jsx
│   │   │   │   │   ├── popup.jsx
│   │   │   │   │   ├── question.jsx
│   │   │   │   │   ├── questions
│   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   ├── answer_table.test.jsx
│   │   │   │   │   │   │   ├── calculated.test.jsx
│   │   │   │   │   │   │   ├── essay.test.jsx
│   │   │   │   │   │   │   ├── file_upload.test.jsx
│   │   │   │   │   │   │   ├── fill_in_multiple_blanks.test.jsx
│   │   │   │   │   │   │   ├── multiple_choice.test.jsx
│   │   │   │   │   │   │   └── short_answer.test.jsx
│   │   │   │   │   │   ├── abstract_text_question.jsx
│   │   │   │   │   │   ├── answer_table.jsx
│   │   │   │   │   │   ├── calculated.jsx
│   │   │   │   │   │   ├── essay.jsx
│   │   │   │   │   │   ├── file_upload.jsx
│   │   │   │   │   │   ├── fill_in_multiple_blanks.jsx
│   │   │   │   │   │   ├── header.jsx
│   │   │   │   │   │   ├── multiple_choice.jsx
│   │   │   │   │   │   ├── short_answer.jsx
│   │   │   │   │   │   └── user_list_dialog.jsx
│   │   │   │   │   └── summary
│   │   │   │   │       ├── __tests__
│   │   │   │   │       │   ├── index.test.jsx
│   │   │   │   │       │   ├── report.test.jsx
│   │   │   │   │       │   ├── report_status.test.jsx
│   │   │   │   │       │   ├── score_percentile_chart.test.jsx
│   │   │   │   │       │   └── section_select.test.jsx
│   │   │   │   │       ├── index.jsx
│   │   │   │   │       ├── report.jsx
│   │   │   │   │       ├── report_status.jsx
│   │   │   │   │       ├── score_percentile_chart.js
│   │   │   │   │       └── section_select.jsx
│   │   │   │   ├── hocs
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   └── createChartComponent.test.jsx
│   │   │   │   │   └── createChartComponent.jsx
│   │   │   │   └── index.js
│   │   │   ├── services
│   │   │   │   └── poll_progress.js
│   │   │   ├── stores
│   │   │   │   ├── __tests__
│   │   │   │   │   └── reports.test.js
│   │   │   │   ├── reports.js
│   │   │   │   ├── statistics.js
│   │   │   │   └── util
│   │   │   │       └── populate_collection.js
│   │   │   └── util
│   │   │       ├── format_number.js
│   │   │       └── parse_number.js
│   │   ├── quiz_submission
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── quizzes
│   │   │   ├── __tests__
│   │   │   │   └── QuizFormulaSolution.spec.js
│   │   │   ├── backbone
│   │   │   │   └── views
│   │   │   │       └── QuizRegradeView.js
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   ├── MultipleChoiceToggle.js
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── addAriaDescription.test.js
│   │   │   │   │   └── quizzes.test.js
│   │   │   │   ├── calcCmd.js
│   │   │   │   ├── quiz_labels.js
│   │   │   │   ├── quizzes.js
│   │   │   │   └── supercalc.js
│   │   │   ├── jst
│   │   │   │   ├── regrade.handlebars
│   │   │   │   └── regrade.handlebars.json
│   │   │   ├── package.json
│   │   │   └── quiz_formula_solution.js
│   │   ├── quizzes_access_code
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── index.js
│   │   │   └── package.json
│   │   ├── quizzes_index
│   │   │   ├── backbone
│   │   │   │   ├── collections
│   │   │   │   │   ├── QuizCollection.js
│   │   │   │   │   └── __tests__
│   │   │   │   │       └── QuizCollection.spec.js
│   │   │   │   ├── models
│   │   │   │   │   ├── QuizOverrideLoader.js
│   │   │   │   │   └── __tests__
│   │   │   │   │       └── QuizOverrideLoader.spec.js
│   │   │   │   └── views
│   │   │   │       ├── IndexView.jsx
│   │   │   │       ├── NoQuizzesView.js
│   │   │   │       ├── QuizItemGroupView.js
│   │   │   │       ├── QuizItemView.jsx
│   │   │   │       └── __tests__
│   │   │   │           ├── IndexView.test.jsx
│   │   │   │           ├── NoQuizzesView.spec.js
│   │   │   │           ├── QuizItemGroupView.test.js
│   │   │   │           ├── QuizItemView1.test.jsx
│   │   │   │           └── QuizItemView2.test.jsx
│   │   │   ├── index.js
│   │   │   ├── jst
│   │   │   │   ├── IndexView.handlebars
│   │   │   │   ├── IndexView.handlebars.json
│   │   │   │   ├── NoQuizzesView.handlebars
│   │   │   │   ├── NoQuizzesView.handlebars.json
│   │   │   │   ├── QuizItemGroupView.handlebars
│   │   │   │   ├── QuizItemGroupView.handlebars.json
│   │   │   │   ├── QuizItemView.handlebars
│   │   │   │   └── QuizItemView.handlebars.json
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── QuizEngineModal.jsx
│   │   │       └── __tests__
│   │   │           └── QuizEngineModal.test.jsx
│   │   ├── registration
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── index.js
│   │   │   ├── jst
│   │   │   │   ├── login.handlebars
│   │   │   │   └── login.handlebars.json
│   │   │   └── package.json
│   │   ├── registration_confirmation
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── release_notes_edit
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── CreateEditModal.tsx
│   │   │       ├── NotesTable.tsx
│   │   │       ├── NotesTableRow.tsx
│   │   │       ├── ReleaseNotesEditRoute.tsx
│   │   │       ├── __tests__
│   │   │       │   ├── CreateEditModal.test.jsx
│   │   │       │   ├── NotesTable.test.jsx
│   │   │       │   ├── NotesTableRow.test.jsx
│   │   │       │   └── index.test.jsx
│   │   │       ├── createEditModalReducer.ts
│   │   │       ├── index.tsx
│   │   │       ├── types.ts
│   │   │       └── util.ts
│   │   ├── roster
│   │   │   ├── backbone
│   │   │   │   ├── collections
│   │   │   │   │   ├── RolesCollection.js
│   │   │   │   │   ├── RosterUserCollection.js
│   │   │   │   │   └── __tests__
│   │   │   │   │       └── RolesCollection.test.js
│   │   │   │   ├── models
│   │   │   │   │   ├── Role.js
│   │   │   │   │   ├── RosterUser.js
│   │   │   │   │   └── __tests__
│   │   │   │   │       └── Role.test.js
│   │   │   │   └── views
│   │   │   │       ├── EditRolesView.js
│   │   │   │       ├── EditSectionsView.jsx
│   │   │   │       ├── InvitationsView.js
│   │   │   │       ├── ResendInvitationsView.js
│   │   │   │       ├── RoleSelectView.js
│   │   │   │       ├── RosterDialogMixin.js
│   │   │   │       ├── RosterTabsView.js
│   │   │   │       ├── RosterUserView.jsx
│   │   │   │       ├── RosterView.jsx
│   │   │   │       ├── SelectView.js
│   │   │   │       └── __tests__
│   │   │   │           ├── InvitationsView.test.js
│   │   │   │           ├── RosterDialogMixin.test.js
│   │   │   │           ├── RosterUserView.test.js
│   │   │   │           └── SelectView.test.js
│   │   │   ├── index.js
│   │   │   ├── jst
│   │   │   │   ├── EditSectionsView.handlebars
│   │   │   │   ├── EditSectionsView.handlebars.json
│   │   │   │   ├── InvitationsView.handlebars
│   │   │   │   ├── InvitationsView.handlebars.json
│   │   │   │   ├── editRolesView.handlebars
│   │   │   │   ├── editRolesView.handlebars.json
│   │   │   │   ├── index.handlebars
│   │   │   │   ├── index.handlebars.json
│   │   │   │   ├── resendInvitations.handlebars
│   │   │   │   ├── resendInvitations.handlebars.json
│   │   │   │   ├── roleSelect.handlebars
│   │   │   │   ├── roleSelect.handlebars.json
│   │   │   │   ├── rosterTabs.handlebars
│   │   │   │   ├── rosterTabs.handlebars.json
│   │   │   │   ├── rosterUser.handlebars
│   │   │   │   ├── rosterUser.handlebars.json
│   │   │   │   ├── rosterUsers.handlebars
│   │   │   │   └── rosterUsers.handlebars.json
│   │   │   ├── package.json
│   │   │   ├── react
│   │   │   │   ├── LinkToStudents.tsx
│   │   │   │   ├── SectionInput.tsx
│   │   │   │   ├── SectionSelector.tsx
│   │   │   │   ├── __tests__
│   │   │   │   │   └── LinkToStudents.test.tsx
│   │   │   │   └── api.ts
│   │   │   └── util
│   │   │       ├── __tests__
│   │   │       │   └── secondsToTime.spec.js
│   │   │       └── secondsToTime.js
│   │   ├── rubric_assessment
│   │   │   ├── index.jsx
│   │   │   └── package.json
│   │   ├── rubrics
│   │   │   ├── components
│   │   │   │   ├── RubricBreadcrumbs.tsx
│   │   │   │   └── ViewRubrics
│   │   │   │       ├── DeleteRubricModal.tsx
│   │   │   │       ├── DuplicateRubricModal.tsx
│   │   │   │       ├── ImportRubric
│   │   │   │       │   ├── ImportFailuresModal.tsx
│   │   │   │       │   ├── ImportRubricTray.tsx
│   │   │   │       │   ├── __tests__
│   │   │   │       │   │   └── ImportRubric.test.tsx
│   │   │   │       │   └── index.tsx
│   │   │   │       ├── RubricPopover.tsx
│   │   │   │       ├── RubricTable.tsx
│   │   │   │       ├── UsedLocationsModal.tsx
│   │   │   │       ├── __tests__
│   │   │   │       │   ├── DeleteRubricModal.test.tsx
│   │   │   │       │   ├── DuplicateRubricModal.test.tsx
│   │   │   │       │   ├── ViewRubrics.test.tsx
│   │   │   │       │   └── fixtures.ts
│   │   │   │       └── index.tsx
│   │   │   ├── package.json
│   │   │   ├── pages
│   │   │   │   ├── RubricForm.tsx
│   │   │   │   └── ViewRubrics.tsx
│   │   │   ├── queries
│   │   │   │   ├── RubricFormQueries.ts
│   │   │   │   └── ViewRubricQueries.ts
│   │   │   ├── routes
│   │   │   │   └── rubricRoutes.tsx
│   │   │   └── types
│   │   │       ├── Rubric.ts
│   │   │       └── RubricForm.ts
│   │   ├── rubrics_index
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── rubrics_show
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── search
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── IndexingProgress.jsx
│   │   │       ├── SearchApp.jsx
│   │   │       ├── SearchResult.jsx
│   │   │       ├── SearchResults.jsx
│   │   │       ├── SearchRoute.tsx
│   │   │       ├── enhanced_ui
│   │   │       │   ├── BestResults.tsx
│   │   │       │   ├── EnhancedSmartSearch.tsx
│   │   │       │   ├── Feedback.tsx
│   │   │       │   ├── NegativeFeedbackModal.tsx
│   │   │       │   ├── PositiveFeedbackModal.tsx
│   │   │       │   ├── ResultCard.tsx
│   │   │       │   ├── SimilarResults.tsx
│   │   │       │   ├── SmartSearchHeader.tsx
│   │   │       │   └── __tests__
│   │   │       │       ├── BestResults.test.tsx
│   │   │       │       ├── EnhancedSmartSearch.test.tsx
│   │   │       │       ├── Feedback.test.tsx
│   │   │       │       ├── ResultCard.test.tsx
│   │   │       │       └── SimilarResults.test.tsx
│   │   │       ├── stopwords.ts
│   │   │       ├── types.ts
│   │   │       └── utils.ts
│   │   ├── section
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   ├── PaginatedList.js
│   │   │   │   ├── __tests__
│   │   │   │   │   └── paginatedList.test.js
│   │   │   │   └── index.jsx
│   │   │   ├── jst
│   │   │   │   ├── enrollment.handlebars
│   │   │   │   └── enrollment.handlebars.json
│   │   │   ├── package.json
│   │   │   └── sectionEnrollmentPresenter.js
│   │   ├── select_content_dialog
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── self_enrollment
│   │   │   ├── backbone
│   │   │   │   └── views
│   │   │   │       └── SelfEnrollmentForm.js
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── settings_sidebar
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── sis_import
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── ConfirmationModal.jsx
│   │   │       ├── SisImportForm.tsx
│   │   │       └── __tests__
│   │   │           ├── ConfirmationModal.test.jsx
│   │   │           └── SisImportForm.test.tsx
│   │   ├── slickgrid
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── speed_grader
│   │   │   ├── JQuerySelectorCache.js
│   │   │   ├── QuizzesNextSpeedGrading.ts
│   │   │   ├── SpeedGraderStatusMenuHelpers.js
│   │   │   ├── __tests__
│   │   │   │   ├── JQuerySelectorCache.test.js
│   │   │   │   ├── SpeedGraderStatusMenuHelpers.test.js
│   │   │   │   ├── quizzesNextSpeedGrading.test.js
│   │   │   │   └── speed_grader.utils.test.ts
│   │   │   ├── global.d.ts
│   │   │   ├── index.jsx
│   │   │   ├── jquery
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── SpeedGraderAlerts.test.jsx
│   │   │   │   │   ├── SpeedGraderAttachments.test.jsx
│   │   │   │   │   ├── SpeedGraderCommentRendering.test.jsx
│   │   │   │   │   ├── SpeedGraderDiscussion.test.jsx
│   │   │   │   │   ├── SpeedGraderGradeFormat.test.jsx
│   │   │   │   │   ├── SpeedGraderGradeParser.test.jsx
│   │   │   │   │   ├── SpeedGraderGradeRefresh.test.jsx
│   │   │   │   │   ├── SpeedGraderGrading.test.jsx
│   │   │   │   │   ├── SpeedGraderLtiAndGrades.test.jsx
│   │   │   │   │   ├── SpeedGraderMediaComment.test.jsx
│   │   │   │   │   ├── SpeedGraderOptionsMenu.test.jsx
│   │   │   │   │   ├── SpeedGraderRubricWarning.test.jsx
│   │   │   │   │   ├── SpeedGraderSelectMenu.test.js
│   │   │   │   │   ├── SpeedGraderSubmissionDetails.test.jsx
│   │   │   │   │   ├── SpeedGraderSubmissionHistory.test.jsx
│   │   │   │   │   ├── SpeedGraderTimeouts.test.jsx
│   │   │   │   │   ├── SpeedgraderHelpers.test.js
│   │   │   │   │   ├── getStudentNameAndGrade.test.jsx
│   │   │   │   │   └── gradeParsingAndTypes.test.jsx
│   │   │   │   ├── speed_grader.d.ts
│   │   │   │   ├── speed_grader.tsx
│   │   │   │   ├── speed_grader.utils.tsx
│   │   │   │   ├── speed_grader_helpers.ts
│   │   │   │   └── speed_grader_select_menu.ts
│   │   │   ├── jst
│   │   │   │   ├── _turnitinInfo.handlebars
│   │   │   │   ├── _turnitinInfo.handlebars.json
│   │   │   │   ├── _vericiteInfo.handlebars
│   │   │   │   ├── _vericiteInfo.handlebars.json
│   │   │   │   ├── speech_recognition.handlebars
│   │   │   │   ├── speech_recognition.handlebars.json
│   │   │   │   ├── student_viewed_at.handlebars
│   │   │   │   ├── student_viewed_at.handlebars.json
│   │   │   │   ├── submissions_dropdown.handlebars
│   │   │   │   ├── submissions_dropdown.handlebars.json
│   │   │   │   └── unsubmitted_comment.handlebars
│   │   │   ├── mutations
│   │   │   │   ├── comment_bank
│   │   │   │   │   ├── createCommentBankItemMutation.ts
│   │   │   │   │   ├── deleteCommentBankItemMutation.ts
│   │   │   │   │   ├── updateCommentBankItemMutation.ts
│   │   │   │   │   └── updateCommentSuggestionsEnabled.ts
│   │   │   │   ├── createSubmissionCommentMutation.ts
│   │   │   │   ├── deleteAttachmentMutation.ts
│   │   │   │   ├── deleteSubmissionCommentMutation.ts
│   │   │   │   ├── hideAssignmentGradesForSectionsMutation.ts
│   │   │   │   ├── postAssignmentGradesForSectionsMutation.ts
│   │   │   │   ├── postDraftSubmissionCommentMutation.ts
│   │   │   │   ├── reassignAssignmentMutation.ts
│   │   │   │   ├── saveRubricAssessmentMutation.ts
│   │   │   │   ├── updateSpeedGraderSettingsMutation.ts
│   │   │   │   ├── updateSubmissionGradeMutation.ts
│   │   │   │   ├── updateSubmissionGradeStatusMutation.ts
│   │   │   │   └── updateSubmissionSecondsLateMutation.ts
│   │   │   ├── package.json
│   │   │   ├── react
│   │   │   │   ├── AssessmentAuditTray
│   │   │   │   │   ├── Api.js
│   │   │   │   │   ├── AuditTrailHelpers.js
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   ├── Api.spec.js
│   │   │   │   │   │   ├── AssessmentAuditTray.test.jsx
│   │   │   │   │   │   ├── AuditTrailHelpers.test.js
│   │   │   │   │   │   ├── AuditTrailSpecHelpers.js
│   │   │   │   │   │   └── buildAuditTrail.test.js
│   │   │   │   │   ├── buildAuditTrail.js
│   │   │   │   │   ├── components
│   │   │   │   │   │   ├── AssessmentAuditButton.jsx
│   │   │   │   │   │   ├── AssessmentSummary.jsx
│   │   │   │   │   │   ├── AuditTrail
│   │   │   │   │   │   │   ├── AuditEvent.jsx
│   │   │   │   │   │   │   ├── CreatorEventGroup.jsx
│   │   │   │   │   │   │   ├── DateEventGroup.jsx
│   │   │   │   │   │   │   ├── __tests__
│   │   │   │   │   │   │   │   ├── AuditEvent.test.jsx
│   │   │   │   │   │   │   │   ├── AuditTrail.test.jsx
│   │   │   │   │   │   │   │   ├── CreatorEventGroup.test.jsx
│   │   │   │   │   │   │   │   └── DateEventGroup.test.jsx
│   │   │   │   │   │   │   ├── index.jsx
│   │   │   │   │   │   │   └── propTypes.js
│   │   │   │   │   │   └── __tests__
│   │   │   │   │   │       ├── AssessmentAuditButton.spec.jsx
│   │   │   │   │   │       └── AssessmentSummary.test.jsx
│   │   │   │   │   └── index.jsx
│   │   │   │   ├── CommentArea.jsx
│   │   │   │   ├── CommentLibrary
│   │   │   │   │   ├── Comment.jsx
│   │   │   │   │   ├── CommentEditView.jsx
│   │   │   │   │   ├── Library.jsx
│   │   │   │   │   ├── LibraryManager.jsx
│   │   │   │   │   ├── Suggestions.jsx
│   │   │   │   │   ├── Tray.jsx
│   │   │   │   │   ├── TrayTextArea.jsx
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   ├── Comment.test.jsx
│   │   │   │   │   │   ├── CommentEditView.test.jsx
│   │   │   │   │   │   ├── Library.test.jsx
│   │   │   │   │   │   ├── LibraryManager.test.jsx
│   │   │   │   │   │   ├── Suggestions.test.jsx
│   │   │   │   │   │   ├── Tray.test.jsx
│   │   │   │   │   │   ├── TrayTextArea.test.jsx
│   │   │   │   │   │   └── mocks.js
│   │   │   │   │   ├── graphql
│   │   │   │   │   │   ├── Mutations.js
│   │   │   │   │   │   └── Queries.js
│   │   │   │   │   └── index.jsx
│   │   │   │   ├── GradeLoadingSpinner.tsx
│   │   │   │   ├── LtiAssetReports.tsx
│   │   │   │   ├── PostPolicies
│   │   │   │   │   ├── __tests__
│   │   │   │   │   │   └── PostPolicies.test.js
│   │   │   │   │   └── index.jsx
│   │   │   │   ├── RubricAssessmentContainerWrapper
│   │   │   │   │   └── index.tsx
│   │   │   │   ├── ScreenCaptureIcon.tsx
│   │   │   │   ├── Shared
│   │   │   │   │   └── UseSameGrade.tsx
│   │   │   │   ├── SpeedGraderAlerts.ts
│   │   │   │   ├── SpeedGraderCheckpoints
│   │   │   │   │   ├── AssessmentGradeInput.tsx
│   │   │   │   │   ├── SpeedGraderCheckpoint.tsx
│   │   │   │   │   ├── SpeedGraderCheckpointsContainer.tsx
│   │   │   │   │   ├── SpeedGraderCheckpointsWrapper.tsx
│   │   │   │   │   └── __tests__
│   │   │   │   │       └── SpeedGraderCheckpoint.test.tsx
│   │   │   │   ├── SpeedGraderDiscussionsNavigation.tsx
│   │   │   │   ├── SpeedGraderDiscussionsNavigation2.tsx
│   │   │   │   ├── SpeedGraderPostGradesMenu.tsx
│   │   │   │   ├── SpeedGraderProvisionalGradeSelector.jsx
│   │   │   │   ├── SpeedGraderSettingsMenu.jsx
│   │   │   │   ├── SpeedGraderStatusMenu.tsx
│   │   │   │   └── __tests__
│   │   │   │       ├── CommentArea.test.jsx
│   │   │   │       ├── GradeLoadingSpinner.test.tsx
│   │   │   │       ├── LtiAssetReports.test.tsx
│   │   │   │       ├── SpeedGraderAlerts.test.js
│   │   │   │       ├── SpeedGraderDiscussionsNavigation.test.tsx
│   │   │   │       ├── SpeedGraderPostGradesMenu.test.jsx
│   │   │   │       ├── SpeedGraderProvisionalGradeSelector.test.jsx
│   │   │   │       ├── SpeedGraderSettingsMenu.test.jsx
│   │   │   │       └── SpeedGraderStatusMenu.test.jsx
│   │   │   ├── sg_uploader.js
│   │   │   ├── stores
│   │   │   │   └── index.ts
│   │   │   └── touch_punch.js
│   │   ├── student_group_dialog
│   │   │   ├── index.jsx
│   │   │   └── package.json
│   │   ├── sub_accounts
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── DeleteSubaccountModal.tsx
│   │   │       ├── SubaccountItem.tsx
│   │   │       ├── SubaccountNameForm.tsx
│   │   │       ├── SubaccountRoute.tsx
│   │   │       ├── SubaccountTree.tsx
│   │   │       ├── __tests__
│   │   │       │   ├── SubaccountItem.test.tsx
│   │   │       │   ├── SubaccountNameForm.test.tsx
│   │   │       │   └── SubaccountTree.test.tsx
│   │   │       ├── types.ts
│   │   │       └── util.tsx
│   │   ├── submission_download
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   ├── __tests__
│   │   │   │   │   └── DownloadSubmissionsDialogManager.test.js
│   │   │   │   └── index.js
│   │   │   └── package.json
│   │   ├── submissions
│   │   │   ├── graphql
│   │   │   │   └── submission.ts
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   ├── __tests__
│   │   │   │   │   └── submissions.test.js
│   │   │   │   └── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── CheckpointGradeContainer.tsx
│   │   │       ├── CheckpointGradeRoot.tsx
│   │   │       └── __tests__
│   │   │           └── CheckpointGradeContainer.test.tsx
│   │   ├── submissions_show_preview_media
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── submissions_show_preview_text
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── submissions_show_preview_upload
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── submit_assignment
│   │   │   ├── __tests__
│   │   │   │   └── deepLinking.test.js
│   │   │   ├── backbone
│   │   │   │   ├── HomeworkSubmissionLtiContainer.js
│   │   │   │   ├── __tests__
│   │   │   │   │   ├── HomeworkSubmissionLtiContainer.test.js
│   │   │   │   │   └── contentExtension.test.js
│   │   │   │   ├── collections
│   │   │   │   │   ├── ExternalToolCollection.js
│   │   │   │   │   └── __tests__
│   │   │   │   │       └── ExternalToolCollection.spec.js
│   │   │   │   ├── contentExtension.js
│   │   │   │   ├── environment.js
│   │   │   │   └── views
│   │   │   │       ├── ExternalContentFileSubmissionView.jsx
│   │   │   │       ├── ExternalContentHomeworkSubmissionView.js
│   │   │   │       ├── ExternalContentLtiLinkSubmissionView.jsx
│   │   │   │       ├── ExternalContentUrlSubmissionView.jsx
│   │   │   │       └── __tests__
│   │   │   │           ├── ExternalContentFileSubmissionView.test.js
│   │   │   │           ├── ExternalContentHomeworkSubmissionView.test.js
│   │   │   │           └── ExternalContentLtiLinkSubmissionView.test.js
│   │   │   ├── deepLinking.js
│   │   │   ├── images
│   │   │   │   └── UploadFile.svg
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   ├── __tests__
│   │   │   │   │   └── submitAssignmentHelper.test.js
│   │   │   │   ├── helper.js
│   │   │   │   └── index.jsx
│   │   │   ├── jst
│   │   │   │   ├── ExternalContentHomeworkFileSubmissionView.handlebars
│   │   │   │   ├── ExternalContentHomeworkFileSubmissionView.handlebars.json
│   │   │   │   ├── ExternalContentHomeworkUrlSubmissionView.handlebars
│   │   │   │   ├── ExternalContentHomeworkUrlSubmissionView.handlebars.json
│   │   │   │   ├── homework_submission_tool.handlebars
│   │   │   │   └── homework_submission_tool.handlebars.json
│   │   │   ├── package.json
│   │   │   ├── react
│   │   │   │   ├── Attachment.jsx
│   │   │   │   ├── OnlineUrlSubmission.tsx
│   │   │   │   ├── WebcamModal.jsx
│   │   │   │   └── __tests__
│   │   │   │       ├── Attachment.test.jsx
│   │   │   │       ├── OnlineUrlSubmission.test.tsx
│   │   │   │       └── WebcamModal.test.jsx
│   │   │   └── util
│   │   │       └── mediaUtils.js
│   │   ├── syllabus
│   │   │   ├── backbone
│   │   │   │   ├── collections
│   │   │   │   │   ├── SyllabusAppointmentGroupsCollection.js
│   │   │   │   │   ├── SyllabusCalendarEventsCollection.js
│   │   │   │   │   ├── SyllabusCollection.js
│   │   │   │   │   └── SyllabusPlannerCollection.js
│   │   │   │   └── views
│   │   │   │       ├── SyllabusView.js
│   │   │   │       └── __tests__
│   │   │   │           └── SyllabusView.test.js
│   │   │   ├── index.jsx
│   │   │   ├── jst
│   │   │   │   ├── Syllabus.handlebars
│   │   │   │   └── Syllabus.handlebars.json
│   │   │   ├── package.json
│   │   │   └── util
│   │   │       ├── __tests__
│   │   │       │   └── utils.test.js
│   │   │       └── utils.js
│   │   ├── take_quiz
│   │   │   ├── backbone
│   │   │   │   └── views
│   │   │   │       ├── FileUploadQuestionView.js
│   │   │   │       ├── LDBLoginPopup.js
│   │   │   │       └── __tests__
│   │   │   │           ├── FileUploadQuestionView.test.js
│   │   │   │           └── LDBLoginPopup.test.js
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   ├── behaviors
│   │   │   │   │   └── autoBlurActiveInput.js
│   │   │   │   ├── index.js
│   │   │   │   └── quiz_taking_police.js
│   │   │   ├── jst
│   │   │   │   ├── LDBLoginPopup.handlebars
│   │   │   │   ├── LDBLoginPopup.handlebars.json
│   │   │   │   ├── fileUploadQuestionState.handlebars
│   │   │   │   ├── fileUploadQuestionState.handlebars.json
│   │   │   │   ├── fileUploadedOrRemoved.handlebars
│   │   │   │   └── fileUploadedOrRemoved.handlebars.json
│   │   │   └── package.json
│   │   ├── teacher_activity_report
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── index.js
│   │   │   └── package.json
│   │   ├── terms_index
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── terms_of_service_modal
│   │   │   ├── index.tsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── TermsOfServiceModal.jsx
│   │   │       └── __tests__
│   │   │           └── TermsOfServiceModal.test.jsx
│   │   ├── terms_of_use
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── theme_editor
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── RangeInput.jsx
│   │   │       ├── SaveThemeButton.tsx
│   │   │       ├── ThemeEditor.jsx
│   │   │       ├── ThemeEditorAccordion.jsx
│   │   │       ├── ThemeEditorColorRow.jsx
│   │   │       ├── ThemeEditorFileUpload.jsx
│   │   │       ├── ThemeEditorImageRow.jsx
│   │   │       ├── ThemeEditorModal.jsx
│   │   │       ├── ThemeEditorSidebar.jsx
│   │   │       ├── ThemeEditorVariableGroup.jsx
│   │   │       └── __tests__
│   │   │           ├── RangeInput.test.jsx
│   │   │           ├── SaveThemeButton.test.tsx
│   │   │           ├── ThemeEditor.test.jsx
│   │   │           ├── ThemeEditorAccordion.test.jsx
│   │   │           ├── ThemeEditorColorRow.test.jsx
│   │   │           ├── ThemeEditorFileUpload.test.jsx
│   │   │           ├── ThemeEditorImageRow.test.jsx
│   │   │           └── ThemeEditorModal.test.jsx
│   │   ├── theme_preview
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── top_navigation_tools
│   │   │   ├── index.tsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── TopNavigationTools.tsx
│   │   │       ├── __tests__
│   │   │       │   ├── TopNavigationTools.test.tsx
│   │   │       │   └── __snapshots__
│   │   │       │       └── TopNavigationTools.test.tsx.snap
│   │   │       └── types.ts
│   │   ├── user
│   │   │   ├── index.jsx
│   │   │   ├── jquery
│   │   │   │   └── index.js
│   │   │   └── package.json
│   │   ├── user_grades
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── index.js
│   │   │   └── package.json
│   │   ├── user_lists
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── index.js
│   │   │   └── package.json
│   │   ├── user_logins
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── AddEditPseudonym.tsx
│   │   │       ├── SuspendedIcon.jsx
│   │   │       └── __tests__
│   │   │           └── AddEditPseudonym.test.tsx
│   │   ├── user_name
│   │   │   ├── index.jsx
│   │   │   ├── jquery
│   │   │   │   └── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── EditUserDetails.tsx
│   │   │       ├── UserSuspendLink.jsx
│   │   │       └── __tests__
│   │   │           ├── EditUserDetails.test.tsx
│   │   │           └── UserSuspendLink.test.jsx
│   │   ├── user_observees
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── UserObservees.tsx
│   │   │       └── __tests__
│   │   │           └── UserObservees.test.tsx
│   │   ├── user_outcome_results
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── users_admin_merge
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── FindUserToMerge.tsx
│   │   │       ├── MergeUsers.tsx
│   │   │       ├── MergeUsersRoute.tsx
│   │   │       ├── PreviewUserMerge.tsx
│   │   │       ├── __tests__
│   │   │       │   ├── FindUserToMerge.test.tsx
│   │   │       │   ├── MergeUsers.test.tsx
│   │   │       │   ├── PreviewUserMerge.test.tsx
│   │   │       │   └── test-data.ts
│   │   │       └── common.ts
│   │   ├── users_index
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── visibility_help
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── webzip_export
│   │   │   ├── index.jsx
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── App.jsx
│   │   │       ├── __tests__
│   │   │       │   └── App.test.jsx
│   │   │       └── components
│   │   │           ├── Errors.jsx
│   │   │           ├── ExportInProgress.jsx
│   │   │           ├── ExportList.jsx
│   │   │           ├── ExportListItem.jsx
│   │   │           └── __tests__
│   │   │               ├── Errors.test.jsx
│   │   │               ├── ExportInProgress.test.jsx
│   │   │               ├── ExportList.test.jsx
│   │   │               └── ExportListItem.test.jsx
│   │   ├── wiki_page_edit
│   │   │   ├── index.js
│   │   │   └── package.json
│   │   ├── wiki_page_index
│   │   │   ├── backbone
│   │   │   │   ├── collections
│   │   │   │   │   ├── WikiPageCollection.js
│   │   │   │   │   └── __tests__
│   │   │   │   │       └── WikiPageCollection.spec.js
│   │   │   │   └── views
│   │   │   │       ├── WikiPageIndexItemView.js
│   │   │   │       ├── WikiPageIndexView.jsx
│   │   │   │       └── __tests__
│   │   │   │           ├── WikiPageIndexItemView.spec.js
│   │   │   │           └── WikiPageIndexView.test.js
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   ├── __tests__
│   │   │   │   │   └── redirectClickTo.test.js
│   │   │   │   └── redirectClickTo.js
│   │   │   ├── jst
│   │   │   │   ├── WikiPageIndex.handlebars
│   │   │   │   ├── WikiPageIndex.handlebars.json
│   │   │   │   ├── WikiPageIndexItem.handlebars
│   │   │   │   └── WikiPageIndexItem.handlebars.json
│   │   │   ├── package.json
│   │   │   └── react
│   │   │       ├── ConfirmDeleteModal.jsx
│   │   │       ├── WikiPageIndexEditModal.tsx
│   │   │       ├── __tests__
│   │   │       │   ├── ConfirmDeleteModal.test.jsx
│   │   │       │   ├── WikiPageIndexEditModal.test.jsx
│   │   │       │   └── apiClient.test.js
│   │   │       └── apiClient.js
│   │   ├── wiki_page_revisions
│   │   │   ├── backbone
│   │   │   │   ├── collections
│   │   │   │   │   ├── WikiPageRevisionsCollection.js
│   │   │   │   │   └── __tests__
│   │   │   │   │       └── WikiPageRevisionsCollection.spec.js
│   │   │   │   └── views
│   │   │   │       ├── WikiPageContentView.js
│   │   │   │       ├── WikiPageRevisionView.js
│   │   │   │       ├── WikiPageRevisionsView.js
│   │   │   │       └── __tests__
│   │   │   │           ├── WikiPageContentView.test.js
│   │   │   │           ├── WikiPageRevisionView.test.js
│   │   │   │           └── WikiPageRevisionsView.test.js
│   │   │   ├── index.js
│   │   │   ├── jquery
│   │   │   │   └── floatingSticky.js
│   │   │   ├── jst
│   │   │   │   ├── WikiPageContent.handlebars
│   │   │   │   ├── WikiPageContent.handlebars.json
│   │   │   │   ├── WikiPageRevision.handlebars
│   │   │   │   ├── WikiPageRevision.handlebars.json
│   │   │   │   ├── WikiPageRevisions.handlebars
│   │   │   │   └── WikiPageRevisions.handlebars.json
│   │   │   └── package.json
│   │   └── wiki_page_show
│   │       ├── backbone
│   │       │   └── views
│   │       │       ├── WikiPageView.jsx
│   │       │       └── __tests__
│   │       │           └── WikiPageView.test.jsx
│   │       ├── index.js
│   │       ├── jst
│   │       │   ├── WikiPage.handlebars
│   │       │   └── WikiPage.handlebars.json
│   │       └── package.json
│   ├── global.d.ts
│   ├── imports.d.ts
│   ├── index.ts
│   ├── loadLocale.ts
│   ├── setup-vitests.tsx
│   └── shared
│       ├── add-people
│       │   ├── initialState.js
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   ├── actions.test.js
│       │       │   └── reducer.test.js
│       │       ├── actions.js
│       │       ├── api_client.js
│       │       ├── components
│       │       │   ├── __tests__
│       │       │   │   ├── MissingPeopleSection.spec.jsx
│       │       │   │   ├── addPeopleSpec.spec.jsx
│       │       │   │   ├── add_people.spec.jsx
│       │       │   │   ├── api_error.spec.jsx
│       │       │   │   ├── duplicate_section.test.jsx
│       │       │   │   ├── peopleReadyList.spec.jsx
│       │       │   │   ├── peopleSearch.test.jsx
│       │       │   │   ├── peopleValidationIssues.test.jsx
│       │       │   │   └── people_search.spec.jsx
│       │       │   ├── add_people.jsx
│       │       │   ├── api_error.jsx
│       │       │   ├── duplicate_section.jsx
│       │       │   ├── missing_people_section.jsx
│       │       │   ├── people_ready_list.jsx
│       │       │   ├── people_search.tsx
│       │       │   ├── people_validation_issues.jsx
│       │       │   └── shapes.js
│       │       ├── helpers.js
│       │       ├── index.jsx
│       │       ├── reducer.js
│       │       ├── reducers
│       │       │   ├── apiState_reducer.js
│       │       │   ├── inputParams_reducer.js
│       │       │   ├── userValidationResult_reducer.js
│       │       │   ├── usersEnrolled_reducer.js
│       │       │   └── usersToBeEnrolled_reducer.js
│       │       ├── resolveValidationIssues.js
│       │       └── store.js
│       ├── alerts
│       │   ├── package.json
│       │   └── react
│       │       ├── AlertManager.tsx
│       │       ├── ExpandableErrorAlert.tsx
│       │       ├── FlashAlert.tsx
│       │       ├── InlineAlert.jsx
│       │       └── __tests__
│       │           ├── ExpandableErrorAlert.test.tsx
│       │           ├── FlashAlert.test.js
│       │           ├── FlashAlert.test.jsx
│       │           └── InlineAlert.test.jsx
│       ├── announcements
│       │   ├── package.json
│       │   └── react
│       │       ├── components
│       │       │   ├── ActionDropDown.tsx
│       │       │   ├── AnnouncementRow.jsx
│       │       │   ├── CourseItemRow.jsx
│       │       │   └── __tests__
│       │       │       ├── ActionDropDown.test.tsx
│       │       │       ├── AnnouncementRow.test.jsx
│       │       │       └── CourseItemRow.test.jsx
│       │       └── proptypes
│       │           └── announcement.js
│       ├── api
│       │   ├── accounts
│       │   │   └── getAccounts.ts
│       │   └── package.json
│       ├── apollo-v3
│       │   ├── __tests__
│       │   │   └── client.test.js
│       │   ├── index.js
│       │   ├── package.json
│       │   └── possibleTypes.json
│       ├── array-erase
│       │   ├── index.ts
│       │   └── package.json
│       ├── assignments
│       │   ├── TurnitinSettings.js
│       │   ├── VeriCiteSettings.js
│       │   ├── __tests__
│       │   │   ├── TurnitinSettings.spec.js
│       │   │   ├── VeriCiteSettings.spec.js
│       │   │   └── originalityReportHelper.test.ts
│       │   ├── assignment-categories.js
│       │   ├── backbone
│       │   │   ├── collections
│       │   │   │   ├── AssignmentCollection.js
│       │   │   │   ├── AssignmentGroupCollection.js
│       │   │   │   ├── AssignmentOverrideCollection.js
│       │   │   │   ├── SubmissionCollection.js
│       │   │   │   └── __tests__
│       │   │   │       └── AssignmentGroupCollection.test.js
│       │   │   ├── models
│       │   │   │   ├── Assignment.js
│       │   │   │   ├── AssignmentGroup.js
│       │   │   │   ├── AssignmentOverride.js
│       │   │   │   ├── LtiAssignmentHelpers.js
│       │   │   │   ├── Submission.js
│       │   │   │   └── __tests__
│       │   │   │       ├── Assignment1.test.js
│       │   │   │       ├── Assignment2.test.js
│       │   │   │       ├── Assignment3.test.js
│       │   │   │       ├── Assignment4.test.js
│       │   │   │       ├── Assignment5.test.js
│       │   │   │       ├── Assignment6.test.js
│       │   │   │       ├── Assignment7.test.js
│       │   │   │       ├── AssignmentGroup.spec.js
│       │   │   │       ├── AssignmentOverride.spec.js
│       │   │   │       ├── LtiAssignmentHelpers.test.js
│       │   │   │       └── Submission.spec.js
│       │   │   └── views
│       │   │       ├── AssignmentGroupCreateDialog.js
│       │   │       ├── AssignmentGroupSelector.js
│       │   │       ├── DateAvailableColumnView.js
│       │   │       ├── DateDueColumnView.js
│       │   │       ├── GradingTypeSelector.jsx
│       │   │       └── PeerReviewsSelector.js
│       │   ├── graphql
│       │   │   ├── student
│       │   │   │   ├── AssessmentRequest.js
│       │   │   │   ├── Assignment.js
│       │   │   │   ├── AssignmentGroup.js
│       │   │   │   ├── Error.js
│       │   │   │   ├── ExternalTool.js
│       │   │   │   ├── File.js
│       │   │   │   ├── Group.js
│       │   │   │   ├── GroupSet.js
│       │   │   │   ├── LockInfo.js
│       │   │   │   ├── MediaObject.js
│       │   │   │   ├── MediaSource.js
│       │   │   │   ├── MediaTrack.js
│       │   │   │   ├── Module.js
│       │   │   │   ├── Mutations.js
│       │   │   │   ├── ProficiencyRating.js
│       │   │   │   ├── Queries.js
│       │   │   │   ├── Rubric.js
│       │   │   │   ├── RubricAssessment.js
│       │   │   │   ├── RubricAssessmentRating.js
│       │   │   │   ├── RubricAssociation.js
│       │   │   │   ├── RubricCriterion.js
│       │   │   │   ├── RubricRating.js
│       │   │   │   ├── Submission.js
│       │   │   │   ├── SubmissionComment.js
│       │   │   │   ├── SubmissionDraft.js
│       │   │   │   ├── SubmissionHistory.js
│       │   │   │   ├── SubmissionInterface.js
│       │   │   │   ├── TurnitinData.js
│       │   │   │   ├── User.js
│       │   │   │   └── UserGroups.js
│       │   │   ├── studentMocks.js
│       │   │   └── teacher
│       │   │       ├── AssignmentTeacherTypes.ts
│       │   │       ├── Mutations.ts
│       │   │       └── Queries.ts
│       │   ├── jquery
│       │   │   ├── __tests__
│       │   │   │   └── reuploadSubmissionsHelper.test.js
│       │   │   ├── reuploadSubmissionsHelper.jsx
│       │   │   └── toggleAccessibly.js
│       │   ├── jst
│       │   │   ├── AssignmentGroupCreateDialog.handlebars
│       │   │   ├── AssignmentGroupCreateDialog.handlebars.json
│       │   │   ├── AssignmentGroupSelector.handlebars
│       │   │   ├── AssignmentGroupSelector.handlebars.json
│       │   │   ├── DateAvailableColumnView.handlebars
│       │   │   ├── DateAvailableColumnView.handlebars.json
│       │   │   ├── DateDueColumnView.handlebars
│       │   │   ├── DateDueColumnView.handlebars.json
│       │   │   ├── DueDateOverride.handlebars
│       │   │   ├── DueDateOverride.handlebars.json
│       │   │   ├── GradingTypeSelector.handlebars
│       │   │   ├── GradingTypeSelector.handlebars.json
│       │   │   ├── PeerReviewsSelector.handlebars
│       │   │   ├── PeerReviewsSelector.handlebars.json
│       │   │   ├── _available_date_description.handlebars
│       │   │   └── _available_date_description.handlebars.json
│       │   ├── package.json
│       │   └── react
│       │       ├── AssignmentExternalTools.jsx
│       │       ├── AssignmentHeader.tsx
│       │       ├── AssignmentPublishButton.tsx
│       │       ├── AssignmentTypes.tsx
│       │       ├── AvailabilityDates.jsx
│       │       ├── CreateEditAssignmentModal.tsx
│       │       ├── FormattedErrorMessage.tsx
│       │       ├── OptionsMenu.tsx
│       │       ├── SimilarityPledge.tsx
│       │       ├── SubmissionStatusPill.jsx
│       │       └── __tests__
│       │           ├── AssignmentExternalTools.test.jsx
│       │           ├── AssignmentHeader.test.tsx
│       │           ├── AssignmentPublishButton.test.tsx
│       │           ├── AvailabilityDates.test.jsx
│       │           ├── CreateEditAssignmentModal.test.tsx
│       │           ├── FormattedErrorMessage.test.tsx
│       │           ├── OptionsMenu.test.tsx
│       │           ├── SimilarityPledge.test.jsx
│       │           ├── SubmissionStatusPill.test.jsx
│       │           └── test-utils.ts
│       ├── authenticity-token
│       │   ├── jquery
│       │   │   └── index.js
│       │   └── package.json
│       ├── auto-complete-select
│       │   └── react
│       │       ├── AutoCompleteSelect.tsx
│       │       └── __tests__
│       │           └── AutoCompleteSelect.test.tsx
│       ├── avatar
│       │   ├── jst
│       │   │   ├── _avatar.handlebars
│       │   │   └── _avatar.handlebars.json
│       │   └── package.json
│       ├── avatar-dialog-view
│       │   ├── AvatarWidget.js
│       │   ├── BlobFactory.js
│       │   ├── __tests__
│       │   │   └── AvatarWidget.spec.js
│       │   ├── backbone
│       │   │   └── views
│       │   │       ├── AvatarDialogView.js
│       │   │       ├── AvatarUploadBaseView.js
│       │   │       ├── GravatarView.js
│       │   │       ├── TakePictureView.js
│       │   │       ├── UploadFileView.js
│       │   │       └── __tests__
│       │   │           ├── AvatarDialogView.test.js
│       │   │           ├── GravatarView.test.js
│       │   │           └── UploadFileView.test.js
│       │   ├── jst
│       │   │   ├── avatarDialog.handlebars
│       │   │   ├── avatarDialog.handlebars.json
│       │   │   ├── gravatarView.handlebars
│       │   │   ├── gravatarView.handlebars.json
│       │   │   ├── takePictureView.handlebars
│       │   │   ├── takePictureView.handlebars.json
│       │   │   ├── uploadFileView.handlebars
│       │   │   └── uploadFileView.handlebars.json
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   └── cropper.test.jsx
│       │       ├── cropper.jsx
│       │       └── cropperMaker.jsx
│       ├── await-element
│       │   ├── __tests__
│       │   │   └── index.test.ts
│       │   ├── index.ts
│       │   └── package.json
│       ├── axios
│       │   ├── __tests__
│       │   │   └── axios.test.js
│       │   ├── index.js
│       │   └── package.json
│       ├── backbone
│       │   ├── Backbone.syncWithMultipart.js
│       │   ├── Collection.js
│       │   ├── DefaultUrlMixin.js
│       │   ├── Model
│       │   │   ├── computedAttributes.js
│       │   │   ├── dateAttributes.js
│       │   │   └── errors.js
│       │   ├── Model.js
│       │   ├── View.js
│       │   ├── __tests__
│       │   │   ├── Collection.test.js
│       │   │   ├── Model.spec.js
│       │   │   ├── View.spec.js
│       │   │   ├── dateAttributes.spec.js
│       │   │   └── mixin.spec.js
│       │   ├── createStore.ts
│       │   ├── index.js
│       │   ├── mixin.js
│       │   ├── package.json
│       │   └── utils.ts
│       ├── backbone-collection-view
│       │   ├── backbone
│       │   │   └── views
│       │   │       ├── __tests__
│       │   │       │   └── CollectionView.test.js
│       │   │       └── index.js
│       │   ├── jst
│       │   │   ├── index.handlebars
│       │   │   └── index.handlebars.json
│       │   └── package.json
│       ├── backbone-input-filter-view
│       │   ├── package.json
│       │   └── src
│       │       ├── __tests__
│       │       │   └── InputFilterView.test.js
│       │       └── index.js
│       ├── backbone-input-view
│       │   ├── package.json
│       │   └── src
│       │       ├── __tests__
│       │       │   └── InputView.test.js
│       │       └── index.js
│       ├── backoff-poller
│       │   ├── __tests__
│       │   │   └── BackoffPoller.test.js
│       │   ├── index.js
│       │   └── package.json
│       ├── block-editor
│       │   ├── package.json
│       │   └── react
│       │       ├── BlockEditor.tsx
│       │       ├── BlockEditorView.tsx
│       │       ├── Contexts.ts
│       │       ├── CreateFromTemplate.tsx
│       │       ├── __tests__
│       │       │   ├── BlockEditor.test.tsx
│       │       │   ├── CreateFromTemplate.test.tsx
│       │       │   └── test-content.ts
│       │       ├── assets
│       │       │   ├── data
│       │       │   │   ├── announcements.ts
│       │       │   │   └── quizQuestions.ts
│       │       │   ├── globalTemplates
│       │       │   │   ├── README.md
│       │       │   │   ├── blank.json
│       │       │   │   ├── blankPage.json
│       │       │   │   ├── cardssection.json
│       │       │   │   ├── contentPage1.json
│       │       │   │   ├── contentPage2.json
│       │       │   │   ├── contentPage3.json
│       │       │   │   ├── courseOverview.json
│       │       │   │   ├── courseTour.json
│       │       │   │   ├── herosectionfullwidth.json
│       │       │   │   ├── herosectiontwocolumn.json
│       │       │   │   ├── herosectionwithnavigation.json
│       │       │   │   ├── homePage2.json
│       │       │   │   ├── homePage3.json
│       │       │   │   ├── homePage4.json
│       │       │   │   ├── homePageBlue.json
│       │       │   │   ├── homePageElementary.json
│       │       │   │   ├── homePageElementary2.json
│       │       │   │   ├── homePageYellow.json
│       │       │   │   ├── homepage1.json
│       │       │   │   ├── index.ts
│       │       │   │   ├── instructorInformation.json
│       │       │   │   ├── knowledgeCheck.json
│       │       │   │   ├── moduleOverview1.json
│       │       │   │   ├── moduleOverview2.json
│       │       │   │   ├── moduleOverview3.json
│       │       │   │   ├── moduleOverviewPeach.json
│       │       │   │   ├── moduleWrapUp1.json
│       │       │   │   ├── moduleWrapUp2.json
│       │       │   │   ├── navigationsection.json
│       │       │   │   ├── resourcePage.json
│       │       │   │   └── resourcesSage.json
│       │       │   ├── iconTypes.ts
│       │       │   ├── internal-icons
│       │       │   │   ├── background-color.tsx
│       │       │   │   ├── desktop.tsx
│       │       │   │   ├── index.ts
│       │       │   │   ├── mobile.tsx
│       │       │   │   ├── placement-bottom.tsx
│       │       │   │   ├── placement-middle.tsx
│       │       │   │   ├── placement-top.tsx
│       │       │   │   ├── redo.tsx
│       │       │   │   ├── resize.tsx
│       │       │   │   ├── tablet.tsx
│       │       │   │   └── undo.tsx
│       │       │   ├── logos
│       │       │   │   └── canvas_logo_left.ts
│       │       │   ├── templates
│       │       │   │   ├── index.ts
│       │       │   │   └── templateOne.ts
│       │       │   └── user-icons
│       │       │       ├── alarm.tsx
│       │       │       ├── apple.tsx
│       │       │       ├── atom.tsx
│       │       │       ├── basketball.tsx
│       │       │       ├── bell.tsx
│       │       │       ├── briefcase.tsx
│       │       │       ├── calculator.tsx
│       │       │       ├── calendar.tsx
│       │       │       ├── clock.tsx
│       │       │       ├── cog.tsx
│       │       │       ├── communication.tsx
│       │       │       ├── conical_flask.tsx
│       │       │       ├── flask.tsx
│       │       │       ├── glasses.tsx
│       │       │       ├── globe.tsx
│       │       │       ├── iconTypes.ts
│       │       │       ├── idea.tsx
│       │       │       ├── index.ts
│       │       │       ├── instuiIcons.tsx
│       │       │       ├── monitor.tsx
│       │       │       ├── note_paper.tsx
│       │       │       ├── notebook.tsx
│       │       │       ├── notes.tsx
│       │       │       ├── pencil.tsx
│       │       │       ├── resume.tsx
│       │       │       ├── ruler.tsx
│       │       │       ├── schedule.tsx
│       │       │       └── test_tube.tsx
│       │       ├── components
│       │       │   ├── blocks.ts
│       │       │   ├── create_from_templates
│       │       │   │   ├── DisplayLayoutButtons.tsx
│       │       │   │   ├── QuickLook.tsx
│       │       │   │   ├── TagSelect.tsx
│       │       │   │   ├── TemplateCardSekeleton.tsx
│       │       │   │   └── __tests__
│       │       │   │       ├── TagSelect.test.tsx
│       │       │   │       └── TemplateCardSkeleton.test.tsx
│       │       │   ├── editor
│       │       │   │   ├── AddImageModal
│       │       │   │   │   ├── AddImageModal.tsx
│       │       │   │   │   ├── __tests__
│       │       │   │   │   │   └── AddImageModal.test.tsx
│       │       │   │   │   └── index.ts
│       │       │   │   ├── AddMediaModals
│       │       │   │   │   ├── SelectMediaModal.tsx
│       │       │   │   │   ├── UploadRecordMediaModal.tsx
│       │       │   │   │   ├── __tests__
│       │       │   │   │   │   ├── SelectMediaModal.test.tsx
│       │       │   │   │   │   ├── UploadRecordMediaModal.test.tsx
│       │       │   │   │   │   └── fixtures
│       │       │   │   │   │       └── mockTrayProps.tsx
│       │       │   │   │   └── index.ts
│       │       │   │   ├── BlockResizer.tsx
│       │       │   │   ├── BlockToolbar.tsx
│       │       │   │   ├── ColorPicker.tsx
│       │       │   │   ├── EditTemplateModal.tsx
│       │       │   │   ├── ErrorBoundary.tsx
│       │       │   │   ├── LinkModal.tsx
│       │       │   │   ├── PreviewModal.tsx
│       │       │   │   ├── RenderNode.tsx
│       │       │   │   ├── SectionBrowser.tsx
│       │       │   │   ├── Toolbox
│       │       │   │   │   ├── BlocksPanel.tsx
│       │       │   │   │   ├── EditTemplateButtons.tsx
│       │       │   │   │   ├── SectionsPanel.tsx
│       │       │   │   │   ├── Toolbox.tsx
│       │       │   │   │   ├── __tests__
│       │       │   │   │   │   ├── BlocksPanel.test.tsx
│       │       │   │   │   │   ├── EditTemplateButtons.test.tsx
│       │       │   │   │   │   ├── SectionsPanel.test.tsx
│       │       │   │   │   │   ├── Toolbox.test.tsx
│       │       │   │   │   │   └── testTemplates.ts
│       │       │   │   │   └── types.ts
│       │       │   │   ├── Topbar.tsx
│       │       │   │   ├── __tests__
│       │       │   │   │   ├── BlockResizer.test.tsx
│       │       │   │   │   ├── BlockToolbar.test.tsx
│       │       │   │   │   ├── EditTemplateModal.test.tsx
│       │       │   │   │   ├── ErrorBoundary.test.tsx
│       │       │   │   │   ├── LinkModal.test.tsx
│       │       │   │   │   ├── PreviewModal.test.tsx
│       │       │   │   │   ├── RenderNode.test.tsx
│       │       │   │   │   ├── SectionBrowser.test.tsx
│       │       │   │   │   └── Topbar.test.tsx
│       │       │   │   └── types.ts
│       │       │   └── user
│       │       │       ├── Resizer.tsx
│       │       │       ├── blocks
│       │       │       │   ├── ButtonBlock
│       │       │       │   │   ├── ButtonBlock.tsx
│       │       │       │   │   ├── ButtonBlockToolbar.tsx
│       │       │       │   │   ├── __tests__
│       │       │       │   │   │   ├── ButtonBlock.test.tsx
│       │       │       │   │   │   └── ButtonBlockToolbar.test.tsx
│       │       │       │   │   ├── index.tsx
│       │       │       │   │   └── types.ts
│       │       │       │   ├── Container
│       │       │       │   │   ├── Container.tsx
│       │       │       │   │   ├── __tests__
│       │       │       │   │   │   └── Container.test.tsx
│       │       │       │   │   ├── index.ts
│       │       │       │   │   └── types.ts
│       │       │       │   ├── DividerBlock
│       │       │       │   │   ├── DividerBlock.tsx
│       │       │       │   │   └── index.ts
│       │       │       │   ├── GroupBlock
│       │       │       │   │   ├── GroupBlock.tsx
│       │       │       │   │   ├── GroupBlockToolbar.tsx
│       │       │       │   │   ├── __tests__
│       │       │       │   │   │   ├── GroupBlock.test.tsx
│       │       │       │   │   │   ├── GroupBlockToolbar.test.tsx
│       │       │       │   │   │   └── ToolbarAlignment.test.tsx
│       │       │       │   │   ├── index.ts
│       │       │       │   │   ├── toolbar
│       │       │       │   │   │   ├── ToolbarAlignment.tsx
│       │       │       │   │   │   └── ToolbarCorners.tsx
│       │       │       │   │   └── types.ts
│       │       │       │   ├── HeadingBlock
│       │       │       │   │   ├── HeadingBlock.tsx
│       │       │       │   │   ├── HeadingBlockToolbar.tsx
│       │       │       │   │   ├── __tests__
│       │       │       │   │   │   ├── HeadingBlock.test.tsx
│       │       │       │   │   │   └── HeadingBlockToolbar.test.tsx
│       │       │       │   │   ├── index.tsx
│       │       │       │   │   └── types.ts
│       │       │       │   ├── IconBlock
│       │       │       │   │   ├── IconBlock.tsx
│       │       │       │   │   ├── IconBlockToolbar.tsx
│       │       │       │   │   ├── IconPicker.tsx
│       │       │       │   │   ├── __tests__
│       │       │       │   │   │   ├── IconBlock.test.tsx
│       │       │       │   │   │   ├── IconBlockToolbar.test.tsx
│       │       │       │   │   │   └── IconPicker.test.tsx
│       │       │       │   │   ├── index.ts
│       │       │       │   │   └── types.ts
│       │       │       │   ├── ImageBlock
│       │       │       │   │   ├── ImageBlock.tsx
│       │       │       │   │   ├── ImageBlockToolbar.tsx
│       │       │       │   │   ├── ImageSizePopup.tsx
│       │       │       │   │   ├── __tests__
│       │       │       │   │   │   ├── ImageBlock.test.tsx
│       │       │       │   │   │   ├── ImageBlockToolbar.test.tsx
│       │       │       │   │   │   └── types.d.ts
│       │       │       │   │   ├── index.ts
│       │       │       │   │   └── types.ts
│       │       │       │   ├── MediaBlock
│       │       │       │   │   ├── AddMediaButton.tsx
│       │       │       │   │   ├── BlockEditorVideoOptionsTray.tsx
│       │       │       │   │   ├── MediaBlock.tsx
│       │       │       │   │   ├── MediaBlockPreviewThumbnail.tsx
│       │       │       │   │   ├── MediaBlockToolbar.tsx
│       │       │       │   │   ├── MediaPreviewModal.tsx
│       │       │       │   │   ├── __tests__
│       │       │       │   │   │   ├── AddMediaButton.test.tsx
│       │       │       │   │   │   ├── MediaBlock.test.tsx
│       │       │       │   │   │   └── MediaBlockToolbar.test.tsx
│       │       │       │   │   ├── index.ts
│       │       │       │   │   └── types.ts
│       │       │       │   ├── PageBlock
│       │       │       │   │   ├── PageBlock.tsx
│       │       │       │   │   ├── __tests__
│       │       │       │   │   │   └── PageBlock.test.tsx
│       │       │       │   │   └── index.ts
│       │       │       │   ├── RCEBlock
│       │       │       │   │   ├── RCEBlock.tsx
│       │       │       │   │   ├── __tests__
│       │       │       │   │   │   └── RCEBlock.test.tsx
│       │       │       │   │   ├── index.ts
│       │       │       │   │   └── types.ts
│       │       │       │   ├── RCETextBlock
│       │       │       │   │   ├── RCETextBlock.tsx
│       │       │       │   │   ├── RCETextBlockPopup.tsx
│       │       │       │   │   ├── RCETextBlockToolbar.tsx
│       │       │       │   │   ├── __tests__
│       │       │       │   │   │   ├── RCETextBlockPopup.test.tsx
│       │       │       │   │   │   └── RCETextBlockToolbar.test.tsx
│       │       │       │   │   ├── index.ts
│       │       │       │   │   └── types.ts
│       │       │       │   ├── ResourceCard
│       │       │       │   │   ├── ResourceCard.tsx
│       │       │       │   │   ├── __tests__
│       │       │       │   │   │   └── RecourseCard.test.tsx
│       │       │       │   │   ├── index.ts
│       │       │       │   │   └── types.ts
│       │       │       │   ├── TabsBlock
│       │       │       │   │   ├── TabsBlock.tsx
│       │       │       │   │   ├── TabsBlockToolbar.tsx
│       │       │       │   │   ├── __tests__
│       │       │       │   │   │   ├── TabsBlock.test.tsx
│       │       │       │   │   │   └── TabsBlockToolbar.test.tsx
│       │       │       │   │   ├── index.tsx
│       │       │       │   │   └── types.ts
│       │       │       │   └── TextBlock
│       │       │       │       ├── TextBlock.tsx
│       │       │       │       ├── TextBlockToolbar.tsx
│       │       │       │       ├── __tests__
│       │       │       │       │   └── TextBlock.test.tsx
│       │       │       │       ├── index.ts
│       │       │       │       └── types.ts
│       │       │       ├── common
│       │       │       │   ├── ColorModal.tsx
│       │       │       │   ├── IconPopup.tsx
│       │       │       │   ├── NoSections.tsx
│       │       │       │   ├── ResizePopup.tsx
│       │       │       │   ├── SectionToolbar.tsx
│       │       │       │   ├── ToolbarColor.tsx
│       │       │       │   ├── __tests__
│       │       │       │   │   ├── ColorModal.test.tsx
│       │       │       │   │   ├── IconPopup.test.tsx
│       │       │       │   │   ├── NoSections.test.tsx
│       │       │       │   │   ├── SectionToolbar.test.tsx
│       │       │       │   │   └── ToolbarColor.test.tsx
│       │       │       │   └── index.tsx
│       │       │       ├── sections
│       │       │       │   ├── AboutSection
│       │       │       │   │   ├── AboutSection.tsx
│       │       │       │   │   ├── AboutTextHalf.tsx
│       │       │       │   │   └── index.ts
│       │       │       │   ├── AnnouncementSection
│       │       │       │   │   ├── AnnouncementModal.tsx
│       │       │       │   │   ├── AnnouncementSection.tsx
│       │       │       │   │   ├── AnnouncementView.tsx
│       │       │       │   │   ├── index.ts
│       │       │       │   │   └── types.ts
│       │       │       │   ├── BlankSection
│       │       │       │   │   ├── BlankSection.tsx
│       │       │       │   │   ├── __tests__
│       │       │       │   │   │   └── BlankSection.test.tsx
│       │       │       │   │   └── index.ts
│       │       │       │   ├── ColumnsSection
│       │       │       │   │   ├── ColumnCountPopup.tsx
│       │       │       │   │   ├── ColumnsSection.tsx
│       │       │       │   │   ├── ColumnsSectionToolbar.tsx
│       │       │       │   │   ├── __tests__
│       │       │       │   │   │   ├── ColumnCountPopup.test.tsx
│       │       │       │   │   │   ├── ColumnsSection.test.tsx
│       │       │       │   │   │   └── ColumnsSectionToolbar.test.tsx
│       │       │       │   │   ├── index.ts
│       │       │       │   │   └── types.ts
│       │       │       │   ├── FooterSection
│       │       │       │   │   ├── FooterSection.tsx
│       │       │       │   │   └── index.ts
│       │       │       │   ├── HeroSection
│       │       │       │   │   ├── HeroSection.tsx
│       │       │       │   │   ├── HeroTextHalf.tsx
│       │       │       │   │   └── index.ts
│       │       │       │   ├── KnowledgeCheckSection
│       │       │       │   │   ├── KnowledgeCheckSection.tsx
│       │       │       │   │   ├── KnowledgeCheckSectionToolbar.tsx
│       │       │       │   │   ├── QuestionSelect.tsx
│       │       │       │   │   ├── QuestionToggle.tsx
│       │       │       │   │   ├── QuizModal.tsx
│       │       │       │   │   ├── QuizSelect.tsx
│       │       │       │   │   ├── __tests__
│       │       │       │   │   │   ├── KnowledgeCheckSection.test.tsx
│       │       │       │   │   │   ├── QuestionSelect.test.tsx
│       │       │       │   │   │   ├── QuestionToggle.test.tsx
│       │       │       │   │   │   ├── QuizModal.test.tsx
│       │       │       │   │   │   ├── QuizSelect.test.tsx
│       │       │       │   │   │   └── testQuestions.tsx
│       │       │       │   │   ├── index.ts
│       │       │       │   │   ├── questions
│       │       │       │   │   │   ├── MatchingQuestion.tsx
│       │       │       │   │   │   ├── MultipleChoiceQuestion.tsx
│       │       │       │   │   │   └── TrueFalseQuestion.tsx
│       │       │       │   │   ├── types.ts
│       │       │       │   │   └── utils
│       │       │       │   │       └── questionUtils.tsx
│       │       │       │   ├── NavigationSection
│       │       │       │   │   ├── NavigationSection.tsx
│       │       │       │   │   └── index.ts
│       │       │       │   └── ResourcesSection
│       │       │       │       ├── ResourcesSection.tsx
│       │       │       │       └── index.tsx
│       │       │       └── types.ts
│       │       ├── index.tsx
│       │       ├── renderChooseEditorModal.tsx
│       │       ├── style.css
│       │       ├── types.ts
│       │       └── utils
│       │           ├── KBNavigator.ts
│       │           ├── __tests__
│       │           │   ├── colorUtils.test.ts
│       │           │   ├── deletable.test.ts
│       │           │   ├── dom.test.ts
│       │           │   ├── getNodeIndex.test.ts
│       │           │   ├── kb.test.ts
│       │           │   ├── mergeTemplates.test.ts
│       │           │   ├── renderNodeHelpers.test.ts
│       │           │   ├── resizeHelpers.test.ts
│       │           │   ├── size.test.ts
│       │           │   ├── transformations.test.ts
│       │           │   └── useClassNames.test.tsx
│       │           ├── buildPageContent.tsx
│       │           ├── captureElement.ts
│       │           ├── cleanupBlocks.ts
│       │           ├── colorUtils.ts
│       │           ├── constants.ts
│       │           ├── deletable.ts
│       │           ├── dimensionChangingCallbacks.tsx
│       │           ├── dom.ts
│       │           ├── getCloneTree.ts
│       │           ├── getNodeIndex.ts
│       │           ├── getScrollParent.ts
│       │           ├── getTemplates.tsx
│       │           ├── index.ts
│       │           ├── kb.ts
│       │           ├── mergeTemplates.ts
│       │           ├── renderNodeHelpers.ts
│       │           ├── resizeHelpers.ts
│       │           ├── saveGlobalTemplate.ts
│       │           ├── size.ts
│       │           ├── transformations.ts
│       │           ├── types.ts
│       │           └── useClassNames.ts
│       ├── blueprint-courses
│       │   ├── getSampleData.js
│       │   ├── package.json
│       │   └── react
│       │       ├── LockItemFormat.js
│       │       ├── __tests__
│       │       │   ├── LockItemFormat.spec.js
│       │       │   ├── actions.test.js
│       │       │   ├── apiClient.test.js
│       │       │   ├── flashNotifications.test.js
│       │       │   ├── reducer.spec.js
│       │       │   └── router.test.js
│       │       ├── actions.js
│       │       ├── apiClient.js
│       │       ├── components
│       │       │   ├── BlueprintLocks.jsx
│       │       │   ├── BlueprintModal.jsx
│       │       │   ├── LockManager
│       │       │   │   ├── LockBanner.jsx
│       │       │   │   ├── LockToggle.jsx
│       │       │   │   ├── __tests__
│       │       │   │   │   ├── LockBanner.test.jsx
│       │       │   │   │   ├── LockManager.spec.js
│       │       │   │   │   └── LockToggle.test.jsx
│       │       │   │   ├── buildLockProps.js
│       │       │   │   └── index.jsx
│       │       │   ├── SyncChange.jsx
│       │       │   ├── SyncHistoryItem.jsx
│       │       │   └── __tests__
│       │       │       ├── BlueprintModal.test.jsx
│       │       │       ├── SyncChange.test.jsx
│       │       │       ├── SyncChange2.test.jsx
│       │       │       ├── SyncHistoryItem.test.jsx
│       │       │       └── getSampleData.js
│       │       ├── flashNotifications.js
│       │       ├── labels.js
│       │       ├── loadStates.js
│       │       ├── migrationStates.js
│       │       ├── propTypes.js
│       │       ├── reducer.js
│       │       ├── router.js
│       │       ├── startApp.js
│       │       └── store.js
│       ├── brandable-css
│       │   ├── __tests__
│       │   │   └── index.test.js
│       │   ├── index.js
│       │   └── package.json
│       ├── breadcrumbs
│       │   ├── package.json
│       │   ├── useAppendBreadcrumb.ts
│       │   └── useBreadcrumbStore.ts
│       ├── bundles
│       │   └── package.json
│       ├── calendar
│       │   ├── AccountCalendarsUtils.js
│       │   ├── TimeBlockListManager.js
│       │   ├── __tests__
│       │   │   └── TimeBlockListManager.test.js
│       │   ├── jquery
│       │   │   ├── CommonEvent
│       │   │   │   ├── Assignment.js
│       │   │   │   ├── AssignmentOverride.js
│       │   │   │   ├── CalendarEvent.js
│       │   │   │   ├── CommonEvent.js
│       │   │   │   ├── PlannerNote.js
│       │   │   │   ├── SubAssignment.js
│       │   │   │   ├── SubAssignmentOverride.js
│       │   │   │   ├── ToDoItem.js
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── CalendarEvent.test.js
│       │   │   │   │   ├── CommonEvent.CalendarEvent.spec.js
│       │   │   │   │   ├── CommonEvent.spec.js
│       │   │   │   │   └── CommonEvent.test.js
│       │   │   │   └── index.js
│       │   │   ├── EventDataSource.js
│       │   │   ├── MessageParticipantsDialog.js
│       │   │   ├── __tests__
│       │   │   │   ├── EventDataSource.test.js
│       │   │   │   ├── coupleTimeFields.test.js
│       │   │   │   └── fcUtil.spec.js
│       │   │   ├── coupleTimeFields.js
│       │   │   └── fcUtil.js
│       │   ├── jst
│       │   │   ├── messageParticipants.handlebars
│       │   │   ├── messageParticipants.handlebars.json
│       │   │   ├── recipientList.handlebars
│       │   │   └── recipientList.handlebars.json
│       │   ├── package.json
│       │   └── react
│       │       └── RecurringEvents
│       │           ├── CustomRecurrence
│       │           │   ├── CustomRecurrence.tsx
│       │           │   └── __tests__
│       │           │       └── CustomRecurrence.test.tsx
│       │           ├── CustomRecurrenceModal
│       │           │   ├── CustomRecurrenceModal.tsx
│       │           │   └── __tests__
│       │           │       └── CustomRecurrenceModal.test.tsx
│       │           ├── DeleteCalendarEventDialog.tsx
│       │           ├── FrequencyPicker
│       │           │   ├── FrequencyPicker.tsx
│       │           │   ├── __tests__
│       │           │   │   ├── FrequencyPicker.test.tsx
│       │           │   │   └── utils.test.ts
│       │           │   └── utils.ts
│       │           ├── RRuleHelper.ts
│       │           ├── RRuleNaturalLanguage.ts
│       │           ├── RecurrenceEndPicker
│       │           │   ├── RecurrenceEndPicker.tsx
│       │           │   └── __tests__
│       │           │       ├── RecurrenceEndPicker.test.tsx
│       │           │       └── utils.ts
│       │           ├── RepeatPicker
│       │           │   ├── RepeatPicker.tsx
│       │           │   └── __tests__
│       │           │       └── RepeatPicker.test.tsx
│       │           ├── UpdateCalendarEventDialog.tsx
│       │           ├── WeekdayPicker
│       │           │   ├── WeekdayPicker.tsx
│       │           │   └── __tests__
│       │           │       └── WeekdayPicker.test.tsx
│       │           ├── __tests__
│       │           │   ├── DeleteCalendarEventDialog.test.jsx
│       │           │   ├── RRuleHelper.test.ts
│       │           │   ├── RRuleNaturalLanguage.test.ts
│       │           │   ├── UpdateCalendarEventDialog.test.jsx
│       │           │   └── utils.test.ts
│       │           ├── types.ts
│       │           └── utils.ts
│       ├── calendar-conferences
│       │   ├── __tests__
│       │   │   ├── filterConferenceTypes.test.js
│       │   │   └── getConferenceType.test.js
│       │   ├── filterConferenceTypes.js
│       │   ├── getConferenceType.js
│       │   ├── package.json
│       │   └── react
│       │       ├── AddConference
│       │       │   ├── AddLtiConferenceDialog.jsx
│       │       │   ├── ConferenceButton.jsx
│       │       │   ├── ConferenceSelect.jsx
│       │       │   ├── __tests__
│       │       │   │   └── index.test.jsx
│       │       │   └── index.jsx
│       │       ├── CalendarConferenceWidget.jsx
│       │       ├── Conference.jsx
│       │       ├── __tests__
│       │       │   ├── CalendarConferenceWidget.test.jsx
│       │       │   └── Conference.test.jsx
│       │       └── proptypes
│       │           ├── webConference.js
│       │           └── webConferenceType.js
│       ├── canvas-media-player
│       │   ├── package.json
│       │   └── react
│       │       ├── CanvasMediaPlayer.jsx
│       │       ├── __mocks__
│       │       │   └── screenfull.js
│       │       └── __tests__
│       │           └── CanvasMediaPlayer.test.jsx
│       ├── canvas-studio-player
│       │   ├── package.json
│       │   └── react
│       │       ├── CanvasStudioPlayer.tsx
│       │       ├── __tests__
│       │       │   └── CanvasStudioPlayer.test.tsx
│       │       └── types.tsx
│       ├── color-picker
│       │   ├── package.json
│       │   └── react
│       │       ├── CourseNicknameEdit.jsx
│       │       ├── __tests__
│       │       │   └── index.test.jsx
│       │       └── index.jsx
│       ├── combo-box
│       │   ├── backbone
│       │   │   └── index.js
│       │   ├── jst
│       │   │   ├── index.handlebars
│       │   │   └── index.handlebars.json
│       │   └── package.json
│       ├── common
│       │   ├── __tests__
│       │   │   ├── elementToggler.test.js
│       │   │   ├── injectAuthTokenIntoForms.test.js
│       │   │   ├── instructureInlineMediaComment.test.js
│       │   │   ├── markBrokenImages.test.js
│       │   │   └── tooltip.spec.js
│       │   ├── activateCourseMenuToggler.js
│       │   ├── activateElementToggler.js
│       │   ├── activateKeyClicks.js
│       │   ├── activateLtiThumbnailLauncher.js
│       │   ├── activateReminderControls.js
│       │   ├── activateTooltips.js
│       │   ├── ajax_errors.js
│       │   ├── injectAuthTokenIntoForms.js
│       │   ├── loadInlineMediaComments.js
│       │   ├── markBrokenImages.js
│       │   └── package.json
│       ├── conditional-release-cyoe-helper
│       │   ├── __tests__
│       │   │   └── CyoeHelper.spec.js
│       │   ├── index.js
│       │   └── package.json
│       ├── conditional-release-editor
│       │   ├── package.json
│       │   └── react
│       │       ├── MasteryPathsReactWrapper.tsx
│       │       ├── __tests__
│       │       │   ├── ConditionalRelease.test.jsx
│       │       │   ├── score-helpers.test.js
│       │       │   ├── scoring-ranges-reducer.test.js
│       │       │   └── validations.test.js
│       │       ├── actions.js
│       │       ├── actors.js
│       │       ├── assignment-path.js
│       │       ├── assignment-picker-actions.js
│       │       ├── assignment-picker-reducer.js
│       │       ├── categories.js
│       │       ├── components
│       │       │   ├── assignment-card-menu.jsx
│       │       │   ├── assignment-card.jsx
│       │       │   ├── assignment-filter.jsx
│       │       │   ├── assignment-list.jsx
│       │       │   ├── assignment-picker-modal.jsx
│       │       │   ├── assignment-picker.jsx
│       │       │   ├── assignment-set.jsx
│       │       │   ├── condition-toggle.jsx
│       │       │   ├── score-input.jsx
│       │       │   ├── score-label.jsx
│       │       │   └── scoring-range.jsx
│       │       ├── create-redux-store.js
│       │       ├── cyoe-api.js
│       │       ├── editor-view.jsx
│       │       ├── editor.jsx
│       │       ├── grading-types.js
│       │       ├── index.jsx
│       │       ├── reducer-helpers.js
│       │       ├── reducer.js
│       │       ├── score-helpers.js
│       │       ├── scoring-ranges-reducer.js
│       │       └── validations.js
│       ├── conditional-release-score
│       │   ├── grading-types.js
│       │   ├── index.js
│       │   └── package.json
│       ├── conditional-release-stats
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   ├── actions.spec.js
│       │       │   └── index.test.jsx
│       │       ├── actions.js
│       │       ├── app.jsx
│       │       ├── components
│       │       │   ├── __tests__
│       │       │   │   ├── breakdownDetails.test.jsx
│       │       │   │   ├── breakdownGraph.test.jsx
│       │       │   │   ├── breakdownGraphBar.test.jsx
│       │       │   │   ├── student-range-item.test.jsx
│       │       │   │   ├── student-ranges-view.test.jsx
│       │       │   │   ├── studentAssignmentItem.test.jsx
│       │       │   │   ├── studentDetailsView.test.jsx
│       │       │   │   └── studentRange.test.jsx
│       │       │   ├── breakdown-details.jsx
│       │       │   ├── breakdown-graph-bar.jsx
│       │       │   ├── breakdown-graphs.jsx
│       │       │   ├── student-assignment-item.jsx
│       │       │   ├── student-details-view.jsx
│       │       │   ├── student-range-item.jsx
│       │       │   ├── student-range.jsx
│       │       │   └── student-ranges-view.jsx
│       │       ├── create-store.js
│       │       ├── cyoe-api.js
│       │       ├── helpers
│       │       │   ├── __tests__
│       │       │   │   └── actions.spec.js
│       │       │   ├── actions.js
│       │       │   └── reducer.js
│       │       ├── index.js
│       │       ├── reducers
│       │       │   ├── __tests__
│       │       │   │   └── reducer.test.js
│       │       │   └── root-reducer.js
│       │       └── shapes
│       │           ├── assignment.js
│       │           ├── index.js
│       │           ├── rule.js
│       │           ├── selected-path.js
│       │           └── student.js
│       ├── confetti
│       │   ├── images
│       │   │   ├── Balloon.svg
│       │   │   ├── BifrostTrophy.svg
│       │   │   ├── Butterfly.svg
│       │   │   ├── EinsteinRosenTrophy.svg
│       │   │   ├── Fire.svg
│       │   │   ├── Flowers.svg
│       │   │   ├── FourLeafClover.svg
│       │   │   ├── Gift.svg
│       │   │   ├── Gnome.svg
│       │   │   ├── HelixRocket.svg
│       │   │   ├── HorseShoe.svg
│       │   │   ├── HotAirBalloon.svg
│       │   │   ├── MagicMysteryThumbsUp.svg
│       │   │   ├── Medal.svg
│       │   │   ├── Moon.svg
│       │   │   ├── PanamaRocket.svg
│       │   │   ├── Panda.svg
│       │   │   ├── PandaUnicycle.svg
│       │   │   ├── Pinwheel.svg
│       │   │   ├── PizzaSlice.svg
│       │   │   ├── Rocket.svg
│       │   │   ├── Star.svg
│       │   │   ├── ThumbsUp.svg
│       │   │   └── Trophy.svg
│       │   ├── javascript
│       │   │   ├── ConfettiGenerator.ts
│       │   │   ├── __tests__
│       │   │   │   └── confetti.utils.test.ts
│       │   │   ├── assetFactory.js
│       │   │   └── confetti.utils.ts
│       │   ├── package.json
│       │   ├── react
│       │   │   ├── Confetti.stories.jsx
│       │   │   ├── Confetti.tsx
│       │   │   ├── __tests__
│       │   │   │   └── Confetti.test.tsx
│       │   │   └── index.jsx
│       │   └── types.d.ts
│       ├── content-locks
│       │   ├── jquery
│       │   │   └── lock_reason.ts
│       │   └── package.json
│       ├── content-migrations
│       │   ├── backbone
│       │   │   ├── models
│       │   │   │   ├── ContentMigration.jsx
│       │   │   │   ├── ContentMigrationProgress.js
│       │   │   │   └── __tests__
│       │   │   │       └── ContentMigration.spec.js
│       │   │   └── views
│       │   │       ├── ConverterViewControl.js
│       │   │       ├── DateShiftView.js
│       │   │       ├── ImportQuizzesNextView.js
│       │   │       ├── MigrationView.js
│       │   │       ├── __tests__
│       │   │       │   ├── ConverterViewControl.spec.js
│       │   │       │   └── DateShiftView.spec.js
│       │   │       └── subviews
│       │   │           ├── ChooseMigrationFileView.js
│       │   │           ├── ImportBlueprintSettingsView.handlebars
│       │   │           ├── ImportBlueprintSettingsView.handlebars.json
│       │   │           ├── ImportBlueprintSettingsView.js
│       │   │           ├── OverwriteAssessmentContentView.js
│       │   │           ├── QuestionBankView.js
│       │   │           ├── SelectContentCheckboxView.js
│       │   │           └── __tests__
│       │   │               ├── ImportQuizzesNext.spec.js
│       │   │               └── SelectContentCheckbox.test.js
│       │   ├── index.tsx
│       │   ├── jst
│       │   │   ├── DateShift.handlebars
│       │   │   ├── DateShift.handlebars.json
│       │   │   ├── ImportQuizzesNextView.handlebars
│       │   │   ├── ImportQuizzesNextView.handlebars.json
│       │   │   └── subviews
│       │   │       ├── ChooseMigrationFile.handlebars
│       │   │       ├── ChooseMigrationFile.handlebars.json
│       │   │       ├── OverwriteAssessmentContent.handlebars
│       │   │       ├── OverwriteAssessmentContent.handlebars.json
│       │   │       ├── QuestionBank.handlebars
│       │   │       ├── QuestionBank.handlebars.json
│       │   │       ├── SelectContentCheckbox.handlebars
│       │   │       └── SelectContentCheckbox.handlebars.json
│       │   ├── package.json
│       │   └── react
│       │       ├── CommonMigratorControls
│       │       │   ├── CommonMigratorControls.tsx
│       │       │   ├── DateAdjustments.tsx
│       │       │   ├── DaySubstitution.tsx
│       │       │   ├── FormLabel.tsx
│       │       │   ├── InfoButton.tsx
│       │       │   ├── __tests__
│       │       │   │   ├── CommonMigratorControls.test.tsx
│       │       │   │   ├── DateAdjustments.test.tsx
│       │       │   │   ├── DaySubstitution.test.tsx
│       │       │   │   ├── FormLabel.test.tsx
│       │       │   │   ├── InfoButton.test.tsx
│       │       │   │   └── timeZonedFormMessages.test.tsx
│       │       │   ├── converter
│       │       │   │   ├── __tests__
│       │       │   │   │   └── form_data_converter.test.ts
│       │       │   │   └── form_data_converter.ts
│       │       │   ├── timeZonedFormMessages.tsx
│       │       │   └── types.ts
│       │       ├── TreeSelector
│       │       │   ├── TreeSelector.tsx
│       │       │   └── __tests__
│       │       │       └── TreeSelector.test.tsx
│       │       ├── __tests__
│       │       │   ├── errorFormMessage.test.tsx
│       │       │   └── utils.test.ts
│       │       ├── errorFormMessage.tsx
│       │       └── utils.ts
│       ├── content-sharing
│       │   ├── package.json
│       │   └── react
│       │       └── proptypes
│       │           ├── attachment.js
│       │           ├── contentExport.js
│       │           └── contentShare.js
│       ├── context-cards
│       │   ├── package.json
│       │   └── react
│       │       ├── Avatar.jsx
│       │       ├── GraphQLStudentContextTray.jsx
│       │       ├── LastActivity.jsx
│       │       ├── MetricsList.jsx
│       │       ├── Rating.jsx
│       │       ├── SectionInfo.jsx
│       │       ├── StudentContextCardTrigger.jsx
│       │       ├── StudentContextTray.jsx
│       │       ├── SubmissionProgressBars.jsx
│       │       └── __tests__
│       │           ├── Avatar.test.jsx
│       │           ├── LastActivity.test.jsx
│       │           ├── MetricsList.test.jsx
│       │           ├── Rating.test.jsx
│       │           ├── StudentContextTray.test.jsx
│       │           └── SubmissionProgressBars.test.jsx
│       ├── context-module-file-drop
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   ├── apiClient.test.js
│       │       │   └── index.test.jsx
│       │       ├── apiClient.js
│       │       └── index.jsx
│       ├── context-modules
│       │   ├── __tests__
│       │   │   ├── FetchError.test.tsx
│       │   │   ├── ModuleItemPaging.test.tsx
│       │   │   ├── ModuleItemsStore.test.ts
│       │   │   ├── publishAllModulesHelper.test.ts
│       │   │   ├── publishOneModuleHelper.test.ts
│       │   │   └── testHelpers.ts
│       │   ├── backbone
│       │   │   ├── models
│       │   │   │   ├── MasterCourseModuleLock.js
│       │   │   │   ├── Publishable.js
│       │   │   │   ├── PublishableModuleItem.js
│       │   │   │   └── __tests__
│       │   │   │       └── Publishable.test.js
│       │   │   └── views
│       │   │       └── context_modules.js
│       │   ├── differentiated-modules
│       │   │   ├── index.ts
│       │   │   ├── react
│       │   │   │   ├── AssignToPanel.tsx
│       │   │   │   ├── AssigneeSelector.tsx
│       │   │   │   ├── DifferentiatedModulesTray.tsx
│       │   │   │   ├── Footer.tsx
│       │   │   │   ├── Item
│       │   │   │   │   ├── AvailableFromDateTimeInput.tsx
│       │   │   │   │   ├── AvailableToDateTimeInput.tsx
│       │   │   │   │   ├── ClearableDateTimeInput.tsx
│       │   │   │   │   ├── ContextModuleLink.tsx
│       │   │   │   │   ├── DueDateTimeInput.tsx
│       │   │   │   │   ├── ItemAssignToCard.tsx
│       │   │   │   │   ├── ItemAssignToManager.tsx
│       │   │   │   │   ├── ItemAssignToTray.tsx
│       │   │   │   │   ├── ItemAssignToTrayContent.tsx
│       │   │   │   │   ├── ReplyToTopicDueDateTimeInput.tsx
│       │   │   │   │   ├── RequiredRepliesDueDateTimeInput.tsx
│       │   │   │   │   ├── __tests__
│       │   │   │   │   │   ├── ClearableDateTimeInput.test.tsx
│       │   │   │   │   │   ├── ContextModuleLink.test.tsx
│       │   │   │   │   │   ├── ItemAssignToCard.1.test.tsx
│       │   │   │   │   │   ├── ItemAssignToCard.2.test.tsx
│       │   │   │   │   │   ├── ItemAssignToCard.3.test.tsx
│       │   │   │   │   │   └── ItemAssignToTray.test.tsx
│       │   │   │   │   ├── types.d.ts
│       │   │   │   │   └── utils.ts
│       │   │   │   ├── LoadingOverlay.tsx
│       │   │   │   ├── ModuleAssignments.tsx
│       │   │   │   ├── PrerequisiteForm.tsx
│       │   │   │   ├── PrerequisiteSelector.tsx
│       │   │   │   ├── RequirementCountInput.tsx
│       │   │   │   ├── RequirementForm.tsx
│       │   │   │   ├── RequirementSelector.tsx
│       │   │   │   ├── ScoreSection.tsx
│       │   │   │   ├── SettingsPanel.tsx
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── AssignToPanel.test.tsx
│       │   │   │   │   ├── DifferentiatedModulesTray.test.tsx
│       │   │   │   │   ├── Footer.test.tsx
│       │   │   │   │   ├── ModuleAssignments.test.tsx
│       │   │   │   │   ├── PrerequisiteForm.test.tsx
│       │   │   │   │   ├── PrerequisiteSelector.test.tsx
│       │   │   │   │   ├── RequirementCountInput.test.tsx
│       │   │   │   │   ├── RequirementForm.test.tsx
│       │   │   │   │   ├── RequirementSelector.test.tsx
│       │   │   │   │   ├── SettingsPanel.test.tsx
│       │   │   │   │   └── mocks.ts
│       │   │   │   ├── settingsReducer.ts
│       │   │   │   └── types.ts
│       │   │   └── utils
│       │   │       ├── __tests__
│       │   │       │   ├── assignToHelper.test.ts
│       │   │       │   ├── fixtures.ts
│       │   │       │   ├── miscHelpers.test.ts
│       │   │       │   └── moduleHelpers.test.ts
│       │   │       ├── assignToHelper.ts
│       │   │       ├── hooks
│       │   │       │   ├── getStudentsByCourse.ts
│       │   │       │   ├── queryFn.ts
│       │   │       │   ├── useFetchAssignees.tsx
│       │   │       │   └── useGetAssigneeOptions.ts
│       │   │       ├── miscHelpers.ts
│       │   │       └── moduleHelpers.ts
│       │   ├── jquery
│       │   │   ├── __tests__
│       │   │   │   ├── context_modules_helper.test.js
│       │   │   │   └── setupContentIds.test.js
│       │   │   ├── context_modules_helper.js
│       │   │   ├── index.jsx
│       │   │   ├── setupContentIds.js
│       │   │   └── utils.jsx
│       │   ├── jst
│       │   │   ├── _vddTooltip.handlebars
│       │   │   └── _vddTooltip.handlebars.json
│       │   ├── package.json
│       │   ├── react
│       │   │   ├── ContextModulesHeader.tsx
│       │   │   ├── ContextModulesPublishIcon.tsx
│       │   │   ├── ContextModulesPublishMenu.tsx
│       │   │   ├── ContextModulesPublishModal.tsx
│       │   │   ├── ModuleDuplicationSpinner.jsx
│       │   │   ├── __tests__
│       │   │   │   ├── ContextModulesHeader.test.tsx
│       │   │   │   ├── ContextModulesPublishIcon.1.test.tsx
│       │   │   │   ├── ContextModulesPublishIcon.2.test.tsx
│       │   │   │   ├── ContextModulesPublishMenu.test.tsx
│       │   │   │   └── ContextModulesPublishModal.test.tsx
│       │   │   └── types.ts
│       │   └── utils
│       │       ├── FetchError.tsx
│       │       ├── ModuleItemLoadingData.ts
│       │       ├── ModuleItemPaging.tsx
│       │       ├── ModuleItemsLazyLoader.tsx
│       │       ├── ModuleItemsStore.ts
│       │       ├── __tests__
│       │       │   ├── ModuleItemLoadingData.test.ts
│       │       │   ├── ModuleItemsLazyLoader.test.ts
│       │       │   └── showAllOrLess.test.ts
│       │       ├── moduleHelpers.tsx
│       │       ├── publishAllModulesHelper.tsx
│       │       ├── publishOneModuleHelper.tsx
│       │       ├── showAllOrLess.ts
│       │       └── types.ts
│       ├── convert-case
│       │   ├── __tests__
│       │   │   └── convert-case.test.ts
│       │   ├── convert-case.ts
│       │   └── package.json
│       ├── copy-to-clipboard
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   └── index.test.jsx
│       │       └── index.jsx
│       ├── copy-to-clipboard-button
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   └── index.test.jsx
│       │       └── index.tsx
│       ├── course-homepage
│       │   ├── package.json
│       │   └── react
│       │       ├── Dialog.jsx
│       │       ├── Prompt.jsx
│       │       └── __tests__
│       │           └── CourseHomeDialog.test.jsx
│       ├── courses
│       │   ├── __tests__
│       │   │   └── courseAPIClient.test.js
│       │   ├── backbone
│       │   │   └── models
│       │   │       └── Course.js
│       │   ├── courseAPIClient.ts
│       │   ├── jquery
│       │   │   ├── __tests__
│       │   │   │   ├── toggleCourseNav.test.js
│       │   │   │   └── updateSubnavMenuToggle.test.js
│       │   │   ├── toggleCourseNav.js
│       │   │   └── updateSubnavMenuToggle.js
│       │   ├── package.json
│       │   └── react
│       │       ├── CoursePublishButton.tsx
│       │       ├── __tests__
│       │       │   └── CoursePublishButton.test.tsx
│       │       └── proptypes
│       │           └── masterCourseData.js
│       ├── create-course-modal
│       │   ├── package.json
│       │   └── react
│       │       ├── CreateCourseModal.jsx
│       │       ├── __tests__
│       │       │   ├── CreateCourseModal.test.jsx
│       │       │   └── utils.test.js
│       │       └── utils.js
│       ├── dashboard-card
│       │   ├── __tests__
│       │   │   └── loadCardDashboard.test.js
│       │   ├── dashboardCardQueries.ts
│       │   ├── graphql
│       │   │   ├── ActivityStream.ts
│       │   │   ├── CourseDashboardCard.ts
│       │   │   └── Queries.ts
│       │   ├── loadCardDashboard.tsx
│       │   ├── package.json
│       │   ├── react
│       │   │   ├── ConfirmUnfavoriteCourseModal.tsx
│       │   │   ├── CourseActivitySummaryStore.ts
│       │   │   ├── DashboardCard.tsx
│       │   │   ├── DashboardCardAction.jsx
│       │   │   ├── DashboardCardBackgroundStore.ts
│       │   │   ├── DashboardCardBox.tsx
│       │   │   ├── DashboardCardMenu.tsx
│       │   │   ├── DashboardCardMovementMenu.tsx
│       │   │   ├── DefaultDragDropContext.tsx
│       │   │   ├── DraggableDashboardCard.jsx
│       │   │   ├── MovementUtils.ts
│       │   │   ├── PublishButton.tsx
│       │   │   ├── Types.ts
│       │   │   ├── __tests__
│       │   │   │   ├── ConfirmUnfavoriteCourseModal.test.jsx
│       │   │   │   ├── CourseActivitySummaryStore.test.js
│       │   │   │   ├── DashboardCard.test.jsx
│       │   │   │   ├── DashboardCard2.test.jsx
│       │   │   │   ├── DashboardCardAction.test.jsx
│       │   │   │   ├── DashboardCardBackgroundStore.test.js
│       │   │   │   ├── DashboardCardBox.test.jsx
│       │   │   │   ├── DashboardCardMenu.test.jsx
│       │   │   │   ├── DashboardCardMovementMenu.test.jsx
│       │   │   │   ├── DashboardCardReordering.test.jsx
│       │   │   │   └── PublishButton.test.jsx
│       │   │   └── getDroppableDashboardCardBox.ts
│       │   ├── types.d.ts
│       │   └── util
│       │       ├── __tests__
│       │       │   ├── dashboardUtils.test.ts
│       │       │   └── instFSOptimizedImageUrl.test.js
│       │       ├── dashboardUtils.ts
│       │       └── instFSOptimizedImageUrl.ts
│       ├── date-group
│       │   ├── backbone
│       │   │   ├── collections
│       │   │   │   └── DateGroupCollection.js
│       │   │   └── models
│       │   │       ├── DateGroup.js
│       │   │       └── __tests__
│       │   │           └── DateGroup.spec.js
│       │   └── package.json
│       ├── datetime
│       │   ├── __tests__
│       │   │   ├── accessibleDateFormat.spec.js
│       │   │   ├── changeToTheSecondBeforeMidnight.test.js
│       │   │   ├── dateHelper.spec.js
│       │   │   ├── format.test.js
│       │   │   ├── helpers.js
│       │   │   ├── instructureDateTime.test.js
│       │   │   ├── isMidnight.test.js
│       │   │   ├── mergeTimeAndDate.test.js
│       │   │   ├── meridiem.test.js
│       │   │   ├── moment.test.js
│       │   │   ├── moment_formats.spec.js
│       │   │   ├── parse.test.js
│       │   │   ├── semanticDateRange.spec.js
│       │   │   └── shifting.test.js
│       │   ├── accessibleDateFormat.js
│       │   ├── configureDateTime.js
│       │   ├── configureDateTimeMomentParser.js
│       │   ├── date-functions.js
│       │   ├── dateHelper.js
│       │   ├── jquery
│       │   │   ├── DatetimeField.js
│       │   │   ├── __tests__
│       │   │   │   └── DatetimeField.test.js
│       │   │   └── datepicker.js
│       │   ├── package.json
│       │   ├── react
│       │   │   ├── __tests__
│       │   │   │   └── dateUtils.spec.js
│       │   │   ├── components
│       │   │   │   ├── ConnectedFriendlyDatetimes.tsx
│       │   │   │   ├── DateInput.tsx
│       │   │   │   ├── DateInput2.tsx
│       │   │   │   ├── DateTimeInput.jsx
│       │   │   │   ├── DatetimeDisplay.jsx
│       │   │   │   ├── FriendlyDatetime.tsx
│       │   │   │   ├── TimeZoneSelect.tsx
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── ConnectedFriendlyDatetimes.test.tsx
│       │   │   │   │   ├── DateInput.test.jsx
│       │   │   │   │   ├── DateInput2.test.jsx
│       │   │   │   │   ├── DateTimeInput.test.jsx
│       │   │   │   │   ├── DatetimeDisplay.test.jsx
│       │   │   │   │   └── TimeZoneSelect.test.jsx
│       │   │   │   ├── localized-timezone-lists
│       │   │   │   │   ├── ar.json
│       │   │   │   │   ├── cy.json
│       │   │   │   │   ├── da-x-k12.json
│       │   │   │   │   ├── da.json
│       │   │   │   │   ├── de.json
│       │   │   │   │   ├── el.json
│       │   │   │   │   ├── en-AU.json
│       │   │   │   │   ├── en-CA.json
│       │   │   │   │   ├── en-GB-x-lbs.json
│       │   │   │   │   ├── en-GB-x-ukhe.json
│       │   │   │   │   ├── en-GB.json
│       │   │   │   │   ├── en.json
│       │   │   │   │   ├── es-AR.json
│       │   │   │   │   ├── es-CL.json
│       │   │   │   │   ├── es-CO.json
│       │   │   │   │   ├── es-CR.json
│       │   │   │   │   ├── es-EC.json
│       │   │   │   │   ├── es-PE.json
│       │   │   │   │   ├── es-PY.json
│       │   │   │   │   ├── es.json
│       │   │   │   │   ├── fa.json
│       │   │   │   │   ├── fi.json
│       │   │   │   │   ├── fr-CA.json
│       │   │   │   │   ├── fr.json
│       │   │   │   │   ├── he.json
│       │   │   │   │   ├── ht.json
│       │   │   │   │   ├── hu.json
│       │   │   │   │   ├── hy.json
│       │   │   │   │   ├── is.json
│       │   │   │   │   ├── it.json
│       │   │   │   │   ├── ja.json
│       │   │   │   │   ├── ko.json
│       │   │   │   │   ├── mi.json
│       │   │   │   │   ├── nb-x-k12.json
│       │   │   │   │   ├── nb.json
│       │   │   │   │   ├── nl.json
│       │   │   │   │   ├── nn.json
│       │   │   │   │   ├── pl.json
│       │   │   │   │   ├── pt-BR.json
│       │   │   │   │   ├── pt.json
│       │   │   │   │   ├── ru.json
│       │   │   │   │   ├── sl.json
│       │   │   │   │   ├── sv-x-k12.json
│       │   │   │   │   ├── sv.json
│       │   │   │   │   ├── tr.json
│       │   │   │   │   ├── uk.json
│       │   │   │   │   ├── zh-Hans.json
│       │   │   │   │   └── zh-Hant.json
│       │   │   │   └── render-datepicker-time.jsx
│       │   │   └── date-utils.jsx
│       │   └── semanticDateRange.js
│       ├── datetime-natural-parsing-instrument
│       │   ├── index.ts
│       │   └── package.json
│       ├── day-substitution
│       │   ├── backbone
│       │   │   ├── collections
│       │   │   │   ├── DaySubstitutionCollection.js
│       │   │   │   └── __tests__
│       │   │   │       └── DaySubstitutionCollection.spec.js
│       │   │   ├── models
│       │   │   │   └── DaySubstitution.js
│       │   │   └── views
│       │   │       └── DaySubstitutionView.js
│       │   ├── jst
│       │   │   ├── DaySubstitution.handlebars
│       │   │   ├── DaySubstitution.handlebars.json
│       │   │   ├── DaySubstitutionCollection.handlebars
│       │   │   └── DaySubstitutionCollection.handlebars.json
│       │   └── package.json
│       ├── deep-linking
│       │   ├── ContentItemProcessor.ts
│       │   ├── DeepLinkResponse.ts
│       │   ├── DeepLinking.ts
│       │   ├── __tests__
│       │   │   ├── DeepLinking.test.ts
│       │   │   └── collaborations.test.js
│       │   ├── collaborations.js
│       │   ├── models
│       │   │   ├── AssetProcessorContentItem.ts
│       │   │   ├── ContentItem.ts
│       │   │   ├── HtmlFragmentContentItem.ts
│       │   │   ├── ImageContentItem.ts
│       │   │   ├── LinkContentItem.ts
│       │   │   ├── ResourceLinkContentItem.ts
│       │   │   ├── __tests__
│       │   │   │   ├── AssetProcessorContentItem.test.ts
│       │   │   │   ├── HtmlFragmentContentItem.test.ts
│       │   │   │   ├── ImageContentItem.test.ts
│       │   │   │   ├── LinkContentItem.test.ts
│       │   │   │   └── ResourceLinkContentItem.test.ts
│       │   │   └── helpers.ts
│       │   ├── package.json
│       │   └── processors
│       │       ├── __tests__
│       │       │   └── processSingleContentItem.test.ts
│       │       ├── processMultipleContentItems.ts
│       │       └── processSingleContentItem.ts
│       ├── dialog-base-view
│       │   ├── __tests__
│       │   │   └── DialogBaseView.test.js
│       │   ├── index.js
│       │   └── package.json
│       ├── differentiation-tags
│       │   ├── package.json
│       │   └── react
│       │       ├── DifferentiationTagModalForm
│       │       │   ├── DifferentiationTagModalForm.tsx
│       │       │   ├── DifferentiationTagModalManager.tsx
│       │       │   ├── TagInputRow.tsx
│       │       │   └── __tests__
│       │       │       ├── DifferentiationTagModalForm.test.tsx
│       │       │       ├── DifferentiationTagModalManager.test.tsx
│       │       │       └── TagInputRow.test.tsx
│       │       ├── DifferentiationTagTray
│       │       │   ├── DifferentiationTagSearch.tsx
│       │       │   ├── DifferentiationTagTray.tsx
│       │       │   ├── DifferentiationTagTrayManager.tsx
│       │       │   ├── TagCategoryCard.tsx
│       │       │   ├── TagInfo.tsx
│       │       │   └── __tests__
│       │       │       ├── DifferentiationTagSearch.test.tsx
│       │       │       ├── DifferentiationTagTray.test.tsx
│       │       │       ├── DifferentiationTagTrayManager.test.tsx
│       │       │       ├── TagCategoryCard.test.tsx
│       │       │       └── TagInfo.test.tsx
│       │       ├── UserDifferentiationTagManager
│       │       │   ├── UserDifferentiationTagManager.tsx
│       │       │   └── __tests__
│       │       │       └── UserDifferentiationTagManager.test.tsx
│       │       ├── UserTaggedModal
│       │       │   ├── UserTaggedModal.tsx
│       │       │   └── __tests__
│       │       │       └── UserTaggedModal.test.tsx
│       │       ├── WarningModal.tsx
│       │       ├── __tests__
│       │       │   └── WarningModal.test.tsx
│       │       ├── components
│       │       │   ├── TruncateTextWithTooltip.tsx
│       │       │   └── __tests__
│       │       │       └── TruncateTextWithTooltip.test.tsx
│       │       ├── hooks
│       │       │   ├── useAddTagMembership.tsx
│       │       │   ├── useBulkManageDifferentiationTags.tsx
│       │       │   ├── useDeleteDifferentiationTagCategory.tsx
│       │       │   ├── useDeleteTagMembership.tsx
│       │       │   ├── useDifferentiationTagCategoriesIndex.tsx
│       │       │   ├── useDifferentiationTagSet.tsx
│       │       │   └── useUserTags.tsx
│       │       ├── images
│       │       │   └── pandasBalloon.svg
│       │       ├── types.d.ts
│       │       └── util
│       │           ├── constants.tsx
│       │           └── tagCategoryCardMocks.ts
│       ├── direct-sharing
│       │   ├── package.json
│       │   └── react
│       │       ├── components
│       │       │   ├── AssignmentPicker.tsx
│       │       │   ├── ConfirmActionButtonBar.jsx
│       │       │   ├── ContentShareUserSearchSelector.css
│       │       │   ├── ContentShareUserSearchSelector.tsx
│       │       │   ├── CourseAndModulePicker.jsx
│       │       │   ├── DirectShareCoursePanel.css
│       │       │   ├── DirectShareCoursePanel.jsx
│       │       │   ├── DirectShareCourseTray.jsx
│       │       │   ├── DirectShareOperationStatus.jsx
│       │       │   ├── DirectShareUserModal.jsx
│       │       │   ├── DirectShareUserPanel.jsx
│       │       │   ├── ModulePositionPicker.jsx
│       │       │   ├── UserSearchSelectorItem.tsx
│       │       │   ├── __tests__
│       │       │   │   ├── ConfirmActionButtonBar.test.jsx
│       │       │   │   ├── ContentShareUserSearchSelector.test.jsx
│       │       │   │   ├── CourseAndModulePicker.test.jsx
│       │       │   │   ├── DirectShareCopyTo.test.jsx
│       │       │   │   ├── DirectShareCoursePanel.test.jsx
│       │       │   │   ├── DirectShareCourseTray.test.jsx
│       │       │   │   ├── DirectShareOperationStatus.test.jsx
│       │       │   │   ├── DirectShareSendTo.test.jsx
│       │       │   │   ├── DirectShareUserModal.test.jsx
│       │       │   │   └── ModulePositionPicker.test.jsx
│       │       │   └── queries
│       │       │       └── assignmentsByCourseIdQuery.ts
│       │       ├── effects
│       │       │   ├── __tests__
│       │       │   │   ├── useContentShareUserSearchApi.test.js
│       │       │   │   ├── useManagedCourseSearchApi.test.js
│       │       │   │   └── useModuleCourseSearchApi.test.js
│       │       │   ├── useContentShareUserSearchApi.js
│       │       │   ├── useManagedCourseSearchApi.js
│       │       │   └── useModuleCourseSearchApi.js
│       │       └── proptypes
│       │           └── contentSelection.js
│       ├── discussions
│       │   ├── backbone
│       │   │   ├── collections
│       │   │   │   ├── DiscussionEntriesCollection.js
│       │   │   │   └── ParticipantCollection.js
│       │   │   └── models
│       │   │       ├── Announcement.js
│       │   │       ├── DiscussionEntry.js
│       │   │       ├── DiscussionTopic.js
│       │   │       └── Participant.js
│       │   ├── jquery
│       │   │   ├── __tests__
│       │   │   │   └── assignmentRubricDialog.test.js
│       │   │   └── assignmentRubricDialog.js
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   ├── HeadingMenu.test.jsx
│       │       │   └── SearchField.test.jsx
│       │       ├── components
│       │       │   ├── AnonymousAvatar
│       │       │   │   ├── AnonymousAvatar.jsx
│       │       │   │   ├── AnonymousAvatar.stories.jsx
│       │       │   │   └── __tests__
│       │       │   │       └── AnonymousAvatar.test.jsx
│       │       │   ├── AnonymousResponseSelector
│       │       │   │   ├── AnonymousResponseSelector.jsx
│       │       │   │   ├── AnonymousResponseSelector.stories.jsx
│       │       │   │   └── __tests__
│       │       │   │       └── AnonymousResponseSelector.test.jsx
│       │       │   ├── AttachmentDisplay
│       │       │   │   ├── AttachmentButton.jsx
│       │       │   │   ├── AttachmentButton.stories.jsx
│       │       │   │   ├── AttachmentDisplay.jsx
│       │       │   │   ├── AttachmentDisplay.stories.jsx
│       │       │   │   ├── RemovableItem.jsx
│       │       │   │   ├── UploadButton.tsx
│       │       │   │   └── __tests__
│       │       │   │       ├── AttachmentDisplay.test.jsx
│       │       │   │       └── RemovableItem.test.jsx
│       │       │   ├── HeadingMenu.tsx
│       │       │   └── SearchField.tsx
│       │       └── utils
│       │           ├── constants.js
│       │           └── index.js
│       ├── do-fetch-api-effect
│       │   ├── __tests__
│       │   │   └── index.test.js
│       │   ├── apiRequest.ts
│       │   ├── index.ts
│       │   ├── package.json
│       │   └── types.ts
│       ├── download-submissions-modal
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   └── index.test.tsx
│       │       └── index.tsx
│       ├── due-dates
│       │   ├── AssignmentOverrideHelper.js
│       │   ├── __tests__
│       │   │   └── AssignmentOverrideHelper.spec.js
│       │   ├── backbone
│       │   │   ├── models
│       │   │   │   ├── DueDateList.js
│       │   │   │   └── __tests__
│       │   │   │       └── DueDateList.spec.js
│       │   │   └── views
│       │   │       ├── DueDateOverride.jsx
│       │   │       ├── MissingDateDialogView.js
│       │   │       └── __tests__
│       │   │           └── MissingDateDialogView.test.js
│       │   ├── jquery
│       │   │   └── vddTooltip.js
│       │   ├── jst
│       │   │   ├── missingDueDateDialog.handlebars
│       │   │   └── missingDueDateDialog.handlebars.json
│       │   ├── package.json
│       │   ├── react
│       │   │   ├── AssignToContent.jsx
│       │   │   ├── CoursePacingNotice.jsx
│       │   │   ├── DisabledTokenInput.jsx
│       │   │   ├── DueDateAddRowButton.jsx
│       │   │   ├── DueDateCalendarPicker.jsx
│       │   │   ├── DueDateCalendars.jsx
│       │   │   ├── DueDateRemoveRowLink.jsx
│       │   │   ├── DueDateRow.jsx
│       │   │   ├── DueDateTokenWrapper.jsx
│       │   │   ├── OverrideStudentStore.js
│       │   │   ├── StudentGroupStore.js
│       │   │   ├── TokenActions.js
│       │   │   └── __tests__
│       │   │       ├── AssignToContent.test.jsx
│       │   │       ├── CoursePacingNotice.test.jsx
│       │   │       ├── DisabledTokenInput.test.jsx
│       │   │       ├── DueDateAddRowButton.test.jsx
│       │   │       ├── DueDateCalendarPicker.test.jsx
│       │   │       ├── DueDateCalendars.test.jsx
│       │   │       ├── DueDateOverride.test.js
│       │   │       ├── DueDateRemoveRowLink.test.jsx
│       │   │       ├── DueDateRow.test.jsx
│       │   │       ├── DueDateTokenWrapper.test.jsx
│       │   │       ├── OverrideStudentStore.test.js
│       │   │       ├── StudentGroupStore.test.js
│       │   │       └── TokenActions.spec.js
│       │   └── util
│       │       ├── differentiatedModulesCardActions.js
│       │       ├── differentiatedModulesUtil.jsx
│       │       └── overridesUtils.js
│       ├── easy-student-view
│       │   ├── jquery
│       │   │   └── index.js
│       │   └── package.json
│       ├── editor-toggle
│       │   ├── backbone
│       │   │   └── views
│       │   │       ├── EditorToggle.jsx
│       │   │       └── __tests__
│       │   │           └── EditorToggle.test.js
│       │   ├── package.json
│       │   └── react
│       │       ├── SwitchEditorControl.jsx
│       │       └── __tests__
│       │           └── SwitchEditorControl.test.jsx
│       ├── emoji
│       │   ├── package.json
│       │   └── react
│       │       ├── EmojiPicker.jsx
│       │       ├── EmojiQuickPicker.jsx
│       │       ├── __tests__
│       │       │   ├── EmojiPicker.test.jsx
│       │       │   └── EmojiQuickPicker.test.jsx
│       │       └── index.jsx
│       ├── encrypted-forage
│       │   └── index.js
│       ├── enhanced-user-content
│       │   ├── jquery
│       │   │   ├── index.js
│       │   │   └── instructure_helper.js
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   └── showFilePreview.test.js
│       │       └── showFilePreview.jsx
│       ├── error-boundary
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   └── index.test.tsx
│       │       └── index.tsx
│       ├── escape-regex
│       │   ├── index.ts
│       │   └── package.json
│       ├── external-apps
│       │   ├── iframeAllowances.js
│       │   ├── package.json
│       │   └── react
│       │       ├── components
│       │       │   ├── ExternalAppsMenuPanel.tsx
│       │       │   └── ExternalAppsMenuTray.tsx
│       │       └── shared
│       │           └── types.tsx
│       ├── external-tools
│       │   ├── __tests__
│       │   │   └── messages.test.ts
│       │   ├── backbone
│       │   │   ├── models
│       │   │   │   ├── ExternalTool.js
│       │   │   │   └── __tests__
│       │   │   │       └── ExternalTool.spec.js
│       │   │   └── views
│       │   │       ├── ExternalContentReturnView.js
│       │   │       └── __tests__
│       │   │           └── ExternalContentReturnView.spec.js
│       │   ├── jst
│       │   │   ├── ExternalContentReturnView.handlebars
│       │   │   ├── ExternalContentReturnView.handlebars.json
│       │   │   ├── _external_tool_menuitem.handlebars
│       │   │   ├── _external_tool_menuitem.handlebars.json
│       │   │   ├── _external_tools_menu.handlebars
│       │   │   └── _external_tools_menu.handlebars.json
│       │   ├── messages.ts
│       │   ├── package.json
│       │   └── react
│       │       └── components
│       │           ├── ExternalToolModalLauncher.tsx
│       │           ├── ToolLaunchIframe.tsx
│       │           └── __tests__
│       │               ├── ExternalToolModalLauncher.test.tsx
│       │               └── ToolLaunchIframe.test.jsx
│       ├── feature-flags
│       │   ├── package.json
│       │   └── react
│       │       ├── ConfirmationDialog.jsx
│       │       ├── FeatureFlagButton.jsx
│       │       ├── FeatureFlagTable.jsx
│       │       ├── FeatureFlags.jsx
│       │       ├── StatusPill.jsx
│       │       ├── __tests__
│       │       │   ├── FeatureFlagButton.test.jsx
│       │       │   ├── FeatureFlagTable.test.jsx
│       │       │   ├── FeatureFlags.test.jsx
│       │       │   ├── StatusPill.test.jsx
│       │       │   ├── sampleData.json
│       │       │   └── util.test.js
│       │       └── util.jsx
│       ├── files
│       │   ├── backbone
│       │   │   ├── collections
│       │   │   │   └── FilesCollection.js
│       │   │   └── models
│       │   │       ├── File.js
│       │   │       ├── FilesystemObject.js
│       │   │       ├── Folder.js
│       │   │       ├── ModuleFile.js
│       │   │       └── __tests__
│       │   │           └── Folder.spec.js
│       │   ├── mockFilesENV.js
│       │   ├── package.json
│       │   ├── react
│       │   │   ├── components
│       │   │   │   ├── CurrentUploads.jsx
│       │   │   │   ├── DialogPreview.jsx
│       │   │   │   ├── FilePreview.jsx
│       │   │   │   ├── FilePreviewInfoPanel.jsx
│       │   │   │   ├── FileRenameForm.jsx
│       │   │   │   ├── FilesystemObjectThumbnail.jsx
│       │   │   │   ├── LegacyFileRenameForm.jsx
│       │   │   │   ├── LegacyFilesystemObjectThumbnail.js
│       │   │   │   ├── LegacyPublishCloud.js
│       │   │   │   ├── LegacyRestrictedDialogForm.js
│       │   │   │   ├── LegacyUsageRightsDialog.js
│       │   │   │   ├── PublishCloud.jsx
│       │   │   │   ├── RestrictedDialogForm.jsx
│       │   │   │   ├── RestrictedRadioButtons.jsx
│       │   │   │   ├── UploadForm.jsx
│       │   │   │   ├── UploadProgress.jsx
│       │   │   │   ├── UsageRightsDialog.jsx
│       │   │   │   ├── UsageRightsIndicator.jsx
│       │   │   │   ├── UsageRightsSelectBox.jsx
│       │   │   │   ├── ZipFileOptionsForm.jsx
│       │   │   │   └── __tests__
│       │   │   │       ├── CurrentUploads.test.jsx
│       │   │   │       ├── DialogPreview.test.jsx
│       │   │   │       ├── FilePreview.test.tsx
│       │   │   │       ├── FilePreviewInfoPanel.test.jsx
│       │   │   │       ├── FileRenameForm.test.jsx
│       │   │   │       ├── FilesystemObjectThumbnail.test.jsx
│       │   │   │       ├── FriendlyDatetime.test.jsx
│       │   │   │       ├── PublishCloud.test.jsx
│       │   │   │       ├── RestrictedDialogForm.test.jsx
│       │   │   │       ├── RestrictedRadioButtons.test.jsx
│       │   │   │       ├── UploadForm.test.jsx
│       │   │   │       ├── UploadProgress.test.jsx
│       │   │   │       ├── UsageRightsDialog.test.jsx
│       │   │   │       ├── UsageRightsIndicator.test.jsx
│       │   │   │       ├── UsageRightsSelectBox.test.jsx
│       │   │   │       └── ZipFileOptionsForm.test.jsx
│       │   │   ├── mixins
│       │   │   │   └── BackboneMixin.js
│       │   │   └── modules
│       │   │       ├── BaseUploader.js
│       │   │       ├── FileOptionsCollection.jsx
│       │   │       ├── FileUploader.js
│       │   │       ├── UploadQueue.js
│       │   │       ├── ZipUploader.js
│       │   │       ├── __tests__
│       │   │       │   ├── FileOptionsCollection.test.js
│       │   │       │   ├── FileOptionsCollection.test.ts
│       │   │       │   ├── FileUploader.test.js
│       │   │       │   ├── FileUploader.test.ts
│       │   │       │   ├── UploadQueue.test.js
│       │   │       │   └── ZipUploader.test.js
│       │   │       ├── customPropTypes.js
│       │   │       └── filesEnv.js
│       │   └── util
│       │       ├── __tests__
│       │       │   └── apiFileUtils.test.js
│       │       ├── apiFileUtils.js
│       │       ├── backboneIdentityMap.js
│       │       ├── collectionHandler.js
│       │       ├── friendlyBytes.js
│       │       ├── getFileStatus.js
│       │       ├── setUsageRights.js
│       │       └── updateModelsUsageRights.js
│       ├── files_v2
│       │   ├── package.json
│       │   └── react
│       │       └── modules
│       │           ├── filesEnvFactory.ts
│       │           └── filesEnvFactory.types.ts
│       ├── filter-bar
│       │   ├── index.ts
│       │   ├── package.json
│       │   └── react
│       │       ├── FilterBar.tsx
│       │       └── __tests__
│       │           └── FilterBar.test.tsx
│       ├── final-grade-override
│       │   ├── __tests__
│       │   │   ├── FinalGradeOverrideTextBox.test.tsx
│       │   │   └── finalGradeOverrideUtils.test.ts
│       │   ├── index.ts
│       │   ├── package.json
│       │   ├── react
│       │   │   └── index.tsx
│       │   └── utils
│       │       └── index.ts
│       ├── forms
│       │   ├── __tests__
│       │   │   └── sanitizeData.test.js
│       │   ├── backbone
│       │   │   └── views
│       │   │       ├── DialogFormView.js
│       │   │       ├── ValidatedFormView.js
│       │   │       ├── ValidatedMixin.js
│       │   │       └── __tests__
│       │   │           ├── DialogFormView.test.js
│       │   │           ├── ValidatedFormView.test.js
│       │   │           └── ValidatedMixin.test.js
│       │   ├── jquery
│       │   │   └── jquery.instructure_forms.js
│       │   ├── jst
│       │   │   ├── DialogFormWrapper.handlebars
│       │   │   ├── DialogFormWrapper.handlebars.json
│       │   │   ├── EmptyDialogFormWrapper.handlebars
│       │   │   └── EmptyDialogFormWrapper.handlebars.json
│       │   ├── package.json
│       │   ├── react
│       │   │   ├── field-group
│       │   │   │   ├── FieldGroup.css
│       │   │   │   ├── FieldGroup.tsx
│       │   │   │   └── __tests__
│       │   │   │       └── FieldGroup.test.tsx
│       │   │   └── react-hook-form
│       │   │       └── utils.ts
│       │   └── sanitizeData.js
│       ├── fuzzy-relative-time
│       │   ├── __tests__
│       │   │   └── index.test.ts
│       │   ├── index.ts
│       │   └── package.json
│       ├── generate-pairing-code
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   └── index.test.jsx
│       │       └── index.jsx
│       ├── generic-error-page
│       │   ├── package.json
│       │   └── react
│       │       ├── ErrorPageHeader.jsx
│       │       ├── ErrorTextInputForm.jsx
│       │       ├── NotFoundArtwork.jsx
│       │       ├── __tests__
│       │       │   ├── NotFoundArtwork.test.jsx
│       │       │   └── index.test.jsx
│       │       └── index.jsx
│       ├── global
│       │   ├── DateRange.d.ts
│       │   ├── env
│       │   │   ├── ContentMigrations.d.ts
│       │   │   ├── EnvAccounts.d.ts
│       │   │   ├── EnvAlerts.d.ts
│       │   │   ├── EnvAssignments.d.ts
│       │   │   ├── EnvChangePassword.d.ts
│       │   │   ├── EnvCommon.d.ts
│       │   │   ├── EnvContextModules.d.ts
│       │   │   ├── EnvCourse.d.ts
│       │   │   ├── EnvCoursePaces.d.ts
│       │   │   ├── EnvDeepLinking.d.ts
│       │   │   ├── EnvDeveloperKeys.d.ts
│       │   │   ├── EnvDiscussions.d.ts
│       │   │   ├── EnvGradebook.d.ts
│       │   │   ├── EnvGradingStandards.d.ts
│       │   │   ├── EnvHorizon.d.ts
│       │   │   ├── EnvLtiRegistrations.d.ts
│       │   │   ├── EnvOutcomes.d.ts
│       │   │   ├── EnvPermissions.d.ts
│       │   │   ├── EnvPlatformStorage.d.ts
│       │   │   ├── EnvPortfolio.d.ts
│       │   │   ├── EnvProfiles.d.ts
│       │   │   ├── EnvRce.d.ts
│       │   │   ├── EnvReleaseNotes.d.ts
│       │   │   ├── EnvSmartSearch.d.ts
│       │   │   ├── EnvUserMerge.d.ts
│       │   │   ├── EnvWikiPages.d.ts
│       │   │   └── GlobalEnv.d.ts
│       │   ├── inst
│       │   │   ├── GlobalInst.d.ts
│       │   │   ├── InstClientCommon.d.ts
│       │   │   ├── InstServerCommon.d.ts
│       │   │   └── InstSpeedGrader.d.ts
│       │   ├── package.json
│       │   └── remotes
│       │       └── GlobalRemotes.d.ts
│       ├── grade-summary
│       │   ├── backbone
│       │   │   └── models
│       │   │       ├── Outcome.js
│       │   │       └── __tests__
│       │   │           └── Outcome.spec.js
│       │   ├── package.json
│       │   └── react
│       │       ├── IndividualStudentMastery
│       │       │   ├── AssignmentResult.jsx
│       │       │   ├── NaiveFetchDispatch.js
│       │       │   ├── Outcome.jsx
│       │       │   ├── OutcomeGroup.jsx
│       │       │   ├── OutcomePopover.jsx
│       │       │   ├── UnassessedAssignment.jsx
│       │       │   ├── __tests__
│       │       │   │   ├── AssignmentResult.test.jsx
│       │       │   │   ├── NaiveFetchDispatch.test.js
│       │       │   │   ├── Outcome.test.jsx
│       │       │   │   ├── OutcomeGroup.test.jsx
│       │       │   │   ├── OutcomePopover.test.jsx
│       │       │   │   ├── UnassessedAssignment.test.jsx
│       │       │   │   ├── __snapshots__
│       │       │   │   │   └── AssignmentResult.test.jsx.snap
│       │       │   │   ├── fetchOutcomes.test.js
│       │       │   │   ├── index.test.jsx
│       │       │   │   └── scoreCalculation.test.js
│       │       │   ├── fetchOutcomes.js
│       │       │   ├── index.jsx
│       │       │   ├── scoreCalculation.js
│       │       │   └── shapes.js
│       │       ├── TruncateWithTooltip.jsx
│       │       └── __tests__
│       │           └── TruncateWithTooltip.test.jsx
│       ├── gradebook-content-filters
│       │   ├── package.json
│       │   └── react
│       │       ├── ContentFilter.jsx
│       │       └── SectionFilter.jsx
│       ├── gradebook-menu
│       │   ├── package.json
│       │   └── react
│       │       ├── GradebookMenu.tsx
│       │       └── __tests__
│       │           └── GradebookMenu.test.tsx
│       ├── grading
│       │   ├── AssignmentGroupGradeCalculator.ts
│       │   ├── CalculationMethodContent.js
│       │   ├── CourseGradeCalculator.ts
│       │   ├── DateValidator.js
│       │   ├── DownloadSubmissionsDialogManager.ts
│       │   ├── EffectiveDueDates.ts
│       │   ├── FinalGradeOverrideApi.ts
│       │   ├── Fixtures.js
│       │   ├── GradeCalculationHelper.ts
│       │   ├── GradeCalculatorSpecHelper.js
│       │   ├── GradeEntry
│       │   │   ├── GradeOverrideEntry.ts
│       │   │   ├── GradeOverrideInfo.ts
│       │   │   ├── __tests__
│       │   │   │   ├── GradeOverrideEntry.test.ts
│       │   │   │   └── GradeOverrideInfo.test.ts
│       │   │   └── index.ts
│       │   ├── GradeFormatHelper.ts
│       │   ├── GradeInputHelper.ts
│       │   ├── GradeOverride.ts
│       │   ├── GradebookTranslations.ts
│       │   ├── GradingPeriodsHelper.ts
│       │   ├── GradingSchemeHelper.ts
│       │   ├── OutlierScoreHelper.ts
│       │   ├── SubmissionHelper.ts
│       │   ├── SubmissionStateMap.ts
│       │   ├── SubmissionStateMap.utils.ts
│       │   ├── TimeLateInput.tsx
│       │   ├── Turnitin.ts
│       │   ├── __tests__
│       │   │   ├── AssignmentGroupGradeCalculator1.test.js
│       │   │   ├── AssignmentGroupGradeCalculator2.test.js
│       │   │   ├── AssignmentGroupGradeCalculator3.test.js
│       │   │   ├── AssignmentGroupGradeCalculator4.test.js
│       │   │   ├── CourseGradeCalculator1.test.js
│       │   │   ├── CourseGradeCalculator2.test.js
│       │   │   ├── CourseGradeCalculator3.test.js
│       │   │   ├── CourseGradeCalculator4.test.js
│       │   │   ├── CourseGradeCalculator5.test.js
│       │   │   ├── DateValidator.spec.js
│       │   │   ├── EffectiveDueDates.spec.js
│       │   │   ├── FinalGradeOverrideApi.test.ts
│       │   │   ├── GradeCalculationHelper.spec.js
│       │   │   ├── GradeFormatHelper1.test.js
│       │   │   ├── GradeFormatHelper2.test.js
│       │   │   ├── GradeFormatHelper_quantitative.test.js
│       │   │   ├── GradeFormatHelper_submission.test.js
│       │   │   ├── GradeInputHelper.spec.js
│       │   │   ├── GradeOverride.test.ts
│       │   │   ├── GradingPeriodsHelper.spec.js
│       │   │   ├── GradingSchemeHelper.spec.js
│       │   │   ├── OutlierScoreHelper.spec.js
│       │   │   ├── SubmissionHelper.spec.js
│       │   │   ├── SubmissionStateMap.test.ts
│       │   │   ├── SubmissionStateMapGradeVisibility.spec.js
│       │   │   ├── SubmissionStateMapGradingPeriodInfo.spec.js
│       │   │   ├── SubmissionStateMapLocking.spec.js
│       │   │   ├── TimeLateInput.test.tsx
│       │   │   ├── Turnitin.spec.js
│       │   │   └── messageStudentsWhoHelper.test.js
│       │   ├── accountGradingStatus.d.ts
│       │   ├── content-filters
│       │   │   └── ContentFilterDriver.js
│       │   ├── grading.d.ts
│       │   ├── jquery
│       │   │   ├── CurveGradesDialog.js
│       │   │   ├── SetDefaultGradeDialog.jsx
│       │   │   ├── __tests__
│       │   │   │   ├── SetDefaultGradeDialog1.test.js
│       │   │   │   ├── SetDefaultGradeDialog2.test.js
│       │   │   │   ├── gradingPeriodSetsApi.test.js
│       │   │   │   └── gradingPeriodsApi.test.js
│       │   │   ├── gradingPeriodSetsApi.ts
│       │   │   └── gradingPeriodsApi.ts
│       │   ├── jst
│       │   │   ├── CurveGradesDialog.handlebars
│       │   │   ├── CurveGradesDialog.handlebars.json
│       │   │   ├── SetDefaultGradeDialog.handlebars
│       │   │   ├── SetDefaultGradeDialog.handlebars.json
│       │   │   ├── _grading_box.handlebars
│       │   │   ├── _grading_box.handlebars.json
│       │   │   ├── _plagiarismScore.handlebars
│       │   │   ├── _plagiarismScore.handlebars.json
│       │   │   ├── _turnitinScore.handlebars
│       │   │   ├── _turnitinScore.handlebars.json
│       │   │   ├── _vericiteScore.handlebars
│       │   │   ├── _vericiteScore.handlebars.json
│       │   │   ├── re_upload_submissions_form.handlebars
│       │   │   └── re_upload_submissions_form.handlebars.json
│       │   ├── messageStudentsWhoHelper.ts
│       │   ├── originalityReportHelper.ts
│       │   ├── package.json
│       │   └── react
│       │       ├── CheckpointsDefaultGradeInfo.tsx
│       │       ├── CheckpointsGradeInputs.tsx
│       │       ├── DefaultGradeInput.tsx
│       │       ├── SpecificSections.tsx
│       │       └── __tests__
│       │           ├── CheckpointsGradeInputs.test.tsx
│       │           ├── DefaultGradeInput.test.tsx
│       │           └── SpecificSections.test.jsx
│       ├── grading-standard-collection
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   ├── DataRow.test.jsx
│       │       │   ├── GradingStandard.test.jsx
│       │       │   └── GradingStandardCollection.test.jsx
│       │       ├── dataRow.jsx
│       │       ├── gradingStandard.jsx
│       │       └── index.jsx
│       ├── grading-standards
│       │   ├── jquery
│       │   │   └── index.js
│       │   └── package.json
│       ├── grading-status-list-item
│       │   ├── GradingStatusListItemColors.ts
│       │   ├── index.ts
│       │   ├── package.json
│       │   └── react
│       │       └── index.tsx
│       ├── grading-status-pill
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   └── StatusPill.test.jsx
│       │       └── index.jsx
│       ├── grading_scheme
│       │   ├── defaultPointsGradingScheme.ts
│       │   ├── gradingSchemeApiModel.d.ts
│       │   ├── index.ts
│       │   ├── package.json
│       │   └── react
│       │       ├── components
│       │       │   ├── GradingSchemeCreateModal.tsx
│       │       │   ├── GradingSchemeDeleteModal.tsx
│       │       │   ├── GradingSchemeDuplicateModal.tsx
│       │       │   ├── GradingSchemeEditModal.tsx
│       │       │   ├── GradingSchemeTable.tsx
│       │       │   ├── GradingSchemeUsedLocationsModal.tsx
│       │       │   ├── GradingSchemeViewCopyTemplateModal.tsx
│       │       │   ├── GradingSchemeViewEditModal.tsx
│       │       │   ├── GradingSchemeViewModal.tsx
│       │       │   ├── GradingSchemesManagement.tsx
│       │       │   ├── GradingSchemesSelector.tsx
│       │       │   ├── UsedLocationsModal.tsx
│       │       │   ├── __tests__
│       │       │   │   ├── GradingSchemeCreateModal.test.tsx
│       │       │   │   ├── GradingSchemeDeleteModal.test.tsx
│       │       │   │   ├── GradingSchemeDuplicateModal.test.tsx
│       │       │   │   ├── GradingSchemeEditModal.test.tsx
│       │       │   │   ├── GradingSchemeTable.test.tsx
│       │       │   │   ├── GradingSchemeUsedLocationsModal.test.tsx
│       │       │   │   ├── GradingSchemeViewEditModal.test.tsx
│       │       │   │   ├── GradingSchemeViewModal.test.tsx
│       │       │   │   ├── GradingSchemesManagement.test.tsx
│       │       │   │   ├── GradingSchemesSelector.test.tsx
│       │       │   │   └── fixtures.ts
│       │       │   ├── form
│       │       │   │   ├── AccountDefaultSelector.tsx
│       │       │   │   ├── GradingSchemeDataRowInput.tsx
│       │       │   │   ├── GradingSchemeInput.tsx
│       │       │   │   ├── GradingSchemeValidationAlert.tsx
│       │       │   │   ├── __tests__
│       │       │   │   │   ├── AccountDefaultSelector.test.tsx
│       │       │   │   │   ├── GradingSchemeDataRowInput.test.tsx
│       │       │   │   │   ├── GradingSchemeInput.test.tsx
│       │       │   │   │   └── fixtures.ts
│       │       │   │   └── validations
│       │       │   │       └── gradingSchemeValidations.ts
│       │       │   └── view
│       │       │       ├── GradingSchemeDataRowView.tsx
│       │       │       ├── GradingSchemeTemplateView.tsx
│       │       │       ├── GradingSchemeView.tsx
│       │       │       └── __tests__
│       │       │           ├── GradingSchemeTemplateView.test.tsx
│       │       │           ├── GradingSchemeView.test.tsx
│       │       │           └── fixtures.ts
│       │       ├── helpers
│       │       │   ├── calculateHighRangeForDataRow.ts
│       │       │   ├── gradingSchemePermissions.ts
│       │       │   └── roundDecimalPlaces.ts
│       │       └── hooks
│       │           ├── ApiCallStatus.ts
│       │           ├── __tests__
│       │           │   ├── useAccountDefaultGradingScheme.test.ts
│       │           │   ├── useAccountDefaultGradingSchemeUpdate.test.ts
│       │           │   ├── useDefaultGradingScheme.test.ts
│       │           │   ├── useGradingScheme.test.ts
│       │           │   ├── useGradingSchemeCreate.test.ts
│       │           │   ├── useGradingSchemeDelete.test.ts
│       │           │   ├── useGradingSchemeSummaries.test.ts
│       │           │   ├── useGradingSchemeUpdate.test.ts
│       │           │   └── useGradingSchemes.test.ts
│       │           ├── buildContextPath.ts
│       │           ├── useAccountDefaultGradingScheme.ts
│       │           ├── useAccountDefaultGradingSchemeUpdate.ts
│       │           ├── useDefaultGradingScheme.ts
│       │           ├── useGradingScheme.ts
│       │           ├── useGradingSchemeAccountUsedLocations.ts
│       │           ├── useGradingSchemeArchive.ts
│       │           ├── useGradingSchemeAssignmentUsedLocations.ts
│       │           ├── useGradingSchemeCreate.ts
│       │           ├── useGradingSchemeDelete.ts
│       │           ├── useGradingSchemeSummaries.ts
│       │           ├── useGradingSchemeUnarchive.ts
│       │           ├── useGradingSchemeUpdate.ts
│       │           ├── useGradingSchemeUsedLocations.ts
│       │           └── useGradingSchemes.ts
│       ├── graphql
│       │   └── Error.js
│       ├── graphql-query-mock
│       │   ├── README.md
│       │   ├── __tests__
│       │   │   └── index.test.js
│       │   ├── index.js
│       │   └── package.json
│       ├── group-modal
│       │   ├── package.json
│       │   └── react
│       │       ├── GroupMembershipInput.jsx
│       │       ├── __tests__
│       │       │   ├── GroupMembershipInput.test.jsx
│       │       │   └── index.test.jsx
│       │       └── index.jsx
│       ├── group-navigation-selector
│       │   ├── GroupNavigationSelector.tsx
│       │   ├── GroupNavigationSelectorRoute.tsx
│       │   └── package.json
│       ├── groups
│       │   ├── backbone
│       │   │   ├── collections
│       │   │   │   ├── ContextGroupCollection.js
│       │   │   │   ├── GroupCategoryCollection.js
│       │   │   │   ├── GroupCollection.js
│       │   │   │   ├── GroupUserCollection.js
│       │   │   │   ├── UnassignedGroupUserCollection.js
│       │   │   │   └── __tests__
│       │   │   │       ├── ContextGroupCollection.spec.js
│       │   │   │       ├── GroupUserCollection.spec.js
│       │   │   │       └── UnassignedGroupUserCollection.spec.js
│       │   │   ├── models
│       │   │   │   ├── Group.js
│       │   │   │   ├── GroupCategory.js
│       │   │   │   ├── GroupUser.js
│       │   │   │   └── __tests__
│       │   │   │       └── GroupUser.test.js
│       │   │   └── views
│       │   │       ├── GroupCategoryEditView.jsx
│       │   │       ├── GroupCategorySelector.js
│       │   │       └── __tests__
│       │   │           └── GroupCategorySelector.test.js
│       │   ├── jst
│       │   │   ├── GroupCategorySelector.handlebars
│       │   │   ├── GroupCategorySelector.handlebars.json
│       │   │   ├── _autoLeadershipControls.handlebars
│       │   │   ├── _autoLeadershipControls.handlebars.json
│       │   │   ├── _selfSignupHelp.handlebars
│       │   │   ├── _selfSignupHelp.handlebars.json
│       │   │   ├── groupCategoryEdit.handlebars
│       │   │   └── groupCategoryEdit.handlebars.json
│       │   ├── package.json
│       │   └── react
│       │       ├── CreateOrEditSetModal
│       │       │   ├── AssignmentProgress.jsx
│       │       │   ├── GroupSetName.jsx
│       │       │   ├── GroupStructure.jsx
│       │       │   ├── Leadership.jsx
│       │       │   ├── SelfSignup.jsx
│       │       │   ├── SelfSignupEndDate.tsx
│       │       │   ├── __tests__
│       │       │   │   ├── CreateOrEditSetModal.test.jsx
│       │       │   │   ├── GroupSetName.test.jsx
│       │       │   │   ├── Leadership.test.jsx
│       │       │   │   ├── SelfSignup.test.jsx
│       │       │   │   └── SelfSignupEndDate.test.tsx
│       │       │   ├── context.js
│       │       │   ├── index.jsx
│       │       │   └── utils
│       │       │       └── index.js
│       │       ├── Filter.jsx
│       │       ├── Group.jsx
│       │       ├── GroupLimitInput.tsx
│       │       ├── GroupSetNameInput.tsx
│       │       ├── ManageGroupDialog.jsx
│       │       ├── NewStudentGroupModal.jsx
│       │       ├── PaginatedGroupList.jsx
│       │       ├── PaginatedUserCheckList.jsx
│       │       ├── __tests__
│       │       │   ├── GroupLimitInput.test.tsx
│       │       │   ├── GroupSetNameInput.test.tsx
│       │       │   └── NewStudentGroupModal.test.jsx
│       │       ├── components
│       │       │   ├── StudentMultiSelect.tsx
│       │       │   └── __tests__
│       │       │       └── StudentMultiSelect.test.tsx
│       │       ├── index.jsx
│       │       ├── mixins
│       │       │   ├── BackboneState.js
│       │       │   └── InfiniteScroll.jsx
│       │       └── queries
│       │           └── studentsQuery.ts
│       ├── handlebars-helpers
│       │   ├── __tests__
│       │   │   ├── enrollmentName.spec.js
│       │   │   └── handlebars_helpers.test.js
│       │   ├── dateSelect.js
│       │   ├── enrollmentName.js
│       │   ├── index.js
│       │   └── package.json
│       ├── help-dialog
│       │   ├── images
│       │   │   └── panda-map.svg
│       │   ├── index.tsx
│       │   ├── package.json
│       │   ├── queries
│       │   │   └── helpLinksQuery.ts
│       │   └── react
│       │       ├── CreateTicketForm.tsx
│       │       ├── FeaturedHelpLink.tsx
│       │       ├── HelpLinks.tsx
│       │       ├── TeacherFeedbackForm.jsx
│       │       ├── __tests__
│       │       │   ├── CreateTicketForm.test.tsx
│       │       │   ├── FeaturedHelpLink.test.jsx
│       │       │   ├── HelpLinks.test.jsx
│       │       │   ├── TeacherFeedbackForm.test.jsx
│       │       │   └── loginHelp.test.tsx
│       │       ├── index.tsx
│       │       └── loginHelp.tsx
│       ├── hide-assignment-grades-tray
│       │   ├── package.json
│       │   └── react
│       │       ├── Api.js
│       │       ├── Description.jsx
│       │       ├── FormContent.jsx
│       │       ├── Layout.jsx
│       │       ├── __tests__
│       │       │   ├── Api.test.js
│       │       │   ├── FormContent.test.jsx
│       │       │   ├── HideAssignmentGradesTray.test.jsx
│       │       │   └── Layout.test.jsx
│       │       └── index.jsx
│       ├── i18n
│       │   ├── __tests__
│       │   │   ├── i18n.test.js
│       │   │   ├── numberFormat.spec.js
│       │   │   ├── numberHelper.test.js
│       │   │   └── rtlHelper.spec.js
│       │   ├── i18nLolcalize.js
│       │   ├── i18nObj.js
│       │   ├── logEagerLookupViolations.js
│       │   ├── numberFormat.ts
│       │   ├── numberHelper.ts
│       │   ├── package.json
│       │   ├── parse-decimal-number.d.ts
│       │   └── rtlHelper.js
│       ├── ignite-ai-icon
│       │   ├── package.json
│       │   └── react
│       │       └── IgniteAiIcon.tsx
│       ├── images
│       │   ├── ConfusedPanda.svg
│       │   ├── ErrorShip.svg
│       │   ├── PageNotFoundPanda.svg
│       │   ├── ScreenCaptureIcon.svg
│       │   ├── SpacePanda.svg
│       │   ├── package.json
│       │   └── react
│       │       └── EmptyDesert.jsx
│       ├── immersive-reader
│       │   ├── ContentChunker.ts
│       │   ├── ContentUtils.ts
│       │   ├── Formatter.ts
│       │   ├── ImmersiveReader.jsx
│       │   ├── __tests__
│       │   │   ├── ContentChunker.test.ts
│       │   │   ├── ContentUtils.test.ts
│       │   │   └── ImmersiveReader.test.jsx
│       │   ├── formatters
│       │   │   ├── Formatter.d.ts
│       │   │   ├── __tests__
│       │   │   │   └── spacing.test.ts
│       │   │   └── spacing.ts
│       │   └── package.json
│       ├── infinite-scroll
│       │   ├── package.json
│       │   └── react
│       │       └── components
│       │           ├── InfiniteScroll.jsx
│       │           └── __tests__
│       │               └── InfiniteScroll.test.jsx
│       ├── instui-bindings
│       │   ├── package.json
│       │   └── react
│       │       ├── Alert.tsx
│       │       ├── AsyncSelect.tsx
│       │       ├── Confirm.tsx
│       │       ├── ConfirmWithPrompt.tsx
│       │       ├── InstuiModal.tsx
│       │       ├── Modal.tsx
│       │       ├── Paginator.tsx
│       │       ├── Select.tsx
│       │       ├── __tests__
│       │       │   ├── AsyncSelect.test.jsx
│       │       │   ├── Confirm.test.tsx
│       │       │   ├── ConfirmWithPrompt.test.tsx
│       │       │   ├── Modal.test.jsx
│       │       │   ├── Paginator.spec.jsx
│       │       │   └── Select.test.jsx
│       │       └── liveRegion.ts
│       ├── integrations
│       │   ├── package.json
│       │   └── react
│       │       ├── accounts
│       │       │   └── microsoft_sync
│       │       │       ├── MicrosoftSyncAccountSettings.jsx
│       │       │       ├── __tests__
│       │       │       │   ├── ActiveDirectoryLookupAttributeSelector.test.jsx
│       │       │       │   ├── AdminConsentLink.test.jsx
│       │       │       │   ├── LoginAttributeSelector.test.jsx
│       │       │       │   ├── LoginAttributeSuffixInput.test.jsx
│       │       │       │   ├── MicrosoftSyncAccountSettings.test.jsx
│       │       │       │   ├── MicrosoftSyncTitle.test.jsx
│       │       │       │   ├── TenantInput.test.jsx
│       │       │       │   ├── settingsHelper.test.js
│       │       │       │   ├── settingsReducer1.test.js
│       │       │       │   ├── settingsReducer2.test.js
│       │       │       │   └── useSettings.test.js
│       │       │       ├── components
│       │       │       │   ├── ActiveDirectoryLookupAttributeSelector.jsx
│       │       │       │   ├── AdminConsentLink.jsx
│       │       │       │   ├── LoginAttributeSelector.jsx
│       │       │       │   ├── LoginAttributeSuffixInput.jsx
│       │       │       │   ├── MicrosoftSyncTitle.jsx
│       │       │       │   └── TenantInput.jsx
│       │       │       └── lib
│       │       │           ├── settingsHelper.js
│       │       │           ├── settingsReducer.js
│       │       │           └── useSettings.js
│       │       └── courses
│       │           ├── IntegrationRow.jsx
│       │           ├── Integrations.jsx
│       │           ├── __tests__
│       │           │   ├── IntegrationRow.test.jsx
│       │           │   └── Integrations.test.jsx
│       │           └── microsoft_sync
│       │               ├── MicrosoftSync.jsx
│       │               ├── MicrosoftSyncButton.jsx
│       │               ├── MicrosoftSyncDebugInfo.jsx
│       │               ├── __tests__
│       │               │   ├── MicrosoftSync.test.jsx
│       │               │   ├── MicrosoftSyncButton.test.jsx
│       │               │   ├── MicrosoftSyncDebugInfo.test.jsx
│       │               │   └── useSettings.test.js
│       │               └── useSettings.jsx
│       ├── jest-moxios-utils
│       │   ├── __tests__
│       │   │   └── index.spec.js
│       │   ├── index.js
│       │   └── package.json
│       ├── jquery
│       │   ├── FakeXHR.js
│       │   ├── __tests__
│       │   │   ├── ajaxJSON.test.js
│       │   │   ├── formToJSON.test.js
│       │   │   ├── jQuery.instructureMiscPlugins.test.js
│       │   │   ├── jquery.test.js
│       │   │   ├── jqueryUiUnpatchedAutocomplete.test.js
│       │   │   ├── jqueryUiUnpatchedButton.test.js
│       │   │   ├── jqueryUiUnpatchedDatepicker.test.js
│       │   │   ├── jqueryUiUnpatchedDialog.test.js
│       │   │   ├── jqueryUiUnpatchedDraggable.test.js
│       │   │   ├── jqueryUiUnpatchedDroppable.test.js
│       │   │   ├── jqueryUiUnpatchedMenu.test.js
│       │   │   ├── jqueryUiUnpatchedMouse.test.js
│       │   │   ├── jqueryUiUnpatchedPosition.test.js
│       │   │   ├── jqueryUiUnpatchedProgressbar.test.js
│       │   │   ├── jqueryUiUnpatchedResizable.test.js
│       │   │   ├── jqueryUiUnpatchedSortable.test.js
│       │   │   ├── jqueryUiUnpatchedTabs.test.js
│       │   │   └── jqueryUiUnpatchedTooltip.test.js
│       │   ├── jquery.ajaxJSON.js
│       │   ├── jquery.disableWhileLoading.js
│       │   ├── jquery.instructure_forms.js
│       │   ├── jquery.instructure_jquery_patches.js
│       │   ├── jquery.instructure_misc_helpers.js
│       │   ├── jquery.instructure_misc_plugins.js
│       │   ├── jquery.simulate.js
│       │   ├── jquery.toJSON.js
│       │   ├── jquery.tree.js
│       │   └── package.json
│       ├── jquery-keycodes
│       │   ├── jquery.keycodes.d.ts
│       │   ├── jquery.keycodes.js
│       │   └── package.json
│       ├── jquery-sticky
│       │   ├── __tests__
│       │   │   └── sticky.spec.js
│       │   ├── index.js
│       │   └── package.json
│       ├── k5
│       │   ├── images
│       │   │   ├── empty-dashboard.svg
│       │   │   └── empty-groups.svg
│       │   ├── package.json
│       │   ├── react
│       │   │   ├── AppsList.jsx
│       │   │   ├── EmptyDashboardState.jsx
│       │   │   ├── EmptyK5Announcement.jsx
│       │   │   ├── GroupsPage.jsx
│       │   │   ├── ImportantInfo.jsx
│       │   │   ├── ImportantInfoLayout.jsx
│       │   │   ├── K5Announcement.jsx
│       │   │   ├── K5AppLink.jsx
│       │   │   ├── K5DashboardContext.js
│       │   │   ├── K5Tabs.jsx
│       │   │   ├── LoadingSkeleton.jsx
│       │   │   ├── LoadingWrapper.jsx
│       │   │   ├── ResourcesPage.jsx
│       │   │   ├── SchedulePage.jsx
│       │   │   ├── StaffContactInfoLayout.jsx
│       │   │   ├── StaffInfo.jsx
│       │   │   ├── TeacherGroupsPage.jsx
│       │   │   ├── __tests__
│       │   │   │   ├── AppsList.test.jsx
│       │   │   │   ├── EmptyK5Announcement.test.jsx
│       │   │   │   ├── ImportantInfo.test.jsx
│       │   │   │   ├── ImportantInfoLayout.test.jsx
│       │   │   │   ├── K5Announcement.test.jsx
│       │   │   │   ├── K5AppLink.test.jsx
│       │   │   │   ├── LoadingSkeleton.test.jsx
│       │   │   │   ├── LoadingWrapper.test.jsx
│       │   │   │   ├── ResourcesPage.test.jsx
│       │   │   │   ├── StaffContactInfoLayout.test.jsx
│       │   │   │   ├── StaffInfo.test.jsx
│       │   │   │   ├── fixtures.js
│       │   │   │   ├── k5-theme.test.js
│       │   │   │   └── utils.test.js
│       │   │   ├── hooks
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── usePlanner.test.jsx
│       │   │   │   │   └── useTabState.test.jsx
│       │   │   │   ├── usePlanner.js
│       │   │   │   └── useTabState.js
│       │   │   ├── k5-theme.ts
│       │   │   └── utils.js
│       │   └── redux
│       │       ├── __tests__
│       │       │   └── redux-helpers.test.js
│       │       └── redux-helpers.js
│       ├── keyboard-nav-dialog
│       │   ├── backbone
│       │   │   └── views
│       │   │       └── index.js
│       │   ├── jst
│       │   │   ├── KeyboardNavDialog.handlebars
│       │   │   └── KeyboardNavDialog.handlebars.json
│       │   └── package.json
│       ├── lazy-load
│       │   ├── package.json
│       │   └── react
│       │       └── LazyLoad.jsx
│       ├── list-view-checkpoints
│       │   ├── package.json
│       │   └── react
│       │       ├── ListViewCheckpoints.tsx
│       │       ├── TeacherCheckpointsInfo.tsx
│       │       └── __tests__
│       │           ├── ListViewCheckpoints.test.tsx
│       │           ├── TeacherCheckpointsInfo.test.tsx
│       │           └── mocks.tsx
│       ├── loading-image
│       │   ├── jquery
│       │   │   ├── index.d.ts
│       │   │   └── index.js
│       │   └── package.json
│       ├── loading-indicator
│       │   ├── package.json
│       │   └── react
│       │       └── index.tsx
│       ├── lock-icon
│       │   ├── backbone
│       │   │   └── views
│       │   │       ├── Button.js
│       │   │       ├── __tests__
│       │   │       │   └── Button.spec.js
│       │   │       └── index.js
│       │   └── package.json
│       ├── lti
│       │   ├── jquery
│       │   │   ├── __tests__
│       │   │   │   ├── ToolInline.test.js
│       │   │   │   ├── messages.test.js
│       │   │   │   ├── platform_storage.test.ts
│       │   │   │   ├── response_messages.test.js
│       │   │   │   └── tool_launch_resizer.test.js
│       │   │   ├── constants.ts
│       │   │   ├── lti_message_handler.ts
│       │   │   ├── messages.ts
│       │   │   ├── platform_storage.ts
│       │   │   ├── response_messages.ts
│       │   │   ├── subjects
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── hideNavigationMenu.test.js
│       │   │   │   │   ├── lti.close.test.ts
│       │   │   │   │   ├── lti.getPageContent.test.js
│       │   │   │   │   ├── lti.getPageSettings.test.js
│       │   │   │   │   ├── lti.get_data.test.ts
│       │   │   │   │   ├── lti.put_data.test.ts
│       │   │   │   │   ├── lti.resourceImported.test.js
│       │   │   │   │   ├── lti.screenReaderAlert.test.js
│       │   │   │   │   ├── lti.showAlert.test.js
│       │   │   │   │   ├── requestFullWindowLaunch.test.js
│       │   │   │   │   └── showNavigationMenu.test.js
│       │   │   │   ├── hideNavigationMenu.ts
│       │   │   │   ├── lti.capabilities.ts
│       │   │   │   ├── lti.close.ts
│       │   │   │   ├── lti.enableScrollEvents.ts
│       │   │   │   ├── lti.fetchWindowSize.ts
│       │   │   │   ├── lti.frameResize.ts
│       │   │   │   ├── lti.getPageContent.ts
│       │   │   │   ├── lti.getPageSettings.ts
│       │   │   │   ├── lti.get_data.ts
│       │   │   │   ├── lti.hideRightSideWrapper.ts
│       │   │   │   ├── lti.put_data.ts
│       │   │   │   ├── lti.removeUnloadMessage.ts
│       │   │   │   ├── lti.resourceImported.ts
│       │   │   │   ├── lti.screenReaderAlert.ts
│       │   │   │   ├── lti.scrollToTop.ts
│       │   │   │   ├── lti.setUnloadMessage.ts
│       │   │   │   ├── lti.showAlert.ts
│       │   │   │   ├── lti.showModuleNavigation.ts
│       │   │   │   ├── requestFullWindowLaunch.ts
│       │   │   │   ├── showNavigationMenu.ts
│       │   │   │   └── toggleCourseNavigationMenu.ts
│       │   │   ├── tool_launch_resizer.ts
│       │   │   └── util.ts
│       │   ├── model
│       │   │   ├── AssetProcessor.ts
│       │   │   ├── LtiScope.ts
│       │   │   ├── __tests__
│       │   │   │   └── LtiScope.test.ts
│       │   │   ├── common.ts
│       │   │   └── i18nLtiScope.ts
│       │   ├── package.json
│       │   └── react
│       │       ├── LtiToolIcon.tsx
│       │       └── __tests__
│       │           └── LtiToolIcon.test.jsx
│       ├── lti-apps
│       │   ├── components
│       │   │   ├── Discover.tsx
│       │   │   ├── InstructorApps.tsx
│       │   │   ├── ProductDetail
│       │   │   │   ├── Badges.tsx
│       │   │   │   ├── ExternalLinks.tsx
│       │   │   │   ├── IntegrationDetailModal.tsx
│       │   │   │   ├── LtiConfigurationDetail.tsx
│       │   │   │   ├── ProductDetail.tsx
│       │   │   │   └── __tests__
│       │   │   │       ├── Badges.test.tsx
│       │   │   │       ├── ExternalLinks.test.tsx
│       │   │   │       └── LtiConfigurationDetail.test.tsx
│       │   │   ├── apps
│       │   │   │   ├── FilterOptions.tsx
│       │   │   │   ├── FilterTags.tsx
│       │   │   │   ├── Header.tsx
│       │   │   │   ├── LtiFilterTray.tsx
│       │   │   │   ├── ProductCard.tsx
│       │   │   │   ├── Products.tsx
│       │   │   │   ├── SearchAndFilter.tsx
│       │   │   │   └── __tests__
│       │   │   │       └── ProductCard.test.tsx
│       │   │   └── common
│       │   │       ├── Carousels
│       │   │       │   ├── Arrows.tsx
│       │   │       │   ├── ImageCarouselModal.tsx
│       │   │       │   ├── ProductCarousel.tsx
│       │   │       │   └── utils.ts
│       │   │       ├── Disclaimer.tsx
│       │   │       ├── ToolIconOrDefault.tsx
│       │   │       ├── TruncateWithTooltip.tsx
│       │   │       ├── __tests__
│       │   │       │   ├── ToolIconOrDefault.test.tsx
│       │   │       │   ├── carousels.test.tsx
│       │   │       │   ├── data.ts
│       │   │       │   └── utils.test.ts
│       │   │       └── stripHtmlTags.tsx
│       │   ├── hooks
│       │   │   ├── useBreakpoints.ts
│       │   │   ├── useCreateScreenReaderFilterMessage.ts
│       │   │   ├── useDebouncedSearch.ts
│       │   │   └── useDiscoverQueryParams.ts
│       │   ├── models
│       │   │   ├── AccountId.ts
│       │   │   ├── Filter.ts
│       │   │   ├── Product.ts
│       │   │   └── UnifiedToolId.ts
│       │   ├── package.json
│       │   ├── queries
│       │   │   ├── __tests__
│       │   │   │   ├── useProduct.test.tsx
│       │   │   │   └── useSimilarProducts.test.tsx
│       │   │   ├── productsQuery.ts
│       │   │   ├── useProduct.ts
│       │   │   └── useSimilarProducts.ts
│       │   └── utils
│       │       ├── __tests__
│       │       │   └── pickPreferredIntegration.test.ts
│       │       ├── basename.ts
│       │       ├── breakpoints.ts
│       │       ├── pickPreferredIntegration.ts
│       │       └── routes.ts
│       ├── make-promise-pool
│       │   ├── __tests__
│       │   │   └── makePromisePool.spec.js
│       │   ├── index.js
│       │   └── package.json
│       ├── mastery-path-toggle
│       │   ├── backbone
│       │   │   └── views
│       │   │       └── MasteryPathToggle.jsx
│       │   ├── package.json
│       │   └── react
│       │       └── MasteryPathToggle.jsx
│       ├── media-comments
│       │   ├── jquery
│       │   │   ├── MediaElementKeyActionHandler.js
│       │   │   ├── __tests__
│       │   │   │   ├── MediaElementKeyActionHandler.test.js
│       │   │   │   ├── kalturaAnalytics.test.js
│       │   │   │   ├── kaltura_session_loader.spec.js
│       │   │   │   ├── mediaComment.spec.js
│       │   │   │   ├── mediaComment.test.js
│       │   │   │   └── mediaCommentThumbnail.test.js
│       │   │   ├── comment_ui_loader.js
│       │   │   ├── dialog_manager.jsx
│       │   │   ├── file_input_manager.js
│       │   │   ├── index.js
│       │   │   ├── js_uploader.js
│       │   │   ├── kalturaAnalytics.js
│       │   │   ├── kaltura_session_loader.js
│       │   │   ├── mediaComment.jsx
│       │   │   ├── mediaCommentThumbnail.js
│       │   │   └── upload_view_manager.js
│       │   ├── jst
│       │   │   ├── MediaComments.handlebars
│       │   │   └── MediaComments.handlebars.json
│       │   └── package.json
│       ├── media-recorder
│       │   ├── mimetypes.js
│       │   ├── package.json
│       │   ├── react
│       │   │   └── components
│       │   │       ├── MediaRecorder.jsx
│       │   │       └── __tests__
│       │   │           └── MediaRecorder.test.jsx
│       │   └── renderRecorder.jsx
│       ├── mediaelement
│       │   ├── InheritedCaptionTooltip
│       │   │   └── index.jsx
│       │   ├── UploadMediaTrackForm.jsx
│       │   ├── __tests__
│       │   │   └── UploadMediaTrackForm.test.js
│       │   ├── eslint.config.js
│       │   ├── index.js
│       │   ├── jst
│       │   │   ├── UploadMediaTrackForm.handlebars
│       │   │   └── UploadMediaTrackForm.handlebars.json
│       │   ├── mediaLanguageCodes.ts
│       │   ├── mep-feature-tracks-instructure.jsx
│       │   └── package.json
│       ├── message-attachments
│       │   ├── index.js
│       │   ├── package.json
│       │   ├── react
│       │   │   └── components
│       │   │       ├── AttachmentDisplay
│       │   │       │   ├── Attachment.jsx
│       │   │       │   ├── AttachmentDisplay.jsx
│       │   │       │   ├── AttachmentDisplay.stories.jsx
│       │   │       │   └── __tests__
│       │   │       │       ├── Attachment.test.jsx
│       │   │       │       └── AttachmentDisplay.test.jsx
│       │   │       ├── AttachmentUploadSpinner
│       │   │       │   ├── AttachmentUploadSpinner.jsx
│       │   │       │   └── __tests__
│       │   │       │       └── AttachmentUploadSpinner.test.jsx
│       │   │       ├── FileAttachmentUpload
│       │   │       │   ├── FileAttachmentUpload.jsx
│       │   │       │   └── __tests__
│       │   │       │       └── FileAttachmentUpload.test.jsx
│       │   │       ├── MediaAttachment
│       │   │       │   ├── MediaAttachment.tsx
│       │   │       │   └── __tests__
│       │   │       │       └── MediaAttachment.test.tsx
│       │   │       └── RemovableItem
│       │   │           ├── RemovableItem.jsx
│       │   │           ├── RemovableItem.stories.jsx
│       │   │           └── __tests__
│       │   │               └── RemovableItem.test.jsx
│       │   └── util
│       │       ├── __tests__
│       │       │   └── attachments.test.js
│       │       └── attachments.js
│       ├── message-students-dialog
│       │   ├── backbone
│       │   │   ├── models
│       │   │   │   ├── Conversation.js
│       │   │   │   ├── ConversationCreator.js
│       │   │   │   └── __tests__
│       │   │   │       ├── Conversation.spec.js
│       │   │   │       └── ConversationCreator.test.js
│       │   │   └── views
│       │   │       ├── __tests__
│       │   │       │   └── MessageStudentsDialog.test.js
│       │   │       └── index.js
│       │   ├── graphql
│       │   │   └── Queries.ts
│       │   ├── jquery
│       │   │   └── message_students.js
│       │   ├── jst
│       │   │   ├── _messageStudentsWhoRecipientList.handlebars
│       │   │   ├── _messageStudentsWhoRecipientList.handlebars.json
│       │   │   ├── messageStudentsDialog.handlebars
│       │   │   └── messageStudentsDialog.handlebars.json
│       │   ├── package.json
│       │   └── react
│       │       ├── MessageStudentsWhoDialog.stories.jsx
│       │       ├── MessageStudentsWhoDialog.tsx
│       │       ├── Pill.stories.jsx
│       │       ├── Pill.tsx
│       │       ├── __tests__
│       │       │   ├── MessageStudentsWhoDialog.test.tsx
│       │       │   └── Pill.test.tsx
│       │       └── hooks
│       │           └── useObserverEnrollments.ts
│       ├── message-students-modal
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   ├── MessageStudents1.test.jsx
│       │       │   └── MessageStudents2.test.jsx
│       │       └── index.jsx
│       ├── mime
│       │   ├── mimeClass.js
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   └── mimeClassIconHelper.test.js
│       │       └── mimeClassIconHelper.jsx
│       ├── modal
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   ├── Modal.test.jsx
│       │       │   ├── modal-buttons.test.jsx
│       │       │   └── modal-content.spec.jsx
│       │       ├── buttons.jsx
│       │       ├── content.jsx
│       │       └── index.jsx
│       ├── module-sequence-footer
│       │   ├── jquery
│       │   │   ├── __tests__
│       │   │   │   └── ModuleSequenceFooter.test.js
│       │   │   └── index.jsx
│       │   ├── jst
│       │   │   ├── ModuleSequenceFooter.handlebars
│       │   │   └── ModuleSequenceFooter.handlebars.json
│       │   └── package.json
│       ├── modules
│       │   ├── backbone
│       │   │   ├── collections
│       │   │   │   ├── ModuleCollection.js
│       │   │   │   ├── ModuleItemCollection.js
│       │   │   │   └── __tests__
│       │   │   │       ├── ModuleCollection.spec.js
│       │   │   │       └── ModuleItemCollection.spec.js
│       │   │   └── models
│       │   │       ├── Module.js
│       │   │       ├── ModuleItem.js
│       │   │       └── __tests__
│       │   │           └── Module.test.js
│       │   ├── jquery
│       │   │   └── prerequisites_lookup.js
│       │   └── package.json
│       ├── move-item-tray
│       │   ├── __tests__
│       │   │   └── index.test.js
│       │   ├── index.jsx
│       │   ├── package.json
│       │   └── react
│       │       ├── MoveSelect.jsx
│       │       ├── __tests__
│       │       │   ├── MoveItemTray.test.jsx
│       │       │   └── MoveSelect.test.jsx
│       │       ├── index.jsx
│       │       └── propTypes.js
│       ├── msw
│       │   ├── mswClient.js
│       │   └── mswServer.js
│       ├── multi-select
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   └── index.test.jsx
│       │       └── index.tsx
│       ├── mutex-manager
│       │   ├── MutexManager.ts
│       │   ├── __tests__
│       │   │   └── MutexManager.test.js
│       │   ├── index.js
│       │   └── package.json
│       ├── network
│       │   ├── NaiveRequestDispatch
│       │   │   ├── CheatDepaginator.ts
│       │   │   ├── __tests__
│       │   │   │   ├── FakeServer.js
│       │   │   │   └── index.test.js
│       │   │   └── index.js
│       │   ├── NetworkFake
│       │   │   ├── NetworkFake.ts
│       │   │   ├── Request.ts
│       │   │   ├── Response.ts
│       │   │   ├── __tests__
│       │   │   │   ├── NetworkFake.test.ts
│       │   │   │   ├── Request.test.ts
│       │   │   │   └── Response.test.ts
│       │   │   ├── index.ts
│       │   │   ├── response-helpers
│       │   │   │   ├── __tests__
│       │   │   │   │   └── setPaginationLinkHeader.test.ts
│       │   │   │   ├── index.ts
│       │   │   │   └── setPaginationLinkHeader.ts
│       │   │   ├── specHelpers.ts
│       │   │   └── waitForCondition.js
│       │   ├── RequestDispatch
│       │   │   ├── CheatDepaginator.ts
│       │   │   ├── __tests__
│       │   │   │   └── index.test.ts
│       │   │   └── index.ts
│       │   ├── index.ts
│       │   └── package.json
│       ├── normalize-registration-errors
│       │   ├── backbone
│       │   │   └── models
│       │   │       └── ObserverPairingCodeModel.js
│       │   ├── index.js
│       │   ├── obj-flatten.ts
│       │   └── package.json
│       ├── notification-preferences
│       │   ├── graphql
│       │   │   └── Queries.js
│       │   ├── images
│       │   │   └── PleaseWaitWristWatch.svg
│       │   ├── package.json
│       │   └── react
│       │       ├── NotificationPreferencesContextProvider.jsx
│       │       ├── NotificationPreferencesContextSelect.jsx
│       │       ├── NotificationPreferencesContextSelectQuery.jsx
│       │       ├── Setting.jsx
│       │       ├── Shape.js
│       │       ├── Table.jsx
│       │       ├── __tests__
│       │       │   ├── MockedNotificationPreferences.js
│       │       │   ├── Setting.test.jsx
│       │       │   ├── Table.test.jsx
│       │       │   └── index.test.jsx
│       │       └── index.jsx
│       ├── notification-preferences-course
│       │   ├── graphql
│       │   │   ├── Mutations.js
│       │   │   └── Queries.js
│       │   ├── package.json
│       │   └── react
│       │       ├── CourseNotificationSettingsManager.jsx
│       │       ├── CourseNotificationSettingsQuery.jsx
│       │       ├── __tests__
│       │       │   └── CourseNotificationSettingsQuery.test.jsx
│       │       └── index.jsx
│       ├── notifications
│       │   ├── package.json
│       │   └── redux
│       │       ├── __tests__
│       │       │   └── reduxNotifications.test.jsx
│       │       └── actions.js
│       ├── obj-select
│       │   ├── __tests__
│       │   │   └── select.spec.js
│       │   ├── index.ts
│       │   └── package.json
│       ├── observer-picker
│       │   ├── ObserverGetObservee.js
│       │   ├── package.json
│       │   ├── react
│       │   │   ├── AddStudentModal.jsx
│       │   │   ├── ObserverOptions.jsx
│       │   │   ├── __tests__
│       │   │   │   ├── AddStudentModal.test.jsx
│       │   │   │   ├── ObserverOptions.test.jsx
│       │   │   │   ├── fixtures.js
│       │   │   │   └── utils.test.js
│       │   │   └── utils.js
│       │   └── util
│       │       ├── __tests__
│       │       │   └── pageReloadHelper.test.js
│       │       └── pageReloadHelper.js
│       ├── outcome-gradebook-grid
│       │   ├── __tests__
│       │   │   └── OutcomeGradebookGrid.test.js
│       │   ├── backbone
│       │   │   └── views
│       │   │       └── OutcomeColumnView.js
│       │   ├── index.jsx
│       │   ├── jst
│       │   │   ├── header_filter.handlebars
│       │   │   ├── header_filter.handlebars.json
│       │   │   ├── outcome_gradebook_cell.handlebars
│       │   │   ├── outcome_gradebook_cell.handlebars.json
│       │   │   ├── outcome_gradebook_student_cell.handlebars
│       │   │   └── outcome_gradebook_student_cell.handlebars.json
│       │   ├── package.json
│       │   └── react
│       │       ├── HeaderFilterView.jsx
│       │       ├── OutcomeFilterView.jsx
│       │       └── __tests__
│       │           ├── HeaderFilterView.test.jsx
│       │           └── OutcomeFilterView.test.jsx
│       ├── outcomes
│       │   ├── __tests__
│       │   │   ├── addZeroWidthSpace.test.js
│       │   │   └── stripHtmlTags.test.js
│       │   ├── addZeroWidthSpace.js
│       │   ├── backbone
│       │   │   ├── collections
│       │   │   │   └── OutcomeCollection.js
│       │   │   ├── models
│       │   │   │   ├── Outcome.js
│       │   │   │   ├── OutcomeGroup.js
│       │   │   │   └── __tests__
│       │   │   │       └── Outcome.test.js
│       │   │   └── views
│       │   │       └── FindDialog.js
│       │   ├── content-view
│       │   │   ├── backbone
│       │   │   │   └── views
│       │   │   │       ├── CalculationMethodFormView.js
│       │   │   │       ├── OutcomeContentBase.js
│       │   │   │       ├── OutcomeGroupView.js
│       │   │   │       ├── OutcomeView.js
│       │   │   │       ├── RootOutcomesFinder.js
│       │   │   │       ├── __tests__
│       │   │   │       │   ├── OutcomeGroupView.test.js
│       │   │   │       │   ├── OutcomeView1.test.js
│       │   │   │       │   ├── OutcomeView2.test.js
│       │   │   │       │   └── OutcomeView3.test.js
│       │   │   │       └── index.js
│       │   │   ├── jst
│       │   │   │   ├── MoveOutcomeDialog.handlebars
│       │   │   │   ├── MoveOutcomeDialog.handlebars.json
│       │   │   │   ├── _criterion.handlebars
│       │   │   │   ├── _criterion.handlebars.json
│       │   │   │   ├── _criterionHeader.handlebars
│       │   │   │   ├── _criterionHeader.handlebars.json
│       │   │   │   ├── noOutcomesWarning.handlebars
│       │   │   │   ├── noOutcomesWarning.handlebars.json
│       │   │   │   ├── outcome.handlebars
│       │   │   │   ├── outcome.handlebars.json
│       │   │   │   ├── outcomeCalculationMethodForm.handlebars
│       │   │   │   ├── outcomeCalculationMethodForm.handlebars.json
│       │   │   │   ├── outcomeForm.handlebars
│       │   │   │   ├── outcomeForm.handlebars.json
│       │   │   │   ├── outcomeGroup.handlebars
│       │   │   │   ├── outcomeGroup.handlebars.json
│       │   │   │   ├── outcomeGroupForm.handlebars
│       │   │   │   └── outcomeGroupForm.handlebars.json
│       │   │   └── react
│       │   │       ├── ConfirmOutcomeEditModal.jsx
│       │   │       ├── CriterionInfo.jsx
│       │   │       ├── CriterionInfo.stories.jsx
│       │   │       └── __tests__
│       │   │           ├── ConfirmOutcomeEditModal.test.jsx
│       │   │           ├── CriterionInfo.test.jsx
│       │   │           └── __snapshots__
│       │   │               └── CriterionInfo.test.jsx.snap
│       │   ├── find_outcome.js
│       │   ├── graphql
│       │   │   ├── Management.js
│       │   │   ├── MasteryCalculation.js
│       │   │   ├── MasteryScale.js
│       │   │   ├── Outcomes.js
│       │   │   └── __tests__
│       │   │       └── Management.test.js
│       │   ├── jst
│       │   │   ├── _calculationMethodExample.handlebars
│       │   │   ├── _calculationMethodExample.handlebars.json
│       │   │   ├── browser.handlebars
│       │   │   ├── browser.handlebars.json
│       │   │   ├── findInstructions.handlebars
│       │   │   ├── findInstructions.handlebars.json
│       │   │   ├── outcomePopover.handlebars
│       │   │   └── outcomePopover.handlebars.json
│       │   ├── mocks
│       │   │   ├── Management.js
│       │   │   └── Outcomes.js
│       │   ├── package.json
│       │   ├── react
│       │   │   ├── Focus.js
│       │   │   ├── ImportOutcomesModal.jsx
│       │   │   ├── OutcomesImporter.jsx
│       │   │   ├── __tests__
│       │   │   │   ├── Focus.test.jsx
│       │   │   │   ├── ImportOutcomesModal.test.jsx
│       │   │   │   ├── OutcomesImporter.test.jsx
│       │   │   │   ├── apiClient.test.js
│       │   │   │   └── treeBrowser.test.jsx
│       │   │   ├── apiClient.js
│       │   │   ├── contexts
│       │   │   │   ├── LMGBContext.js
│       │   │   │   └── OutcomesContext.js
│       │   │   ├── helpers
│       │   │   │   ├── __tests__
│       │   │   │   │   └── ratingsHelpers.test.js
│       │   │   │   ├── ratingsHelpers.js
│       │   │   │   └── testHelpers.js
│       │   │   ├── hooks
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── useBoolean.test.js
│       │   │   │   │   ├── useCanvasContext.test.jsx
│       │   │   │   │   ├── useCourseAlignmentStats.test.jsx
│       │   │   │   │   ├── useCourseAlignments.test.jsx
│       │   │   │   │   ├── useGroupCreate.test.jsx
│       │   │   │   │   ├── useGroupDetail.test.jsx
│       │   │   │   │   ├── useInput.test.js
│       │   │   │   │   ├── useInputFocus.test.js
│       │   │   │   │   ├── useLMGBContext.test.jsx
│       │   │   │   │   ├── useModal.test.js
│       │   │   │   │   ├── useOutcomeFormValidate.test.jsx
│       │   │   │   │   ├── useOutcomesImport.test.jsx
│       │   │   │   │   ├── useOutcomesRemove.test.jsx
│       │   │   │   │   ├── useRatings.test.js
│       │   │   │   │   ├── useResize.test.jsx
│       │   │   │   │   ├── useSearch.test.js
│       │   │   │   │   └── useSelectedOutcomes.test.js
│       │   │   │   ├── useBoolean.js
│       │   │   │   ├── useCanvasContext.js
│       │   │   │   ├── useCourseAlignmentStats.js
│       │   │   │   ├── useCourseAlignments.js
│       │   │   │   ├── useGroupCreate.js
│       │   │   │   ├── useGroupDetail.js
│       │   │   │   ├── useInput.js
│       │   │   │   ├── useInputFocus.js
│       │   │   │   ├── useLMGBContext.js
│       │   │   │   ├── useLhsTreeBrowserSelectParentGroup.js
│       │   │   │   ├── useModal.js
│       │   │   │   ├── useOutcomeFormValidate.js
│       │   │   │   ├── useOutcomesImport.js
│       │   │   │   ├── useOutcomesRemove.js
│       │   │   │   ├── useRatings.js
│       │   │   │   ├── useResize.js
│       │   │   │   ├── useSearch.js
│       │   │   │   └── useSelectedOutcomes.js
│       │   │   ├── treeBrowser.js
│       │   │   └── validators
│       │   │       ├── __tests__
│       │   │       │   └── finalFormValidators.test.js
│       │   │       └── finalFormValidators.js
│       │   ├── sidebar-view
│       │   │   └── backbone
│       │   │       ├── collections
│       │   │       │   └── OutcomeGroupCollection.js
│       │   │       └── views
│       │   │           ├── AccountDirectoryView.js
│       │   │           ├── FindDirectoryView.js
│       │   │           ├── OutcomeGroupIconView.js
│       │   │           ├── OutcomeIconBase.js
│       │   │           ├── OutcomeIconView.js
│       │   │           ├── OutcomesDirectoryView.js
│       │   │           ├── StateStandardsDirectoryView.js
│       │   │           └── index.js
│       │   └── stripHtmlTags.js
│       ├── package-tests
│       │   ├── __tests__
│       │   │   ├── date.test.js
│       │   │   ├── datePickerFormat.spec.js
│       │   │   ├── deparam.spec.js
│       │   │   ├── htmlEscape.test.js
│       │   │   ├── parseLinkHeaderAxios.spec.js
│       │   │   ├── parseLinkHeaderXHR.spec.js
│       │   │   └── unflatten.spec.js
│       │   └── package.json
│       ├── pagination
│       │   ├── backbone
│       │   │   ├── collections
│       │   │   │   ├── PaginatedCollection.js
│       │   │   │   └── __tests__
│       │   │   │       └── PaginatedCollection.test.js
│       │   │   └── views
│       │   │       ├── PaginatedCollectionView.jsx
│       │   │       ├── PaginatedView.js
│       │   │       └── __tests__
│       │   │           └── PaginatedCollectionView.test.js
│       │   ├── jst
│       │   │   ├── PaginatedView.handlebars
│       │   │   ├── PaginatedView.handlebars.json
│       │   │   ├── paginatedCollection.handlebars
│       │   │   └── paginatedCollection.handlebars.json
│       │   ├── package.json
│       │   └── redux
│       │       ├── __tests__
│       │       │   └── reduxPagination.test.js
│       │       └── actions.js
│       ├── panda-pub-client
│       │   ├── index.js
│       │   └── package.json
│       ├── panda-pub-poller
│       │   ├── index.js
│       │   └── package.json
│       ├── parse-link-header
│       │   ├── __tests__
│       │   │   └── parseLinkHeader.test.ts
│       │   ├── package.json
│       │   └── parseLinkHeader.ts
│       ├── permissions
│       │   ├── __tests__
│       │   │   └── util.test.js
│       │   ├── package.json
│       │   ├── react
│       │   │   └── propTypes.js
│       │   └── util.js
│       ├── planner
│       │   ├── __tests__
│       │   │   ├── ForceFailure.test.js
│       │   │   └── index.test.js
│       │   ├── actions
│       │   │   ├── __tests__
│       │   │   │   ├── actions.1.test.js
│       │   │   │   ├── actions.2.test.js
│       │   │   │   ├── actions.3.test.js
│       │   │   │   ├── actions.4.test.js
│       │   │   │   ├── loading-actions.1.test.js
│       │   │   │   ├── loading-actions.2.test.js
│       │   │   │   ├── loading-actions.3.test.js
│       │   │   │   ├── saga-actions.test.js
│       │   │   │   ├── sagas.test.js
│       │   │   │   └── sidebar-actions.test.js
│       │   │   ├── index.js
│       │   │   ├── loading-actions.js
│       │   │   ├── saga-actions.js
│       │   │   ├── sagas.js
│       │   │   └── sidebar-actions.js
│       │   ├── components
│       │   │   ├── BadgeList
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── BadgeList.spec.jsx
│       │   │   │   │   └── __snapshots__
│       │   │   │   │       └── BadgeList.spec.jsx.snap
│       │   │   │   ├── index.jsx
│       │   │   │   └── style.js
│       │   │   ├── CalendarEventModal
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── CalendarEventModal.spec.jsx
│       │   │   │   │   └── __snapshots__
│       │   │   │   │       └── CalendarEventModal.spec.jsx.snap
│       │   │   │   └── index.jsx
│       │   │   ├── CompletedItemsFacade
│       │   │   │   ├── __tests__
│       │   │   │   │   └── CompletedItemsFacade.spec.jsx
│       │   │   │   ├── index.jsx
│       │   │   │   └── style.js
│       │   │   ├── Day
│       │   │   │   ├── __tests__
│       │   │   │   │   └── Day.spec.jsx
│       │   │   │   ├── index.jsx
│       │   │   │   └── style.js
│       │   │   ├── EmptyDays
│       │   │   │   ├── GroupedDates.jsx
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── EmptyDays.spec.jsx
│       │   │   │   │   └── __snapshots__
│       │   │   │   │       └── EmptyDays.spec.jsx.snap
│       │   │   │   ├── index.jsx
│       │   │   │   └── style.js
│       │   │   ├── ErrorAlert
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── ErrorAlert.spec.jsx
│       │   │   │   │   └── __snapshots__
│       │   │   │   │       └── ErrorAlert.spec.jsx.snap
│       │   │   │   └── index.jsx
│       │   │   ├── GradesDisplay
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── GradesDisplay.spec.jsx
│       │   │   │   │   └── __snapshots__
│       │   │   │   │       └── GradesDisplay.spec.jsx.snap
│       │   │   │   ├── index.jsx
│       │   │   │   └── style.js
│       │   │   ├── Grouping
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── Grouping.spec.jsx
│       │   │   │   │   └── __snapshots__
│       │   │   │   │       └── Grouping.spec.jsx.snap
│       │   │   │   ├── index.jsx
│       │   │   │   └── style.js
│       │   │   ├── JumpToHeaderButton
│       │   │   │   └── index.jsx
│       │   │   ├── LoadingFutureIndicator
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── LoadingFutureIndicator.spec.jsx
│       │   │   │   │   └── __snapshots__
│       │   │   │   │       └── LoadingFutureIndicator.spec.jsx.snap
│       │   │   │   └── index.jsx
│       │   │   ├── LoadingPastIndicator
│       │   │   │   ├── TV.jsx
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── LoadingPastIndicator.spec.jsx
│       │   │   │   │   └── __snapshots__
│       │   │   │   │       └── LoadingPastIndicator.spec.jsx.snap
│       │   │   │   └── index.jsx
│       │   │   ├── MissingAssignments
│       │   │   │   ├── __tests__
│       │   │   │   │   └── MissingAssignments.spec.jsx
│       │   │   │   ├── index.jsx
│       │   │   │   └── style.js
│       │   │   ├── NotificationBadge
│       │   │   │   ├── Indicator.jsx
│       │   │   │   ├── MissingIndicator.jsx
│       │   │   │   ├── NewActivityIndicator.jsx
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── Indicator.spec.jsx
│       │   │   │   │   ├── MissingIndicator.spec.jsx
│       │   │   │   │   ├── NewActivityIndicator.spec.jsx
│       │   │   │   │   ├── NotificationBadge.spec.jsx
│       │   │   │   │   └── __snapshots__
│       │   │   │   │       ├── MissingIndicator.spec.jsx.snap
│       │   │   │   │       ├── NewActivityIndicator.spec.jsx.snap
│       │   │   │   │       └── NotificationBadge.spec.jsx.snap
│       │   │   │   ├── index.jsx
│       │   │   │   └── style.js
│       │   │   ├── Opportunities
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── Opportunities.spec.jsx
│       │   │   │   │   └── __snapshots__
│       │   │   │   │       └── Opportunities.spec.jsx.snap
│       │   │   │   ├── index.jsx
│       │   │   │   └── style.js
│       │   │   ├── Opportunity
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── Opportunity.spec.jsx
│       │   │   │   │   └── __snapshots__
│       │   │   │   │       └── Opportunity.spec.jsx.snap
│       │   │   │   ├── index.jsx
│       │   │   │   └── style.js
│       │   │   ├── PlannerApp
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── PlannerApp.spec.jsx
│       │   │   │   │   ├── WeeklyPlannerApp.spec.jsx
│       │   │   │   │   └── __snapshots__
│       │   │   │   │       └── PlannerApp.spec.jsx.snap
│       │   │   │   └── index.jsx
│       │   │   ├── PlannerEmptyState
│       │   │   │   ├── Balloons.jsx
│       │   │   │   ├── EmptyDesert.jsx
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── PlannerEmptyState.spec.jsx
│       │   │   │   │   └── __snapshots__
│       │   │   │   │       └── PlannerEmptyState.spec.jsx.snap
│       │   │   │   ├── index.jsx
│       │   │   │   └── style.js
│       │   │   ├── PlannerHeader
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── PlannerHeader.spec.jsx
│       │   │   │   │   └── __snapshots__
│       │   │   │   │       └── PlannerHeader.spec.jsx.snap
│       │   │   │   ├── index.jsx
│       │   │   │   └── style.js
│       │   │   ├── PlannerItem
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── PlannerItem.spec.jsx
│       │   │   │   │   └── __snapshots__
│       │   │   │   │       └── PlannerItem.spec.jsx.snap
│       │   │   │   ├── index.jsx
│       │   │   │   └── style.js
│       │   │   ├── PlannerPreview
│       │   │   │   ├── KinderPanda.jsx
│       │   │   │   ├── index.jsx
│       │   │   │   └── mock-items.js
│       │   │   ├── ShowOnFocusButton
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── ShowOnFocusButton.spec.jsx
│       │   │   │   │   └── __snapshots__
│       │   │   │   │       └── ShowOnFocusButton.spec.jsx.snap
│       │   │   │   └── index.jsx
│       │   │   ├── StickyButton
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── StickyButton.spec.jsx
│       │   │   │   │   └── __snapshots__
│       │   │   │   │       └── StickyButton.spec.jsx.snap
│       │   │   │   ├── index.jsx
│       │   │   │   └── style.js
│       │   │   ├── ToDoSidebar
│       │   │   │   ├── ToDoItem.jsx
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── ToDoItem.spec.jsx
│       │   │   │   │   ├── __snapshots__
│       │   │   │   │   │   └── index.spec.jsx.snap
│       │   │   │   │   └── index.spec.jsx
│       │   │   │   └── index.jsx
│       │   │   ├── TodoEditorModal
│       │   │   │   ├── __tests__
│       │   │   │   │   └── TodoEditorModal.test.jsx
│       │   │   │   └── index.jsx
│       │   │   ├── UpdateItemTray
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── UpdateItemTray.spec.jsx
│       │   │   │   │   └── __snapshots__
│       │   │   │   │       └── UpdateItemTray.spec.jsx.snap
│       │   │   │   ├── index.jsx
│       │   │   │   └── style.js
│       │   │   ├── WeeklyPlannerHeader
│       │   │   │   ├── __tests__
│       │   │   │   │   └── WeeklyPlannerHeader.spec.jsx
│       │   │   │   ├── index.jsx
│       │   │   │   └── style.js
│       │   │   ├── index.js
│       │   │   ├── plannerPropTypes.js
│       │   │   ├── responsiviser.jsx
│       │   │   └── themes.js
│       │   ├── dynamic-ui
│       │   │   ├── __tests__
│       │   │   │   ├── __snapshots__
│       │   │   │   │   ├── animatable.spec.jsx.snap
│       │   │   │   │   └── notifier.spec.jsx.snap
│       │   │   │   ├── animatable-registry.test.js
│       │   │   │   ├── animatable.spec.jsx
│       │   │   │   ├── animation.test.js
│       │   │   │   ├── animator.test.js
│       │   │   │   ├── manager.test.js
│       │   │   │   ├── middleware.test.js
│       │   │   │   └── notifier.spec.jsx
│       │   │   ├── animatable-registry.js
│       │   │   ├── animatable.jsx
│       │   │   ├── animation-collection.js
│       │   │   ├── animation.js
│       │   │   ├── animations
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── continue-initial-load.test.js
│       │   │   │   │   ├── focus-item-on-save.test.js
│       │   │   │   │   ├── focus-prior-item-on-delete.test.js
│       │   │   │   │   ├── focus-prior-item-on-load-more.test.js
│       │   │   │   │   ├── maintain-scroll-position-when-scrolling-into-the-past.test.js
│       │   │   │   │   ├── return-focus-on-cancel-editing.test.js
│       │   │   │   │   ├── scroll-to-last-loaded-new-activity.test.js
│       │   │   │   │   ├── scroll-to-loaded-today.test.js
│       │   │   │   │   ├── scroll-to-new-activity.test.js
│       │   │   │   │   ├── scroll-to-today.test.js
│       │   │   │   │   └── test-utils.js
│       │   │   │   ├── continue-initial-load.js
│       │   │   │   ├── focus-item-on-save.js
│       │   │   │   ├── focus-prior-item-on-delete.js
│       │   │   │   ├── focus-prior-item-on-load-more.js
│       │   │   │   ├── index.js
│       │   │   │   ├── maintain-scroll-position-when-scrolling-into-the-past.js
│       │   │   │   ├── return-focus-on-cancel-editing.js
│       │   │   │   ├── scroll-to-last-loaded-new-activity.js
│       │   │   │   ├── scroll-to-loaded-today.js
│       │   │   │   ├── scroll-to-new-activity.js
│       │   │   │   └── scroll-to-today.js
│       │   │   ├── animator.js
│       │   │   ├── index.js
│       │   │   ├── manager.js
│       │   │   ├── middleware.js
│       │   │   ├── notifier.jsx
│       │   │   ├── provider.js
│       │   │   └── util.js
│       │   ├── getThemeVars.js
│       │   ├── index.jsx
│       │   ├── package.json
│       │   ├── reducers
│       │   │   ├── __tests__
│       │   │   │   ├── __snapshots__
│       │   │   │   │   ├── courses-reducer.test.js.snap
│       │   │   │   │   └── save-item-reducer.test.js.snap
│       │   │   │   ├── courses-reducer.test.js
│       │   │   │   ├── days-reducer.test.js
│       │   │   │   ├── index.test.js
│       │   │   │   ├── loading-reducer.test.js
│       │   │   │   ├── opportunities-reducer.test.js
│       │   │   │   ├── save-item-reducer.test.js
│       │   │   │   ├── sidebar-reducer.test.js
│       │   │   │   ├── todo-reducer.test.js
│       │   │   │   └── weekly-reducer.test.js
│       │   │   ├── courses-reducer.js
│       │   │   ├── days-reducer.js
│       │   │   ├── groups-reducer.js
│       │   │   ├── index.js
│       │   │   ├── loading-reducer.js
│       │   │   ├── opportunities-reducer.js
│       │   │   ├── save-item-reducer.js
│       │   │   ├── selected-observee-reducer.js
│       │   │   ├── sidebar-reducer.js
│       │   │   ├── todo-reducer.js
│       │   │   ├── ui-reducer.js
│       │   │   └── weekly-reducer.js
│       │   ├── store
│       │   │   └── configureStore.js
│       │   └── utilities
│       │       ├── __tests__
│       │       │   ├── __snapshots__
│       │       │   │   ├── apiUtils.test.js.snap
│       │       │   │   └── daysUtils.test.js.snap
│       │       │   ├── alertUtils.test.js
│       │       │   ├── apiUtils.test.js
│       │       │   ├── configureAxios.test.js
│       │       │   ├── contentUtils.test.js
│       │       │   ├── dateUtils.test.js
│       │       │   ├── daysUtils.test.js
│       │       │   ├── redux-identifiable-thunk.test.js
│       │       │   ├── scrollUtils.test.js
│       │       │   └── statusUtils.test.js
│       │       ├── alertUtils.js
│       │       ├── apiUtils.js
│       │       ├── configureAxios.js
│       │       ├── contentUtils.js
│       │       ├── dateUtils.js
│       │       ├── daysUtils.js
│       │       ├── redux-identifiable-thunk.js
│       │       ├── scrollUtils.js
│       │       └── statusUtils.js
│       ├── positions
│       │   ├── __tests__
│       │   │   └── positions.spec.js
│       │   ├── package.json
│       │   └── positions.js
│       ├── post-assignment-grades-tray
│       │   ├── package.json
│       │   └── react
│       │       ├── Api.js
│       │       ├── FormContent.jsx
│       │       ├── Layout.jsx
│       │       ├── PostTypes.jsx
│       │       ├── __tests__
│       │       │   ├── Api.test.js
│       │       │   ├── FormContent.test.jsx
│       │       │   ├── Layout.test.jsx
│       │       │   ├── PostAssignmentGradesTray.test.jsx
│       │       │   └── PostTypes.test.jsx
│       │       └── index.jsx
│       ├── progress
│       │   ├── ProgressHelpers.ts
│       │   ├── __tests__
│       │   │   └── ProgressHelpers.test.ts
│       │   ├── backbone
│       │   │   └── models
│       │   │       ├── Progress.js
│       │   │       ├── __tests__
│       │   │       │   ├── Progress.test.js
│       │   │       │   └── progressable.test.js
│       │   │       └── progressable.js
│       │   ├── package.json
│       │   ├── react
│       │   │   └── components
│       │   │       ├── ApiProgressBar.jsx
│       │   │       ├── ProgressBar.jsx
│       │   │       └── __tests__
│       │   │           ├── ApiProgressBar.test.jsx
│       │   │           └── ProgressBar.test.jsx
│       │   ├── resolve_progress.js
│       │   └── stores
│       │       ├── ProgressStore.js
│       │       └── __tests__
│       │           └── ProgressStore.test.js
│       ├── proxy-submission
│       │   ├── package.json
│       │   └── react
│       │       ├── ProxyUploadModal.tsx
│       │       └── __tests__
│       │           └── ProxyUploadModal.test.tsx
│       ├── pseudonyms
│       │   ├── backbone
│       │   │   └── models
│       │   │       └── Pseudonym.js
│       │   └── package.json
│       ├── publish-button-view
│       │   ├── backbone
│       │   │   └── views
│       │   │       ├── __tests__
│       │   │       │   ├── PublishButtonView.test.jsx
│       │   │       │   └── PublishButtonViewValidations.test.jsx
│       │   │       └── index.jsx
│       │   ├── package.json
│       │   └── react
│       │       └── components
│       │           ├── DelayedPublishDialog.jsx
│       │           └── __tests__
│       │               └── DelayedPublishDialog.test.jsx
│       ├── publish-icon-view
│       │   ├── backbone
│       │   │   └── views
│       │   │       ├── __tests__
│       │   │       │   └── PublishIconView.test.js
│       │   │       └── index.js
│       │   └── package.json
│       ├── query
│       │   ├── broadcast.ts
│       │   ├── graphql
│       │   │   └── index.ts
│       │   ├── index.tsx
│       │   └── package.json
│       ├── quiz-legacy-client-apps
│       │   ├── adapter.js
│       │   ├── dispatcher.js
│       │   ├── environment.js
│       │   ├── eslint.config.js
│       │   ├── package.json
│       │   ├── react
│       │   │   └── components
│       │   │       ├── __tests__
│       │   │       │   ├── screen_reader_content.test.jsx
│       │   │       │   └── sighted_user_content.test.jsx
│       │   │       ├── screen_reader_content.jsx
│       │   │       ├── sighted_user_content.jsx
│       │   │       └── spinner.jsx
│       │   ├── store.js
│       │   └── util
│       │       ├── array_wrap.js
│       │       ├── class_set.js
│       │       ├── convert_case.js
│       │       ├── date_time_helpers.js
│       │       ├── from_jsonapi.js
│       │       ├── inflections.js
│       │       ├── pick_and_normalize.js
│       │       ├── round.js
│       │       └── seconds_to_time.js
│       ├── quiz-log-auditing
│       │   ├── jquery
│       │   │   ├── __tests__
│       │   │   │   ├── event.spec.js
│       │   │   │   ├── event_buffer.spec.js
│       │   │   │   └── event_manager.test.js
│       │   │   ├── constants.js
│       │   │   ├── dump_events.js
│       │   │   ├── event.js
│       │   │   ├── event_buffer.js
│       │   │   ├── event_manager.js
│       │   │   ├── event_set.js
│       │   │   ├── event_tracker.js
│       │   │   ├── event_trackers
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── page_blurred.test.js
│       │   │   │   │   ├── page_focused.test.js
│       │   │   │   │   ├── question_flagged.test.js
│       │   │   │   │   ├── question_viewed.test.js
│       │   │   │   │   └── session_started.test.js
│       │   │   │   ├── page_blurred.js
│       │   │   │   ├── page_focused.js
│       │   │   │   ├── question_flagged.js
│       │   │   │   ├── question_viewed.js
│       │   │   │   └── session_started.js
│       │   │   ├── expressions
│       │   │   │   └── in_viewport.js
│       │   │   ├── log_auditing.js
│       │   │   └── util
│       │   │       ├── debugConsole.js
│       │   │       ├── generateUUID.js
│       │   │       └── parse_question_id.js
│       │   └── package.json
│       ├── quizzes
│       │   ├── backbone
│       │   │   └── models
│       │   │       ├── Quiz.js
│       │   │       └── __tests__
│       │   │           └── Quiz.test.js
│       │   ├── jquery
│       │   │   ├── __tests__
│       │   │   │   ├── QuizArrows.spec.js
│       │   │   │   └── QuizRubric.test.js
│       │   │   ├── behaviors
│       │   │   │   └── quiz_selectmenu.js
│       │   │   ├── quiz_arrows.js
│       │   │   ├── quiz_form_utils.js
│       │   │   ├── quiz_inputs.js
│       │   │   └── quiz_rubric.js
│       │   └── package.json
│       ├── rails-flash-notifications
│       │   ├── jquery
│       │   │   ├── __tests__
│       │   │   │   ├── index.test.ts
│       │   │   │   └── railsFlashNotificationsHelper.test.js
│       │   │   ├── helper.ts
│       │   │   └── index.ts
│       │   └── package.json
│       ├── rce
│       │   ├── FileBrowser.jsx
│       │   ├── RichContentEditor.js
│       │   ├── Sidebar.js
│       │   ├── __mocks__
│       │   │   └── RichContentEditor.js
│       │   ├── __tests__
│       │   │   ├── FileBrowser.test.jsx
│       │   │   ├── Integration.test.js
│       │   │   ├── RichContentEditor.test.js
│       │   │   ├── a11yCheckerHooks.test.js
│       │   │   ├── getRCSProps.test.js
│       │   │   ├── jwt.spec.js
│       │   │   ├── loadEventListeners.test.js
│       │   │   ├── serviceRCELoader.test.js
│       │   │   └── shouldUseFeature.test.ts
│       │   ├── a11yCheckerHooks.js
│       │   ├── backbone
│       │   │   └── views
│       │   │       ├── FindFlickrImageView.js
│       │   │       └── __tests__
│       │   │           └── FindFlickrImageView.test.jsx
│       │   ├── canvas-rce.js
│       │   ├── editorOptions.js
│       │   ├── editorUtils.js
│       │   ├── getRCSProps.js
│       │   ├── jst
│       │   │   ├── FindFlickrImageResult.handlebars
│       │   │   ├── FindFlickrImageResult.handlebars.json
│       │   │   ├── FindFlickrImageView.handlebars
│       │   │   └── FindFlickrImageView.handlebars.json
│       │   ├── jwt.js
│       │   ├── loadEventListeners.js
│       │   ├── package.json
│       │   ├── plugins
│       │   │   └── canvas_mentions
│       │   │       ├── __tests__
│       │   │       │   ├── FakeEditor.js
│       │   │       │   ├── TestEditor.js
│       │   │       │   ├── contentEditable.test.js
│       │   │       │   ├── edit.test.js
│       │   │       │   ├── events.test.jsx
│       │   │       │   ├── mentionWasInitiated.test.js
│       │   │       │   └── plugin.test.js
│       │   │       ├── broadcastMessage.js
│       │   │       ├── components
│       │   │       │   └── MentionAutoComplete
│       │   │       │       ├── MentionDropdown.jsx
│       │   │       │       ├── MentionDropdownMenu.jsx
│       │   │       │       ├── MentionDropdownMenu.stories.jsx
│       │   │       │       ├── MentionDropdownOption.jsx
│       │   │       │       ├── MentionDropdownOptions.stories.jsx
│       │   │       │       ├── MentionDropdownPortal.jsx
│       │   │       │       ├── MentionsUI.jsx
│       │   │       │       ├── __tests__
│       │   │       │       │   ├── MentionDropdown.test.jsx
│       │   │       │       │   ├── MentionDropdownMenu.test.jsx
│       │   │       │       │   ├── MentionDropdownOption.test.jsx
│       │   │       │       │   └── getPosition.test.js
│       │   │       │       ├── getPosition.js
│       │   │       │       └── graphql
│       │   │       │           ├── Queries.js
│       │   │       │           └── mswHandlers.js
│       │   │       ├── constants.js
│       │   │       ├── contentEditable.js
│       │   │       ├── edit.js
│       │   │       ├── events.jsx
│       │   │       ├── mentionWasInitiated.js
│       │   │       └── plugin.js
│       │   ├── polyfill.js
│       │   ├── react
│       │   │   ├── CanvasRce.tsx
│       │   │   └── __tests__
│       │   │       └── CanvasRce.test.jsx
│       │   ├── serviceRCELoader.js
│       │   ├── shouldUseFeature.ts
│       │   ├── tinymce.config.ts
│       │   └── util
│       │       ├── __tests__
│       │       │   ├── deprecated.test.js
│       │       │   └── mergeConfig.test.js
│       │       ├── deprecated.js
│       │       └── mergeConfig.js
│       ├── rce-command-shim
│       │   ├── RceCommandShim.js
│       │   ├── __tests__
│       │   │   └── RceCommandShim.test.js
│       │   └── package.json
│       ├── react
│       │   ├── index.tsx
│       │   └── package.json
│       ├── react-modal
│       │   ├── index.jsx
│       │   └── package.json
│       ├── read-icon
│       │   ├── index.jsx
│       │   └── package.json
│       ├── relock-modules-dialog
│       │   ├── RelockModulesDialog.handlebars
│       │   ├── RelockModulesDialog.handlebars.json
│       │   ├── RelockModulesDialog.js
│       │   └── package.json
│       ├── round
│       │   ├── __tests__
│       │   │   └── round.spec.js
│       │   ├── index.ts
│       │   └── package.json
│       ├── rubrics
│       │   ├── backbone
│       │   │   └── views
│       │   │       ├── EditRubricPage.js
│       │   │       └── __tests__
│       │   │           └── EditRubricPage.test.js
│       │   ├── jquery
│       │   │   ├── __tests__
│       │   │   │   ├── edit_rubric.test.js
│       │   │   │   └── rubric_assessment.test.js
│       │   │   ├── edit_rubric.jsx
│       │   │   ├── rubricEditBinding.js
│       │   │   ├── rubric_assessment.jsx
│       │   │   └── rubric_delete_confirmation.js
│       │   ├── jst
│       │   │   ├── changePointsPossibleToMatchRubricDialog.handlebars
│       │   │   └── changePointsPossibleToMatchRubricDialog.handlebars.json
│       │   ├── package.json
│       │   ├── react
│       │   │   ├── CommentButton.jsx
│       │   │   ├── Comments.jsx
│       │   │   ├── Criterion.jsx
│       │   │   ├── Points.jsx
│       │   │   ├── Ratings.jsx
│       │   │   ├── Rubric.jsx
│       │   │   ├── RubricAssessment
│       │   │   │   ├── CommentLibrary.tsx
│       │   │   │   ├── CriteriaReadonlyComment.tsx
│       │   │   │   ├── HorizontalButtonDisplay.tsx
│       │   │   │   ├── InstructorScore.tsx
│       │   │   │   ├── LongDescriptionModal.tsx
│       │   │   │   ├── ModernView.tsx
│       │   │   │   ├── OutcomeTag.tsx
│       │   │   │   ├── RatingButton.tsx
│       │   │   │   ├── RubricAssessmentContainer.tsx
│       │   │   │   ├── RubricAssessmentTray.tsx
│       │   │   │   ├── SelfAssessmentComment.tsx
│       │   │   │   ├── SelfAssessmentInstructions.tsx
│       │   │   │   ├── SelfAssessmentInstructorScore.tsx
│       │   │   │   ├── SelfAssessmentRatingButton.tsx
│       │   │   │   ├── TraditionalView.tsx
│       │   │   │   ├── VerticalButtonDisplay.tsx
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── HorizontalButtonDisplay.test.tsx
│       │   │   │   │   ├── ModernView.test.tsx
│       │   │   │   │   ├── RatingButton.test.jsx
│       │   │   │   │   ├── RubricAssessmentContainer.test.tsx
│       │   │   │   │   ├── RubricAssessmentTray.test.tsx
│       │   │   │   │   ├── TraditionalView.test.tsx
│       │   │   │   │   └── fixtures.ts
│       │   │   │   ├── index.ts
│       │   │   │   └── utils
│       │   │   │       └── rubricUtils.ts
│       │   │   ├── RubricAssignment
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── RubricAssignmentContainer.test.tsx
│       │   │   │   │   └── fixtures.ts
│       │   │   │   ├── components
│       │   │   │   │   ├── CopyEditConfirmModal.tsx
│       │   │   │   │   ├── DeleteConfirmModal.tsx
│       │   │   │   │   ├── RubricAssignmentContainer.tsx
│       │   │   │   │   ├── RubricCreateModal.tsx
│       │   │   │   │   ├── RubricSearchTray.tsx
│       │   │   │   │   ├── RubricSelfAssessmentSettings.tsx
│       │   │   │   │   └── RubricSelfAssessmentSettingsWrapper.tsx
│       │   │   │   ├── index.tsx
│       │   │   │   ├── queries
│       │   │   │   │   └── index.tsx
│       │   │   │   └── types
│       │   │   │       └── rubricAssignment.d.ts
│       │   │   ├── RubricForm
│       │   │   │   ├── CriterionModal.tsx
│       │   │   │   ├── NewCriteriaRow.tsx
│       │   │   │   ├── OutcomeCriterionModal.tsx
│       │   │   │   ├── RubricCriteriaRow.tsx
│       │   │   │   ├── WarningModal.tsx
│       │   │   │   ├── __tests__
│       │   │   │   │   ├── CriterionModal.test.tsx
│       │   │   │   │   ├── OutcomeCriterionModal.test.tsx
│       │   │   │   │   ├── RubricForm.test.tsx
│       │   │   │   │   └── fixtures.ts
│       │   │   │   ├── drag-and-drop
│       │   │   │   │   └── styles.css
│       │   │   │   ├── index.tsx
│       │   │   │   ├── queries
│       │   │   │   │   └── RubricFormQueries.ts
│       │   │   │   ├── types
│       │   │   │   │   └── RubricForm.ts
│       │   │   │   └── utils
│       │   │   │       └── index.ts
│       │   │   ├── RubricImport
│       │   │   │   ├── ImportTable.tsx
│       │   │   │   └── index.ts
│       │   │   ├── __tests__
│       │   │   │   ├── CommentButton.test.jsx
│       │   │   │   ├── Comments.test.jsx
│       │   │   │   ├── Criterion.test.jsx
│       │   │   │   ├── Points.test.jsx
│       │   │   │   ├── Ratings.test.jsx
│       │   │   │   ├── Rubric.test.jsx
│       │   │   │   ├── __snapshots__
│       │   │   │   │   ├── CommentButton.test.jsx.snap
│       │   │   │   │   ├── Comments.test.jsx.snap
│       │   │   │   │   ├── Criterion.test.jsx.snap
│       │   │   │   │   ├── Points.test.jsx.snap
│       │   │   │   │   ├── Ratings.test.jsx.snap
│       │   │   │   │   └── Rubric.test.jsx.snap
│       │   │   │   ├── fixtures.js
│       │   │   │   └── helpers.test.js
│       │   │   ├── api.js
│       │   │   ├── components
│       │   │   │   ├── ProficiencyRating.jsx
│       │   │   │   ├── ProficiencyTable.jsx
│       │   │   │   ├── RubricAddCriterionPopover.jsx
│       │   │   │   ├── RubricManagement.jsx
│       │   │   │   ├── RubricPanel.jsx
│       │   │   │   └── __tests__
│       │   │   │       ├── ProficiencyRating.test.jsx
│       │   │   │       ├── ProficiencyTable.test.jsx
│       │   │   │       ├── RubricManagement.test.jsx
│       │   │   │       └── __snapshots__
│       │   │   │           ├── ProficiencyTable.test.jsx.snap
│       │   │   │           └── RubricManagement.test.jsx.snap
│       │   │   ├── helpers.js
│       │   │   ├── types
│       │   │   │   └── rubric.d.ts
│       │   │   ├── types.js
│       │   │   └── utils
│       │   │       └── index.ts
│       │   └── stores
│       │       └── index.ts
│       ├── schemas
│       │   ├── index.ts
│       │   └── package.json
│       ├── search-item-selector
│       │   ├── package.json
│       │   └── react
│       │       ├── SearchItemSelector.jsx
│       │       ├── __tests__
│       │       │   └── SearchItemSelector.test.jsx
│       │       └── hooks
│       │           ├── __tests__
│       │           │   └── useDebouncedSearchTerm.test.js
│       │           └── useDebouncedSearchTerm.ts
│       ├── sections
│       │   ├── backbone
│       │   │   ├── collections
│       │   │   │   └── SectionCollection.js
│       │   │   └── models
│       │   │       ├── Section.js
│       │   │       └── __tests__
│       │   │           └── Section.spec.js
│       │   └── package.json
│       ├── sections-tooltip
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   └── index.test.jsx
│       │       └── index.jsx
│       ├── select-content-dialog
│       │   ├── __tests__
│       │   │   ├── select_content.test.js
│       │   │   ├── select_content_dialog.test.ts
│       │   │   └── setDefaultToolValues.test.js
│       │   ├── global.d.ts
│       │   ├── jquery
│       │   │   └── select_content_dialog.tsx
│       │   ├── package.json
│       │   ├── react
│       │   │   └── components
│       │   │       ├── FileSelectBox.jsx
│       │   │       └── __tests__
│       │   │           └── FileSelectBox.test.jsx
│       │   ├── select_content.ts
│       │   ├── setDefaultToolValues.ts
│       │   └── stores
│       │       ├── FileStore.js
│       │       ├── FolderStore.js
│       │       ├── ObjectStore.ts
│       │       └── __tests__
│       │           ├── FileStore.spec.js
│       │           ├── FolderStore.spec.js
│       │           └── ObjectStore.test.js
│       ├── select-position
│       │   ├── package.json
│       │   └── react
│       │       ├── ConnectorIcon.jsx
│       │       ├── __tests__
│       │       │   └── index.test.jsx
│       │       └── index.jsx
│       ├── serialize-form
│       │   ├── __tests__
│       │   │   └── serializeForm.test.js
│       │   ├── jquery.serializeForm.js
│       │   └── package.json
│       ├── services
│       │   ├── findLinkForService.js
│       │   └── package.json
│       ├── settings-query
│       │   ├── package.json
│       │   └── react
│       │       └── settingsQuery.ts
│       ├── shave
│       │   ├── index.js
│       │   └── package.json
│       ├── shortid
│       │   ├── index.ts
│       │   └── package.json
│       ├── signup-dialog
│       │   ├── jquery
│       │   │   ├── addPrivacyLinkToDialog.js
│       │   │   ├── index.js
│       │   │   └── validate.js
│       │   ├── jst
│       │   │   ├── newParentDialog.handlebars
│       │   │   ├── newParentDialog.handlebars.json
│       │   │   ├── parentDialog.handlebars
│       │   │   ├── parentDialog.handlebars.json
│       │   │   ├── samlDialog.handlebars
│       │   │   ├── samlDialog.handlebars.json
│       │   │   ├── studentDialog.handlebars
│       │   │   ├── studentDialog.handlebars.json
│       │   │   ├── teacherDialog.handlebars
│       │   │   └── teacherDialog.handlebars.json
│       │   └── package.json
│       ├── sis
│       │   ├── SisValidationHelper.js
│       │   ├── __tests__
│       │   │   └── SisValidationHelper.spec.js
│       │   ├── backbone
│       │   │   └── views
│       │   │       ├── SisButtonView.js
│       │   │       └── __tests__
│       │   │           └── SisButtonView.test.js
│       │   ├── jst
│       │   │   ├── _sisButton.handlebars
│       │   │   └── _sisButton.handlebars.json
│       │   └── package.json
│       ├── sparkles
│       │   ├── package.json
│       │   └── react
│       │       └── components
│       │           ├── Sparkle.tsx
│       │           └── Sparkles.tsx
│       ├── speed-grader-link
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   └── SpeedGraderLink.test.jsx
│       │       └── index.jsx
│       ├── spinner
│       │   ├── jst
│       │   │   ├── _spinner.handlebars
│       │   │   └── _spinner.handlebars.json
│       │   └── package.json
│       ├── split-and-line-icon
│       │   ├── index.jsx
│       │   └── package.json
│       ├── stub-env
│       │   ├── index.js
│       │   └── package.json
│       ├── student-alerts
│       │   ├── package.json
│       │   └── react
│       │       ├── Alert.tsx
│       │       ├── AlertList.tsx
│       │       ├── SaveAlert.tsx
│       │       ├── __tests__
│       │       │   ├── Alert.test.tsx
│       │       │   ├── AlertList.test.tsx
│       │       │   ├── SaveAlert.test.tsx
│       │       │   └── helpers.ts
│       │       ├── types.ts
│       │       └── utils.ts
│       ├── student-group-filter
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   └── StudentGroupFilter.test.jsx
│       │       └── index.jsx
│       ├── student_view_peer_reviews
│       │   ├── package.json
│       │   └── react
│       │       ├── StudentViewPeerReviews.tsx
│       │       └── __tests__
│       │           └── StudentViewPeerReviews.test.tsx
│       ├── submission-sticker
│       │   ├── images
│       │   │   ├── add_sticker.svg
│       │   │   ├── apple.svg
│       │   │   ├── basketball.svg
│       │   │   ├── beaker.svg
│       │   │   ├── bell.svg
│       │   │   ├── book.svg
│       │   │   ├── bookbag.svg
│       │   │   ├── briefcase.svg
│       │   │   ├── bus.svg
│       │   │   ├── calculator.svg
│       │   │   ├── calendar.svg
│       │   │   ├── chem.svg
│       │   │   ├── clock.svg
│       │   │   ├── column.svg
│       │   │   ├── composite_notebook.svg
│       │   │   ├── computer.svg
│       │   │   ├── design.svg
│       │   │   ├── globe.svg
│       │   │   ├── grad.svg
│       │   │   ├── gym.svg
│       │   │   ├── mail.svg
│       │   │   ├── microscope.svg
│       │   │   ├── mouse.svg
│       │   │   ├── music.svg
│       │   │   ├── notebook.svg
│       │   │   ├── page.svg
│       │   │   ├── paintbrush.svg
│       │   │   ├── panda1.svg
│       │   │   ├── panda2.svg
│       │   │   ├── panda3.svg
│       │   │   ├── panda4.svg
│       │   │   ├── panda5.svg
│       │   │   ├── panda6.svg
│       │   │   ├── panda7.svg
│       │   │   ├── panda8.svg
│       │   │   ├── panda9.svg
│       │   │   ├── paperclip.svg
│       │   │   ├── pen.svg
│       │   │   ├── pencil.svg
│       │   │   ├── presentation.svg
│       │   │   ├── ruler.svg
│       │   │   ├── science.svg
│       │   │   ├── science2.svg
│       │   │   ├── scissors.svg
│       │   │   ├── star.svg
│       │   │   ├── tablet.svg
│       │   │   ├── tag.svg
│       │   │   ├── tape.svg
│       │   │   ├── target.svg
│       │   │   ├── telescope.svg
│       │   │   └── trophy.svg
│       │   ├── index.ts
│       │   ├── package.json
│       │   └── react
│       │       ├── components
│       │       │   ├── ClickableImage.tsx
│       │       │   ├── Sticker.tsx
│       │       │   ├── StickerModal.tsx
│       │       │   └── __tests__
│       │       │       └── Sticker.test.tsx
│       │       ├── helpers
│       │       │   ├── api.ts
│       │       │   ├── assetFactory.ts
│       │       │   └── utils.ts
│       │       └── types
│       │           └── stickers.d.ts
│       ├── svg-wrapper
│       │   ├── package.json
│       │   └── react
│       │       └── index.jsx
│       ├── syllabus
│       │   ├── SyllabusViewPrerendered.js
│       │   ├── backbone
│       │   │   └── behaviors
│       │   │       ├── SyllabusBehaviors.js
│       │   │       └── __tests__
│       │   │           └── SyllabusBehaviors.test.js
│       │   ├── jquery
│       │   │   └── calendar_move.js
│       │   └── package.json
│       ├── temporary-enrollment
│       │   ├── package.json
│       │   └── react
│       │       ├── EnrollmentStateSelect.tsx
│       │       ├── EnrollmentTree.tsx
│       │       ├── EnrollmentTreeGroup.tsx
│       │       ├── EnrollmentTreeItem.tsx
│       │       ├── ManageTempEnrollButton.tsx
│       │       ├── RoleMismatchToolTip.tsx
│       │       ├── RoleSearchSelect.tsx
│       │       ├── TempEnrollAssign.tsx
│       │       ├── TempEnrollAvatar.tsx
│       │       ├── TempEnrollCustom.css
│       │       ├── TempEnrollModal.tsx
│       │       ├── TempEnrollNavigation.tsx
│       │       ├── TempEnrollSearch.tsx
│       │       ├── TempEnrollSearchConfirmation.tsx
│       │       ├── TempEnrollUsersListRow.tsx
│       │       ├── TempEnrollView.tsx
│       │       ├── ToolTipWrapper.tsx
│       │       ├── __tests__
│       │       │   ├── EnrollmentStateSelect.test.tsx
│       │       │   ├── EnrollmentTree.test.tsx
│       │       │   ├── EnrollmentTreeGroup.test.tsx
│       │       │   ├── EnrollmentTreeItem.test.tsx
│       │       │   ├── ManageTempEnrollButton.test.tsx
│       │       │   ├── RoleMismatchToolTip.test.tsx
│       │       │   ├── RoleSearchSelect.test.tsx
│       │       │   ├── TempEnrollAssign1.test.tsx
│       │       │   ├── TempEnrollAssign2.test.tsx
│       │       │   ├── TempEnrollAssign3.test.tsx
│       │       │   ├── TempEnrollAvatar.test.tsx
│       │       │   ├── TempEnrollModal.test.tsx
│       │       │   ├── TempEnrollNavigation.test.tsx
│       │       │   ├── TempEnrollSearch.test.tsx
│       │       │   ├── TempEnrollSearchConfirmation.test.tsx
│       │       │   ├── TempEnrollUsersListRow.test.tsx
│       │       │   ├── TempEnrollView.test.tsx
│       │       │   ├── api
│       │       │   │   └── enrollment.test.ts
│       │       │   └── util
│       │       │       ├── analytics.test.tsx
│       │       │       └── helpers.test.ts
│       │       ├── api
│       │       │   └── enrollment.ts
│       │       ├── types.ts
│       │       └── util
│       │           ├── analytics.ts
│       │           └── helpers.ts
│       ├── test-utils
│       │   ├── I18nStubber.js
│       │   ├── MockCanvasClient.js
│       │   ├── Waiters.js
│       │   ├── __tests__
│       │   │   └── assertions.test.js
│       │   ├── assertions.js
│       │   ├── assertionsSpec.js
│       │   ├── fakeENV.js
│       │   ├── fixtures.js
│       │   ├── getFakePage.js
│       │   ├── jestAssertions.js
│       │   ├── package.json
│       │   ├── query.jsx
│       │   ├── spec-support
│       │   │   ├── AsyncTracker.js
│       │   │   ├── ContextTracker.js
│       │   │   ├── EventTracker.js
│       │   │   ├── SafetyNet.js
│       │   │   ├── SandboxFactory.js
│       │   │   ├── logging.js
│       │   │   ├── sandboxes
│       │   │   │   ├── FetchSandbox.js
│       │   │   │   └── SinonSandbox.js
│       │   │   ├── specProtection.js
│       │   │   └── timezoneBackwardsCompatLayer.js
│       │   └── stubRouterContext.jsx
│       ├── theme-editor
│       │   ├── __tests__
│       │   │   └── submitHtmlForm.test.js
│       │   ├── package.json
│       │   ├── react
│       │   │   └── PropTypes.js
│       │   └── submitHtmlForm.js
│       ├── tinymce-equella
│       │   ├── index.js
│       │   └── package.json
│       ├── top-navigation
│       │   ├── package.json
│       │   └── react
│       │       ├── TopNav.tsx
│       │       ├── TopNavPortal.tsx
│       │       ├── TopNavPortalBase.tsx
│       │       ├── TopNavPortalWithDefaults.tsx
│       │       ├── __tests__
│       │       │   └── TopNav.test.tsx
│       │       └── hooks
│       │           └── useToggleCourseNav.ts
│       ├── tour-pubsub
│       │   ├── __tests__
│       │   │   └── pubsub.test.js
│       │   ├── index.ts
│       │   ├── package.json
│       │   └── pubsub.ts
│       ├── trays
│       │   ├── package.json
│       │   └── react
│       │       ├── ContentTypeExternalToolDrawer.tsx
│       │       ├── ContentTypeExternalToolTray.tsx
│       │       ├── LazyTray.jsx
│       │       ├── Tray.tsx
│       │       ├── __tests__
│       │       │   ├── ContentTypeExternalToolDrawer.test.jsx
│       │       │   ├── ContentTypeExternalToolTray.test.jsx
│       │       │   ├── Tray.test.jsx
│       │       │   └── __snapshots__
│       │       │       └── ContentTypeExternalToolDrawer.test.jsx.snap
│       │       └── constants.tsx
│       ├── tree-browser-view
│       │   ├── backbone
│       │   │   └── views
│       │   │       ├── TreeBrowserView.js
│       │   │       ├── TreeItemView.js
│       │   │       └── TreeView.js
│       │   ├── jst
│       │   │   ├── TreeBrowser.handlebars
│       │   │   ├── TreeBrowser.handlebars.json
│       │   │   ├── TreeCollection.handlebars
│       │   │   ├── TreeCollection.handlebars.json
│       │   │   ├── TreeItem.handlebars
│       │   │   └── TreeItem.handlebars.json
│       │   └── package.json
│       ├── types
│       │   ├── MakeOptional.ts
│       │   ├── package.json
│       │   └── timezone.d.ts
│       ├── unread-badge
│       │   ├── package.json
│       │   └── react
│       │       ├── __tests__
│       │       │   └── UnreadBadge.test.jsx
│       │       └── index.jsx
│       ├── unread-icon
│       │   ├── index.jsx
│       │   └── package.json
│       ├── upload-file
│       │   ├── __tests__
│       │   │   └── uploadFile.test.js
│       │   ├── index.js
│       │   └── package.json
│       ├── upload-media-translations
│       │   ├── index.js
│       │   └── package.json
│       ├── use-date-time-format-hook
│       │   ├── __tests__
│       │   │   └── index.test.jsx
│       │   ├── index.ts
│       │   └── package.json
│       ├── use-fetch-api-hook
│       │   ├── __tests__
│       │   │   └── index.test.js
│       │   ├── index.ts
│       │   └── package.json
│       ├── use-immediate-hook
│       │   ├── __tests__
│       │   │   └── index.test.js
│       │   ├── index.js
│       │   └── package.json
│       ├── use-random-interval-hook
│       │   ├── package.json
│       │   └── useRandomInterval.ts
│       ├── use-state-with-callback-hook
│       │   ├── __tests__
│       │   │   └── index.test.jsx
│       │   ├── index.ts
│       │   └── package.json
│       ├── user-settings
│       │   ├── __tests__
│       │   │   └── userSettings.spec.js
│       │   ├── index.ts
│       │   └── package.json
│       ├── user-sortable-name
│       │   ├── jquery
│       │   │   ├── __tests__
│       │   │   │   └── userNameParts.spec.js
│       │   │   ├── index.js
│       │   │   └── user_utils.js
│       │   ├── package.json
│       │   └── react
│       │       └── index.ts
│       ├── users
│       │   ├── backbone
│       │   │   ├── collections
│       │   │   │   └── UserCollection.js
│       │   │   └── models
│       │   │       └── User.js
│       │   ├── package.json
│       │   └── react
│       │       └── proptypes
│       │           └── user.js
│       ├── util
│       │   ├── MessageBus.js
│       │   ├── TextHelper.ts
│       │   ├── __tests__
│       │   │   ├── TextHelper.test.ts
│       │   │   ├── fileHelper.test.js
│       │   │   ├── hex2rgb.test.js
│       │   │   ├── natcompare.spec.js
│       │   │   ├── resourceTypeUtil.test.js
│       │   │   ├── sanitizeUrl.test.js
│       │   │   ├── searchHelpers.spec.js
│       │   │   └── validateReturnToURL.test.js
│       │   ├── contextColorer.js
│       │   ├── decodeFromHex.ts
│       │   ├── fileHelper.jsx
│       │   ├── fileSize.ts
│       │   ├── flattenObjects.ts
│       │   ├── globalUtils.ts
│       │   ├── hex2rgb.ts
│       │   ├── jquery
│       │   │   ├── __tests__
│       │   │   │   ├── apiUserContent.spec.js
│       │   │   │   └── fixDialogButtons.test.js
│       │   │   ├── apiUserContent.js
│       │   │   ├── fixDialogButtons.js
│       │   │   └── markAsDone.js
│       │   ├── legacyCoffeesScriptHelpers.js
│       │   ├── listFormatter.ts
│       │   ├── natcompare.js
│       │   ├── package.json
│       │   ├── preventDefault.ts
│       │   ├── react
│       │   │   ├── proptypes
│       │   │   │   └── plainStoreShape.js
│       │   │   └── testing
│       │   │       ├── MockedProviderWithPossibleTypes.jsx
│       │   │       ├── TableHelper.jsx
│       │   │       └── injectGlobalAlertContainers.ts
│       │   ├── replaceTags.ts
│       │   ├── resourceTypeUtil.js
│       │   ├── rgb2hex.js
│       │   ├── sanitizeUrl.ts
│       │   ├── searchHelpers.js
│       │   ├── splitAssetString.ts
│       │   ├── stringPluralize.ts
│       │   ├── templateData.js
│       │   ├── validateReturnToURL.js
│       │   ├── wasPageReloaded.ts
│       │   └── xhr.ts
│       ├── wiki
│       │   ├── backbone
│       │   │   ├── models
│       │   │   │   ├── WikiPage.js
│       │   │   │   ├── WikiPageRevision.js
│       │   │   │   └── __tests__
│       │   │   │       ├── WikiPage.test.js
│       │   │   │       └── WikiPageRevision.test.js
│       │   │   └── views
│       │   │       ├── StickyHeaderMixin.js
│       │   │       ├── WikiPageDeleteDialog.js
│       │   │       ├── WikiPageEditView.jsx
│       │   │       ├── WikiPageReloadView.js
│       │   │       └── __tests__
│       │   │           ├── WikiPageDeleteDialog.spec.js
│       │   │           └── WikiPageEditView.test.jsx
│       │   ├── jst
│       │   │   ├── WikiPageEdit.handlebars
│       │   │   └── WikiPageEdit.handlebars.json
│       │   ├── package.json
│       │   ├── react
│       │   │   ├── __tests__
│       │   │   │   ├── renderAssignToTray.test.tsx
│       │   │   │   ├── renderFrontPagePill.test.tsx
│       │   │   │   └── renderWikiPageTitle.test.tsx
│       │   │   ├── renderAssignToTray.tsx
│       │   │   ├── renderFrontPagePill.tsx
│       │   │   └── renderWikiPageTitle.tsx
│       │   └── utils
│       │       ├── __tests__
│       │       │   └── titleConflicts.test.tsx
│       │       ├── constants.js
│       │       └── titleConflicts.tsx
│       └── with-breakpoints
│           ├── package.json
│           └── src
│               ├── __tests__
│               │   └── index.test.jsx
│               ├── index.tsx
│               └── types.d.ts
├── ui-build
│   ├── esbuild
│   │   ├── handlebars-plugin.ts
│   │   └── svg-plugin.ts
│   ├── package.json
│   ├── params.js
│   ├── tools
│   │   └── component-info.mjs
│   └── webpack
│       ├── generatePluginBundles.js
│       ├── generatePluginExtensions.js
│       ├── i18nLinerHandlebars.js
│       ├── index.js
│       ├── momentBundles.js
│       ├── remotes.js
│       ├── webpack.plugins.js
│       ├── webpack.rules.js
│       ├── webpack.utils.js
│       ├── webpackHooks
│       │   ├── gnomeNotifications.sh
│       │   └── macNotifications.sh
│       ├── webpackHooks.js
│       └── webpackPublicPath.js
├── vendor
│   └── gems
│       └── bundler-multilock
│           ├── lib
│           │   └── bundler
│           │       ├── multilock
│           │       │   ├── cache.rb
│           │       │   ├── check.rb
│           │       │   ├── ext
│           │       │   │   ├── bundler.rb
│           │       │   │   ├── cli.rb
│           │       │   │   ├── definition.rb
│           │       │   │   ├── dsl.rb
│           │       │   │   ├── plugin
│           │       │   │   │   └── dsl.rb
│           │       │   │   ├── plugin.rb
│           │       │   │   ├── shared_helpers.rb
│           │       │   │   ├── source.rb
│           │       │   │   └── source_list.rb
│           │       │   ├── lockfile_generator.rb
│           │       │   ├── ui
│           │       │   │   └── capture.rb
│           │       │   └── version.rb
│           │       └── multilock.rb
│           └── plugins.rb
├── vitest.config.ts
├── vitest.workspace.ts
└── yarn.lock

4323 directories, 19989 files
