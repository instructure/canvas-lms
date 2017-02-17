#
# Copyright (C) 2011 Instructure, Inc.
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

# rubocop:disable Migration/PrimaryKey
class InitCanvasDb < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table "abstract_courses", :force => true do |t|
      t.string   "sis_source_id"
      t.string   "sis_batch_id"
      t.integer  "department_id", :limit => 8
      t.integer  "college_id", :limit => 8
      t.integer  "root_account_id", :limit => 8
      t.string   "course_code"
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "abstract_courses", ["college_id"], :name => "index_abstract_courses_on_college_id"
    add_index "abstract_courses", ["department_id"], :name => "index_abstract_courses_on_department_id"
    add_index "abstract_courses", ["root_account_id", "sis_source_id"], :name => "index_abstract_courses_on_root_account_id_and_sis_source_id"
    add_index "abstract_courses", ["sis_source_id"], :name => "index_abstract_courses_on_sis_source_id"

    create_table "account_authorization_configs", :force => true do |t|
      t.integer  "account_id", :limit => 8
      t.integer  "auth_port"
      t.string   "auth_host"
      t.string   "auth_base"
      t.string   "auth_username"
      t.string   "auth_crypted_password"
      t.string   "auth_password_salt"
      t.string   "auth_type"
      t.boolean  "auth_over_tls"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "log_in_url"
      t.string   "log_out_url"
      t.string   "identifier_format"
      t.string   "certificate_fingerprint"
      t.string   "entity_id"
      t.string   "change_password_url"
      t.string   "login_handle_name"
      t.string   "auth_filter"
    end

    add_index "account_authorization_configs", ["account_id"], :name => "index_account_authorization_configs_on_account_id"

    create_table "account_reports" do |t|
      t.integer  "user_id", :limit => 8
      t.text     "message"
      t.integer  "account_id", :limit => 8
      t.integer  "attachment_id", :limit => 8
      t.string   "workflow_state", :default => "created"
      t.string   "report_type"
      t.integer  "progress"
      t.date     "start_at"
      t.date     "end_at"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "account_users", :force => true do |t|
      t.integer  "account_id", :limit => 8
      t.integer  "user_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "membership_type", :default => "AccountAdmin"
    end

    add_index "account_users", ["account_id"], :name => "index_account_users_on_account_id"
    add_index "account_users", ["user_id"], :name => "index_account_users_on_user_id"

    create_table "accounts", :force => true do |t|
      t.string   "name"
      t.string   "type"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "workflow_state",                                :default => "active"
      t.datetime "deleted_at"
      t.integer  "parent_account_id", :limit => 8
      t.string   "sis_source_id"
      t.string   "sis_batch_id"
      t.string   "current_sis_batch_id"
      t.integer  "root_account_id", :limit => 8
      t.string   "last_successful_sis_batch_id"
      t.boolean  "moved_in_account_structure",                    :default => true
      t.string   "membership_types"
      t.boolean  "require_authorization_code"
      t.string   "default_time_zone"
      t.string   "external_status",                               :default => "active"
      t.integer  "storage_quota"
      t.integer  "default_storage_quota"
      t.boolean  "enable_user_notes",                             :default => false
      t.string   "allowed_services"
      t.text     "turnitin_pledge"
      t.text     "turnitin_comments"
      t.string   "turnitin_account_id"
      t.string   "turnitin_salt"
      t.string   "turnitin_crypted_secret"
      t.boolean  "show_section_name_as_course_name",              :default => false
      t.boolean  "allow_sis_import",                              :default => false
      t.string   "equella_endpoint"
      t.text     "settings"
      t.string   "sis_name"
      t.string   "uuid"
    end

    add_index "accounts", ["id", "type"], :name => "index_accounts_on_id_and_type"
    add_index "accounts", ["name", "parent_account_id"], :name => "index_accounts_on_name_and_parent_account_id"
    add_index "accounts", ["parent_account_id", "root_account_id"], :name => "index_accounts_on_parent_account_id_and_root_account_id"
    add_index "accounts", ["root_account_id", "sis_source_id"], :name => "index_accounts_on_root_account_id_and_sis_source_id"
    add_index "accounts", ["sis_source_id"], :name => "index_accounts_on_sis_source_id"
    add_index "accounts", ["type"], :name => "index_accounts_on_type"

    create_table "assessment_question_bank_users", :force => true do |t|
      t.integer  "assessment_question_bank_id", :limit => 8
      t.integer  "user_id", :limit => 8
      t.string   "permissions"
      t.string   "workflow_state"
      t.datetime "deleted_at"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "assessment_question_bank_users", ["assessment_question_bank_id"], :name => "assessment_qbu_aqb_id"
    add_index "assessment_question_bank_users", ["user_id"], :name => "assessment_qbu_u_id"

    create_table "assessment_question_banks", :force => true do |t|
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.string   "title"
      t.string   "workflow_state"
      t.datetime "deleted_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "migration_id"
    end

    add_index "assessment_question_banks", ["context_id", "context_type"], :name => "index_on_aqb_on_context_id_and_context_type"

    create_table "assessment_questions", :force => true do |t|
      t.string   "name"
      t.text     "question_data"
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.string   "workflow_state"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "assessment_question_bank_id", :limit => 8
      t.datetime "deleted_at"
      t.string   "migration_id"
      t.integer  "position"
    end

    add_index "assessment_questions", ["assessment_question_bank_id", "position"], :name => "question_bank_id_and_position"
    add_index "assessment_questions", ["context_id", "context_type"], :name => "index_assessment_questions_on_context_id_and_context_type"

    create_table "assessment_requests", :force => true do |t|
      t.integer  "rubric_assessment_id", :limit => 8
      t.integer  "user_id", :limit => 8
      t.integer  "asset_id", :limit => 8
      t.string   "asset_type"
      t.integer  "assessor_asset_id", :limit => 8
      t.string   "assessor_asset_type"
      t.text     "comments"
      t.string   "workflow_state"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "uuid"
      t.integer  "rubric_association_id", :limit => 8
      t.integer  "assessor_id", :limit => 8
    end

    add_index "assessment_requests", ["assessor_asset_id", "assessor_asset_type"], :name => "aa_id_and_aa_type"
    add_index "assessment_requests", ["assessor_id"], :name => "index_assessment_requests_on_assessor_id"
    add_index "assessment_requests", ["asset_id", "asset_type"], :name => "index_assessment_requests_on_asset_id_and_asset_type"
    add_index "assessment_requests", ["rubric_assessment_id"], :name => "index_assessment_requests_on_rubric_assessment_id"
    add_index "assessment_requests", ["rubric_association_id"], :name => "index_assessment_requests_on_rubric_association_id"
    add_index "assessment_requests", ["user_id"], :name => "index_assessment_requests_on_user_id"

    create_table "asset_user_accesses", :force => true do |t|
      t.string   "asset_code"
      t.string   "asset_group_code"
      t.integer  "user_id", :limit => 8
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.integer  "count"
      t.integer  "progress"
      t.datetime "last_access"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "asset_category"
      t.float    "view_score"
      t.float    "participate_score"
      t.string   "action_level"
      t.datetime "summarized_at"
      t.float    "interaction_seconds"
      t.string   "display_name"
      t.string   "membership_type"
    end

    add_index "asset_user_accesses", ["context_id", "context_type"], :name => "index_asset_user_accesses_on_context_id_and_context_type"
    add_index "asset_user_accesses", ["user_id", "asset_code"], :name => "index_asset_user_accesses_on_user_id_and_asset_code"

    create_table "assignment_groups", :force => true do |t|
      t.string   "name"
      t.text     "rules"
      t.string   "default_assignment_name"
      t.integer  "position"
      t.string   "assignment_weighting_scheme"
      t.float    "group_weight"
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.string   "workflow_state"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "cloned_item_id", :limit => 8
      t.string   "context_code"
      t.string   "migration_id"
    end

    add_index "assignment_groups", ["cloned_item_id"], :name => "index_assignment_groups_on_cloned_item_id"
    add_index "assignment_groups", ["context_code"], :name => "index_assignment_groups_on_context_code"
    add_index "assignment_groups", ["context_id", "context_type"], :name => "index_assignment_groups_on_context_id_and_context_type"

    create_table "assignment_reminders", :force => true do |t|
      t.integer  "assignment_id", :limit => 8
      t.integer  "user_id", :limit => 8
      t.datetime "remind_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "reminder_type"
    end

    add_index "assignment_reminders", ["assignment_id"], :name => "index_assignment_reminders_on_assignment_id"
    add_index "assignment_reminders", ["user_id"], :name => "index_assignment_reminders_on_user_id"

    create_table "assignments", :force => true do |t|
      t.string   "title"
      t.text     "description",                       :limit => 16777215
      t.datetime "due_at"
      t.datetime "unlock_at"
      t.datetime "lock_at"
      t.float    "points_possible"
      t.float    "min_score"
      t.float    "max_score"
      t.float    "mastery_score"
      t.string   "grading_type"
      t.string   "submission_types"
      t.string   "before_quiz_submission_types"
      t.string   "workflow_state"
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.integer  "assignment_group_id", :limit => 8
      t.integer  "grading_scheme_id", :limit => 8
      t.integer  "grading_standard_id", :limit => 8
      t.string   "location"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "group_category"
      t.integer  "submissions_downloads",                                 :default => 0
      t.integer  "peer_review_count",                                     :default => 0
      t.datetime "peer_reviews_due_at"
      t.boolean  "peer_reviews_assigned",                                 :default => false
      t.boolean  "peer_reviews",                                          :default => false
      t.boolean  "automatic_peer_reviews",                                :default => false
      t.datetime "reminders_created_for_due_at"
      t.boolean  "publishing_reminder_sent",                              :default => false
      t.boolean  "all_day"
      t.date     "all_day_date"
      t.boolean  "previously_published"
      t.boolean  "could_be_locked"
      t.integer  "cloned_item_id", :limit => 8
      t.string   "context_code"
      t.integer  "position"
      t.string   "migration_id"
      t.boolean  "grade_group_students_individually"
      t.boolean  "anonymous_peer_reviews"
      t.string   "time_zone_edited"
      t.boolean  "turnitin_enabled"
      t.string   "allowed_extensions"
    end

    add_index "assignments", ["assignment_group_id"], :name => "index_assignments_on_assignment_group_id"
    add_index "assignments", ["cloned_item_id"], :name => "index_assignments_on_cloned_item_id"
    add_index "assignments", ["context_code"], :name => "index_assignments_on_context_code"
    add_index "assignments", ["context_id", "context_type"], :name => "index_assignments_on_context_id_and_context_type"
    add_index "assignments", ["due_at", "context_code"], :name => "index_assignments_on_due_at_and_context_code"
    add_index "assignments", ["grading_standard_id"], :name => "index_assignments_on_grading_standard_id"
    add_index "assignments", ["workflow_state"], :name => "index_assignments_on_workflow_state"

    create_table "attachment_associations", :force => true do |t|
      t.integer "attachment_id", :limit => 8
      t.integer "context_id", :limit => 8
      t.string  "context_type"
    end

    add_index "attachment_associations", ["attachment_id"], :name => "index_attachment_associations_on_attachment_id"
    add_index "attachment_associations", ["context_id", "context_type"], :name => "attachment_associations_a_id_a_type"

    create_table "attachments", :force => true do |t|
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.integer  "size"
      t.integer  "folder_id", :limit => 8
      t.integer  "enrollment_id", :limit => 8
      t.string   "content_type"
      t.string   "filename"
      t.string   "uuid"
      t.string   "display_name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "scribd_mime_type_id", :limit => 8
      t.string   "scribd_user"
      t.datetime "submitted_to_scribd_at"
      t.integer  "scribd_account_id", :limit => 8
      t.string   "workflow_state"
      t.text     "scribd_doc"
      t.integer  "user_id", :limit => 8
      t.string   "local_filename"
      t.boolean  "locked",                  :default => false
      t.text     "cached_s3_url"
      t.datetime "s3_url_cached_at"
      t.string   "file_state"
      t.datetime "deleted_at"
      t.integer  "position"
      t.datetime "lock_at"
      t.datetime "unlock_at"
      t.datetime "last_lock_at"
      t.datetime "last_unlock_at"
      t.integer  "scribd_attempts"
      t.boolean  "could_be_locked"
      t.integer  "root_attachment_id", :limit => 8
      t.integer  "cloned_item_id", :limit => 8
      t.string   "migration_id"
      t.string   "namespace"
      t.string   "media_entry_id"
      t.string   "md5"
      t.string   "cached_scribd_thumbnail"
    end

    add_index "attachments", ["cloned_item_id"], :name => "index_attachments_on_cloned_item_id"
    add_index "attachments", ["context_id", "context_type"], :name => "index_attachments_on_context_id_and_context_type"
    add_index "attachments", ["enrollment_id"], :name => "index_attachments_on_enrollment_id"
    add_index "attachments", ["folder_id"], :name => "index_attachments_on_folder_id"
    add_index "attachments", ["md5", "namespace"], :name => "index_attachments_on_md5_and_namespace"
    add_index "attachments", ["root_attachment_id"], :name => "index_attachments_on_root_attachment_id"
    add_index "attachments", ["scribd_account_id"], :name => "index_attachments_on_scribd_account_id"
    add_index "attachments", ["scribd_attempts", "scribd_mime_type_id", "workflow_state"], :name => "scribd_attempts_smt_workflow_state"
    add_index "attachments", ["scribd_mime_type_id"], :name => "index_attachments_on_scribd_mime_type_id"
    add_index "attachments", ["user_id"], :name => "index_attachments_on_user_id"
    add_index "attachments", ["workflow_state", "updated_at"], :name => "index_attachments_on_workflow_state_and_updated_at"

    create_table "authorization_codes", :force => true do |t|
      t.string   "authorization_code"
      t.string   "authorization_service"
      t.integer  "account_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "associated_account_id", :limit => 8
    end

    add_index "authorization_codes", ["account_id"], :name => "index_authorization_codes_on_account_id"

    create_table "calendar_events", :force => true do |t|
      t.string   "title"
      t.text     "description",      :limit => 16777215
      t.string   "location_name"
      t.string   "location_address"
      t.datetime "start_at"
      t.datetime "end_at"
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.string   "workflow_state"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "user_id", :limit => 8
      t.boolean  "all_day"
      t.date     "all_day_date"
      t.datetime "deleted_at"
      t.integer  "cloned_item_id", :limit => 8
      t.string   "context_code"
      t.string   "migration_id"
      t.string   "time_zone_edited"
      t.integer  "external_feed_id", :limit => 8
    end

    add_index "calendar_events", ["cloned_item_id"], :name => "index_calendar_events_on_cloned_item_id"
    add_index "calendar_events", ["context_code"], :name => "index_calendar_events_on_context_code"
    add_index "calendar_events", ["context_id", "context_type"], :name => "index_calendar_events_on_context_id_and_context_type"
    add_index "calendar_events", ["user_id"], :name => "index_calendar_events_on_user_id"

    create_table "cloned_items", :force => true do |t|
      t.integer  "original_item_id", :limit => 8
      t.string   "original_item_type"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "cloned_items", ["original_item_id", "original_item_type"], :name => "cloned_items_original_item_id_and_type"

    create_table "collaborations", :force => true do |t|
      t.string   "collaboration_type"
      t.string   "document_id"
      t.integer  "user_id", :limit => 8
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.string   "url"
      t.string   "uuid"
      t.text     "data"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "description"
      t.string   "title"
      t.string   "workflow_state",     :default => "active"
      t.datetime "deleted_at"
      t.string   "context_code"
      t.string   "type"
    end

    add_index "collaborations", ["context_id", "context_type"], :name => "index_collaborations_on_context_id_and_context_type"
    add_index "collaborations", ["user_id"], :name => "index_collaborations_on_user_id"

    create_table "collaborators", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "collaboration_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "authorized_service_user_id"
    end

    add_index "collaborators", ["collaboration_id"], :name => "index_collaborators_on_collaboration_id"
    add_index "collaborators", ["user_id"], :name => "index_collaborators_on_user_id"

    create_table "communication_channels", :force => true do |t|
      t.string   "path"
      t.string   "path_type",                  :default => "email"
      t.integer  "position"
      t.integer  "user_id", :limit => 8
      t.integer  "pseudonym_id", :limit => 8
      t.integer  "bounce_count",               :default => 0
      t.string   "workflow_state"
      t.string   "confirmation_code"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "build_pseudonym_on_confirm"
    end

    add_index "communication_channels", ["path", "path_type"], :name => "index_communication_channels_on_path_and_path_type"
    add_index "communication_channels", ["pseudonym_id"], :name => "index_communication_channels_on_pseudonym_id"
    add_index "communication_channels", ["user_id"], :name => "index_communication_channels_on_user_id"

    create_table "content_migrations", :force => true do |t|
      t.integer  "context_id", :limit => 8
      t.integer  "user_id", :limit => 8
      t.string   "workflow_state"
      t.text     "migration_settings"
      t.datetime "started_at"
      t.datetime "finished_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.float    "progress"
      t.string   "context_type"
      t.integer  "error_count"
      t.text     "error_data"
      t.integer  "attachment_id", :limit => 8
      t.integer  "overview_attachment_id", :limit => 8
    end

    create_table "content_tags", :force => true do |t|
      t.integer  "content_id", :limit => 8
      t.string   "content_type"
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.string   "title"
      t.string   "tag"
      t.string   "url"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "comments"
      t.string   "tag_type",                      :default => "default"
      t.integer  "context_module_id", :limit => 8
      t.integer  "context_module_association_id", :limit => 8
      t.integer  "position"
      t.integer  "indent"
      t.string   "migration_id"
      t.integer  "learning_outcome_id", :limit => 8
      t.string   "context_code"
      t.float    "mastery_score"
      t.integer  "rubric_association_id", :limit => 8
      t.string   "workflow_state",                :default => "active"
      t.integer  "cloned_item_id", :limit => 8
      t.integer  "associated_asset_id", :limit => 8
      t.string   "associated_asset_type"
    end

    add_index "content_tags", ["content_id", "content_type"], :name => "index_content_tags_on_content_id_and_content_type"
    add_index "content_tags", ["context_id", "context_type"], :name => "index_content_tags_on_context_id_and_context_type"
    add_index "content_tags", ["context_module_id"], :name => "index_content_tags_on_context_module_id"
    add_index "content_tags", ["workflow_state"], :name => "index_content_tags_on_workflow_state"

    create_table "context_message_participants", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "context_message_id", :limit => 8
      t.string   "participation_type"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "context_message_participants", ["context_message_id"], :name => "index_context_message_participants_on_context_message_id"
    add_index "context_message_participants", ["user_id"], :name => "index_context_message_participants_on_user_id"

    create_table "context_messages", :force => true do |t|
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.integer  "user_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "body"
      t.string   "subject"
      t.text     "recipients"
      t.integer  "root_context_message_id", :limit => 8
      t.string   "workflow_state"
      t.string   "viewed_user_ids"
      t.string   "context_code"
      t.boolean  "protect_recipients"
    end

    add_index "context_messages", ["context_id", "context_type"], :name => "index_context_messages_on_context_id_and_context_type"
    add_index "context_messages", ["root_context_message_id"], :name => "index_context_messages_on_root_context_message_id"
    add_index "context_messages", ["user_id"], :name => "index_context_messages_on_user_id"

    create_table "context_module_progressions", :force => true do |t|
      t.integer  "context_module_id", :limit => 8
      t.integer  "user_id", :limit => 8
      t.text     "requirements_met"
      t.string   "workflow_state"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "collapsed"
      t.integer  "current_position"
      t.datetime "completed_at"
    end

    add_index "context_module_progressions", ["context_module_id"], :name => "index_context_module_progressions_on_context_module_id"
    add_index "context_module_progressions", ["user_id", "context_module_id"], :name => "u_id_module_id"

    create_table "context_modules", :force => true do |t|
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.string   "name"
      t.integer  "position"
      t.text     "prerequisites"
      t.text     "completion_requirements"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "downstream_modules"
      t.string   "workflow_state",              :default => "active"
      t.datetime "deleted_at"
      t.datetime "unlock_at"
      t.datetime "start_at"
      t.datetime "end_at"
      t.string   "migration_id"
      t.boolean  "require_sequential_progress"
      t.integer  "cloned_item_id", :limit => 8
    end

    add_index "context_modules", ["context_id", "context_type"], :name => "index_context_modules_on_context_id_and_context_type"

    create_table "course_account_associations", :force => true do |t|
      t.integer  "course_id", :limit => 8
      t.integer  "account_id", :limit => 8
      t.integer  "depth"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "course_section_id", :limit => 8
    end

    add_index "course_account_associations", ["account_id", "depth"], :name => "index_course_account_associations_on_account_id_and_depth_id"
    add_index "course_account_associations", ["course_id"], :name => "index_course_account_associations_on_course_id"

    create_table "course_imports", :force => true do |t|
      t.integer  "course_id", :limit => 8
      t.integer  "source_id", :limit => 8
      t.text     "added_item_codes"
      t.text     "log"
      t.string   "workflow_state"
      t.string   "import_type"
      t.integer  "progress"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "course_sections", :force => true do |t|
      t.string   "sis_source_id"
      t.string   "sis_batch_id"
      t.integer  "course_id", :limit => 8
      t.integer  "abstract_course_id", :limit => 8
      t.integer  "root_account_id", :limit => 8
      t.integer  "enrollment_term_id", :limit => 8
      t.string   "section_code"
      t.string   "long_section_code"
      t.string   "name"
      t.string   "section_organization_name"
      t.boolean  "default_section"
      t.boolean  "accepting_enrollments"
      t.boolean  "can_manually_enroll"
      t.integer  "sis_cross_listed_section_id", :limit => 8
      t.string   "sis_cross_listed_section_sis_batch_id"
      t.datetime "start_at"
      t.datetime "end_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "sis_name"
      t.string   "workflow_state",                        :default => "active"
    end

    add_index "course_sections", ["abstract_course_id"], :name => "index_course_sections_on_abstract_course_id"
    add_index "course_sections", ["course_id"], :name => "index_course_sections_on_course_id"
    add_index "course_sections", ["enrollment_term_id"], :name => "index_course_sections_on_enrollment_term_id"
    add_index "course_sections", ["root_account_id", "sis_source_id"], :name => "index_course_sections_on_root_account_id_and_sis_source_id"
    add_index "course_sections", ["sis_cross_listed_section_id"], :name => "index_course_sections_on_sis_cross_listed_section_id"

    create_table "courses", :force => true do |t|
      t.string   "name"
      t.string   "section"
      t.integer  "account_id", :limit => 8
      t.string   "group_weighting_scheme"
      t.integer  "old_account_id", :limit => 8
      t.string   "workflow_state"
      t.string   "uuid"
      t.datetime "start_at"
      t.datetime "conclude_at"
      t.integer  "grading_standard_id", :limit => 8
      t.boolean  "is_public"
      t.boolean  "publish_grades_immediately"
      t.boolean  "allow_student_wiki_edits"
      t.boolean  "allow_student_assignment_edits"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "hashtag"
      t.boolean  "show_public_context_messages"
      t.text     "syllabus_body",                   :limit => 16777215
      t.text     "hidden_tabs"
      t.boolean  "allow_student_forum_attachments",                     :default => false
      t.string   "default_wiki_editing_roles"
      t.integer  "wiki_id", :limit => 8
      t.boolean  "allow_student_organized_groups",                      :default => true
      t.string   "course_code"
      t.string   "default_view",                                        :default => "feed"
      t.integer  "abstract_course_id", :limit => 8
      t.integer  "root_account_id", :limit => 8
      t.integer  "enrollment_term_id", :limit => 8
      t.string   "sis_source_id"
      t.boolean  "moved_in_account_structure",                          :default => true
      t.string   "sis_batch_id"
      t.boolean  "show_all_discussion_entries"
      t.boolean  "open_enrollment"
      t.integer  "storage_quota"
      t.text     "tab_configuration"
      t.boolean  "allow_wiki_comments"
      t.text     "turnitin_comments"
      t.boolean  "self_enrollment"
      t.string   "license"
      t.boolean  "indexed"
      t.string   "sis_name"
      t.string   "sis_course_code"
    end

    add_index "courses", ["abstract_course_id"], :name => "index_courses_on_abstract_course_id"
    add_index "courses", ["account_id"], :name => "index_courses_on_account_id"
    add_index "courses", ["enrollment_term_id"], :name => "index_courses_on_enrollment_term_id"
    add_index "courses", ["grading_standard_id"], :name => "index_courses_on_grading_standard_id"
    add_index "courses", ["moved_in_account_structure", "updated_at"], :name => "index_courses_on_moved_in_account_structure_and_updated_at"
    add_index "courses", ["root_account_id"], :name => "index_courses_on_root_account_id"
    add_index "courses", ["wiki_id"], :name => "index_courses_on_wiki_id"

    create_table "custom_field_values", :force => true do |t|
      t.integer  "custom_field_id", :limit => 8
      t.string   "value"
      t.string   "customized_type"
      t.integer  "customized_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "custom_fields", :force => true do |t|
      t.string   "name"
      t.string   "description"
      t.string   "field_type"
      t.string   "default_value"
      t.string   "scoper_type"
      t.integer  "scoper_id", :limit => 8
      t.string   "target_type"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "delayed_messages", :force => true do |t|
      t.integer  "notification_id", :limit => 8
      t.integer  "notification_policy_id", :limit => 8
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.integer  "communication_channel_id", :limit => 8
      t.string   "frequency"
      t.string   "workflow_state"
      t.datetime "batched_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "send_at"
      t.string   "link"
      t.string   "name_of_topic"
      t.text     "summary"
    end

    add_index "delayed_messages", ["communication_channel_id", "workflow_state", "send_at"], :name => "ccid_ws_sa"
    add_index "delayed_messages", ["send_at"], :name => "by_sent_at"
    add_index "delayed_messages", ["workflow_state", "send_at"], :name => "ws_sa"

    create_table "delayed_notifications", :force => true do |t|
      t.integer  "notification_id", :limit => 8
      t.integer  "asset_id", :limit => 8
      t.string   "asset_type"
      t.text     "recipient_keys"
      t.string   "workflow_state"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "delayed_notifications", ["workflow_state", "created_at"], :name => "index_delayed_notifications_on_workflow_state_and_created_at"

    create_table "developer_keys", :force => true do |t|
      t.string   "api_key"
      t.string   "email"
      t.string   "user_name"
      t.string   "user_id"
      t.integer  "account_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "discussion_entries", :force => true do |t|
      t.text     "message"
      t.integer  "discussion_topic_id", :limit => 8
      t.integer  "user_id", :limit => 8
      t.integer  "parent_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "attachment_id", :limit => 8
      t.string   "workflow_state",      :default => "active"
      t.datetime "deleted_at"
      t.string   "migration_id"
      t.integer  "editor_id", :limit => 8
    end

    add_index "discussion_entries", ["attachment_id"], :name => "index_discussion_entries_on_attachment_id"
    add_index "discussion_entries", ["discussion_topic_id"], :name => "index_discussion_entries_on_discussion_topic_id"
    add_index "discussion_entries", ["user_id"], :name => "index_discussion_entries_on_user_id"

    create_table "discussion_topics", :force => true do |t|
      t.string   "title"
      t.text     "message",                :limit => 16777215
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.string   "type"
      t.integer  "user_id", :limit => 8
      t.string   "workflow_state"
      t.datetime "last_reply_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "delayed_post_at"
      t.datetime "posted_at"
      t.integer  "assignment_id", :limit => 8
      t.integer  "attachment_id", :limit => 8
      t.datetime "deleted_at"
      t.integer  "root_topic_id", :limit => 8
      t.boolean  "could_be_locked"
      t.integer  "cloned_item_id", :limit => 8
      t.string   "context_code"
      t.integer  "position"
      t.string   "migration_id"
      t.integer  "old_assignment_id", :limit => 8
      t.datetime "subtopics_refreshed_at"
      t.integer  "last_assignment_id", :limit => 8
      t.integer  "external_feed_id", :limit => 8
      t.integer  "editor_id", :limit => 8
    end

    add_index "discussion_topics", ["attachment_id"], :name => "index_discussion_topics_on_attachment_id"
    add_index "discussion_topics", ["cloned_item_id"], :name => "index_discussion_topics_on_cloned_item_id"
    add_index "discussion_topics", ["context_code"], :name => "index_discussion_topics_on_context_code"
    add_index "discussion_topics", ["context_id", "context_type"], :name => "index_discussion_topics_on_context_id_and_context_type"
    add_index "discussion_topics", ["context_id", "position"], :name => "index_discussion_topics_on_context_id_and_position"
    add_index "discussion_topics", ["id", "type"], :name => "index_discussion_topics_on_id_and_type"
    add_index "discussion_topics", ["root_topic_id"], :name => "index_discussion_topics_on_root_topic_id"
    add_index "discussion_topics", ["user_id"], :name => "index_discussion_topics_on_user_id"
    add_index "discussion_topics", ["workflow_state"], :name => "index_discussion_topics_on_workflow_state"

    create_table "enrollment_dates_overrides", :force => true do |t|
      t.integer  "enrollment_term_id", :limit => 8
      t.string   "enrollment_type"
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.datetime "start_at"
      t.datetime "end_at"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "enrollment_terms", :force => true do |t|
      t.integer  "root_account_id", :limit => 8
      t.string   "name"
      t.string   "term_code"
      t.string   "sis_source_id"
      t.string   "sis_batch_id"
      t.datetime "start_at"
      t.datetime "end_at"
      t.boolean  "accepting_enrollments"
      t.boolean  "can_manually_enroll"
      t.text     "sis_data"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "sis_name"
      t.string   "workflow_state",        :default => "active"
    end

    add_index "enrollment_terms", ["root_account_id", "sis_source_id"], :name => "index_enrollment_terms_on_root_account_id_and_sis_source_id"
    add_index "enrollment_terms", ["sis_source_id"], :name => "index_enrollment_terms_on_sis_source_id"

    create_table "enrollments", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "course_id", :limit => 8
      t.string   "type"
      t.string   "uuid"
      t.string   "workflow_state"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "associated_user_id", :limit => 8
      t.string   "sis_source_id"
      t.string   "sis_batch_id"
      t.datetime "start_at"
      t.datetime "end_at"
      t.integer  "course_section_id", :limit => 8
      t.integer  "root_account_id", :limit => 8
      t.string   "invitation_email"
      t.float    "computed_final_score"
      t.datetime "completed_at"
      t.boolean  "limit_priveleges_to_course_section"
      t.boolean  "self_enrolled"
      t.float    "computed_current_score"
    end

    add_index "enrollments", ["course_id", "workflow_state"], :name => "index_enrollments_on_course_id_and_workflow_state"
    add_index "enrollments", ["course_section_id"], :name => "index_enrollments_on_course_section_id"
    add_index "enrollments", ["id", "type"], :name => "index_enrollments_on_id_and_type"
    add_index "enrollments", ["root_account_id"], :name => "index_enrollments_on_root_account_id"
    add_index "enrollments", ["sis_source_id"], :name => "index_enrollments_on_sis_source_id"
    add_index "enrollments", ["user_id"], :name => "index_enrollments_on_user_id"
    add_index "enrollments", ["uuid"], :name => "index_enrollments_on_uuid"
    add_index "enrollments", ["workflow_state"], :name => "index_enrollments_on_workflow_state"

    create_table "eportfolio_categories", :force => true do |t|
      t.integer  "eportfolio_id", :limit => 8
      t.string   "name"
      t.integer  "position"
      t.string   "slug"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "eportfolio_categories", ["eportfolio_id"], :name => "index_eportfolio_categories_on_eportfolio_id"

    create_table "eportfolio_entries", :force => true do |t|
      t.integer  "eportfolio_id", :limit => 8
      t.integer  "eportfolio_category_id", :limit => 8
      t.integer  "position"
      t.string   "name"
      t.integer  "artifact_type"
      t.integer  "attachment_id", :limit => 8
      t.boolean  "allow_comments"
      t.boolean  "show_comments"
      t.string   "slug"
      t.string   "url"
      t.text     "content",                :limit => 16777215
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "eportfolio_entries", ["eportfolio_category_id"], :name => "index_eportfolio_entries_on_eportfolio_category_id"
    add_index "eportfolio_entries", ["eportfolio_id"], :name => "index_eportfolio_entries_on_eportfolio_id"

    create_table "eportfolios", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.string   "name"
      t.boolean  "public"
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "uuid"
      t.string   "workflow_state", :default => "active"
      t.datetime "deleted_at"
    end

    add_index "eportfolios", ["user_id"], :name => "index_eportfolios_on_user_id"

    create_table "error_reports", :force => true do |t|
      t.text     "backtrace"
      t.string   "url"
      t.string   "message"
      t.text     "comments"
      t.integer  "user_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "email"
      t.boolean  "during_tests",                           :default => false
      t.string   "user_agent"
      t.string   "request_method"
      t.text     "http_env",           :limit => 16777215
      t.string   "subject"
      t.string   "request_context_id"
      t.integer  "account_id", :limit => 8
      t.integer  "zendesk_ticket_id", :limit => 8
    end

    add_index "error_reports", ["created_at"], :name => "error_reports_created_at"
    add_index "error_reports", ["zendesk_ticket_id"], :name => "index_error_reports_on_zendesk_ticket_id"

    create_table "external_feed_entries", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "external_feed_id", :limit => 8
      t.string   "title"
      t.text     "message"
      t.string   "source_name"
      t.string   "source_url"
      t.datetime "posted_at"
      t.datetime "start_at"
      t.datetime "end_at"
      t.string   "workflow_state"
      t.string   "url"
      t.string   "author_name"
      t.string   "author_email"
      t.string   "author_url"
      t.integer  "asset_id", :limit => 8
      t.string   "asset_type"
      t.string   "uuid"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "external_feed_entries", ["asset_id", "asset_type"], :name => "index_external_feed_entries_on_asset_id_and_asset_type"
    add_index "external_feed_entries", ["external_feed_id", "uuid"], :name => "external_feed_id_uuid"
    add_index "external_feed_entries", ["user_id"], :name => "index_external_feed_entries_on_user_id"

    create_table "external_feeds", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.integer  "consecutive_failures"
      t.integer  "failures"
      t.datetime "refresh_at"
      t.string   "title"
      t.string   "feed_type"
      t.string   "feed_purpose"
      t.string   "url"
      t.string   "header_match"
      t.string   "body_match"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "verbosity"
    end

    add_index "external_feeds", ["context_id", "context_type"], :name => "index_external_feeds_on_context_id_and_context_type"
    add_index "external_feeds", ["user_id"], :name => "index_external_feeds_on_user_id"

    create_table "folders", :force => true do |t|
      t.string   "name"
      t.string   "full_name"
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.integer  "parent_folder_id", :limit => 8
      t.string   "workflow_state"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "deleted_at"
      t.boolean  "locked"
      t.datetime "lock_at"
      t.datetime "unlock_at"
      t.datetime "last_lock_at"
      t.datetime "last_unlock_at"
      t.integer  "cloned_item_id", :limit => 8
      t.integer  "position"
    end

    add_index "folders", ["cloned_item_id"], :name => "index_folders_on_cloned_item_id"
    add_index "folders", ["context_id", "context_type"], :name => "index_folders_on_context_id_and_context_type"
    add_index "folders", ["parent_folder_id"], :name => "index_folders_on_parent_folder_id"

    create_table "gradebook_uploads", :force => true do |t|
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "gradebook_uploads", ["context_id", "context_type"], :name => "index_gradebook_uploads_on_context_id_and_context_type"

    create_table "grading_standards", :force => true do |t|
      t.string   "title"
      t.text     "data"
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "user_id", :limit => 8
      t.integer  "usage_count"
      t.string   "context_code"
    end

    add_index "grading_standards", ["context_code"], :name => "index_grading_standards_on_context_code"
    add_index "grading_standards", ["context_id", "context_type"], :name => "index_grading_standards_on_context_id_and_context_type"
    add_index "grading_standards", ["user_id"], :name => "index_grading_standards_on_user_id"

    create_table "group_memberships", :force => true do |t|
      t.integer  "group_id", :limit => 8
      t.string   "workflow_state"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "user_id", :limit => 8
      t.string   "uuid"
    end

    add_index "group_memberships", ["group_id"], :name => "index_group_memberships_on_group_id"
    add_index "group_memberships", ["user_id"], :name => "index_group_memberships_on_user_id"
    add_index "group_memberships", ["workflow_state"], :name => "index_group_memberships_on_workflow_state"

    create_table "groups", :force => true do |t|
      t.string   "name"
      t.string   "workflow_state"
      t.integer  "groupable_id", :limit => 8
      t.string   "groupable_type"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.string   "type"
      t.string   "category"
      t.integer  "max_membership"
      t.string   "hashtag"
      t.boolean  "show_public_context_messages"
      t.boolean  "is_public"
      t.integer  "account_id", :limit => 8
      t.string   "default_wiki_editing_roles"
      t.integer  "wiki_id", :limit => 8
      t.datetime "deleted_at"
      t.string   "join_level"
      t.string   "default_view",                 :default => "feed"
      t.string   "migration_id"
      t.integer  "storage_quota"
      t.string   "uuid"
    end

    add_index "groups", ["account_id"], :name => "index_groups_on_account_id"
    add_index "groups", ["context_id", "context_type"], :name => "index_groups_on_context_id_and_context_type"
    add_index "groups", ["id", "type"], :name => "index_groups_on_id_and_type"
    add_index "groups", ["wiki_id"], :name => "index_groups_on_wiki_id"
    add_index "groups", ["workflow_state"], :name => "index_groups_on_workflow_state"

    create_table "hashtags", :force => true do |t|
      t.string   "hashtag"
      t.datetime "refresh_at"
      t.string   "last_result_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "inbox_items", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "sender_id", :limit => 8
      t.integer  "asset_id", :limit => 8
      t.string   "subject"
      t.string   "body_teaser"
      t.string   "asset_type"
      t.string   "workflow_state"
      t.boolean  "sender"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "context_code"
    end

    add_index "inbox_items", ["sender"], :name => "index_inbox_items_on_sender"
    add_index "inbox_items", ["sender_id"], :name => "index_inbox_items_on_sender_id"
    add_index "inbox_items", ["user_id"], :name => "index_inbox_items_on_user_id"
    add_index "inbox_items", ["workflow_state"], :name => "index_inbox_items_on_workflow_state"

    create_table "learning_outcome_groups", :force => true do |t|
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.string   "title"
      t.integer  "learning_outcome_group_id", :limit => 8
      t.integer  "root_learning_outcome_group_id", :limit => 8
      t.string   "workflow_state"
      t.text     "description"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "learning_outcome_results", :force => true do |t|
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.string   "context_code"
      t.integer  "association_id", :limit => 8
      t.string   "association_type"
      t.integer  "content_tag_id", :limit => 8
      t.integer  "learning_outcome_id", :limit => 8
      t.boolean  "mastery"
      t.integer  "user_id", :limit => 8
      t.float    "score"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "attempt"
      t.float    "possible"
      t.string   "comments"
      t.float    "original_score"
      t.float    "original_possible"
      t.boolean  "original_mastery"
      t.integer  "artifact_id", :limit => 8
      t.string   "artifact_type"
      t.datetime "assessed_at"
      t.string   "title"
      t.float    "percent"
    end

    add_index "learning_outcome_results", ["user_id", "content_tag_id"], :name => "index_learning_outcome_results_on_user_id_and_content_tag_id", :unique => true

    create_table "learning_outcomes", :force => true do |t|
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.string   "short_description"
      t.string   "context_code"
      t.text     "description"
      t.text     "data"
      t.string   "workflow_state"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "migration_id"
    end

    create_table "mailboxes", :force => true do |t|
      t.string   "name"
      t.string   "purpose",                 :default => "broadcast"
      t.string   "handle"
      t.string   "content_parser"
      t.string   "workflow_state"
      t.string   "mailboxable_entity_type"
      t.integer  "mailboxable_entity_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "mailboxes", ["handle"], :name => "index_mailboxes_on_handle"
    add_index "mailboxes", ["mailboxable_entity_id", "mailboxable_entity_type"], :name => "me_id_and_me_type"

    create_table "mailboxes_pseudonyms", :force => true do |t|
      t.integer  "mailbox_id", :limit => 8
      t.integer  "pseudonym_id", :limit => 8
      t.string   "workflow_state"
      t.boolean  "originating_party"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "media_objects", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.string   "workflow_state"
      t.string   "user_type"
      t.string   "title"
      t.string   "user_entered_title"
      t.string   "media_id"
      t.string   "media_type"
      t.integer  "duration"
      t.integer  "max_size"
      t.integer  "root_account_id", :limit => 8
      t.text     "data"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "attachment_id", :limit => 8
      t.integer  "total_size"
    end

    add_index "media_objects", ["attachment_id"], :name => "index_media_objects_on_attachment_id"
    add_index "media_objects", ["context_id", "context_type"], :name => "index_media_objects_on_context_id_and_context_type"
    add_index "media_objects", ["media_id"], :name => "index_media_objects_on_media_id"

    create_table "messages", :force => true do |t|
      t.string   "to"
      t.string   "from"
      t.string   "cc"
      t.string   "bcc"
      t.string   "subject"
      t.text     "body"
      t.integer  "delay_for",                :default => 120
      t.datetime "dispatch_at"
      t.datetime "sent_at"
      t.string   "workflow_state"
      t.text     "transmission_errors"
      t.boolean  "is_bounced"
      t.integer  "notification_id", :limit => 8
      t.integer  "communication_channel_id", :limit => 8
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.integer  "asset_context_id", :limit => 8
      t.string   "asset_context_type"
      t.integer  "user_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "notification_name"
      t.string   "url"
      t.string   "path_type"
      t.string   "from_name"
      t.string   "asset_context_code"
      t.string   "notification_category"
      t.boolean  "to_email"
    end

    add_index "messages", ["asset_context_id", "asset_context_type"], :name => "index_messages_on_asset_context_id_and_asset_context_type"
    add_index "messages", ["communication_channel_id"], :name => "index_messages_on_communication_channel_id"
    add_index "messages", ["context_id", "context_type", "notification_name", "to", "user_id"], :name => "existing_undispatched_message"
    add_index "messages", ["notification_id"], :name => "index_messages_on_notification_id"
    add_index "messages", ["notification_name", "workflow_state", "created_at"], :name => "index_messages_on_notification_name_workflow_state_created_at"
    add_index "messages", ["sent_at", "to_email", "user_id", "notification_category"], :name => "index_messages_on_sa_ui_te_nc"
    add_index "messages", ["user_id", "to_email", "dispatch_at"], :name => "index_messages_user_id_dispatch_at_to_email"
    add_index "messages", ["workflow_state", "dispatch_at"], :name => "index_messages_on_workflow_state_and_dispatch_at"

    create_table "notification_policies", :force => true do |t|
      t.integer  "notification_id", :limit => 8
      t.integer  "user_id", :limit => 8
      t.integer  "communication_channel_id", :limit => 8
      t.boolean  "broadcast",                :default => true
      t.string   "frequency"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "notification_policies", ["communication_channel_id"], :name => "index_notification_policies_on_communication_channel_id"
    add_index "notification_policies", ["notification_id"], :name => "index_notification_policies_on_notification_id"
    add_index "notification_policies", ["user_id"], :name => "index_notification_policies_on_user_id"

    create_table "notifications", :force => true do |t|
      t.string   "workflow_state"
      t.string   "name"
      t.string   "subject"
      t.text     "body"
      t.string   "sms_body"
      t.string   "category"
      t.integer  "delay_for",      :default => 120
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "main_link"
    end

    create_table "oauth_requests", :force => true do |t|
      t.string   "token"
      t.string   "secret"
      t.string   "user_secret"
      t.string   "return_url"
      t.string   "workflow_state"
      t.integer  "user_id", :limit => 8
      t.string   "original_host_with_port"
      t.string   "service"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "oauth_requests", ["user_id"], :name => "index_oauth_requests_on_user_id"

    create_table "page_comments", :force => true do |t|
      t.text     "message"
      t.integer  "page_id", :limit => 8
      t.string   "page_type"
      t.integer  "user_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "page_comments", ["page_id", "page_type"], :name => "index_page_comments_on_page_id_and_page_type"
    add_index "page_comments", ["user_id"], :name => "index_page_comments_on_user_id"

    create_table "page_view_ranges", :force => true do |t|
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.integer  "page_view_count"
      t.integer  "page_participated_count"
      t.integer  "total_interaction_seconds"
      t.string   "workflow_state"
      t.float    "mean_interaction_seconds"
      t.integer  "developer_key_count"
      t.datetime "start_at"
      t.datetime "end_at"
      t.text     "data"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "page_view_ranges", ["context_id", "context_type", "start_at", "end_at"], :name => "by_context_range"
    add_index "page_view_ranges", ["workflow_state", "updated_at"], :name => "index_page_view_ranges_on_workflow_state_and_updated_at"

    create_table "page_views", :id => false, :force => true do |t|
      t.string   "request_id"
      t.string   "session_id"
      t.integer  "user_id", :limit => 8
      t.string   "url"
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.integer  "asset_id", :limit => 8
      t.string   "asset_type"
      t.string   "controller"
      t.string   "action"
      t.boolean  "contributed"
      t.float    "interaction_seconds"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "developer_key_id", :limit => 8
      t.boolean  "user_request"
      t.float    "render_time"
      t.string   "user_agent"
      t.integer  "asset_user_access_id", :limit => 8
      t.boolean  "participated"
      t.boolean  "summarized"
      t.integer  "account_id", :limit => 8
    end
    execute("ALTER TABLE #{PageView.quoted_table_name} ADD PRIMARY KEY (request_id)")

    add_index "page_views", ["account_id"], :name => "index_page_views_on_account_id"
    add_index "page_views", ["asset_user_access_id"], :name => "index_page_views_asset_user_access_id"
    add_index "page_views", ["context_type", "context_id"], :name => "index_page_views_on_context_type_and_context_id"
    add_index "page_views", ["summarized", "created_at"], :name => "index_page_views_summarized_created_at"
    add_index "page_views", ["user_id", "created_at"], :name => "index_page_views_on_user_id_and_created_at"

    create_table "plugin_settings", :force => true do |t|
      t.string   "name",       :default => "", :null => false
      t.text     "settings"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "plugin_settings", ["name"], :name => "index_plugin_settings_on_name"

    create_table "pseudonyms", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "account_id", :limit => 8
      t.string   "workflow_state"
      t.string   "type"
      t.string   "unique_id",                                :null => false
      t.string   "crypted_password",                         :null => false
      t.string   "password_salt",                            :null => false
      t.string   "persistence_token",                        :null => false
      t.string   "single_access_token",                      :null => false
      t.string   "perishable_token",                         :null => false
      t.integer  "login_count",              :default => 0,  :null => false
      t.integer  "failed_login_count",       :default => 0,  :null => false
      t.datetime "last_request_at"
      t.datetime "last_login_at"
      t.datetime "current_login_at"
      t.string   "last_login_ip"
      t.string   "current_login_ip"
      t.string   "reset_password_token",     :default => "", :null => false
      t.integer  "position"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "password_auto_generated"
      t.datetime "deleted_at"
      t.string   "deleted_unique_id"
      t.string   "sis_source_id"
      t.string   "sis_batch_id"
      t.string   "sis_user_id"
      t.text     "sis_update_data"
      t.string   "sis_ssha"
      t.integer  "communication_channel_id", :limit => 8
      t.string   "login_path_to_ignore"
    end

    add_index "pseudonyms", ["account_id", "sis_source_id"], :name => "index_pseudonyms_on_account_id_and_sis_source_id"
    add_index "pseudonyms", ["communication_channel_id"], :name => "index_pseudonyms_on_communication_channel_id"
    add_index "pseudonyms", ["persistence_token"], :name => "index_pseudonyms_on_persistence_token"
    add_index "pseudonyms", ["single_access_token"], :name => "index_pseudonyms_on_single_access_token"
    add_index "pseudonyms", ["unique_id"], :name => "index_pseudonyms_on_unique_id"
    add_index "pseudonyms", ["user_id"], :name => "index_pseudonyms_on_user_id"

    create_table "quiz_groups", :force => true do |t|
      t.integer  "quiz_id", :limit => 8
      t.string   "name"
      t.integer  "pick_count"
      t.float    "question_points"
      t.integer  "position"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "migration_id"
      t.integer  "assessment_question_bank_id", :limit => 8
    end

    add_index "quiz_groups", ["quiz_id"], :name => "index_quiz_groups_on_quiz_id"

    create_table "quiz_questions", :force => true do |t|
      t.integer  "quiz_id", :limit => 8
      t.integer  "quiz_group_id", :limit => 8
      t.integer  "assessment_question_id", :limit => 8
      t.text     "question_data"
      t.integer  "assessment_question_version"
      t.integer  "position"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "migration_id"
    end

    add_index "quiz_questions", ["assessment_question_id"], :name => "index_quiz_questions_on_assessment_question_id"
    add_index "quiz_questions", ["quiz_group_id"], :name => "quiz_questions_quiz_group_id"
    add_index "quiz_questions", ["quiz_id"], :name => "index_quiz_questions_on_quiz_id"

    create_table "quiz_submission_snapshots", :force => true do |t|
      t.integer  "quiz_submission_id", :limit => 8
      t.integer  "attempt"
      t.text     "data"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "quiz_submission_snapshots", ["quiz_submission_id"], :name => "index_quiz_submission_snapshots_on_quiz_submission_id"

    create_table "quiz_submissions", :force => true do |t|
      t.integer  "quiz_id", :limit => 8
      t.integer  "quiz_version"
      t.integer  "user_id", :limit => 8
      t.text     "submission_data",      :limit => 16777215
      t.integer  "submission_id", :limit => 8
      t.float    "score"
      t.float    "kept_score"
      t.text     "quiz_data",            :limit => 16777215
      t.datetime "started_at"
      t.datetime "end_at"
      t.datetime "finished_at"
      t.integer  "attempt"
      t.string   "workflow_state"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "fudge_points",                             :default => 0
      t.integer  "quiz_points_possible"
      t.integer  "extra_attempts"
      t.string   "temporary_user_code"
    end

    add_index "quiz_submissions", ["quiz_id", "user_id"], :name => "index_quiz_submissions_on_quiz_id_and_user_id", :unique => true
    add_index "quiz_submissions", ["submission_id"], :name => "index_quiz_submissions_on_submission_id"
    add_index "quiz_submissions", ["temporary_user_code"], :name => "index_quiz_submissions_on_temporary_user_code"
    add_index "quiz_submissions", ["user_id"], :name => "index_quiz_submissions_on_user_id"

    create_table "quizzes", :force => true do |t|
      t.string   "title"
      t.text     "description",                :limit => 16777215
      t.text     "quiz_data",                  :limit => 16777215
      t.float    "points_possible"
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.integer  "assignment_id", :limit => 8
      t.string   "workflow_state"
      t.boolean  "shuffle_answers"
      t.boolean  "show_correct_answers"
      t.integer  "time_limit"
      t.integer  "allowed_attempts"
      t.string   "scoring_policy"
      t.string   "quiz_type"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "lock_at"
      t.datetime "unlock_at"
      t.datetime "deleted_at"
      t.boolean  "could_be_locked"
      t.integer  "cloned_item_id", :limit => 8
      t.string   "access_code"
      t.string   "migration_id"
      t.integer  "unpublished_question_count",                     :default => 0
      t.datetime "due_at"
      t.integer  "question_count"
      t.integer  "last_assignment_id", :limit => 8
      t.datetime "published_at"
      t.datetime "last_edited_at"
      t.boolean  "anonymous_submissions"
      t.integer  "assignment_group_id", :limit => 8
      t.string   "hide_results"
    end

    add_index "quizzes", ["assignment_id"], :name => "index_quizzes_on_assignment_id", :unique => true
    add_index "quizzes", ["cloned_item_id"], :name => "index_quizzes_on_cloned_item_id"
    add_index "quizzes", ["context_id", "context_type"], :name => "index_quizzes_on_context_id_and_context_type"

    create_table "report_snapshots", :force => true do |t|
      t.string   "report_type"
      t.text     "data",        :limit => 16777215
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "role_overrides", :force => true do |t|
      t.string   "enrollment_type"
      t.string   "permission"
      t.boolean  "enabled"
      t.boolean  "locked"
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "context_code"
    end

    add_index "role_overrides", ["context_id", "context_type"], :name => "index_role_overrides_on_context_id_and_context_type"

    create_table "rubric_assessments", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "rubric_id", :limit => 8
      t.integer  "rubric_association_id", :limit => 8
      t.float    "score"
      t.text     "data"
      t.text     "comments"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "artifact_id", :limit => 8
      t.string   "artifact_type"
      t.string   "assessment_type"
      t.integer  "assessor_id", :limit => 8
      t.integer  "artifact_attempt"
    end

    add_index "rubric_assessments", ["artifact_id", "artifact_type"], :name => "index_rubric_assessments_on_artifact_id_and_artifact_type"
    add_index "rubric_assessments", ["assessor_id"], :name => "index_rubric_assessments_on_assessor_id"
    add_index "rubric_assessments", ["rubric_association_id"], :name => "index_rubric_assessments_on_rubric_association_id"
    add_index "rubric_assessments", ["rubric_id"], :name => "index_rubric_assessments_on_rubric_id"
    add_index "rubric_assessments", ["user_id"], :name => "index_rubric_assessments_on_user_id"

    create_table "rubric_associations", :force => true do |t|
      t.integer  "rubric_id", :limit => 8
      t.integer  "association_id", :limit => 8
      t.string   "association_type"
      t.boolean  "use_for_grading"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "title"
      t.text     "description"
      t.text     "summary_data"
      t.string   "purpose"
      t.string   "url"
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.boolean  "hide_score_total"
      t.boolean  "bookmarked",       :default => true
      t.string   "context_code"
    end

    add_index "rubric_associations", ["association_id", "association_type"], :name => "index_rubric_associations_on_aid_and_atype"
    add_index "rubric_associations", ["context_code"], :name => "index_rubric_associations_on_context_code"
    add_index "rubric_associations", ["context_id", "context_type"], :name => "index_rubric_associations_on_context_id_and_context_type"
    add_index "rubric_associations", ["rubric_id"], :name => "index_rubric_associations_on_rubric_id"

    create_table "rubrics", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "rubric_id", :limit => 8
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.text     "data"
      t.integer  "points_possible"
      t.string   "title"
      t.text     "description"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "reusable",                     :default => false
      t.boolean  "public",                       :default => false
      t.boolean  "read_only",                    :default => false
      t.integer  "association_count",            :default => 0
      t.boolean  "free_form_criterion_comments"
      t.string   "context_code"
      t.string   "migration_id"
      t.boolean  "hide_score_total"
      t.string   "workflow_state",               :default => "active"
    end

    add_index "rubrics", ["context_code"], :name => "index_rubrics_on_context_code"
    add_index "rubrics", ["context_id", "context_type"], :name => "index_rubrics_on_context_id_and_context_type"
    add_index "rubrics", ["rubric_id"], :name => "index_rubrics_on_rubric_id"
    add_index "rubrics", ["user_id"], :name => "index_rubrics_on_user_id"

    create_table "scribd_accounts", :force => true do |t|
      t.integer  "scribdable_id", :limit => 8
      t.string   "scribdable_type"
      t.string   "uuid"
      t.string   "workflow_state"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "scribd_accounts", ["scribdable_id", "scribdable_type"], :name => "index_scribd_accounts_on_scribdable_id_and_scribdable_type"

    create_table "scribd_mime_types", :force => true do |t|
      t.string   "extension"
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "scribd_mime_types", ["extension"], :name => "index_scribd_mime_types_on_extension"

    create_table "sessions", :force => true do |t|
      t.string   "session_id", :null => false
      t.text     "data"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
    add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

    create_table "settings", :force => true do |t|
      t.string   "name"
      t.string   "value"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "short_message_associations", :force => true do |t|
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.integer  "short_message_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "short_message_associations", ["context_id", "context_type"], :name => "index_short_message_associations_on_context_id_and_context_type"
    add_index "short_message_associations", ["short_message_id"], :name => "index_short_message_associations_on_short_message_id"

    create_table "short_messages", :force => true do |t|
      t.string   "message"
      t.integer  "user_id", :limit => 8
      t.string   "author_name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "is_public",          :default => false
      t.string   "service_message_id"
      t.string   "service"
      t.string   "service_user_name"
    end

    add_index "short_messages", ["user_id"], :name => "index_short_messages_on_user_id"

    create_table "sis_batch_log_entries", :force => true do |t|
      t.integer  "sis_batch_id", :limit => 8
      t.string   "log_type"
      t.text     "text"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "sis_batches", :force => true do |t|
      t.integer  "account_id", :limit => 8
      t.string   "batch_id"
      t.datetime "ended_at"
      t.integer  "errored_attempts"
      t.string   "workflow_state"
      t.text     "data"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "attachment_id", :limit => 8
      t.integer  "progress"
      t.text     "processing_errors",   :limit => 16777215
      t.text     "processing_warnings", :limit => 16777215
    end

    create_table "sis_cross_listed_sections", :force => true do |t|
      t.string   "sis_source_id"
      t.string   "sis_batch_id"
      t.integer  "course_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "root_account_id", :limit => 8
    end

    add_index "sis_cross_listed_sections", ["root_account_id", "sis_source_id"], :name => "cross_listed_sis_entries"

    create_table "stream_item_instances", :force => true do |t|
      t.integer "user_id", :limit => 8
      t.integer "stream_item_id", :limit => 8
      t.string  "context_code"
    end

    create_table "stream_items", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.string   "context_code"
      t.string   "item_asset_string"
      t.text     "data"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "stream_items", ["item_asset_string", "created_at"], :name => "index_stream_items_on_item_asset_string_and_created_at"
    add_index "stream_items", ["user_id", "context_code", "created_at"], :name => "uid_cc_ca"
    add_index "stream_items", ["user_id", "created_at"], :name => "index_stream_items_on_user_id_created_at"

    create_table "submission_comment_participants", :force => true do |t|
      t.integer  "submission_comment_id", :limit => 8
      t.integer  "user_id", :limit => 8
      t.string   "participation_type"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "submission_comment_participants", ["submission_comment_id"], :name => "index_submission_comment_participants_on_submission_comment_id"
    add_index "submission_comment_participants", ["user_id"], :name => "index_submission_comment_participants_on_user_id"

    create_table "submission_comments", :force => true do |t|
      t.text     "comment"
      t.integer  "submission_id", :limit => 8
      t.integer  "recipient_id", :limit => 8
      t.integer  "author_id", :limit => 8
      t.string   "author_name"
      t.string   "group_comment_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "attachment_ids"
      t.integer  "assessment_request_id", :limit => 8
      t.string   "media_comment_id"
      t.string   "media_comment_type"
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.text     "cached_attachments"
      t.boolean  "anonymous"
      t.boolean  "teacher_only_comment",  :default => false
    end

    add_index "submission_comments", ["assessment_request_id"], :name => "index_submission_comments_on_assessment_request_id"
    add_index "submission_comments", ["author_id"], :name => "index_submission_comments_on_author_id"
    add_index "submission_comments", ["context_id", "context_type"], :name => "index_submission_comments_on_context_id_and_context_type"
    add_index "submission_comments", ["recipient_id"], :name => "index_submission_comments_on_recipient_id"
    add_index "submission_comments", ["submission_id"], :name => "index_submission_comments_on_submission_id"

    create_table "submissions", :force => true do |t|
      t.text     "body",                             :limit => 16777215
      t.string   "url"
      t.integer  "attachment_id", :limit => 8
      t.string   "grade"
      t.float    "score"
      t.datetime "submitted_at"
      t.integer  "assignment_id", :limit => 8
      t.integer  "user_id", :limit => 8
      t.string   "submission_type"
      t.string   "workflow_state"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "group_id", :limit => 8
      t.string   "attachment_ids"
      t.boolean  "processed"
      t.integer  "process_attempts",                                     :default => 0
      t.boolean  "grade_matches_current_submission"
      t.float    "published_score"
      t.string   "published_grade"
      t.datetime "graded_at"
      t.float    "student_entered_score"
      t.integer  "grader_id", :limit => 8
      t.boolean  "changed_since_publish"
      t.string   "media_comment_id"
      t.string   "media_comment_type"
      t.integer  "quiz_submission_id", :limit => 8
      t.integer  "submission_comments_count"
      t.boolean  "has_rubric_assessment"
      t.integer  "attempt"
      t.string   "context_code"
      t.integer  "media_object_id", :limit => 8
      t.text     "turnitin_data"
    end

    add_index "submissions", ["assignment_id", "submission_type"], :name => "index_submissions_on_assignment_id_and_submission_type"
    add_index "submissions", ["attachment_id", "submission_type", "process_attempts"], :name => "aid_submission_type_process_attempts"
    add_index "submissions", ["grader_id"], :name => "index_submissions_on_grader_id"
    add_index "submissions", ["group_id"], :name => "index_submissions_on_group_id"
    add_index "submissions", ["user_id", "assignment_id"], :name => "index_submissions_on_user_id_and_assignment_id", :unique => true
    add_index "submissions", ["user_id"], :name => "index_submissions_on_user_id"

    create_table "thumbnails", :force => true do |t|
      t.integer  "parent_id", :limit => 8
      t.string   "content_type"
      t.string   "filename"
      t.string   "thumbnail"
      t.integer  "size"
      t.integer  "width"
      t.integer  "height"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "thumbnails", ["parent_id"], :name => "index_thumbnails_on_parent_id"

    create_table "user_account_associations", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "account_id", :limit => 8
      t.integer  "depth"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "user_account_associations", ["account_id"], :name => "index_user_account_associations_on_account_id"
    add_index "user_account_associations", ["user_id"], :name => "index_user_account_associations_on_user_id"

    create_table "user_notes", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.text     "note"
      t.string   "title"
      t.integer  "created_by_id", :limit => 8
      t.string   "workflow_state", :default => "active"
      t.datetime "deleted_at"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "user_notes", ["user_id", "workflow_state"], :name => "index_user_notes_on_user_id_and_workflow_state"

    create_table "user_services", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.string   "token"
      t.string   "secret"
      t.string   "protocol"
      t.string   "service"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "service_user_url"
      t.string   "service_user_id"
      t.string   "service_user_name"
      t.string   "service_domain"
      t.string   "crypted_password"
      t.string   "password_salt"
      t.string   "type"
      t.string   "workflow_state"
      t.string   "last_result_id"
      t.datetime "refresh_at"
    end

    add_index "user_services", ["id", "type"], :name => "index_user_services_on_id_and_type"
    add_index "user_services", ["user_id"], :name => "index_user_services_on_user_id"

    create_table "users", :force => true do |t|
      t.string   "name"
      t.string   "type"
      t.string   "sortable_name"
      t.string   "workflow_state"
      t.integer  "merge_to"
      t.string   "time_zone"
      t.string   "uuid"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "visibility"
      t.string   "avatar_image_url"
      t.string   "avatar_image_source"
      t.datetime "avatar_image_updated_at"
      t.string   "phone"
      t.string   "school_name"
      t.string   "school_position"
      t.string   "short_name"
      t.datetime "deleted_at"
      t.boolean  "show_user_services",          :default => true
      t.string   "gender"
      t.integer  "page_views_count",            :default => 0
      t.string   "creation_unique_id"
      t.string   "creation_sis_batch_id"
      t.string   "creation_email"
      t.boolean  "moved_in_account_structure",  :default => true
      t.integer  "unread_inbox_items_count"
      t.integer  "reminder_time_for_due_dates", :default => 172800
      t.integer  "reminder_time_for_grading",   :default => 0
      t.integer  "storage_quota"
      t.string   "visible_inbox_types"
      t.datetime "last_user_note"
      t.boolean  "subscribe_to_emails"
      t.string   "features_used"
      t.string   "sis_name"
      t.text     "preferences"
      t.string   "avatar_state"
    end

    add_index "users", ["avatar_state", "avatar_image_updated_at"], :name => "index_users_on_avatar_state_and_avatar_image_updated_at"
    add_index "users", ["creation_unique_id", "creation_sis_batch_id"], :name => "users_sis_creation"
    add_index "users", ["id", "type"], :name => "index_users_on_id_and_type"
    add_index "users", ["moved_in_account_structure"], :name => "index_users_on_moved_in_account_structure"
    add_index "users", ["sortable_name"], :name => "index_users_on_sortable_name"
    add_index "users", ["uuid"], :name => "index_users_on_uuid"

    create_table "versions", :force => true do |t|
      t.integer  "versionable_id", :limit => 8
      t.string   "versionable_type"
      t.integer  "number"
      t.text     "yaml",             :limit => 16777215
      t.datetime "created_at"
    end

    add_index "versions", ["versionable_id", "versionable_type"], :name => "index_versions_on_versionable_id_and_versionable_type"

    create_table "web_conference_participants", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "web_conference_id", :limit => 8
      t.string   "participation_type"
      t.string   "workflow_state"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "web_conference_participants", ["user_id"], :name => "index_web_conference_participants_on_user_id"
    add_index "web_conference_participants", ["web_conference_id"], :name => "index_web_conference_participants_on_web_conference_id"

    create_table "web_conferences", :force => true do |t|
      t.string   "title"
      t.string   "conference_type"
      t.string   "conference_key"
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.string   "user_ids"
      t.string   "added_user_ids"
      t.integer  "user_id", :limit => 8
      t.datetime "started_at"
      t.text     "description"
      t.float    "duration"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "uuid"
      t.string   "invited_user_ids"
      t.datetime "ended_at"
      t.datetime "start_at"
      t.datetime "end_at"
      t.string   "context_code"
      t.string   "type"
    end

    add_index "web_conferences", ["context_id", "context_type"], :name => "index_web_conferences_on_context_id_and_context_type"
    add_index "web_conferences", ["user_id"], :name => "index_web_conferences_on_user_id"

    create_table "wiki_namespaces", :force => true do |t|
      t.integer  "wiki_id", :limit => 8
      t.string   "namespace"
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "collaboration_id", :limit => 8
    end

    add_index "wiki_namespaces", ["context_id", "context_type"], :name => "index_wiki_namespaces_on_context_id_and_context_type"
    add_index "wiki_namespaces", ["wiki_id"], :name => "index_wiki_namespaces_on_wiki_id"

    create_table "wiki_page_comments", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "wiki_page_id", :limit => 8
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.string   "user_name"
      t.text     "comments"
      t.string   "workflow_state"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "wiki_page_comments", ["wiki_page_id", "workflow_state"], :name => "index_wiki_page_comments_on_wiki_page_id_and_workflow_state"

    create_table "wiki_pages", :force => true do |t|
      t.integer  "wiki_id", :limit => 8
      t.string   "title"
      t.text     "body",                     :limit => 16777215
      t.string   "workflow_state"
      t.string   "recent_editors"
      t.integer  "user_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "url"
      t.datetime "delayed_post_at"
      t.boolean  "protected_editing",                            :default => false
      t.boolean  "hide_from_students",                           :default => false
      t.string   "editing_roles"
      t.integer  "view_count",                                   :default => 0
      t.datetime "revised_at"
      t.boolean  "could_be_locked"
      t.integer  "cloned_item_id", :limit => 8
      t.string   "migration_id"
      t.integer  "wiki_page_comments_count"
    end

    add_index "wiki_pages", ["cloned_item_id"], :name => "index_wiki_pages_on_cloned_item_id"
    add_index "wiki_pages", ["user_id"], :name => "index_wiki_pages_on_user_id"
    add_index "wiki_pages", ["wiki_id"], :name => "index_wiki_pages_on_wiki_id"

    create_table "wikis", :force => true do |t|
      t.string   "title"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
