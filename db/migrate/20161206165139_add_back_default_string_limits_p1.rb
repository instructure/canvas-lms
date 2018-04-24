#
# Copyright (C) 2016 - present Instructure, Inc.
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

class AddBackDefaultStringLimitsP1 < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    add_string_limit_if_missing :abstract_courses, :sis_source_id
    add_string_limit_if_missing :abstract_courses, :short_name
    add_string_limit_if_missing :abstract_courses, :name
    add_string_limit_if_missing :abstract_courses, :workflow_state

    add_string_limit_if_missing :access_tokens, :purpose
    add_string_limit_if_missing :access_tokens, :crypted_token
    add_string_limit_if_missing :access_tokens, :token_hint
    add_string_limit_if_missing :access_tokens, :crypted_refresh_token

    AuthenticationProvider.maybe_recreate_view do
      add_string_limit_if_missing :account_authorization_configs, :auth_host
      add_string_limit_if_missing :account_authorization_configs, :auth_base
      add_string_limit_if_missing :account_authorization_configs, :auth_username
      add_string_limit_if_missing :account_authorization_configs, :auth_crypted_password
      add_string_limit_if_missing :account_authorization_configs, :auth_password_salt
      add_string_limit_if_missing :account_authorization_configs, :auth_type
      add_string_limit_if_missing :account_authorization_configs, :auth_over_tls
      add_string_limit_if_missing :account_authorization_configs, :log_in_url
      add_string_limit_if_missing :account_authorization_configs, :log_out_url
      add_string_limit_if_missing :account_authorization_configs, :identifier_format
      add_string_limit_if_missing :account_authorization_configs, :entity_id
      add_string_limit_if_missing :account_authorization_configs, :requested_authn_context
      add_string_limit_if_missing :account_authorization_configs, :idp_entity_id
      add_string_limit_if_missing :account_authorization_configs, :workflow_state
      add_string_limit_if_missing :account_authorization_configs, :metadata_uri
    end

    add_string_limit_if_missing :account_notifications, :subject
    add_string_limit_if_missing :account_notifications, :icon
    add_string_limit_if_missing :account_notifications, :required_account_service

    add_string_limit_if_missing :account_reports, :workflow_state
    add_string_limit_if_missing :account_reports, :report_type

    add_string_limit_if_missing :accounts, :name
    add_string_limit_if_missing :accounts, :workflow_state
    add_string_limit_if_missing :accounts, :sis_source_id
    add_string_limit_if_missing :accounts, :membership_types
    add_string_limit_if_missing :accounts, :default_time_zone
    add_string_limit_if_missing :accounts, :external_status
    add_string_limit_if_missing :accounts, :allowed_services
    add_string_limit_if_missing :accounts, :turnitin_account_id
    add_string_limit_if_missing :accounts, :turnitin_salt
    add_string_limit_if_missing :accounts, :turnitin_crypted_secret
    add_string_limit_if_missing :accounts, :equella_endpoint
    add_string_limit_if_missing :accounts, :uuid
    add_string_limit_if_missing :accounts, :default_locale
    add_string_limit_if_missing :accounts, :lti_guid
    add_string_limit_if_missing :accounts, :turnitin_host
    add_string_limit_if_missing :accounts, :integration_id
    add_string_limit_if_missing :accounts, :lti_context_id
    add_string_limit_if_missing :accounts, :turnitin_originality

    add_string_limit_if_missing :alert_criteria, :criterion_type

    add_string_limit_if_missing :alerts, :context_type

    add_string_limit_if_missing :appointment_group_contexts, :context_code
    add_string_limit_if_missing :appointment_group_contexts, :context_type

    add_string_limit_if_missing :appointment_group_sub_contexts, :sub_context_type
    add_string_limit_if_missing :appointment_group_sub_contexts, :sub_context_code

    add_string_limit_if_missing :appointment_groups, :title
    add_string_limit_if_missing :appointment_groups, :location_name
    add_string_limit_if_missing :appointment_groups, :location_address
    add_string_limit_if_missing :appointment_groups, :context_type
    add_string_limit_if_missing :appointment_groups, :context_code
    add_string_limit_if_missing :appointment_groups, :sub_context_type
    add_string_limit_if_missing :appointment_groups, :sub_context_code
    add_string_limit_if_missing :appointment_groups, :workflow_state
    add_string_limit_if_missing :appointment_groups, :participant_visibility

    add_string_limit_if_missing :assessment_question_banks, :context_type
    add_string_limit_if_missing :assessment_question_banks, :workflow_state
    add_string_limit_if_missing :assessment_question_banks, :migration_id

    add_string_limit_if_missing :assessment_questions, :context_type
    add_string_limit_if_missing :assessment_questions, :workflow_state
    add_string_limit_if_missing :assessment_questions, :migration_id

    add_string_limit_if_missing :assessment_requests, :asset_type
    add_string_limit_if_missing :assessment_requests, :assessor_asset_type
    add_string_limit_if_missing :assessment_requests, :workflow_state
    add_string_limit_if_missing :assessment_requests, :uuid

    add_string_limit_if_missing :asset_user_accesses, :asset_code
    add_string_limit_if_missing :asset_user_accesses, :asset_group_code
    add_string_limit_if_missing :asset_user_accesses, :context_type
    add_string_limit_if_missing :asset_user_accesses, :asset_category
    add_string_limit_if_missing :asset_user_accesses, :action_level
    add_string_limit_if_missing :asset_user_accesses, :membership_type

    add_string_limit_if_missing :assignment_configuration_tool_lookups, :tool_type

    add_string_limit_if_missing :assignment_groups, :name
    add_string_limit_if_missing :assignment_groups, :default_assignment_name
    add_string_limit_if_missing :assignment_groups, :assignment_weighting_scheme
    add_string_limit_if_missing :assignment_groups, :context_type
    add_string_limit_if_missing :assignment_groups, :workflow_state
    add_string_limit_if_missing :assignment_groups, :context_code
    add_string_limit_if_missing :assignment_groups, :migration_id
    add_string_limit_if_missing :assignment_groups, :sis_source_id

    add_string_limit_if_missing :assignment_overrides, :title

    add_string_limit_if_missing :assignments, :title
    add_string_limit_if_missing :assignments, :grading_type
    add_string_limit_if_missing :assignments, :group_category
    add_string_limit_if_missing :assignments, :context_code
    add_string_limit_if_missing :assignments, :migration_id
    add_string_limit_if_missing :assignments, :time_zone_edited
    add_string_limit_if_missing :assignments, :allowed_extensions
    add_string_limit_if_missing :assignments, :integration_id
    # This column was added after the rails 4.2 cutover was complete, so is not
    # limited anywhere and adding a limit now would cause a large table rewrite
    # that we don't want to deal with.
    # add_string_limit_if_missing :assignments, :lti_context_id

    add_string_limit_if_missing :course_sections, :sis_source_id
    add_string_limit_if_missing :course_sections, :name
    add_string_limit_if_missing :course_sections, :workflow_state
    add_string_limit_if_missing :course_sections, :integration_id

    add_string_limit_if_missing :courses, :name
    add_string_limit_if_missing :courses, :group_weighting_scheme
    add_string_limit_if_missing :courses, :workflow_state
    add_string_limit_if_missing :courses, :uuid
    add_string_limit_if_missing :courses, :default_wiki_editing_roles
    add_string_limit_if_missing :courses, :course_code
    add_string_limit_if_missing :courses, :default_view
    add_string_limit_if_missing :courses, :sis_source_id
    add_string_limit_if_missing :courses, :license
    add_string_limit_if_missing :courses, :locale
    add_string_limit_if_missing :courses, :self_enrollment_code
    add_string_limit_if_missing :courses, :integration_id
    add_string_limit_if_missing :courses, :time_zone
    add_string_limit_if_missing :courses, :lti_context_id

    add_string_limit_if_missing :enrollments, :uuid
    add_string_limit_if_missing :enrollments, :grade_publishing_status

    add_string_limit_if_missing :group_memberships, :uuid

    add_string_limit_if_missing :groups, :name
    add_string_limit_if_missing :groups, :category
    add_string_limit_if_missing :groups, :join_level
    add_string_limit_if_missing :groups, :default_view
    add_string_limit_if_missing :groups, :migration_id
    add_string_limit_if_missing :groups, :uuid
    add_string_limit_if_missing :groups, :sis_source_id
    add_string_limit_if_missing :groups, :lti_context_id

    add_string_limit_if_missing :submissions, :url
    add_string_limit_if_missing :submissions, :grade
    add_string_limit_if_missing :submissions, :submission_type
    add_string_limit_if_missing :submissions, :published_grade
    add_string_limit_if_missing :submissions, :media_comment_id
    add_string_limit_if_missing :submissions, :media_comment_type
    add_string_limit_if_missing :submissions, :context_code

    add_string_limit_if_missing :attachment_associations, :context_type

    add_string_limit_if_missing :attachments, :context_type
    add_string_limit_if_missing :attachments, :content_type
    add_string_limit_if_missing :attachments, :uuid
    add_string_limit_if_missing :attachments, :workflow_state
    add_string_limit_if_missing :attachments, :file_state
    add_string_limit_if_missing :attachments, :migration_id
    add_string_limit_if_missing :attachments, :namespace
    add_string_limit_if_missing :attachments, :media_entry_id
    add_string_limit_if_missing :attachments, :md5
    add_string_limit_if_missing :attachments, :encoding
    add_string_limit_if_missing :attachments, :upload_error_message

    add_string_limit_if_missing :bookmarks_bookmarks, :name
    add_string_limit_if_missing :bookmarks_bookmarks, :url

    add_string_limit_if_missing :brand_configs, :name
    add_string_limit_if_missing :brand_configs, :parent_md5

    add_string_limit_if_missing :calendar_events, :title
    add_string_limit_if_missing :calendar_events, :location_name
    add_string_limit_if_missing :calendar_events, :location_address
    add_string_limit_if_missing :calendar_events, :context_type
    add_string_limit_if_missing :calendar_events, :workflow_state
    add_string_limit_if_missing :calendar_events, :context_code
    add_string_limit_if_missing :calendar_events, :migration_id
    add_string_limit_if_missing :calendar_events, :time_zone_edited
    add_string_limit_if_missing :calendar_events, :effective_context_code
    add_string_limit_if_missing :calendar_events, :timetable_code

    add_string_limit_if_missing :canvadocs, :document_id
    add_string_limit_if_missing :canvadocs, :process_state
    add_string_limit_if_missing :canvadocs, :preferred_plugin_course_id

    add_string_limit_if_missing :cloned_items, :original_item_type

    add_string_limit_if_missing :collaborations, :collaboration_type
    add_string_limit_if_missing :collaborations, :document_id
    add_string_limit_if_missing :collaborations, :context_type
    add_string_limit_if_missing :collaborations, :url
    add_string_limit_if_missing :collaborations, :uuid
    add_string_limit_if_missing :collaborations, :title
    add_string_limit_if_missing :collaborations, :workflow_state
    add_string_limit_if_missing :collaborations, :context_code
    add_string_limit_if_missing :collaborations, :type

    add_string_limit_if_missing :collaborators, :authorized_service_user_id

    add_string_limit_if_missing :communication_channels, :path
    add_string_limit_if_missing :communication_channels, :path_type
    add_string_limit_if_missing :communication_channels, :workflow_state
    add_string_limit_if_missing :communication_channels, :confirmation_code

    add_string_limit_if_missing :content_exports, :export_type
    add_string_limit_if_missing :content_exports, :workflow_state
    add_string_limit_if_missing :content_exports, :context_type

    add_string_limit_if_missing :content_migrations, :workflow_state
    add_string_limit_if_missing :content_migrations, :context_type
    add_string_limit_if_missing :content_migrations, :migration_type

    add_string_limit_if_missing :content_participation_counts, :content_type
    add_string_limit_if_missing :content_participation_counts, :context_type

    add_string_limit_if_missing :content_participations, :content_type
    add_string_limit_if_missing :content_participations, :workflow_state

    add_string_limit_if_missing :content_tags, :content_type
    add_string_limit_if_missing :content_tags, :context_type
    add_string_limit_if_missing :content_tags, :tag
    add_string_limit_if_missing :content_tags, :tag_type
    add_string_limit_if_missing :content_tags, :migration_id
    add_string_limit_if_missing :content_tags, :context_code
    add_string_limit_if_missing :content_tags, :workflow_state
    add_string_limit_if_missing :content_tags, :associated_asset_type

    add_string_limit_if_missing :context_external_tool_placements, :placement_type

    add_string_limit_if_missing :context_external_tools, :context_type
    add_string_limit_if_missing :context_external_tools, :domain
    add_string_limit_if_missing :context_external_tools, :name
    add_string_limit_if_missing :context_external_tools, :workflow_state
    add_string_limit_if_missing :context_external_tools, :migration_id
    add_string_limit_if_missing :context_external_tools, :tool_id
    add_string_limit_if_missing :context_external_tools, :app_center_id

    add_string_limit_if_missing :context_module_progressions, :workflow_state

    add_string_limit_if_missing :context_modules, :context_type
    add_string_limit_if_missing :context_modules, :workflow_state
    add_string_limit_if_missing :context_modules, :migration_id

    add_string_limit_if_missing :conversation_batches, :workflow_state
    add_string_limit_if_missing :conversation_batches, :context_type
    add_string_limit_if_missing :conversation_batches, :subject

    add_string_limit_if_missing :conversation_message_participants, :workflow_state

    add_string_limit_if_missing :conversation_messages, :media_comment_id
    add_string_limit_if_missing :conversation_messages, :media_comment_type
    add_string_limit_if_missing :conversation_messages, :context_type
    add_string_limit_if_missing :conversation_messages, :asset_type

    add_string_limit_if_missing :conversation_participants, :workflow_state
    add_string_limit_if_missing :conversation_participants, :label
    add_string_limit_if_missing :conversation_participants, :private_hash

    add_string_limit_if_missing :conversations, :private_hash
    add_string_limit_if_missing :conversations, :subject
    add_string_limit_if_missing :conversations, :context_type

    add_string_limit_if_missing :crocodoc_documents, :uuid
    add_string_limit_if_missing :crocodoc_documents, :process_state

    add_string_limit_if_missing :custom_data, :namespace

    add_string_limit_if_missing :custom_gradebook_column_data, :content

    add_string_limit_if_missing :custom_gradebook_columns, :title
    add_string_limit_if_missing :custom_gradebook_columns, :workflow_state
  end

  def add_string_limit_if_missing(table, column)
    return if column_exists?(table, column, :string, limit: 255)
    change_column table, column, :string, limit: 255
  end
end
