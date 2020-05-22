#
# Copyright (C) 2011 - present Instructure, Inc.
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
    connection.transaction(:requires_new => true) do
      begin
        execute("CREATE EXTENSION IF NOT EXISTS pg_collkey SCHEMA #{connection.shard.name}")
      rescue ActiveRecord::StatementInvalid
        raise ActiveRecord::Rollback
      end
    end

    connection.transaction(:requires_new => true) do
      begin
        execute("CREATE EXTENSION IF NOT EXISTS pg_trgm SCHEMA #{connection.shard.name}")
      rescue ActiveRecord::StatementInvalid
        raise ActiveRecord::Rollback
      end
    end

    # everything else is alphabetical,
    # sometimes defining classes try to access
    # this table def and it needs to exist first
    create_table "settings", :force => true do |t|
      t.string   "name", limit: 255
      t.text     "value"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    add_index :settings, :name, :unique => true

    create_table "abstract_courses", :force => true do |t|
      t.string   "sis_source_id", limit: 255
      t.integer  "sis_batch_id", :limit => 8
      t.integer  "account_id", limit: 8, :null => false
      t.integer  "root_account_id", :limit => 8, :null => false
      t.string   "short_name", limit: 255
      t.string   "name", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "enrollment_term_id", :limit => 8, :null => false
      t.string   "workflow_state", :null => false, limit: 255
      t.text     "stuck_sis_fields"
    end

    add_index "abstract_courses", ["root_account_id", "sis_source_id"], :name => "index_abstract_courses_on_root_account_id_and_sis_source_id"
    add_index "abstract_courses", ["sis_source_id"], :name => "index_abstract_courses_on_sis_source_id"
    add_index :abstract_courses, :sis_batch_id, where: "sis_batch_id IS NOT NULL"
    add_index :abstract_courses, :enrollment_term_id

    create_table :access_tokens do |t|
      t.integer :developer_key_id, :limit => 8, :null => false
      t.integer :user_id, :limit => 8
      t.datetime :last_used_at
      t.datetime :expires_at
      t.string :purpose, limit: 255
      t.timestamps null: true
      t.string :crypted_token, limit: 255
      t.string :token_hint, limit: 255
      t.text :scopes
      t.boolean :remember_access
      t.string :crypted_refresh_token, limit: 255
    end
    add_index :access_tokens, [:crypted_token], :unique => true
    add_index :access_tokens, [:crypted_refresh_token], :unique => true
    add_index :access_tokens, :user_id

    create_table "account_authorization_configs", :force => true do |t|
      t.integer  "account_id", :limit => 8, :null => false
      t.integer  "auth_port"
      t.string   "auth_host", limit: 255
      t.string   "auth_base", limit: 255
      t.string   "auth_username", limit: 255
      t.string   "auth_crypted_password", limit: 255
      t.string   "auth_password_salt", limit: 255
      t.string   "auth_type", limit: 255
      t.string   "auth_over_tls", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "log_in_url", limit: 255
      t.string   "log_out_url", limit: 255
      t.string   "identifier_format", limit: 255
      t.text     "certificate_fingerprint"
      t.string   "entity_id", limit: 255
      t.text     "auth_filter"
      t.string   "requested_authn_context", limit: 255
      t.datetime "last_timeout_failure"
      t.text     "login_attribute"
      t.string   "idp_entity_id", limit: 255
      t.integer  "position"
      t.boolean  "parent_registration", default: false, null: false
      t.string   "workflow_state", default: "active", null: false, limit: 255
      t.boolean  "jit_provisioning", default: false, null: false
      t.string   "metadata_uri", limit: 255
      t.json     "settings", default: {}, null: false
    end

    add_index "account_authorization_configs", ["account_id"], :name => "index_account_authorization_configs_on_account_id"
    add_index :account_authorization_configs, :workflow_state
    add_index :account_authorization_configs, :metadata_uri, where: "metadata_uri IS NOT NULL"

    create_table "account_reports" do |t|
      t.integer  "user_id", :limit => 8, :null => false
      t.text     "message"
      t.integer  "account_id", :limit => 8, :null => false
      t.integer  "attachment_id", :limit => 8
      t.string   "workflow_state", :default => "created", :null => false, limit: 255
      t.string   "report_type", limit: 255
      t.integer  "progress"
      t.date     "start_at"
      t.date     "end_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "parameters"
    end
    add_index :account_reports, :attachment_id
    add_index :account_reports, [:account_id, :report_type, :updated_at], order: { updated_at: :desc }, name: 'index_account_reports_latest_per_account'

    create_table :account_notification_roles do |t|
      t.integer :account_notification_id, :limit => 8, :null => false
      t.integer :role_id, :limit => 8
    end
    add_index :account_notification_roles,
              [:account_notification_id, :role_id],
              unique: true,
              name: 'index_account_notification_roles_on_role_id'

    create_table :account_notifications do |t|
      t.string :subject, limit: 255
      t.string :icon, :default => 'warning', limit: 255
      t.text :message
      t.integer :account_id, :limit => 8, :null => false
      t.integer :user_id, :limit => 8
      t.datetime :start_at, :null => false
      t.datetime :end_at, :null => false
      t.timestamps null: true
      t.string :required_account_service, limit: 255
      t.integer :months_in_display_cycle
    end

    add_index :account_notifications, [:account_id, :end_at, :start_at], name: "index_account_notifications_by_account_and_timespan"

    create_table "account_users", :force => true do |t|
      t.integer  "account_id", :limit => 8, :null => false
      t.integer  "user_id", :limit => 8, :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "role_id", :limit => 8, :null => false
    end

    add_index "account_users", ["account_id"], :name => "index_account_users_on_account_id"
    add_index "account_users", ["user_id"], :name => "index_account_users_on_user_id"

    create_table "accounts", :force => true do |t|
      t.string   "name", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "workflow_state",                                :default => "active", :null => false, limit: 255
      t.datetime "deleted_at"
      t.integer  "parent_account_id", :limit => 8
      t.string   "sis_source_id", limit: 255
      t.integer  "sis_batch_id", :limit => 8
      t.integer  "current_sis_batch_id", :limit => 8
      t.integer  "root_account_id", :limit => 8
      t.integer  "last_successful_sis_batch_id", :limit => 8
      t.string   "membership_types", limit: 255
      t.string   "default_time_zone", limit: 255
      t.string   "external_status",                               :default => "active", limit: 255
      t.integer  "storage_quota", :limit => 8
      t.integer  "default_storage_quota", :limit => 8
      t.boolean  "enable_user_notes",                             :default => false
      t.string   "allowed_services", limit: 255
      t.text     "turnitin_pledge"
      t.text     "turnitin_comments"
      t.string   "turnitin_account_id", limit: 255
      t.string   "turnitin_salt", limit: 255
      t.string   "turnitin_crypted_secret", limit: 255
      t.boolean  "show_section_name_as_course_name",              :default => false
      t.boolean  "allow_sis_import",                              :default => false
      t.string   "equella_endpoint", limit: 255
      t.text     "settings"
      t.string   "uuid", limit: 255
      t.string   "default_locale", limit: 255
      t.text     "stuck_sis_fields"
      t.bigint   "default_user_storage_quota"
      t.string   "lti_guid", limit: 255
      t.bigint   "default_group_storage_quota"
      t.string   "turnitin_host", limit: 255
      t.string   "integration_id", limit: 255
      t.string   "lti_context_id", limit: 255
      t.string   "brand_config_md5", limit: 32
      t.string   "turnitin_originality", limit: 255
    end

    add_index "accounts", ["name", "parent_account_id"], :name => "index_accounts_on_name_and_parent_account_id"
    add_index "accounts", ["parent_account_id", "root_account_id"], :name => "index_accounts_on_parent_account_id_and_root_account_id"
    add_index :accounts, [:sis_source_id, :root_account_id], where: "sis_source_id IS NOT NULL", unique: true
    add_index :accounts, :root_account_id
    add_index :accounts, [:integration_id, :root_account_id],
              unique: true,
              name: "index_accounts_on_integration_id",
              where: "integration_id IS NOT NULL"
    add_index :accounts, :lti_context_id, :unique => true
    add_index :accounts, :sis_batch_id, where: "sis_batch_id IS NOT NULL"
    add_index :accounts, :brand_config_md5, where: 'brand_config_md5 IS NOT NULL'

    create_table :alerts do |t|
      t.integer :context_id, :limit => 8, :null => false
      t.string :context_type, :null => false, limit: 255
      t.text :recipients, :null => false
      t.integer :repetition

      t.timestamps null: true
    end

    create_table :alert_criteria do |t|
      t.integer :alert_id, :limit => 8
      t.string :criterion_type, limit: 255
      t.float :threshold
    end

    create_table :appointment_groups do |t|
      t.string :title, limit: 255
      t.text :description
      t.string :location_name, limit: 255
      t.string :location_address, limit: 255
      t.integer :context_id, :limit => 8
      t.string :context_type, limit: 255
      t.string :context_code, limit: 255
      t.integer :sub_context_id, :limit => 8
      t.string :sub_context_type, limit: 255
      t.string :sub_context_code, limit: 255
      t.string :workflow_state, :null => false, limit: 255
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :start_at
      t.datetime :end_at
      t.integer :participants_per_appointment
      t.integer :max_appointments_per_participant # nil means no limit
      t.integer :min_appointments_per_participant, :default => 0
      t.string :participant_visibility, limit: 255
    end
    add_index :appointment_groups, [:context_id]

    create_table :appointment_group_contexts do |t|
      t.references :appointment_group, :limit => 8
      t.string :context_code, limit: 255
      t.integer :context_id, :limit => 8
      t.string :context_type, limit: 255
      t.timestamps null: true
    end
    add_index :appointment_group_contexts, :appointment_group_id

    create_table :appointment_group_sub_contexts do |t|
      t.references :appointment_group, :limit => 8
      t.integer :sub_context_id, :limit => 8
      t.string :sub_context_type, limit: 255
      t.string :sub_context_code, limit: 255
      t.timestamps null: true
    end

    add_index :appointment_group_sub_contexts, :appointment_group_id

    create_table "assessment_question_bank_users", :force => true do |t|
      t.integer  "assessment_question_bank_id", :limit => 8, :null => false
      t.integer  "user_id", :limit => 8, :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "assessment_question_bank_users", ["assessment_question_bank_id"], :name => "assessment_qbu_aqb_id"
    add_index "assessment_question_bank_users", ["user_id"], :name => "assessment_qbu_u_id"

    create_table "assessment_question_banks", :force => true do |t|
      t.integer  "context_id", :limit => 8
      t.string   "context_type", limit: 255
      t.text     "title"
      t.string   "workflow_state", :null => false, limit: 255
      t.datetime "deleted_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "migration_id", limit: 255
    end

    add_index "assessment_question_banks", ["context_id", "context_type"], :name => "index_on_aqb_on_context_id_and_context_type"

    create_table "assessment_questions", :force => true do |t|
      t.text     "name"
      t.text     "question_data"
      t.integer  "context_id", :limit => 8
      t.string   "context_type", limit: 255
      t.string   "workflow_state", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "assessment_question_bank_id", :limit => 8
      t.datetime "deleted_at"
      t.string   "migration_id", limit: 255
      t.integer  "position"
    end

    add_index "assessment_questions", ["assessment_question_bank_id", "position"], :name => "question_bank_id_and_position"

    create_table "assessment_requests", :force => true do |t|
      t.integer  "rubric_assessment_id", :limit => 8
      t.integer  "user_id", :limit => 8, :null => false
      t.integer  "asset_id", :limit => 8, :null => false
      t.string   "asset_type", :null => false, limit: 255
      t.integer  "assessor_asset_id", :limit => 8, :null => false
      t.string   "assessor_asset_type", :null => false, limit: 255
      t.string   "workflow_state", :null => false, limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "uuid", limit: 255
      t.integer  "rubric_association_id", :limit => 8
      t.integer  "assessor_id", :limit => 8, :null => false
    end

    add_index "assessment_requests", ["assessor_asset_id", "assessor_asset_type"], :name => "aa_id_and_aa_type"
    add_index "assessment_requests", ["assessor_id"], :name => "index_assessment_requests_on_assessor_id"
    add_index "assessment_requests", ["asset_id", "asset_type"], :name => "index_assessment_requests_on_asset_id_and_asset_type"
    add_index "assessment_requests", ["rubric_assessment_id"], :name => "index_assessment_requests_on_rubric_assessment_id"
    add_index "assessment_requests", ["rubric_association_id"], :name => "index_assessment_requests_on_rubric_association_id"
    add_index "assessment_requests", ["user_id"], :name => "index_assessment_requests_on_user_id"

    create_table "asset_user_accesses", :force => true do |t|
      t.string   "asset_code", limit: 255
      t.string   "asset_group_code", limit: 255
      t.integer  "user_id", :limit => 8
      t.integer  "context_id", :limit => 8
      t.string   "context_type", limit: 255
      t.datetime "last_access"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "asset_category", limit: 255
      t.float    "view_score"
      t.float    "participate_score"
      t.string   "action_level", limit: 255
      t.text     "display_name"
      t.string   "membership_type", limit: 255
    end

    add_index "asset_user_accesses", ["user_id", "asset_code"], :name => "index_asset_user_accesses_on_user_id_and_asset_code"
    add_index :asset_user_accesses, [:context_id, :context_type, :user_id, :updated_at], name: 'index_asset_user_accesses_on_ci_ct_ui_ua'

    create_table :assignment_configuration_tool_lookups do |t|
      t.integer :assignment_id, limit: 8, null: false
      t.integer :tool_id, limit: 8, null: false
      t.string :tool_type, null: false, limit: 255
    end

    add_index :assignment_configuration_tool_lookups, [:tool_id, :tool_type, :assignment_id], unique: true, name: 'index_tool_lookup_on_tool_assignment_id'
    add_index :assignment_configuration_tool_lookups, :assignment_id

    create_table "assignment_groups", :force => true do |t|
      t.string   "name", limit: 255
      t.text     "rules"
      t.string   "default_assignment_name", limit: 255
      t.integer  "position"
      t.string   "assignment_weighting_scheme", limit: 255
      t.float    "group_weight"
      t.integer  "context_id", :limit => 8, :null => false
      t.string   "context_type", :null => false, limit: 255
      t.string   "workflow_state", :null => false, limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "cloned_item_id", :limit => 8
      t.string   "context_code", limit: 255
      t.string   "migration_id", limit: 255
      t.string   "sis_source_id", limit: 255
      t.text     "integration_data"
    end

    add_index "assignment_groups", ["context_id", "context_type"], :name => "index_assignment_groups_on_context_id_and_context_type"

    create_table :assignment_override_students do |t|
      t.timestamps null: true

      t.integer  :assignment_id, :limit => 8
      t.integer  :assignment_override_id, :null => false, :limit => 8
      t.integer  :user_id, :null => false, :limit => 8
      t.integer  :quiz_id, :limit => 8
    end

    add_index :assignment_override_students, [:assignment_id, :user_id], :unique => true
    add_index :assignment_override_students, :assignment_override_id
    add_index :assignment_override_students, :user_id
    add_index :assignment_override_students, :quiz_id

    create_table :assignment_overrides do |t|
      t.timestamps null: true

      # generic info
      t.integer  :assignment_id, :limit => 8
      t.integer  :assignment_version
      t.string   :set_type, :null => :false, limit: 255
      t.integer  :set_id, :limit => 8
      t.string   :title, :null => false, limit: 255
      t.string   :workflow_state, :null => false, limit: 255

      # due at override
      t.boolean  :due_at_overridden, :default => false, :null => false
      t.datetime :due_at
      t.boolean  :all_day
      t.date     :all_day_date

      # unlock at override
      t.boolean  :unlock_at_overridden, :default => false, :null => false
      t.datetime :unlock_at

      # lock at override
      t.boolean  :lock_at_overridden, :default => false, :null => false
      t.datetime :lock_at

      t.integer  :quiz_id, :limit => 8
      t.integer  :quiz_version
    end

    add_index :assignment_overrides, [:assignment_id, :set_type, :set_id],
      :name => 'index_assignment_overrides_on_assignment_and_set',
      :unique => true,
      :where => "workflow_state='active' and set_id is not null"
    add_index :assignment_overrides, [:set_type, :set_id]
    add_index :assignment_overrides, :quiz_id
    add_index :assignment_overrides, :assignment_id

    create_table "assignments", :force => true do |t|
      t.string   "title", limit: 255
      t.text     "description",                       :limit => 16777215
      t.datetime "due_at"
      t.datetime "unlock_at"
      t.datetime "lock_at"
      t.float    "points_possible"
      t.float    "min_score"
      t.float    "max_score"
      t.float    "mastery_score"
      t.string   "grading_type", limit: 255
      t.string   "submission_types", limit: 255
      t.string   "workflow_state", :null => false, limit: 255
      t.integer  "context_id", :limit => 8, :null => false
      t.string   "context_type", :null => false, limit: 255
      t.integer  "assignment_group_id", :limit => 8
      t.integer  "grading_standard_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "group_category", limit: 255
      t.integer  "submissions_downloads",                                 :default => 0
      t.integer  "peer_review_count",                                     :default => 0
      t.datetime "peer_reviews_due_at"
      t.boolean  "peer_reviews_assigned",                                 :default => false
      t.boolean  "peer_reviews",                                          :default => false
      t.boolean  "automatic_peer_reviews",                                :default => false
      t.boolean  "all_day"
      t.date     "all_day_date"
      t.boolean  "could_be_locked"
      t.integer  "cloned_item_id", :limit => 8
      t.string   "context_code", limit: 255
      t.integer  "position"
      t.string   "migration_id", limit: 255
      t.boolean  "grade_group_students_individually"
      t.boolean  "anonymous_peer_reviews"
      t.string   "time_zone_edited", limit: 255
      t.boolean  "turnitin_enabled"
      t.string   "allowed_extensions", limit: 255
      t.text     "turnitin_settings"
      t.boolean  "muted", :default => false
      t.integer  "group_category_id", :limit => 8
      t.boolean  "freeze_on_copy"
      t.boolean  "copied"
      t.boolean  "only_visible_to_overrides"
      t.boolean  "post_to_sis"
      t.string   "integration_id", limit: 255
      t.text     "integration_data"
      t.integer  "turnitin_id", limit: 8
      t.boolean  "moderated_grading"
      t.datetime "grades_published_at"
      t.boolean  "omit_from_final_grade"
      t.boolean  "vericite_enabled"
      t.boolean  "intra_group_peer_reviews", default: false
      t.string   "lti_context_id"
    end

    add_index "assignments", ["assignment_group_id"], :name => "index_assignments_on_assignment_group_id"
    add_index "assignments", ["context_code"], :name => "index_assignments_on_context_code"
    add_index "assignments", ["context_id", "context_type"], :name => "index_assignments_on_context_id_and_context_type"
    add_index "assignments", ["due_at", "context_code"], :name => "index_assignments_on_due_at_and_context_code"
    add_index "assignments", ["grading_standard_id"], :name => "index_assignments_on_grading_standard_id"
    add_index :assignments, :turnitin_id, unique: true, where: "turnitin_id IS NOT NULL"
    add_index :assignments, :lti_context_id, unique: true

    create_table "attachment_associations", :force => true do |t|
      t.integer "attachment_id", :limit => 8
      t.integer "context_id", :limit => 8
      t.string  "context_type", limit: 255
    end

    add_index "attachment_associations", ["attachment_id"], :name => "index_attachment_associations_on_attachment_id"
    add_index "attachment_associations", ["context_id", "context_type"], :name => "attachment_associations_a_id_a_type"

    create_table "attachments", :force => true do |t|
      t.integer  "context_id", :limit => 8
      t.string   "context_type", limit: 255
      t.integer  "size", :limit => 8
      t.integer  "folder_id", :limit => 8
      t.string   "content_type", limit: 255
      t.text     "filename"
      t.string   "uuid", limit: 255
      t.text     "display_name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "workflow_state", limit: 255
      t.integer  "user_id", :limit => 8
      t.boolean  "locked",                  :default => false
      t.string   "file_state", limit: 255
      t.datetime "deleted_at"
      t.integer  "position"
      t.datetime "lock_at"
      t.datetime "unlock_at"
      t.datetime "last_lock_at"
      t.datetime "last_unlock_at"
      t.boolean  "could_be_locked"
      t.integer  "root_attachment_id", :limit => 8
      t.integer  "cloned_item_id", :limit => 8
      t.string   "migration_id", limit: 255
      t.string   "namespace", limit: 255
      t.string   "media_entry_id", limit: 255
      t.string   "md5", limit: 255
      t.string   "encoding", limit: 255
      t.boolean  "need_notify"
      t.string   "upload_error_message", limit: 255
      t.integer  "replacement_attachment_id", :limit => 8
      t.integer  "usage_rights_id", :limit => 8
      t.datetime "modified_at"
      t.timestamp "viewed_at"
    end

    add_index "attachments", ["cloned_item_id"], :name => "index_attachments_on_cloned_item_id"
    add_index "attachments", ["context_id", "context_type"], :name => "index_attachments_on_context_id_and_context_type"
    add_index "attachments", ["md5", "namespace"], :name => "index_attachments_on_md5_and_namespace"
    add_index "attachments", ["user_id"], :name => "index_attachments_on_user_id"
    add_index "attachments", ["workflow_state", "updated_at"], :name => "index_attachments_on_workflow_state_and_updated_at"
    execute %{create index index_attachments_on_root_attachment_id_not_null on #{Attachment.quoted_table_name} (root_attachment_id) where root_attachment_id is not null}
    if collkey = connection.extension_installed?(:pg_collkey)
      execute("CREATE INDEX index_attachments_on_folder_id_and_file_state_and_display_name ON #{Attachment.quoted_table_name} (folder_id, file_state, #{collkey}.collkey(display_name, 'root', false, 0, true)) WHERE folder_id IS NOT NULL")
    else
      execute("CREATE INDEX index_attachments_on_folder_id_and_file_state_and_display_name ON #{Attachment.quoted_table_name} (folder_id, file_state, CAST(LOWER(replace(display_name, '\\', '\\\\')) AS bytea)) WHERE folder_id IS NOT NULL")
    end
    add_index :attachments, [:folder_id, :file_state, :position]
    add_index :attachments, :need_notify, :where => "need_notify"
    add_index :attachments, :replacement_attachment_id, where: "replacement_attachment_id IS NOT NULL"
    add_index :attachments, :namespace
    add_index :attachments, [:folder_id, :position], where: 'folder_id IS NOT NULL'

    create_table "calendar_events", :force => true do |t|
      t.string   "title", limit: 255
      t.text     "description",      :limit => 16777215
      t.string   "location_name", limit: 255
      t.string   "location_address", limit: 255
      t.datetime "start_at"
      t.datetime "end_at"
      t.integer  "context_id", :limit => 8, :null => false
      t.string   "context_type", :null => false, limit: 255
      t.string   "workflow_state", :null => false, limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "user_id", :limit => 8
      t.boolean  "all_day"
      t.date     "all_day_date"
      t.datetime "deleted_at"
      t.integer  "cloned_item_id", :limit => 8
      t.string   "context_code", limit: 255
      t.string   "migration_id", limit: 255
      t.string   "time_zone_edited", limit: 255
      t.integer  "parent_calendar_event_id", :limit => 8
      t.string   "effective_context_code", limit: 255
      t.integer  "participants_per_appointment"
      t.boolean  "override_participants_per_appointment"
      t.text     "comments"
      t.string   "timetable_code", limit: 255
    end
    add_index :calendar_events, [:context_id, :context_type, :timetable_code], where: "timetable_code IS NOT NULL", unique: true, name: "index_calendar_events_on_context_and_timetable_code"

    create_table :bookmarks_bookmarks do |t|
      t.integer :user_id, limit: 8, null: false
      t.string :name, null: false, limit: 255
      t.string :url, null: false, limit: 255
      t.integer :position
      t.text :json
    end
    add_index :bookmarks_bookmarks, :user_id

    create_table :brand_configs, id: false do |t|
      t.string :md5, limit: 32, null: false, unique: true
      t.column :variables, :text
      t.boolean :share, default: false, null: false
      t.string :name, limit: 255
      t.datetime :created_at, null: false
      t.text :js_overrides
      t.text :css_overrides
      t.text :mobile_js_overrides
      t.text :mobile_css_overrides
      t.string :parent_md5, limit: 255
    end
    # because we didn't use the rails default `id` int primary key, we have to add it manually
    execute %{ ALTER TABLE #{BrandConfig.quoted_table_name} ADD PRIMARY KEY (md5); }
    add_index :brand_configs, :share

    add_index "calendar_events", ["context_code"], :name => "index_calendar_events_on_context_code"
    add_index "calendar_events", ["context_id", "context_type"], :name => "index_calendar_events_on_context_id_and_context_type"
    add_index "calendar_events", ["user_id"], :name => "index_calendar_events_on_user_id"
    add_index :calendar_events, [:parent_calendar_event_id]
    connection.execute("CREATE INDEX index_calendar_events_on_effective_context_code ON #{CalendarEvent.quoted_table_name}(effective_context_code) WHERE effective_context_code IS NOT NULL")

    create_table :canvadocs do |t|
      t.string :document_id, limit: 255
      t.string :process_state, limit: 255
      t.integer :attachment_id, limit: 8, null: false
      t.timestamps null: true
      t.boolean :has_annotations
      t.string :preferred_plugin_course_id, limit: 255
    end
    add_index :canvadocs, :document_id, :unique => true
    add_index :canvadocs, :attachment_id

    create_table :canvadocs_submissions do |t|
      t.integer :canvadoc_id, limit: 8
      t.integer :crocodoc_document_id, limit: 8
      t.integer :submission_id, limit: 8, null: false
    end

    add_index :canvadocs_submissions, :submission_id
    add_index :canvadocs_submissions, [:submission_id, :canvadoc_id],
      where: "canvadoc_id IS NOT NULL",
      name: "unique_submissions_and_canvadocs",
      unique: true
    add_index :canvadocs_submissions, [:submission_id, :crocodoc_document_id],
      where: "crocodoc_document_id IS NOT NULL",
      name: "unique_submissions_and_crocodocs",
      unique: true
    add_index :canvadocs_submissions, :crocodoc_document_id,
      where: "crocodoc_document_id IS NOT NULL"

    create_table "cloned_items", :force => true do |t|
      t.integer  "original_item_id", :limit => 8
      t.string   "original_item_type", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "collaborations", :force => true do |t|
      t.string   "collaboration_type", limit: 255
      t.string   "document_id", limit: 255
      t.integer  "user_id", :limit => 8
      t.integer  "context_id", :limit => 8
      t.string   "context_type", limit: 255
      t.string   "url", limit: 255
      t.string   "uuid", limit: 255
      t.text     "data"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "description"
      t.string   "title", :null => false, limit: 255
      t.string   "workflow_state", :default => "active", :null => false, limit: 255
      t.datetime "deleted_at"
      t.string   "context_code", limit: 255
      t.string   "type", limit: 255
    end

    add_index "collaborations", ["context_id", "context_type"], :name => "index_collaborations_on_context_id_and_context_type"
    add_index "collaborations", ["user_id"], :name => "index_collaborations_on_user_id"

    create_table "collaborators", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "collaboration_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "authorized_service_user_id", limit: 255
      t.integer  "group_id", :limit => 8
    end

    add_index "collaborators", ["collaboration_id"], :name => "index_collaborators_on_collaboration_id"
    add_index "collaborators", ["user_id"], :name => "index_collaborators_on_user_id"
    add_index  :collaborators, [:group_id], :name => 'index_collaborators_on_group_id'

    create_table "communication_channels", :force => true do |t|
      t.string   "path", :null => false, limit: 255
      t.string   "path_type", :default => "email", :null => false, limit: 255
      t.integer  "position"
      t.integer  "user_id", :limit => 8, :null => false
      t.integer  "pseudonym_id", :limit => 8
      t.integer  "bounce_count", :default => 0
      t.string   "workflow_state", :null => false, limit: 255
      t.string   "confirmation_code", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "build_pseudonym_on_confirm"
      t.datetime "last_bounce_at"
      # last_bounce_details was originally intended to have limit: 32768, but
      # it was typoed as "length" instead of "limit" so it did not apply
      t.text     "last_bounce_details"
      t.datetime "last_suppression_bounce_at"
      t.datetime "last_transient_bounce_at"
      # last_transient_bounce_details was originally intended to have limit:
      # 32768, but it was typoed as "length" instead of "limit" so it did not apply
      t.text     "last_transient_bounce_details"
    end

    add_index "communication_channels", ["pseudonym_id", "position"]
    add_index "communication_channels", ["user_id", "position"]
    connection.execute("CREATE INDEX index_communication_channels_on_path_and_path_type ON #{CommunicationChannel.quoted_table_name} (LOWER(path), path_type)")
    if (trgm = connection.extension_installed?(:pg_trgm))
      add_index :communication_channels, "lower(path) #{trgm}.gist_trgm_ops", name: "index_trgm_communication_channels_path", using: :gist
    end
    add_index :communication_channels, :confirmation_code
    connection.execute("CREATE UNIQUE INDEX index_communication_channels_on_user_id_and_path_and_path_type ON #{CommunicationChannel.quoted_table_name} (user_id, LOWER(path), path_type)")
    add_index :communication_channels, :last_bounce_at, where: 'bounce_count > 0'

    create_table :content_exports do |t|
      t.integer :user_id, :limit => 8
      t.integer :attachment_id, :limit => 8
      t.string :export_type, limit: 255
      t.text :settings
      t.float :progress
      t.string :workflow_state, :null => false, limit: 255
      t.timestamps null: true
      t.integer :content_migration_id, :limit => 8
      t.string :context_type, limit: 255
      t.integer :context_id, :limit => 8
    end

    add_index :content_exports, :attachment_id
    add_index :content_exports, :content_migration_id

    create_table "content_migrations", :force => true do |t|
      t.integer  "context_id", :limit => 8, :null => false
      t.integer  "user_id", :limit => 8
      t.string   "workflow_state", :null => false, limit: 255
      t.text     "migration_settings"
      t.datetime "started_at"
      t.datetime "finished_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.float    "progress"
      t.string   "context_type", limit: 255
      t.integer  "attachment_id", :limit => 8
      t.integer  "overview_attachment_id", :limit => 8
      t.integer  "exported_attachment_id", :limit => 8
      t.integer  "source_course_id", :limit => 8
      t.string   "migration_type", limit: 255
    end
    add_index :content_migrations, :context_id
    add_index :content_migrations, :attachment_id, where: 'attachment_id IS NOT NULL'
    add_index :content_migrations, :exported_attachment_id, where: 'exported_attachment_id IS NOT NULL'
    add_index :content_migrations, :overview_attachment_id, where: 'overview_attachment_id IS NOT NULL'
    add_index :content_migrations, :source_course_id, where: "source_course_id IS NOT NULL"

    create_table "content_participation_counts" do |t|
      t.string "content_type", limit: 255
      t.string "context_type", limit: 255
      t.integer "context_id", :limit => 8
      t.integer "user_id", :limit => 8
      t.integer "unread_count", :default => 0
      t.timestamps null: true
    end

    add_index "content_participation_counts", ["context_id", "context_type", "user_id", "content_type"], :name => "index_content_participation_counts_uniquely", :unique => true

    create_table "content_participations" do |t|
      t.string "content_type", :null => false, limit: 255
      t.integer "content_id", :limit => 8, :null => false
      t.integer "user_id", :limit => 8, :null => false
      t.string "workflow_state", :null => false, limit: 255
    end

    add_index "content_participations", ["content_id", "content_type", "user_id"], :name => "index_content_participations_uniquely", :unique => true

    create_table "content_tags", :force => true do |t|
      t.integer  "content_id", :limit => 8
      t.string   "content_type", limit: 255
      t.integer  "context_id", :limit => 8, :null => false
      t.string   "context_type", :null => false, limit: 255
      t.text     "title"
      t.string   "tag", limit: 255
      t.text     "url"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "comments"
      t.string   "tag_type",                      :default => "default", limit: 255
      t.integer  "context_module_id", :limit => 8
      t.integer  "position"
      t.integer  "indent"
      t.string   "migration_id", limit: 255
      t.integer  "learning_outcome_id", :limit => 8
      t.string   "context_code", limit: 255
      t.float    "mastery_score"
      t.integer  "rubric_association_id", :limit => 8
      t.string   "workflow_state",                :default => "active", :null => false, limit: 255
      t.integer  "cloned_item_id", :limit => 8
      t.integer  "associated_asset_id", :limit => 8
      t.string   "associated_asset_type", limit: 255
      t.boolean  "new_tab"
    end

    add_index "content_tags", ["content_id", "content_type"], :name => "index_content_tags_on_content_id_and_content_type"
    add_index "content_tags", ["context_id", "context_type"], :name => "index_content_tags_on_context_id_and_context_type"
    add_index "content_tags", ["context_module_id"], :name => "index_content_tags_on_context_module_id"
    add_index :content_tags, [ :associated_asset_id, :associated_asset_type ], :name => 'index_content_tags_on_associated_asset'
    add_index :content_tags, :learning_outcome_id, :where => "learning_outcome_id IS NOT NULL"

    create_table :context_external_tool_assignment_lookups do |t|
      t.integer :assignment_id, limit: 8, null: false
      t.integer :context_external_tool_id, limit: 8, null: false
    end
    add_index :context_external_tool_assignment_lookups, [:context_external_tool_id, :assignment_id], unique: true, name: 'tool_to_assign'
    add_index :context_external_tool_assignment_lookups, :assignment_id

    create_table :context_external_tool_placements do |t|
      t.string :placement_type, limit: 255
      t.integer :context_external_tool_id, limit: 8, null: false
    end
    add_index :context_external_tool_placements, :context_external_tool_id, :name => 'external_tool_placements_tool_id'
    add_index :context_external_tool_placements, [:placement_type, :context_external_tool_id], unique: true, :name => 'external_tool_placements_type_and_tool_id'

    create_table :context_external_tools do |t|
      t.integer :context_id, :limit => 8
      t.string :context_type, limit: 255
      t.string :domain, limit: 255
      t.string :url, :limit => 4.kilobytes
      t.text :shared_secret, :null => false
      t.text :consumer_key, :null => false
      t.string :name, :null => false, limit: 255
      t.text :description
      t.text :settings
      t.string :workflow_state, :null => false, limit: 255
      t.timestamps null: true
      t.string :migration_id, limit: 255
      t.integer :cloned_item_id, :limit => 8
      t.string :tool_id, limit: 255
      t.boolean :not_selectable
      t.string :app_center_id, limit: 255
    end
    add_index :context_external_tools, [:tool_id]
    add_index :context_external_tools, [:context_id, :context_type]
    add_index :context_external_tools, [:context_id, :context_type, :migration_id], where: "migration_id IS NOT NULL", name: "index_external_tools_on_context_and_migration_id"

    create_table "context_module_progressions", :force => true do |t|
      t.integer  "context_module_id", :limit => 8
      t.integer  "user_id", :limit => 8
      t.text     "requirements_met"
      t.string   "workflow_state", :null => false, limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "collapsed"
      t.integer  "current_position"
      t.datetime "completed_at"
      t.boolean  "current"
      t.integer  "lock_version", :default => 0, :null => false
      t.datetime "evaluated_at"
      t.text     "incomplete_requirements"
    end

    add_index "context_module_progressions", ["context_module_id"], :name => "index_context_module_progressions_on_context_module_id"
    add_index :context_module_progressions, [:user_id, :context_module_id], unique: true, name: 'index_cmp_on_user_id_and_module_id'

    create_table "context_modules", :force => true do |t|
      t.integer  "context_id", :limit => 8, :null => false
      t.string   "context_type", :null => false, limit: 255
      t.text     "name"
      t.integer  "position"
      t.text     "prerequisites"
      t.text     "completion_requirements"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "workflow_state",              :default => "active", :null => false, limit: 255
      t.datetime "deleted_at"
      t.datetime "unlock_at"
      t.string   "migration_id", limit: 255
      t.boolean  "require_sequential_progress"
      t.integer  "cloned_item_id", :limit => 8
      t.text     "completion_events"
      t.integer  "requirement_count"
    end

    add_index "context_modules", ["context_id", "context_type"], :name => "index_context_modules_on_context_id_and_context_type"

    create_table "conversations" do |t|
      t.string "private_hash", limit: 255 # for quick lookups so we know whether or not we need to create a new one
      t.boolean "has_attachments", :default => false, :null => false
      t.boolean "has_media_objects", :default => false, :null => false
      t.text    "tags"
      t.text    "root_account_ids"
      t.string  "subject", limit: 255
      t.string  "context_type", limit: 255
      t.integer "context_id", :limit => 8
      t.timestamp "updated_at"
    end
    add_index "conversations", ["private_hash"], :unique => true

    create_table :conversation_batches do |t|
      t.string :workflow_state, :null => false, limit: 255
      t.integer :user_id, :limit => 8, :null => false
      t.text :recipient_ids
      t.integer :root_conversation_message_id, :limit => 8, :null => false
      t.text :conversation_message_ids
      t.text :tags
      t.timestamps null: true
      t.string  "context_type", limit: 255
      t.integer "context_id", :limit => 8
      t.string :subject, limit: 255
      t.boolean :group
      t.boolean :generate_user_note
    end
    add_index :conversation_batches, [:user_id, :workflow_state]

    create_table "conversation_participants" do |t|
      t.integer  "conversation_id", :limit => 8, :null => false
      t.integer  "user_id", :limit => 8, :null => false
      t.datetime "last_message_at"
      t.boolean  "subscribed", :default => true
      t.string   "workflow_state", :null => false, limit: 255
      t.datetime "last_authored_at"
      t.boolean  "has_attachments", :default => false, :null => false
      t.boolean  "has_media_objects", :default => false, :null => false
      t.integer  "message_count", :default => 0
      t.string   "label", limit: 255
      t.text     "tags"
      t.datetime "visible_last_authored_at"
      t.text     "root_account_ids"
      t.string   "private_hash", limit: 255
      t.timestamp "updated_at"
    end
    add_index "conversation_participants", ["user_id", "last_message_at"]
    add_index :conversation_participants, [:conversation_id, :user_id], :unique => true
    add_index :conversation_participants, [:private_hash, :user_id], :where => "private_hash IS NOT NULL", :unique => true

    create_table "conversation_messages" do |t|
      t.integer  "conversation_id", :limit => 8
      t.integer  "author_id", :limit => 8
      t.datetime "created_at"
      t.boolean  "generated"
      t.text     "body"
      t.text     "forwarded_message_ids"
      t.string   "media_comment_id", limit: 255
      t.string   "media_comment_type", limit: 255
      t.integer  "context_id", :limit => 8
      t.string   "context_type", limit: 255
      t.integer  "asset_id", :limit => 8
      t.string   "asset_type", limit: 255
      t.text     "attachment_ids"
      t.boolean  "has_attachments"
      t.boolean  "has_media_objects"
    end
    add_index "conversation_messages", ["conversation_id", "created_at"]
    add_index :conversation_messages, :author_id

    create_table "conversation_message_participants" do |t|
      t.integer  "conversation_message_id", :limit => 8
      t.integer  "conversation_participant_id", :limit => 8
      t.text     "tags"
      t.integer  "user_id", :limit => 8
      t.string   "workflow_state", limit: 255
      t.datetime "deleted_at"
    end
    add_index :conversation_message_participants, [:conversation_participant_id, :conversation_message_id], :name => :index_cmp_on_cpi_and_cmi
    add_index :conversation_message_participants, [:user_id, :conversation_message_id], :name => "index_conversation_message_participants_on_uid_and_message_id", :unique => true
    add_index :conversation_message_participants, :conversation_message_id, :name => "index_conversation_message_participants_on_message_id"
    add_index :conversation_message_participants, :deleted_at

    create_table "course_account_associations", :force => true do |t|
      t.integer  "course_id", :limit => 8, :null => false
      t.integer  "account_id", :limit => 8, :null => false
      t.integer  "depth", :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "course_section_id", :limit => 8
    end

    add_index "course_account_associations", ["account_id", "depth"], :name => "index_course_account_associations_on_account_id_and_depth_id"
    add_index :course_account_associations, [:course_id, :course_section_id, :account_id], :unique => true, :name => 'index_caa_on_course_id_and_section_id_and_account_id'
    add_index :course_account_associations, :course_section_id

    create_table "course_sections", :force => true do |t|
      t.string   "sis_source_id", limit: 255
      t.integer  "sis_batch_id", :limit => 8
      t.integer  "course_id", :limit => 8, :null => false
      t.integer  "root_account_id", :limit => 8, :null => false
      t.integer  "enrollment_term_id", :limit => 8
      t.string   "name", :null => false, limit: 255
      t.boolean  "default_section"
      t.boolean  "accepting_enrollments"
      t.boolean  "can_manually_enroll"
      t.datetime "start_at"
      t.datetime "end_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "workflow_state",                        :default => "active", :null => false, limit: 255
      t.boolean  "restrict_enrollments_to_section_dates"
      t.integer  "nonxlist_course_id", :limit => 8
      t.text     "stuck_sis_fields"
      t.string   "integration_id", limit: 255
    end

    add_index "course_sections", ["course_id"], :name => "index_course_sections_on_course_id"
    add_index :course_sections, [:nonxlist_course_id], :name => "index_course_sections_on_nonxlist_course", :where => "nonxlist_course_id IS NOT NULL"
    add_index :course_sections, :root_account_id
    add_index :course_sections, [:sis_source_id, :root_account_id], where: "sis_source_id IS NOT NULL", unique: true
    add_index :course_sections, [:integration_id, :root_account_id],
              unique: true,
              name: "index_sections_on_integration_id",
              where: "integration_id IS NOT NULL"
    add_index :course_sections, :sis_batch_id, where: "sis_batch_id IS NOT NULL"
    add_index :course_sections, :enrollment_term_id

    create_table "courses", :force => true do |t|
      t.string   "name", limit: 255
      t.integer  "account_id", :limit => 8, :null => false
      t.string   "group_weighting_scheme", limit: 255
      t.string   "workflow_state", :null => false, limit: 255
      t.string   "uuid", limit: 255
      t.datetime "start_at"
      t.datetime "conclude_at"
      t.integer  "grading_standard_id", :limit => 8
      t.boolean  "is_public"
      t.boolean  "allow_student_wiki_edits"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "show_public_context_messages"
      t.text     "syllabus_body",                   :limit => 16777215
      t.boolean  "allow_student_forum_attachments",                     :default => false
      t.string   "default_wiki_editing_roles", limit: 255
      t.integer  "wiki_id", :limit => 8
      t.boolean  "allow_student_organized_groups",                      :default => true
      t.string   "course_code", limit: 255
      t.string   "default_view", limit: 255
      t.integer  "abstract_course_id", :limit => 8
      t.integer  "root_account_id", :limit => 8, :null => false
      t.integer  "enrollment_term_id", :limit => 8, :null => false
      t.string   "sis_source_id", limit: 255
      t.integer  "sis_batch_id", :limit => 8
      t.boolean  "open_enrollment"
      t.integer  "storage_quota", :limit => 8
      t.text     "tab_configuration"
      t.boolean  "allow_wiki_comments"
      t.text     "turnitin_comments"
      t.boolean  "self_enrollment"
      t.string   "license", limit: 255
      t.boolean  "indexed"
      t.boolean  "restrict_enrollments_to_course_dates"
      t.integer  "template_course_id", :limit => 8
      t.string   "locale", limit: 255
      t.text     "settings"
      t.integer  "replacement_course_id", :limit => 8
      t.text     "stuck_sis_fields"
      t.text     "public_description"
      t.string   "self_enrollment_code", limit: 255
      t.integer  "self_enrollment_limit"
      t.string   "integration_id", limit: 255
      t.string   "time_zone", limit: 255
      t.string   "lti_context_id" , limit: 255
      t.integer  "turnitin_id", :limit => 8, :unique => true
      t.boolean  "show_announcements_on_home_page"
      t.integer  "home_page_announcement_limit"
    end

    add_index "courses", ["account_id"], :name => "index_courses_on_account_id"
    add_index "courses", ["enrollment_term_id"], :name => "index_courses_on_enrollment_term_id"
    add_index "courses", ["root_account_id"], :name => "index_courses_on_root_account_id"
    add_index :courses, [:template_course_id]
    add_index :courses, :uuid
    add_index :courses, [:self_enrollment_code], :unique => true, :where => "self_enrollment_code IS NOT NULL"
    add_index :courses, [:sis_source_id, :root_account_id], where: "sis_source_id IS NOT NULL", unique: true
    add_index :courses, :wiki_id, where: "wiki_id IS NOT NULL"
    if (trgm = connection.extension_installed?(:pg_trgm))
      add_index :courses, "LOWER(name) #{trgm}.gist_trgm_ops", name: "index_trgm_courses_name", using: :gist
      add_index :courses, "LOWER(course_code) #{trgm}.gist_trgm_ops", name: "index_trgm_courses_course_code", using: :gist
      add_index :courses, "LOWER(sis_source_id) #{trgm}.gist_trgm_ops", name: "index_trgm_courses_sis_source_id", using: :gist
      add_index :courses, "(
          coalesce(lower(name), '') || ' ' ||
          coalesce(lower(sis_source_id), '') || ' ' ||
          coalesce(lower(course_code), '')
        ) #{trgm}.gist_trgm_ops",
                name: "index_trgm_courses_composite_search",
                using: :gist
    end
    add_index :courses, [:integration_id, :root_account_id],
              unique: true,
              name: "index_courses_on_integration_id",
              where: "integration_id IS NOT NULL"
    add_index :courses, :lti_context_id, :unique => true
    add_index :courses, :sis_batch_id, where: "sis_batch_id IS NOT NULL"
    add_index :courses, :abstract_course_id, where: "abstract_course_id IS NOT NULL"

    create_table :crocodoc_documents do |t|
      t.string :uuid, limit: 255
      t.string :process_state, limit: 255
      t.integer :attachment_id, :limit => 8
      t.timestamps null: true
    end
    add_index :crocodoc_documents, :uuid
    add_index :crocodoc_documents, :attachment_id
    add_index :crocodoc_documents, :process_state

    create_table :custom_gradebook_columns do |t|
      t.string :title, :null => false, limit: 255
      t.integer :position, :null => false
      t.string :workflow_state, :default => "active", :null => false, limit: 255
      t.integer :course_id, :limit => 8, :null => false
      t.timestamps null: true
      t.boolean :teacher_notes, :default => false, :null => false
    end
    add_index :custom_gradebook_columns, :course_id

    create_table :custom_gradebook_column_data do |t|
      t.string :content, :null => false, limit: 255
      t.integer :user_id, :limit => 8, :null => false
      t.integer :custom_gradebook_column_id, :limit => 8, :null => false
    end
    add_index :custom_gradebook_column_data,
      [:custom_gradebook_column_id, :user_id],
      :unique => true,
      :name => "index_custom_gradebook_column_data_unique_column_and_user"

    create_table "delayed_messages", :force => true do |t|
      t.integer  "notification_id", :limit => 8
      t.integer  "notification_policy_id", :limit => 8
      t.integer  "context_id", :limit => 8
      t.string   "context_type", limit: 255
      t.integer  "communication_channel_id", :limit => 8
      t.string   "frequency", limit: 255
      t.string   "workflow_state", limit: 255
      t.datetime "batched_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "send_at"
      t.text     "link"
      t.text     "name_of_topic"
      t.text     "summary"
      t.integer  "root_account_id", :limit => 8
    end

    add_index "delayed_messages", ["send_at"], :name => "by_sent_at"
    add_index "delayed_messages", ["workflow_state", "send_at"], :name => "ws_sa"
    add_index :delayed_messages, [:communication_channel_id, :root_account_id, :workflow_state, :send_at], :name => "ccid_raid_ws_sa"
    add_index :delayed_messages, :notification_policy_id

    create_table "delayed_notifications", :force => true do |t|
      t.integer  "notification_id", :limit => 8, :null => false
      t.integer  "asset_id", :limit => 8, :null => false
      t.string   "asset_type", :null => false, limit: 255
      t.text     "recipient_keys"
      t.string   "workflow_state", :null => false, limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "asset_context_type", limit: 255
      t.integer  "asset_context_id", :limit => 8
    end

    create_table "developer_keys", :force => true do |t|
      t.string   "api_key", limit: 255
      t.string   "email", limit: 255
      t.string   "user_name", limit: 255
      t.integer  "account_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "user_id", :limit => 8
      t.string   "name", limit: 255
      t.string   "redirect_uri", limit: 255
      t.string   "icon_url", limit: 255
      t.string   "sns_arn", limit: 255
      t.boolean  "trusted"
      t.boolean  "force_token_reuse"
      t.string   "workflow_state", default: "active", null: false, limit: 255
      t.boolean  "replace_tokens"
      t.boolean  "auto_expire_tokens"
      t.string   "redirect_uris", array: true, default: [], null: false, limit: 255
    end

    create_table "discussion_entries", :force => true do |t|
      t.text     "message"
      t.integer  "discussion_topic_id", :limit => 8
      t.integer  "user_id", :limit => 8
      t.integer  "parent_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "attachment_id", :limit => 8
      t.string   "workflow_state",      :default => "active", limit: 255
      t.datetime "deleted_at"
      t.string   "migration_id", limit: 255
      t.integer  "editor_id", :limit => 8
      t.integer  "root_entry_id", :limit => 8
      t.integer  "depth"
      t.integer  "rating_count"
      t.integer  "rating_sum"
    end

    add_index "discussion_entries", ["user_id"], :name => "index_discussion_entries_on_user_id"
    add_index :discussion_entries, :parent_id
    add_index :discussion_entries, [:root_entry_id, :workflow_state, :created_at], :name => "index_discussion_entries_root_entry"
    add_index :discussion_entries, [:discussion_topic_id, :updated_at, :created_at], :name => "index_discussion_entries_for_topic"

    create_table "discussion_entry_participants" do |t|
      t.integer "discussion_entry_id", :limit => 8, :null => false
      t.integer "user_id", :limit => 8, :null => false
      t.string "workflow_state", :null => false, limit: 255
      t.boolean "forced_read_state"
      t.integer "rating"
    end
    add_index "discussion_entry_participants", ["discussion_entry_id", "user_id"], :name => "index_entry_participant_on_entry_id_and_user_id", :unique => true

    create_table "discussion_topics", :force => true do |t|
      t.string   "title", limit: 255
      t.text     "message",                :limit => 16777215
      t.integer  "context_id", :limit => 8, :null => false
      t.string   "context_type", :null => false, limit: 255
      t.string   "type", limit: 255
      t.integer  "user_id", :limit => 8
      t.string   "workflow_state", :null => false, limit: 255
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
      t.string   "context_code", limit: 255
      t.integer  "position"
      t.string   "migration_id", limit: 255
      t.integer  "old_assignment_id", :limit => 8
      t.datetime "subtopics_refreshed_at"
      t.integer  "last_assignment_id", :limit => 8
      t.integer  "external_feed_id", :limit => 8
      t.integer  "editor_id", :limit => 8
      t.boolean  "podcast_enabled"
      t.boolean  "podcast_has_student_posts"
      t.boolean  "require_initial_post"
      t.string   "discussion_type", limit: 255
      t.datetime "lock_at"
      t.boolean  "pinned"
      t.boolean  "locked"
      t.integer  "group_category_id", :limit => 8
      t.boolean  "allow_rating"
      t.boolean  "only_graders_can_rate"
      t.boolean  "sort_by_rating"
    end

    add_index "discussion_topics", ["context_id", "position"], :name => "index_discussion_topics_on_context_id_and_position"
    add_index "discussion_topics", ["id", "type"], :name => "index_discussion_topics_on_id_and_type"
    add_index "discussion_topics", ["root_topic_id"], :name => "index_discussion_topics_on_root_topic_id"
    add_index "discussion_topics", ["user_id"], :name => "index_discussion_topics_on_user_id"
    add_index "discussion_topics", ["workflow_state"], :name => "index_discussion_topics_on_workflow_state"
    add_index :discussion_topics, [:assignment_id]
    add_index :discussion_topics, [:context_id, :context_type, :root_topic_id], :unique => true, :name => "index_discussion_topics_unique_subtopic_per_context"
    add_index :discussion_topics, [:context_id, :last_reply_at], :name => "index_discussion_topics_on_context_and_last_reply_at"
    add_index :discussion_topics, :attachment_id, where: 'attachment_id IS NOT NULL'
    add_index :discussion_topics, :old_assignment_id, where: "old_assignment_id IS NOT NULL"
    add_index :discussion_topics, :external_feed_id, where: "external_feed_id IS NOT NULL"

    # rubocop:disable Migration/PrimaryKey
    create_table :discussion_topic_materialized_views, :id => false do |t|
      t.integer :discussion_topic_id, :limit => 8, :null => false
      t.text :json_structure, :limit => 10.megabytes
      t.text :participants_array, :limit => 10.megabytes
      t.text :entry_ids_array, :limit => 10.megabytes

      t.timestamps null: true
      t.timestamp :generation_started_at
    end
    add_index :discussion_topic_materialized_views, :discussion_topic_id, :unique => true, :name => "index_discussion_topic_materialized_views"
    execute("ALTER TABLE #{DiscussionTopic::MaterializedView.quoted_table_name} ADD CONSTRAINT discussion_topic_materialized_views_pkey PRIMARY KEY USING INDEX index_discussion_topic_materialized_views")

    create_table "discussion_topic_participants" do |t|
      t.integer "discussion_topic_id", :limit => 8, :null => false
      t.integer "user_id", :limit => 8, :null => false
      t.integer "unread_entry_count", :default => 0, :null => false
      t.string "workflow_state", :null => false, limit: 255
      t.boolean "subscribed"
    end
    add_index "discussion_topic_participants", ["discussion_topic_id", "user_id"], :name => "index_topic_participant_on_topic_id_and_user_id", :unique => true

    create_table "enrollment_dates_overrides", :force => true do |t|
      t.integer  "enrollment_term_id", :limit => 8
      t.string   "enrollment_type", limit: 255
      t.integer  "context_id", :limit => 8
      t.string   "context_type", limit: 255
      t.datetime "start_at"
      t.datetime "end_at"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    add_index :enrollment_dates_overrides, :enrollment_term_id

    create_table :enrollment_states, :id => false do |t|
      t.integer :enrollment_id, limit: 8, null: false

      t.string :state, limit: 255
      t.boolean :state_is_current, null: false, default: false
      t.datetime :state_started_at
      t.datetime :state_valid_until

      t.boolean :restricted_access, null: false, default: false
      t.boolean :access_is_current, null: false, default: false

      t.integer :lock_version
    end

    add_index :enrollment_states, :enrollment_id, :unique => true, :name => "index_enrollment_states"
    execute("ALTER TABLE #{EnrollmentState.quoted_table_name} ADD CONSTRAINT enrollment_states_pkey PRIMARY KEY USING INDEX index_enrollment_states")

    add_index :enrollment_states, :state
    add_index :enrollment_states, [:state_is_current, :access_is_current], :name => "index_enrollment_states_on_currents"
    add_index :enrollment_states, :state_valid_until

    create_table "enrollment_terms", :force => true do |t|
      t.integer  "root_account_id", :limit => 8, :null => false
      t.string   "name", limit: 255
      t.string   "term_code", limit: 255
      t.string   "sis_source_id", limit: 255
      t.integer  "sis_batch_id", :limit => 8
      t.datetime "start_at"
      t.datetime "end_at"
      t.boolean  "accepting_enrollments"
      t.boolean  "can_manually_enroll"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "workflow_state",        :default => "active", :null => false, limit: 255
      t.text     "stuck_sis_fields"
      t.string   "integration_id", limit: 255
      t.integer  "grading_period_group_id", limit: 8
    end

    add_index :enrollment_terms, [:sis_source_id, :root_account_id], where: "sis_source_id IS NOT NULL", unique: true
    add_index :enrollment_terms, :root_account_id
    add_index :enrollment_terms, [:integration_id, :root_account_id],
              unique: true,
              name: "index_terms_on_integration_id",
              where: "integration_id IS NOT NULL"
    add_index :enrollment_terms, :sis_batch_id, where: "sis_batch_id IS NOT NULL"
    add_index :enrollment_terms, :grading_period_group_id

    create_table "enrollments", :force => true do |t|
      t.integer  "user_id", :limit => 8, :null => false
      t.integer  "course_id", :limit => 8, :null => false
      t.string   "type", :null => false, limit: 255
      t.string   "uuid", limit: 255
      t.string   "workflow_state", :null => false, limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "associated_user_id", :limit => 8
      t.integer  "sis_batch_id", :limit => 8
      t.datetime "start_at"
      t.datetime "end_at"
      t.integer  "course_section_id", :limit => 8, :null => false
      t.integer  "root_account_id", :limit => 8, :null => false
      t.float    "computed_final_score"
      t.datetime "completed_at"
      t.boolean  "self_enrolled"
      t.float    "computed_current_score"
      t.string   "grade_publishing_status", :default => "unpublished", limit: 255
      t.datetime "last_publish_attempt_at"
      t.text     "stuck_sis_fields"
      t.text     "grade_publishing_message"
      t.boolean  "limit_privileges_to_course_section"
      t.datetime "last_activity_at"
      t.integer  "total_activity_time"
      t.integer  "role_id", :limit => 8, :null => false
      t.datetime "graded_at"
    end

    add_index "enrollments", ["course_id", "workflow_state"], :name => "index_enrollments_on_course_id_and_workflow_state"
    add_index "enrollments", ["course_section_id"], :name => "index_enrollments_on_course_section_id"
    add_index "enrollments", ["user_id"], :name => "index_enrollments_on_user_id"
    add_index "enrollments", ["uuid"], :name => "index_enrollments_on_uuid"
    add_index "enrollments", ["workflow_state"], :name => "index_enrollments_on_workflow_state"
    add_index :enrollments, [:associated_user_id], :where => "associated_user_id IS NOT NULL"
    add_index :enrollments, [:root_account_id, :course_id]
    add_index :enrollments, :sis_batch_id, where: "sis_batch_id IS NOT NULL"
    add_index :enrollments,
              [:user_id, :type, :role_id, :course_section_id, :associated_user_id],
              where: "associated_user_id IS NOT NULL",
              name: 'index_enrollments_on_user_type_role_section_associated_user',
              unique: true
    add_index :enrollments,
              [:user_id, :type, :role_id, :course_section_id],
              where: "associated_user_id IS NULL ",
              name: 'index_enrollments_on_user_type_role_section',
              unique: true
    add_index :enrollments, [:course_id, :user_id]

    create_table "eportfolio_categories", :force => true do |t|
      t.integer  "eportfolio_id", :limit => 8, :null => false
      t.string   "name", limit: 255
      t.integer  "position"
      t.string   "slug", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "eportfolio_categories", ["eportfolio_id"], :name => "index_eportfolio_categories_on_eportfolio_id"

    create_table "eportfolio_entries", :force => true do |t|
      t.integer  "eportfolio_id", :limit => 8, :null => false
      t.integer  "eportfolio_category_id", :limit => 8, :null => false
      t.integer  "position"
      t.string   "name", limit: 255
      t.boolean  "allow_comments"
      t.boolean  "show_comments"
      t.string   "slug", limit: 255
      t.text     "content",                :limit => 16777215
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "eportfolio_entries", ["eportfolio_category_id"], :name => "index_eportfolio_entries_on_eportfolio_category_id"
    add_index "eportfolio_entries", ["eportfolio_id"], :name => "index_eportfolio_entries_on_eportfolio_id"

    create_table "eportfolios", :force => true do |t|
      t.integer  "user_id", :limit => 8, :null => false
      t.string   "name", limit: 255
      t.boolean  "public"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "uuid", limit: 255
      t.string   "workflow_state", :default => "active", :null => false, limit: 255
      t.datetime "deleted_at"
    end

    add_index "eportfolios", ["user_id"], :name => "index_eportfolios_on_user_id"

    create_table :epub_exports do |t|
      t.integer :content_export_id, :course_id, :user_id, limit: 8
      t.string :workflow_state, default: "created", limit: 255
      t.timestamps null: true
      t.string :type, limit: 255
    end
    add_index :epub_exports, :user_id
    add_index :epub_exports, :course_id
    add_index :epub_exports, :content_export_id

    create_table "error_reports", :force => true do |t|
      t.text     "backtrace"
      t.text     "url"
      t.text     "message"
      t.text     "comments"
      t.integer  "user_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "email", limit: 255
      t.boolean  "during_tests",                           :default => false
      t.text     "user_agent"
      t.string   "request_method", limit: 255
      t.text     "http_env",           :limit => 16777215
      t.string   "subject", limit: 255
      t.string   "request_context_id", limit: 255
      t.integer  "account_id", :limit => 8
      t.integer  "zendesk_ticket_id", :limit => 8
      t.text     "data"
      t.string   "category", limit: 255
    end

    add_index "error_reports", ["created_at"], :name => "error_reports_created_at"
    add_index "error_reports", ["zendesk_ticket_id"], :name => "index_error_reports_on_zendesk_ticket_id"
    add_index :error_reports, :category

    create_table :event_stream_failures do |t|
      t.string :operation, :null => false, limit: 255
      t.string :event_stream, :null => false, limit: 255
      t.string :record_id, :null => false, limit: 255
      t.text :payload, :null => false
      t.text :exception
      t.text :backtrace
      t.timestamps null: true
    end

    create_table "external_feed_entries", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "external_feed_id", :limit => 8, :null => false
      t.text     "title"
      t.text     "message"
      t.string   "source_name", limit: 255
      t.text     "source_url"
      t.datetime "posted_at"
      t.string   "workflow_state", :null => false, limit: 255
      t.text     "url"
      t.string   "author_name", limit: 255
      t.string   "author_email", limit: 255
      t.text     "author_url"
      t.integer  "asset_id", :limit => 8
      t.string   "asset_type", limit: 255
      t.string   "uuid", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index :external_feed_entries, :external_feed_id
    add_index :external_feed_entries, :uuid
    add_index :external_feed_entries, :url

    create_table "external_feeds", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "context_id", :limit => 8, :null => false
      t.string   "context_type", :null => false, limit: 255
      t.integer  "consecutive_failures"
      t.integer  "failures"
      t.datetime "refresh_at"
      t.string   "title", limit: 255
      t.string   "url", :null => false, limit: 255
      t.string   "header_match", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "verbosity", limit: 255
      t.string   "migration_id", limit: 255
    end

    add_index "external_feeds", ["context_id", "context_type"], :name => "index_external_feeds_on_context_id_and_context_type"
    add_index :external_feeds, [:context_id, :context_type, :url, :verbosity], unique: true, where: "header_match IS NULL", name: 'index_external_feeds_uniquely_1'
    add_index :external_feeds, [:context_id, :context_type, :url, :header_match, :verbosity], unique: true, where: "header_match IS NOT NULL", name: 'index_external_feeds_uniquely_2'

    create_table :external_integration_keys do |t|
      t.integer :context_id, limit: 8, null: false
      t.string :context_type, null: false, limit: 255
      t.string :key_value, null: false, limit: 255
      t.string :key_type, null: false, limit: 255

      t.timestamps null: true
    end

    add_index :external_integration_keys, [:context_id, :context_type, :key_type], name: 'index_external_integration_keys_unique', unique: true

    create_table :favorites do |t|
      t.integer :user_id, :limit => 8
      t.integer :context_id, :limit => 8
      t.string :context_type, limit: 255

      t.timestamps null: true
    end
    add_index :favorites, [:user_id]
    add_index :favorites, [:user_id, :context_id, :context_type], :unique => true, :name => "index_favorites_unique_user_object"

    create_table :feature_flags do |t|
      t.integer :context_id, limit: 8, null: false
      t.string :context_type, null: false, limit: 255
      t.string :feature, null: false, limit: 255
      t.string :state, default: 'allowed', null: false, limit: 255
      t.timestamps null: true
    end
    add_index :feature_flags, [:context_id, :context_type, :feature], unique: true, name: 'index_feature_flags_on_context_and_feature'

    create_table "folders", :force => true do |t|
      t.string   "name", limit: 255
      t.text     "full_name"
      t.integer  "context_id", :limit => 8, :null => false
      t.string   "context_type", :null => false, limit: 255
      t.integer  "parent_folder_id", :limit => 8
      t.string   "workflow_state", :null => false, limit: 255
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
      t.string   "submission_context_code", limit: 255
    end

    add_index "folders", ["cloned_item_id"], :name => "index_folders_on_cloned_item_id"
    add_index "folders", ["context_id", "context_type"], :name => "index_folders_on_context_id_and_context_type"
    add_index "folders", ["parent_folder_id"], :name => "index_folders_on_parent_folder_id"
    add_index :folders, [:context_id, :context_type], :unique => true, :name => 'index_folders_on_context_id_and_context_type_for_root_folders', :where => "parent_folder_id IS NULL AND workflow_state<>'deleted'"
    add_index :folders, [:submission_context_code, :parent_folder_id], unique: true

    create_table :gradebook_csvs do |t|
      t.integer :user_id, limit: 8, null: false
      t.integer :attachment_id, limit: 8, null: false
      t.integer :progress_id, limit: 8, null: false
      t.integer :course_id, limit: 8, null: false
    end
    add_index :gradebook_csvs, [:user_id, :course_id]

    create_table "gradebook_uploads", :force => true do |t|
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "course_id", limit: 8, null: false
      t.integer  "user_id", limit: 8, null: false
      t.integer  "progress_id", limit: 8, null: false
      t.text     "gradebook", limit: 10.megabytes
    end

    add_index :gradebook_uploads, [:course_id, :user_id], unique: true
    add_index :gradebook_uploads, :progress_id

    create_table :grading_period_groups do |t|
      t.integer :course_id, :limit => 8
      t.integer :account_id, :limit => 8
      t.timestamps null: true
      t.string :workflow_state, default: "active", null: false, limit: 255
      t.string :title, limit: 255
    end
    add_index :grading_period_groups, :course_id
    add_index :grading_period_groups, :account_id
    add_index :grading_period_groups, :workflow_state

    create_table :grading_periods do |t|
      t.float :weight
      t.datetime :start_date, :null => false
      t.datetime :end_date, :null => false
      t.timestamps null: true
      t.string :title, limit: 255
      t.string :workflow_state, default: "active", null: false, limit: 255
      # someone used change_column instead of change_column_null and
      # accidentally lost the limit: 8 on this foreign key
      # (went from bigint -> int). needs to be fixed.
      t.integer :grading_period_group_id, null: false
      t.datetime :close_date
    end
    add_index :grading_periods, :grading_period_group_id
    add_index :grading_periods, :workflow_state

    create_table "grading_standards", :force => true do |t|
      t.string   "title", limit: 255
      t.text     "data"
      t.integer  "context_id", :limit => 8, :null => false
      t.string   "context_type", :null => false, limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "user_id", :limit => 8
      t.integer  "usage_count"
      t.string   "context_code", limit: 255
      t.string   "workflow_state", :null => false, limit: 255
      t.string   "migration_id", limit: 255
      t.integer  "version"
    end

    add_index "grading_standards", ["context_code"], :name => "index_grading_standards_on_context_code"
    add_index "grading_standards", ["context_id", "context_type"], :name => "index_grading_standards_on_context_id_and_context_type"

    create_table "group_memberships", :force => true do |t|
      t.integer  "group_id", :limit => 8, :null => false
      t.string   "workflow_state", :null => false, limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "user_id", :limit => 8, :null => false
      t.string   "uuid", null: false, limit: 255
      t.integer  "sis_batch_id", :limit => 8
      t.boolean  "moderator"
    end

    add_index "group_memberships", ["group_id"], :name => "index_group_memberships_on_group_id"
    add_index "group_memberships", ["user_id"], :name => "index_group_memberships_on_user_id"
    add_index "group_memberships", ["workflow_state"], :name => "index_group_memberships_on_workflow_state"
    add_index :group_memberships, :sis_batch_id, where: "sis_batch_id IS NOT NULL"
    add_index :group_memberships, :uuid, unique: true
    add_index :group_memberships, [:group_id, :user_id], :unique => true, :where => "workflow_state <> 'deleted'"

    create_table "groups", :force => true do |t|
      t.string   "name", limit: 255
      t.string   "workflow_state", :null => false, limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "context_id", :limit => 8, :null => false
      t.string   "context_type", :null => false, limit: 255
      t.string   "category", limit: 255
      t.integer  "max_membership"
      t.boolean  "is_public"
      t.integer  "account_id", :limit => 8, :null => false
      t.integer  "wiki_id", :limit => 8
      t.datetime "deleted_at"
      t.string   "join_level", limit: 255
      t.string   "default_view",                 :default => "feed", limit: 255
      t.string   "migration_id", limit: 255
      t.integer  "storage_quota", :limit => 8
      t.string   "uuid", null: false, limit: 255
      t.integer  "root_account_id", :limit => 8, :null => false
      t.string   "sis_source_id", limit: 255
      t.integer  "sis_batch_id", :limit => 8
      t.text     "stuck_sis_fields"
      t.integer  "group_category_id", :limit => 8
      t.text     "description"
      t.integer  "avatar_attachment_id", :limit => 8
      t.integer  "leader_id", :limit => 8
      t.string   "lti_context_id", limit: 255
    end

    add_index "groups", ["account_id"], :name => "index_groups_on_account_id"
    add_index "groups", ["context_id", "context_type"], :name => "index_groups_on_context_id_and_context_type"
    add_index :groups, :group_category_id
    add_index :groups, [:sis_source_id, :root_account_id], where: "sis_source_id IS NOT NULL", unique: true
    add_index :groups, :wiki_id, where: "wiki_id IS NOT NULL"
    add_index :groups, :sis_batch_id, where: "sis_batch_id IS NOT NULL"
    add_index :groups, :uuid, unique: true

    create_table :group_categories do |t|
      t.integer :context_id, :limit => 8
      t.string :context_type, limit: 255
      t.string :name, limit: 255
      t.string :role, limit: 255
      t.datetime :deleted_at
      t.string :self_signup, limit: 255
      t.integer :group_limit
      t.string :auto_leader, limit: 255
      t.timestamps null: true
    end
    add_index :group_categories, [:context_id, :context_type], :name => "index_group_categories_on_context"
    add_index :group_categories, :role, :name => "index_group_categories_on_role"

    create_table :ignores do |t|
      t.string :asset_type, :null => false, limit: 255
      t.integer :asset_id, :null => false, :limit => 8
      t.integer :user_id, :null => false, :limit => 8
      t.string :purpose, :null => false, limit: 255
      t.boolean :permanent, :null => false, :default => false
      t.timestamps null: true
    end
    add_index :ignores, [:asset_id, :asset_type, :user_id, :purpose], :unique => true, :name => 'index_ignores_on_asset_and_user_id_and_purpose'

    create_table "learning_outcome_groups", :force => true do |t|
      t.integer  "context_id", :limit => 8
      t.string   "context_type", limit: 255
      t.string   "title", :null => false, limit: 255
      t.integer  "learning_outcome_group_id", :limit => 8
      t.integer  "root_learning_outcome_group_id", :limit => 8
      t.string   "workflow_state", :null => false, limit: 255
      t.text     "description"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "migration_id", limit: 255
      t.string   "vendor_guid", limit: 255
      t.string   "low_grade", limit: 255
      t.string   "high_grade", limit: 255
      t.string   "vendor_guid_2", limit: 255
      t.string   "migration_id_2", limit: 255
    end
    add_index :learning_outcome_groups, :vendor_guid, :name => "index_learning_outcome_groups_on_vendor_guid"
    add_index :learning_outcome_groups, :learning_outcome_group_id, :where => "learning_outcome_group_id IS NOT NULL"
    add_index :learning_outcome_groups, [:context_id, :context_type]
    add_index :learning_outcome_groups, :root_learning_outcome_group_id, where: "root_learning_outcome_group_id IS NOT NULL"
    add_index :learning_outcome_groups, :vendor_guid_2, :name => "index_learning_outcome_groups_on_vendor_guid_2"

    create_table :learning_outcome_question_results do |t|
      t.integer :learning_outcome_result_id, limit: 8
      t.integer :learning_outcome_id, limit: 8
      t.integer :associated_asset_id, limit: 8
      t.string :associated_asset_type, limit: 255

      t.float :score
      t.float :possible
      t.boolean :mastery
      t.float :percent
      t.integer :attempt
      t.text :title

      t.float :original_score
      t.float :original_possible
      t.boolean :original_mastery

      t.datetime :assessed_at
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :submitted_at
    end

    add_index "learning_outcome_question_results", [:learning_outcome_id], name: "index_learning_outcome_question_results_on_learning_outcome_id"
    add_index "learning_outcome_question_results", [:learning_outcome_result_id], name: "index_LOQR_on_learning_outcome_result_id"

    create_table "learning_outcome_results", :force => true do |t|
      t.integer  "context_id", :limit => 8
      t.string   "context_type", limit: 255
      t.string   "context_code", limit: 255
      t.integer  "association_id", :limit => 8
      t.string   "association_type", limit: 255
      t.integer  "content_tag_id", :limit => 8
      t.integer  "learning_outcome_id", :limit => 8
      t.boolean  "mastery"
      t.integer  "user_id", :limit => 8
      t.float    "score"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "attempt"
      t.float    "possible"
      t.float    "original_score"
      t.float    "original_possible"
      t.boolean  "original_mastery"
      t.integer  "artifact_id", :limit => 8
      t.string   "artifact_type", limit: 255
      t.datetime "assessed_at"
      t.string   "title", limit: 255
      t.float    "percent"
      t.integer  "associated_asset_id", :limit => 8
      t.string   "associated_asset_type", limit: 255
      t.datetime "submitted_at"
    end

    add_index :learning_outcome_results,
              [:user_id, :content_tag_id, :association_id, :association_type, :associated_asset_id, :associated_asset_type],
              unique: true,
              name: "index_learning_outcome_results_association"
    add_index :learning_outcome_results, :content_tag_id
    add_index :learning_outcome_results, :learning_outcome_id, where: "learning_outcome_id IS NOT NULL"

    create_table "learning_outcomes", :force => true do |t|
      t.integer  "context_id", :limit => 8
      t.string   "context_type", limit: 255
      t.string   "short_description", :null => false, limit: 255
      t.string   "context_code", limit: 255
      t.text     "description"
      t.text     "data"
      t.string   "workflow_state", :null => false, limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "migration_id", limit: 255
      t.string   "vendor_guid", limit: 255
      t.string   "low_grade", limit: 255
      t.string   "high_grade", limit: 255
      t.string   "display_name", limit: 255
      t.string   "calculation_method", limit: 255
      t.integer  "calculation_int", :limit => 2
      t.string   "vendor_guid_2", limit: 255
      t.string   "migration_id_2", limit: 255
    end
    add_index :learning_outcomes, [ :context_id, :context_type ]
    add_index :learning_outcomes, :vendor_guid, :name => "index_learning_outcomes_on_vendor_guid"
    add_index :learning_outcomes, :vendor_guid_2, :name => "index_learning_outcomes_on_vendor_guid_2"

    create_table :live_assessments_assessments do |t|
      t.string :key, null: false, limit: 255
      t.string :title, null: false, limit: 255
      t.integer :context_id, limit: 8, null: false
      t.string :context_type, null: false, limit: 255
      t.timestamps null: true
    end
    add_index :live_assessments_assessments, [:context_id, :context_type, :key], unique: true, name: 'index_live_assessments'

    create_table :live_assessments_results do |t|
      t.integer :user_id, limit: 8, null: false
      t.integer :assessor_id, limit: 8, null: false
      t.integer :assessment_id, limit: 8, null: false
      t.boolean :passed, null: false
      t.datetime :assessed_at, null: false
    end
    add_index :live_assessments_results, [:assessment_id, :user_id]

    create_table :live_assessments_submissions do |t|
      t.integer :user_id, limit: 8, null: false
      t.integer :assessment_id, limit: 8, null: false
      t.float :possible
      t.float :score
      t.datetime :assessed_at
      t.timestamps null: true
    end
    add_index :live_assessments_submissions, [:assessment_id, :user_id], unique: true

    create_table :lti_message_handlers do |t|
      t.string :message_type, null: false, limit: 255
      t.string :launch_path, null: false, limit: 255
      t.text :capabilities
      t.text :parameters
      t.integer :resource_handler_id, limit: 8, null: false
      t.timestamps null: true
    end
    add_index :lti_message_handlers, [:resource_handler_id, :message_type], name: 'index_lti_message_handlers_on_resource_handler_and_type', unique: true

    create_table :lti_product_families do |t|
      t.string :vendor_code, null: false, limit: 255
      t.string :product_code, null: false, limit: 255
      t.string :vendor_name, null: false, limit: 255
      t.text :vendor_description
      t.string :website, limit: 255
      t.string :vendor_email, limit: 255
      t.integer :root_account_id, limit: 8, null: false
      t.timestamps null: true
    end
    add_index :lti_product_families, [:root_account_id, :vendor_code, :product_code], name: 'index_lti_product_families_on_root_account_vend_code_prod_code', unique: true

    create_table :lti_resource_handlers do |t|
      t.string :resource_type_code, null: false, limit: 255
      t.string :placements, limit: 255
      t.string :name, null: false, limit: 255
      t.text :description
      t.text :icon_info
      t.integer :tool_proxy_id, limit: 8, null: false
      t.timestamps null: true
    end
    add_index :lti_resource_handlers, [:tool_proxy_id, :resource_type_code], name: 'index_lti_resource_handlers_on_tool_proxy_and_type_code', unique: true

    create_table :lti_resource_placements do |t|
      t.string :placement, null: false, limit: 255
      t.timestamps null: true
      t.bigint :message_handler_id
    end
    add_index :lti_resource_placements,
              [:placement, :message_handler_id], unique: true,
              where: 'message_handler_id IS NOT NULL',
              name: 'index_resource_placements_on_placement_and_message_handler'

    create_table :lti_tool_proxies do |t|
      t.text :shared_secret, null: false
      t.string :guid, null: false, limit: 255
      t.string :product_version, null: false, limit: 255
      t.string :lti_version, null: false, limit: 255
      t.integer :product_family_id, limit: 8, null: false
      t.integer :context_id, limit: 8, null: false
      t.string :workflow_state, null: false, limit: 255
      t.text :raw_data, null: false
      t.timestamps null: true
      # Note: I think the original migration didn't want this to remain the
      # default, but they didn't remove it properly, so it still is.
      t.string :context_type, null: false, default: 'Account', limit: 255
      t.string :name, limit: 255
      t.string :description, limit: 255
      t.text   :update_payload
    end
    add_index :lti_tool_proxies, [:guid]

    create_table :lti_tool_proxy_bindings do |t|
      t.integer :context_id, limit: 8, null: false
      t.string :context_type, null: false, limit: 255
      t.integer :tool_proxy_id, limit:8, null: false
      t.timestamps null: true
      t.boolean :enabled, null: false, default: true
    end
    add_index :lti_tool_proxy_bindings, [:context_id, :context_type, :tool_proxy_id], name: 'index_lti_tool_proxy_bindings_on_context_and_tool_proxy', unique: true

    create_table :lti_tool_settings do |t|
      t.integer :tool_proxy_id, limit:8, null: false
      t.integer :context_id, limit: 8
      t.string :context_type, limit: 255
      t.text :resource_link_id
      t.text :custom
      t.timestamps null: true
    end
    add_index :lti_tool_settings, [:resource_link_id, :context_type, :context_id, :tool_proxy_id],name: 'index_lti_tool_settings_on_link_context_and_tool_proxy', unique: true

    create_table :master_courses_child_content_tags do |t|
      t.integer :child_subscription_id, limit: 8, null: false # mainly for bulk loading on import

      t.string :content_type, null: false, limit: 255
      t.integer :content_id, limit: 8, null: false

      t.text :downstream_changes
    end

    add_index :master_courses_child_content_tags, [:content_type, :content_id], :unique => true,
      :name => "index_child_content_tags_on_content"
    add_index :master_courses_child_content_tags, :child_subscription_id, :name => "index_child_content_tags_on_subscription"

    create_table :master_courses_child_subscriptions do |t|
      t.integer :master_template_id, limit: 8, null: false
      t.integer :child_course_id, limit: 8, null: false

      t.string :workflow_state, null: false, limit: 255

      # we can use this to keep track of which subscriptions are new
      # vs. which ones have been getting regular updates and we can use a selective copy for
      t.boolean :use_selective_copy, null: false, default: false

      t.timestamps null: false
    end

    add_index :master_courses_child_subscriptions, :master_template_id
    add_index :master_courses_child_subscriptions, [:master_template_id, :child_course_id],
      :unique => true, :where => "workflow_state <> 'deleted'",
      :name => "index_mc_child_subscriptions_on_template_id_and_course_id"

    create_table :master_courses_master_content_tags do |t|
      t.integer :master_template_id, limit: 8, null: false

      # should we add a workflow state and make this soft-deletable? 
      # maybe someday if we decide to use these to define the template content aets

      t.string :content_type, null: false, limit: 255
      t.integer :content_id, limit: 8, null: false

      # when we export an object for a master migration we'll set this column on the tag
      # when we update the content we'll erase this
      # so now we'll know what's been updated since the last successful export
      t.integer :current_migration_id, limit: 8
      t.text :restrictions # we might not leave this at settings/content
      t.string :migration_id
    end

    add_index :master_courses_master_content_tags, :master_template_id
    add_index :master_courses_master_content_tags, [:master_template_id, :content_type, :content_id], :unique => true,
      :name => "index_master_content_tags_on_template_id_and_content"
    add_index :master_courses_master_content_tags, :migration_id, :unique => true, :name => "index_master_content_tags_on_migration_id"

    create_table :master_courses_master_migrations do |t|
      t.integer :master_template_id, limit: 8, null: false
      t.integer :user_id, limit: 8 # exports use a bunch of terrible user-dependent stuff

      # we can just use serialized columns here to store the rest of the data
      # instead of a million rows
      # since we won't really be needing any of it separately

      t.text :export_results # we can store the initial export details here
      t.text :import_results # and then the statuses of each migration on the child courses

      t.datetime :exports_started_at
      t.datetime :imports_queued_at

      t.string :workflow_state, null: false, limit: 255
      t.timestamps null: false
      t.datetime :imports_completed_at
    end

    add_index :master_courses_master_migrations, :master_template_id

    create_table :master_courses_master_templates do |t|
      t.integer :course_id, limit: 8, null: false
      t.boolean :full_course, null: false, default: true # we may not ever get around to allowing selective collection sets out but just in case
      t.string :workflow_state, limit: 255
      t.timestamps null: false
      # due to paranoia about race conditions around trying to make multiple migrations at once
      # we'll lock the template before we create the migration
      # and mark this column with the new migration unless there's already a currently running one, in which case we'll abort
      t.integer :active_migration_id, limit: 8
      t.text :default_restrictions
    end

    add_index :master_courses_master_templates, :course_id

    create_table "media_objects", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "context_id", :limit => 8
      t.string   "context_type", limit: 255
      t.string   "workflow_state", :null => false, limit: 255
      t.string   "user_type", limit: 255
      t.string   "title", limit: 255
      t.string   "user_entered_title", limit: 255
      t.string   "media_id", :null => false, limit: 255
      t.string   "media_type", limit: 255
      t.integer  "duration"
      t.integer  "max_size"
      t.integer  "root_account_id", :limit => 8
      t.text     "data"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "attachment_id", :limit => 8
      t.integer  "total_size"
      t.string   "old_media_id", limit: 255
    end

    add_index "media_objects", ["attachment_id"], :name => "index_media_objects_on_attachment_id"
    add_index "media_objects", ["context_id", "context_type"], :name => "index_media_objects_on_context_id_and_context_type"
    add_index "media_objects", ["media_id"], :name => "index_media_objects_on_media_id"
    add_index "media_objects", ["old_media_id"]
    add_index :media_objects, :root_account_id

    create_table :media_tracks do |t|
      t.integer :user_id,         :limit => 8
      t.integer :media_object_id, :limit => 8, :null => false
      t.string :kind,             :default => "subtitles", limit: 255
      t.string :locale,           :default => "en", limit: 255
      t.text :content,            :null => false

      t.timestamps null: true
    end

    add_index :media_tracks, [:media_object_id, :locale], :name => 'media_object_id_locale'

    create_table "messages", :force => true do |t|
      t.text     "to"
      t.text     "from"
      t.text     "subject"
      t.text     "body"
      t.integer  "delay_for",                :default => 120
      t.datetime "dispatch_at"
      t.datetime "sent_at"
      t.string   "workflow_state", limit: 255
      t.text     "transmission_errors"
      t.boolean  "is_bounced"
      t.integer  "notification_id", :limit => 8
      t.integer  "communication_channel_id", :limit => 8
      t.integer  "context_id", :limit => 8
      t.string   "context_type", limit: 255
      t.integer  "asset_context_id", :limit => 8
      t.string   "asset_context_type", limit: 255
      t.integer  "user_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "notification_name", limit: 255
      t.text     "url"
      t.string   "path_type", limit: 255
      t.text     "from_name"
      t.string   "asset_context_code", limit: 255
      t.boolean  "to_email"
      t.text     "html_body"
      t.integer  "root_account_id", :limit => 8
      t.string   "reply_to_name", limit: 255
    end

    add_index "messages", ["communication_channel_id"], :name => "index_messages_on_communication_channel_id"
    add_index "messages", ["context_id", "context_type", "notification_name", "to", "user_id"], :name => "existing_undispatched_message"
    add_index "messages", ["notification_id"], :name => "index_messages_on_notification_id"
    add_index "messages", ["user_id", "to_email", "dispatch_at"], :name => "index_messages_user_id_dispatch_at_to_email"
    add_index :messages, :root_account_id
    add_index :messages, :sent_at, where: "sent_at IS NOT NULL"

    create_table :migration_issues do |t|
      t.integer :content_migration_id, :limit => 8, :null => false
      t.text :description
      t.string :workflow_state, :null => false, limit: 255
      t.text :fix_issue_html_url
      t.string :issue_type, :null => false, limit: 255
      t.integer :error_report_id, :limit => 8
      t.text :error_message

      t.timestamps null: true
    end
    add_index :migration_issues, :content_migration_id

    create_table :moderated_grading_provisional_grades do |t|
      t.string     :grade, limit: 255
      t.float      :score
      t.timestamp  :graded_at
      t.references :scorer,     null: false, limit: 8
      t.references :submission, null: false, limit: 8

      t.timestamps null: true
      t.boolean    :final,      null: false, default: false
      t.integer    :source_provisional_grade_id, limit: 8
      t.boolean    :graded_anonymously
    end
    add_index :moderated_grading_provisional_grades, :submission_id
    add_index :moderated_grading_provisional_grades,
      [:submission_id],
      :unique => true,
      :where => "final = TRUE",
      :name => :idx_mg_provisional_grades_unique_submission_when_final
    add_index :moderated_grading_provisional_grades,
      [:submission_id, :scorer_id],
      :unique => true,
      :name => :idx_mg_provisional_grades_unique_sub_scorer_when_not_final,
      :where => "final = FALSE"
    add_index :moderated_grading_provisional_grades, :source_provisional_grade_id, name: 'index_provisional_grades_on_source_grade', where: "source_provisional_grade_id IS NOT NULL"

    create_table :moderated_grading_selections do |t|
      t.integer :assignment_id,                 limit: 8, null: false
      t.integer :student_id,                    limit: 8, null: false
      t.integer :selected_provisional_grade_id, limit: 8, null: true

      t.timestamps null: false
    end
    add_index :moderated_grading_selections,
              [:assignment_id, :student_id],
              unique: true,
              name: :idx_mg_selections_unique_on_assignment_and_student
    add_index :moderated_grading_selections, :selected_provisional_grade_id, name: 'index_moderated_grading_selections_on_selected_grade', where: "selected_provisional_grade_id IS NOT NULL"
    add_index :moderated_grading_selections, :student_id

    create_table :notification_endpoints do |t|
      t.integer :access_token_id, limit: 8, null: false
      t.string :token, null: false, limit: 255
      t.string :arn, null: false, limit: 255
      t.timestamps null: true
    end
    add_index :notification_endpoints, :access_token_id

    create_table "notification_policies", :force => true do |t|
      t.integer  "notification_id", :limit => 8
      t.integer  "communication_channel_id", :limit => 8, :null => false
      t.string   "frequency", :default => 'immediately', :null => false, limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "notification_policies", ["notification_id"], :name => "index_notification_policies_on_notification_id"
    add_index :notification_policies, [:communication_channel_id, :notification_id], unique: true, name: 'index_notification_policies_on_cc_and_notification_id'

    create_table "notifications", :force => true do |t|
      t.string   "workflow_state", :null => false, limit: 255
      t.string   "name", limit: 255
      t.string   "subject", limit: 255
      t.string   "category", limit: 255
      t.integer  "delay_for",      :default => 120
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "main_link", limit: 255
    end
    add_index :notifications, [:name], :unique => true, :name => "index_notifications_unique_on_name"

    create_table "oauth_requests", :force => true do |t|
      t.string   "token", limit: 255
      t.string   "secret", limit: 255
      t.string   "user_secret", limit: 255
      t.string   "return_url", :limit => 4.kilobytes
      t.string   "workflow_state", limit: 255
      t.integer  "user_id", :limit => 8
      t.string   "original_host_with_port", limit: 255
      t.string   "service", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table :one_time_passwords do |t|
      t.integer :user_id, limit: 8, null: false
      t.string :code, null: false
      t.boolean :used, null: false, default: false
      t.timestamps null: false
    end
    add_index :one_time_passwords, [:user_id, :code], unique: true

    create_table :originality_reports do |t|
      t.integer :attachment_id, limit: 8, null: false
      t.float :originality_score, null: false
      t.integer :originality_report_attachment_id, limit: 8
      t.text :originality_report_url
      t.text :originality_report_lti_url
      t.timestamps null: false
      t.integer :submission_id, limit: 8, null: false
      t.string :workflow_state, null: false, default: 'pending'
    end
    add_index :originality_reports, :attachment_id, unique: true
    add_index :originality_reports, :originality_report_attachment_id, unique: true
    add_index :originality_reports, :submission_id
    add_index :originality_reports, [:workflow_state]

    create_table "page_comments", :force => true do |t|
      t.text     "message"
      t.integer  "page_id", :limit => 8
      t.string   "page_type", limit: 255
      t.integer  "user_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "page_comments", ["page_id", "page_type"], :name => "index_page_comments_on_page_id_and_page_type"
    add_index "page_comments", ["user_id"], :name => "index_page_comments_on_user_id"

    create_table "page_views", :id => false, :force => true do |t|
      t.string   "request_id", limit: 255
      t.string   "session_id", limit: 255
      t.integer  "user_id", :limit => 8, :null => false
      t.text     "url"
      t.integer  "context_id", :limit => 8
      t.string   "context_type", limit: 255
      t.integer  "asset_id", :limit => 8
      t.string   "asset_type", limit: 255
      t.string   "controller", limit: 255
      t.string   "action", limit: 255
      t.float    "interaction_seconds"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "developer_key_id", :limit => 8
      t.boolean  "user_request"
      t.float    "render_time"
      t.text     "user_agent"
      t.integer  "asset_user_access_id", :limit => 8
      t.boolean  "participated"
      t.boolean  "summarized"
      t.integer  "account_id", :limit => 8
      t.integer  "real_user_id", :limit => 8
      t.string   "http_method", limit: 255
      t.string   "remote_ip", limit: 255
    end
    execute("ALTER TABLE #{PageView.quoted_table_name} ADD PRIMARY KEY (request_id)")

    add_index "page_views", ["account_id", "created_at"]
    add_index "page_views", ["asset_user_access_id"], :name => "index_page_views_asset_user_access_id"
    add_index "page_views", ["context_type", "context_id"], :name => "index_page_views_on_context_type_and_context_id"
    add_index "page_views", ["summarized", "created_at"], :name => "index_page_views_summarized_created_at"
    add_index "page_views", ["user_id", "created_at"], :name => "index_page_views_on_user_id_and_created_at"

    create_table "plugin_settings", :force => true do |t|
      t.string   "name",       :default => "", :null => false, limit: 255
      t.text     "settings"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "disabled"
    end

    add_index "plugin_settings", ["name"], :name => "index_plugin_settings_on_name"

    create_table :polling_poll_choices do |t|
      t.string :text, limit: 255
      t.boolean :is_correct, null: false, default: false
      t.integer :poll_id, limit: 8, null: false
      t.timestamps null: true
      t.integer :position
    end

    add_index :polling_poll_choices, :poll_id

    create_table :polling_poll_sessions do |t|
      t.boolean :is_published, null: false, default: false
      t.boolean :has_public_results, null: false, default: false
      t.integer :course_id, limit: 8, null: false
      t.integer :course_section_id, limit: 8
      t.integer :poll_id, limit: 8, null: false
      t.timestamps null: true
    end

    add_index :polling_poll_sessions, :course_id
    add_index :polling_poll_sessions, :course_section_id
    add_index :polling_poll_sessions, :poll_id

    create_table :polling_poll_submissions do |t|
      t.integer :poll_id, limit: 8, null: false
      t.integer :poll_choice_id, limit: 8, null: false
      t.integer :user_id, limit: 8, null: false
      t.timestamps null: true
      t.integer :poll_session_id, limit: 8, null: false
    end

    add_index :polling_poll_submissions, :poll_choice_id
    add_index :polling_poll_submissions, :poll_session_id
    add_index :polling_poll_submissions, :user_id

    create_table :polling_polls do |t|
      t.string :question, limit: 255
      t.string :description, limit: 255
      t.timestamps null: true
      t.integer :user_id, limit: 8, null: false
    end

    add_index :polling_polls, :user_id

    create_table "pseudonyms", :force => true do |t|
      t.integer  "user_id", :limit => 8, :null => false
      t.integer  "account_id", :limit => 8, :null => false
      t.string   "workflow_state", :null => false, limit: 255
      t.string   "unique_id",                                :null => false, limit: 255
      t.string   "crypted_password",                         :null => false, limit: 255
      t.string   "password_salt",                            :null => false, limit: 255
      t.string   "persistence_token",                        :null => false, limit: 255
      t.string   "single_access_token",                      :null => false, limit: 255
      t.string   "perishable_token",                         :null => false, limit: 255
      t.integer  "login_count",              :default => 0,  :null => false
      t.integer  "failed_login_count",       :default => 0,  :null => false
      t.datetime "last_request_at"
      t.datetime "last_login_at"
      t.datetime "current_login_at"
      t.string   "last_login_ip", limit: 255
      t.string   "current_login_ip", limit: 255
      t.string   "reset_password_token",     :default => "", :null => false, limit: 255
      t.integer  "position"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "password_auto_generated"
      t.datetime "deleted_at"
      t.integer  "sis_batch_id", :limit => 8
      t.string   "sis_user_id", limit: 255
      t.string   "sis_ssha", limit: 255
      t.integer  "communication_channel_id", :limit => 8
      t.integer  "sis_communication_channel_id", :limit => 8
      t.text     "stuck_sis_fields"
      t.string   "integration_id", limit: 255
      t.integer  "authentication_provider_id", :limit => 8
    end

    add_index "pseudonyms", ["persistence_token"], :name => "index_pseudonyms_on_persistence_token"
    add_index "pseudonyms", ["single_access_token"], :name => "index_pseudonyms_on_single_access_token"
    add_index "pseudonyms", ["user_id"], :name => "index_pseudonyms_on_user_id"
    if (trgm = connection.extension_installed?(:pg_trgm))
      add_index :pseudonyms, "lower(sis_user_id) #{trgm}.gist_trgm_ops", name: "index_trgm_pseudonyms_sis_user_id", using: :gist
      add_index :pseudonyms, "lower(unique_id) #{trgm}.gist_trgm_ops", name: "index_trgm_pseudonyms_unique_id", using: :gist
    end
    add_index :pseudonyms, :sis_communication_channel_id
    add_index :pseudonyms, [:sis_user_id, :account_id], where: "sis_user_id IS NOT NULL", unique: true
    add_index :pseudonyms, :account_id
    add_index :pseudonyms, [:integration_id, :account_id],
              unique: true,
              name: "index_pseudonyms_on_integration_id",
              where: "integration_id IS NOT NULL"
    add_index :pseudonyms, :sis_batch_id, where: "sis_batch_id IS NOT NULL"
    add_index :pseudonyms, :authentication_provider_id, where: "authentication_provider_id IS NOT NULL"
    execute "CREATE UNIQUE INDEX index_pseudonyms_on_unique_id_and_account_id_and_authentication_provider_id ON #{Pseudonym.quoted_table_name} (LOWER(unique_id), account_id, authentication_provider_id) WHERE workflow_state='active'"
    execute "CREATE UNIQUE INDEX index_pseudonyms_on_unique_id_and_account_id_no_authentication_provider_id ON #{Pseudonym.quoted_table_name} (LOWER(unique_id), account_id) WHERE workflow_state='active' AND authentication_provider_id IS NULL"

    create_table :profiles do |t|
      t.integer  :root_account_id, :limit => 8, :null => false
      t.string   :context_type, :null => false, limit: 255
      t.integer  :context_id, :limit => 8, :null => false
      t.string   :title, limit: 255
      t.string   :path, limit: 255
      t.text     :description
      t.text     :data
      t.string   :visibility, limit: 255
      t.integer  :position
    end
    add_index :profiles, [:root_account_id, :path], :unique => true
    add_index :profiles, [:context_type, :context_id], :unique => true

    create_table :progresses do |t|
      t.integer :context_id, :limit => 8, :null => false
      t.string :context_type, :null => false, limit: 255
      t.integer :user_id, :limit => 8
      t.string :tag, :null => false, limit: 255
      t.float :completion
      t.string :delayed_job_id, limit: 255
      t.string :workflow_state, :null => false, limit: 255
      t.datetime :created_at
      t.datetime :updated_at
      t.text :message
      t.string :cache_key_context, limit: 255
      t.text :results
    end
    add_index :progresses, [:context_id, :context_type], :name => "index_progresses_on_context_id_and_context_type"

    create_table "quiz_groups", :force => true do |t|
      t.integer  "quiz_id", :limit => 8, :null => false
      t.string   "name", limit: 255
      t.integer  "pick_count"
      t.float    "question_points"
      t.integer  "position"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "migration_id", limit: 255
      t.integer  "assessment_question_bank_id", :limit => 8
    end

    add_index "quiz_groups", ["quiz_id"], :name => "index_quiz_groups_on_quiz_id"

    create_table :quiz_question_regrades do |t|
      t.integer :quiz_regrade_id, limit: 8, null: false
      t.integer :quiz_question_id, limit: 8, null: false
      t.string :regrade_option, null: false, limit: 255

      t.timestamps null: true
    end
    add_index :quiz_question_regrades, :quiz_question_id, name: 'index_qqr_on_qq_id'

    add_index :quiz_question_regrades, [:quiz_regrade_id, :quiz_question_id], unique: true, name: 'index_qqr_on_qr_id_and_qq_id'

    create_table "quiz_questions", :force => true do |t|
      t.integer  "quiz_id", :limit => 8
      t.integer  "quiz_group_id", :limit => 8
      t.integer  "assessment_question_id", :limit => 8
      t.text     "question_data"
      t.integer  "assessment_question_version"
      t.integer  "position"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "migration_id", limit: 255
      t.string   "workflow_state", limit: 255
      t.integer  "duplicate_index"
    end

    add_index "quiz_questions", ["quiz_group_id"], :name => "quiz_questions_quiz_group_id"
    add_index :quiz_questions, [:quiz_id, :assessment_question_id], name: 'idx_qqs_on_quiz_and_aq_ids'
    add_index :quiz_questions, :assessment_question_id, where: "assessment_question_id IS NOT NULL"
    add_index :quiz_questions, [:assessment_question_id, :quiz_group_id, :duplicate_index],
              name: "index_generated_quiz_questions",
              where: "assessment_question_id IS NOT NULL AND quiz_group_id IS NOT NULL AND workflow_state='generated'",
              unique: true

    create_table :quiz_regrade_runs do |t|
      t.integer :quiz_regrade_id, limit: 8, null: false
      t.timestamp :started_at
      t.timestamp :finished_at
      t.timestamps null: true
    end

    create_table :quiz_regrades do |t|
      t.integer :user_id, limit: 8, null: false
      t.integer :quiz_id, limit: 8, null: false
      t.integer :quiz_version, null: false
      t.timestamps null: true
    end

    add_index :quiz_regrades, [:quiz_id, :quiz_version], unique: true

    create_table :quiz_statistics do |t|
      t.integer :quiz_id, :limit => 8
      t.boolean :includes_all_versions
      t.boolean :anonymous
      t.timestamps null: true
      t.string :report_type, limit: 255
    end
    add_index :quiz_statistics, [:quiz_id, :report_type]

    create_table :quiz_submission_events do |t|
      t.integer :attempt, null: false
      t.string :event_type, null: false, limit: 255
      t.integer :quiz_submission_id, limit: 8, null: false
      t.text :event_data
      t.datetime :created_at, null: false
      t.datetime :client_timestamp
    end
    add_index :quiz_submission_events, :created_at
    add_index :quiz_submission_events, [ :quiz_submission_id, :attempt, :created_at ],
      name: 'event_predecessor_locator_index'

    create_table "quiz_submission_snapshots", :force => true do |t|
      t.integer  "quiz_submission_id", :limit => 8
      t.integer  "attempt"
      t.text     "data"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "quiz_submission_snapshots", ["quiz_submission_id"], :name => "index_quiz_submission_snapshots_on_quiz_submission_id"

    create_table "quiz_submissions", :force => true do |t|
      t.integer  "quiz_id", :limit => 8, :null => false
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
      t.string   "workflow_state", :null => false, limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "fudge_points",                             :default => 0
      t.float    "quiz_points_possible"
      t.integer  "extra_attempts"
      t.string   "temporary_user_code", limit: 255
      t.integer  "extra_time"
      t.boolean  "manually_unlocked"
      t.boolean  "manually_scored"
      t.string   "validation_token", limit: 255
      t.float    "score_before_regrade"
      t.boolean  "was_preview"
      t.boolean  "has_seen_results"
      t.boolean  "question_references_fixed"
    end

    # If the column is created as a float with default 0, it becomes 0.0, which
    # would be fine, but it's easier to compare schema consistency this way.
    change_column :quiz_submissions, :fudge_points, :float

    add_index "quiz_submissions", ["quiz_id", "user_id"], :name => "index_quiz_submissions_on_quiz_id_and_user_id", :unique => true
    add_index "quiz_submissions", ["submission_id"], :name => "index_quiz_submissions_on_submission_id"
    add_index "quiz_submissions", ["temporary_user_code"], :name => "index_quiz_submissions_on_temporary_user_code"
    add_index "quiz_submissions", ["user_id"], :name => "index_quiz_submissions_on_user_id"

    create_table "quizzes", :force => true do |t|
      t.string   "title", limit: 255
      t.text     "description",                :limit => 16777215
      t.text     "quiz_data",                  :limit => 16777215
      t.float    "points_possible"
      t.integer  "context_id", :limit => 8, :null => false
      t.string   "context_type", :null => false, limit: 255
      t.integer  "assignment_id", :limit => 8
      t.string   "workflow_state", :null => false, limit: 255
      t.boolean  "shuffle_answers"
      t.boolean  "show_correct_answers"
      t.integer  "time_limit"
      t.integer  "allowed_attempts"
      t.string   "scoring_policy", limit: 255
      t.string   "quiz_type", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "lock_at"
      t.datetime "unlock_at"
      t.datetime "deleted_at"
      t.boolean  "could_be_locked"
      t.integer  "cloned_item_id", :limit => 8
      t.string   "access_code", limit: 255
      t.string   "migration_id", limit: 255
      t.integer  "unpublished_question_count",                     :default => 0
      t.datetime "due_at"
      t.integer  "question_count"
      t.integer  "last_assignment_id", :limit => 8
      t.datetime "published_at"
      t.datetime "last_edited_at"
      t.boolean  "anonymous_submissions"
      t.integer  "assignment_group_id", :limit => 8
      t.string   "hide_results", limit: 255
      t.string   "ip_filter", limit: 255
      t.boolean  "require_lockdown_browser"
      t.boolean  "require_lockdown_browser_for_results"
      t.boolean  "one_question_at_a_time"
      t.boolean  "cant_go_back"
      t.datetime "show_correct_answers_at"
      t.datetime "hide_correct_answers_at"
      t.boolean  "require_lockdown_browser_monitor"
      t.text     "lockdown_browser_monitor_data"
      t.boolean  "only_visible_to_overrides"
      t.boolean  "one_time_results"
      t.boolean  "show_correct_answers_last_attempt"
    end

    add_index "quizzes", ["assignment_id"], :name => "index_quizzes_on_assignment_id", :unique => true
    add_index "quizzes", ["context_id", "context_type"], :name => "index_quizzes_on_context_id_and_context_type"

    create_table "report_snapshots", :force => true do |t|
      t.string   "report_type", limit: 255
      t.text     "data",        :limit => 16777215
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "account_id", :limit => 8
    end
    add_index :report_snapshots, [:report_type, :account_id, :created_at], name: 'index_on_report_snapshots'

    create_table "role_overrides", :force => true do |t|
      t.string   "permission", limit: 255
      t.boolean  "enabled", default: true, null: false
      t.boolean  "locked", default: false, null: false
      t.integer  "context_id", :limit => 8
      t.string   "context_type", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "applies_to_self", :default => true, :null => false
      t.boolean  "applies_to_descendants", :default => true, :null => false
      t.integer  "role_id", :limit => 8, :null => false
    end

    add_index "role_overrides", ["context_id", "context_type"], :name => "index_role_overrides_on_context_id_and_context_type"

    create_table :roles do |t|
      t.string :name, :null => false, limit: 255
      t.string :base_role_type, :null => false, limit: 255
      t.integer :account_id, :null => true, :limit => 8
      t.string :workflow_state, :null => false, limit: 255
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :deleted_at
      t.integer :root_account_id, :limit => 8
    end
    add_index :roles, [:name], :name => "index_roles_on_name"
    add_index :roles, [:account_id], :name => "index_roles_on_account_id"
    add_index :roles, [:root_account_id], :name => "index_roles_on_root_account_id"
    add_index :roles, [:account_id, :name], :unique => true, :name => "index_roles_unique_account_name_where_active", :where => "workflow_state = 'active'"

    create_table "rubric_assessments", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "rubric_id", :limit => 8, :null => false
      t.integer  "rubric_association_id", :limit => 8
      t.float    "score"
      t.text     "data"
      # TODO: we have previously attempted to drop the comments field, but the
      # migration to do so was malformed.
      t.text     "comments"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "artifact_id", :limit => 8, :null => false
      t.string   "artifact_type", :null => false, limit: 255
      t.string   "assessment_type", :null => false, limit: 255
      t.integer  "assessor_id", :limit => 8
      t.integer  "artifact_attempt"
    end

    add_index "rubric_assessments", ["artifact_id", "artifact_type"], :name => "index_rubric_assessments_on_artifact_id_and_artifact_type"
    add_index "rubric_assessments", ["assessor_id"], :name => "index_rubric_assessments_on_assessor_id"
    add_index "rubric_assessments", ["rubric_association_id"], :name => "index_rubric_assessments_on_rubric_association_id"
    add_index "rubric_assessments", ["rubric_id"], :name => "index_rubric_assessments_on_rubric_id"
    add_index "rubric_assessments", ["user_id"], :name => "index_rubric_assessments_on_user_id"

    create_table "rubric_associations", :force => true do |t|
      t.integer  "rubric_id", :limit => 8, :null => false
      t.integer  "association_id", :limit => 8, :null => false
      t.string   "association_type", :null => false, limit: 255
      t.boolean  "use_for_grading"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "title", limit: 255
      t.text     "summary_data"
      t.string   "purpose", :null => false, limit: 255
      t.string   "url", limit: 255
      t.integer  "context_id", :limit => 8, :null => false
      t.string   "context_type", :null => false, limit: 255
      t.boolean  "hide_score_total"
      t.boolean  "bookmarked",       :default => true
      t.string   "context_code", limit: 255
    end

    add_index "rubric_associations", ["association_id", "association_type"], :name => "index_rubric_associations_on_aid_and_atype"
    add_index "rubric_associations", ["context_code"], :name => "index_rubric_associations_on_context_code"
    add_index "rubric_associations", ["context_id", "context_type"], :name => "index_rubric_associations_on_context_id_and_context_type"
    add_index "rubric_associations", ["rubric_id"], :name => "index_rubric_associations_on_rubric_id"

    create_table "rubrics", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "rubric_id", :limit => 8
      t.integer  "context_id", :limit => 8, :null => false
      t.string   "context_type", :null => false, limit: 255
      t.text     "data"
      t.float    "points_possible"
      t.string   "title", limit: 255
      t.text     "description"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "reusable",                     :default => false
      t.boolean  "public",                       :default => false
      t.boolean  "read_only",                    :default => false
      t.integer  "association_count",            :default => 0
      t.boolean  "free_form_criterion_comments"
      t.string   "context_code", limit: 255
      t.string   "migration_id", limit: 255
      t.boolean  "hide_score_total"
      t.string   "workflow_state",               :default => "active", :null => false, limit: 255
    end

    add_index "rubrics", ["context_id", "context_type"], :name => "index_rubrics_on_context_id_and_context_type"
    add_index "rubrics", ["user_id"], :name => "index_rubrics_on_user_id"

    create_table :scores do |t|
      t.integer :enrollment_id, limit: 8, null: false
      t.integer :grading_period_id, limit: 8
      t.string  :workflow_state, default: :active, null: false, limit: 255
      t.float   :current_score
      t.float   :final_score
      t.timestamps null: true
    end

    add_index :scores, [:enrollment_id, :grading_period_id], unique: true

    create_table "scribd_mime_types", :force => true do |t|
      t.string   "extension", limit: 255
      t.string   "name", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "sessions", :force => true do |t|
      t.string   "session_id", :null => false, limit: 255
      t.text     "data"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
    add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

    create_table :session_persistence_tokens do |t|
      t.string :token_salt, :null => false, limit: 255
      t.string :crypted_token, :null => false, limit: 255
      t.integer :pseudonym_id, :limit => 8, :null => false
      t.timestamps null: true
    end
    add_index :session_persistence_tokens, :pseudonym_id

    create_table :shared_brand_configs do |t|
      t.string :name, limit: 255
      t.references :account, null: true, limit: 8, index: true, foreign_key: true
      t.string :brand_config_md5, limit: 32, null: false, index: true
      t.timestamps null: false
    end

    create_table "sis_batches", :force => true do |t|
      t.integer  "account_id", :limit => 8, :null => false
      t.datetime "ended_at"
      t.string   "workflow_state", :null => false, limit: 255
      t.text     "data"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "attachment_id", :limit => 8
      t.integer  "progress"
      t.text     "processing_errors",   :limit => 16777215
      t.text     "processing_warnings", :limit => 16777215
      t.boolean  "batch_mode"
      t.integer  "batch_mode_term_id", :limit => 8
      t.text     "options"
      t.integer  "user_id", :limit => 8
      t.datetime "started_at"
      t.string   "diffing_data_set_identifier", limit: 255
      t.boolean  "diffing_remaster"
      t.integer  "generated_diff_id", :limit => 8
    end
    add_index :sis_batches, [:account_id, :created_at], :where => "workflow_state='created'", name: "index_sis_batches_pending_for_accounts"
    add_index :sis_batches, [:account_id, :created_at], :name => "index_sis_batches_account_id_created_at"
    add_index :sis_batches, :batch_mode_term_id, where: "batch_mode_term_id IS NOT NULL"
    add_index :sis_batches, [:account_id, :diffing_data_set_identifier, :created_at],
      name: 'index_sis_batches_diffing'
    
    create_table :sis_post_grades_statuses do |t|
      t.integer :course_id, :null => false, :limit => 8
      t.integer :course_section_id, :limit => 8
      t.integer :user_id, :limit => 8
      t.string :status, :null => false, limit: 255
      t.string :message, :null => false, limit: 255
      t.datetime :grades_posted_at, :null => false
      t.timestamps null: true
    end

    add_index :sis_post_grades_statuses, :course_id
    add_index :sis_post_grades_statuses, :course_section_id
    add_index :sis_post_grades_statuses, :user_id

    create_table "stream_item_instances", :force => true do |t|
      t.integer "user_id", :limit => 8, :null => false
      t.integer "stream_item_id", :limit => 8, :null => false
      t.boolean "hidden", :default => false, :null => false
      t.string  "workflow_state", limit: 255
      t.string   "context_type", limit: 255
      t.integer  "context_id", :limit => 8
    end

    add_index "stream_item_instances", ["stream_item_id"]
    add_index :stream_item_instances, %w(user_id hidden id stream_item_id), :name => "index_stream_item_instances_global"
    add_index :stream_item_instances, [:context_type, :context_id]
    add_index :stream_item_instances, [:stream_item_id, :user_id], :unique => true

    create_table "stream_items", :force => true do |t|
      t.text     "data", :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "context_type", limit: 255
      t.integer  "context_id", :limit => 8
      t.string   "asset_type", :null => false, limit: 255
      t.integer  "asset_id", :limit => 8
      t.string   "notification_category", limit: 255
    end

    add_index :stream_items, [:asset_type, :asset_id], :unique => true
    add_index :stream_items, :updated_at

    create_table "submission_comment_participants", :force => true do |t|
      t.integer  "submission_comment_id", :limit => 8
      t.integer  "user_id", :limit => 8
      t.string   "participation_type", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "submission_comment_participants", ["submission_comment_id"], :name => "index_submission_comment_participants_on_submission_comment_id"
    add_index "submission_comment_participants", ["user_id"], :name => "index_submission_comment_participants_on_user_id"
    add_index :submission_comment_participants, [:user_id, :participation_type], name: 'index_scp_on_user_id_and_participation_type'

    create_table "submission_comments", :force => true do |t|
      t.text     "comment"
      t.integer  "submission_id", :limit => 8
      t.integer  "author_id", :limit => 8
      t.string   "author_name", limit: 255
      t.string   "group_comment_id", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "attachment_ids"
      t.integer  "assessment_request_id", :limit => 8
      t.string   "media_comment_id", limit: 255
      t.string   "media_comment_type", limit: 255
      t.integer  "context_id", :limit => 8
      t.string   "context_type", limit: 255
      t.text     "cached_attachments"
      t.boolean  "anonymous"
      t.boolean  "teacher_only_comment",  :default => false
      t.boolean  "hidden", :default => false
      t.integer  "provisional_grade_id", limit: 8
      t.boolean  "draft", default: false
    end

    add_index "submission_comments", ["author_id"], :name => "index_submission_comments_on_author_id"
    add_index "submission_comments", ["context_id", "context_type"], :name => "index_submission_comments_on_context_id_and_context_type"
    add_index "submission_comments", ["submission_id"], :name => "index_submission_comments_on_submission_id"
    add_index :submission_comments, :draft
    add_index :submission_comments, :provisional_grade_id, where: "provisional_grade_id IS NOT NULL"

    create_table :submission_versions do |t|
      t.integer  "context_id", :limit => 8
      t.string   "context_type", limit: 255
      t.integer  "version_id", :limit => 8
      t.integer  "user_id", :limit => 8
      t.integer  "assignment_id", :limit => 8
    end

    add_index :submission_versions, [:context_id, :version_id, :user_id, :assignment_id],
      :name => 'index_submission_versions',
      :where => "context_type='Course'",
      :unique => true

    create_table "submissions", :force => true do |t|
      t.text     "body",                             :limit => 16777215
      t.string   "url", limit: 255
      t.integer  "attachment_id", :limit => 8
      t.string   "grade", limit: 255
      t.float    "score"
      t.datetime "submitted_at"
      t.integer  "assignment_id", :limit => 8, :null => false
      t.integer  "user_id", :limit => 8, :null => false
      t.string   "submission_type", limit: 255
      t.string   "workflow_state", :null => false, limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "group_id", :limit => 8
      t.text     "attachment_ids"
      t.boolean  "processed"
      t.integer  "process_attempts",                                     :default => 0
      t.boolean  "grade_matches_current_submission"
      t.float    "published_score"
      t.string   "published_grade", limit: 255
      t.datetime "graded_at"
      t.float    "student_entered_score"
      t.integer  "grader_id", :limit => 8
      t.string   "media_comment_id", limit: 255
      t.string   "media_comment_type", limit: 255
      t.integer  "quiz_submission_id", :limit => 8
      t.integer  "submission_comments_count"
      t.boolean  "has_rubric_assessment"
      t.integer  "attempt"
      t.string   "context_code", limit: 255
      t.integer  "media_object_id", :limit => 8
      t.text     "turnitin_data"
      t.boolean  "has_admin_comment", :default => false, :null => false
      t.datetime "cached_due_date"
      t.boolean  "excused"
      t.boolean  "graded_anonymously"
    end

    add_index "submissions", ["assignment_id", "submission_type"], :name => "index_submissions_on_assignment_id_and_submission_type"
    add_index "submissions", ["user_id", "assignment_id"], :name => "index_submissions_on_user_id_and_assignment_id", :unique => true
    add_index :submissions, :submitted_at
    add_index :submissions, :group_id, where: "group_id IS NOT NULL"
    add_index :submissions, :quiz_submission_id, where: "quiz_submission_id IS NOT NULL"
    add_index :submissions, [:assignment_id, :user_id]
    add_index :submissions, :assignment_id, where: <<-SQL
      submission_type IS NOT NULL
      AND (workflow_state = 'pending_review'
        OR (workflow_state = 'submitted'
          AND (score IS NULL OR NOT grade_matches_current_submission)
        )
      )
    SQL

    create_table :switchman_shards do |t|
      t.string :name, limit: 255
      t.string :database_server_id, limit: 255
      t.boolean :default, :default => false, :null => false
      t.text :settings
      t.integer :delayed_jobs_shard_id, :limit => 8
    end

    create_table "thumbnails", :force => true do |t|
      t.integer  "parent_id", :limit => 8
      t.string   "content_type", :null => false, limit: 255
      t.string   "filename", :null => false, limit: 255
      t.string   "thumbnail", limit: 255
      t.integer  "size", :null => false
      t.integer  "width"
      t.integer  "height"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "uuid", limit: 255
      t.string   "namespace", :null => true, limit: 255
    end

    add_index "thumbnails", ["parent_id"], :name => "index_thumbnails_on_parent_id"
    add_index :thumbnails, [:parent_id, :thumbnail], :unique => true, :name => "index_thumbnails_size"

    create_table :usage_rights do |t|
      t.integer :context_id, :limit => 8, null: false
      t.string :context_type, null: false, limit: 255
      t.string :use_justification, null: false, limit: 255
      t.string :license, null: false, limit: 255
      t.text :legal_copyright
    end
    add_index :usage_rights, [:context_id, :context_type], name: 'usage_rights_context_idx'

    create_table "user_account_associations", :force => true do |t|
      t.integer  "user_id", :limit => 8, :null => false
      t.integer  "account_id", :limit => 8, :null => false
      t.integer  "depth"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "user_account_associations", ["account_id"], :name => "index_user_account_associations_on_account_id"
    add_index :user_account_associations, [:user_id, :account_id], :unique => true

    create_table :user_merge_data do |t|
      t.integer :user_id, limit: 8, null: false
      t.integer :from_user_id, limit: 8, null: false
      t.timestamps null: false
      t.string :workflow_state, null: false, default: 'active', limit: 255
    end

    add_index :user_merge_data, :user_id
    add_index :user_merge_data, :from_user_id

    create_table :user_merge_data_records do |t|
      t.integer :user_merge_data_id, limit: 8, null: false
      t.integer :context_id, limit: 8, null: false
      t.integer :previous_user_id, limit: 8, null: false
      t.string :context_type, null: false, limit: 255
      t.string :previous_workflow_state, limit: 255
    end

    add_index :user_merge_data_records, :user_merge_data_id
    add_index :user_merge_data_records, [:context_id, :context_type, :user_merge_data_id, :previous_user_id],
              unique: true, name: "index_user_merge_data_records_on_context_id_and_context_type"

    create_table "user_notes", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.text     "note"
      t.string   "title", limit: 255
      t.integer  "created_by_id", :limit => 8
      t.string   "workflow_state", :default => "active", :null => false, limit: 255
      t.datetime "deleted_at"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "user_notes", ["user_id", "workflow_state"], :name => "index_user_notes_on_user_id_and_workflow_state"

    create_table :user_observers do |t|
      t.integer :user_id, :limit => 8, :null => false
      t.integer :observer_id, :limit => 8, :null => false
      t.string  :workflow_state, default: 'active', null: false, limit: 255
      t.timestamps null: true
      t.integer :sis_batch_id, limit: 8
    end
    add_index :user_observers, [:user_id, :observer_id], :unique => true
    add_index :user_observers, :observer_id
    add_index :user_observers, :workflow_state
    add_index :user_observers, :sis_batch_id, where: "sis_batch_id IS NOT NULL"

    create_table "user_services", :force => true do |t|
      t.integer  "user_id", :limit => 8, :null => false
      t.text     "token"
      t.string   "secret", limit: 255
      t.string   "protocol", limit: 255
      t.string   "service", :null => false, limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "service_user_url", limit: 255
      t.string   "service_user_id", :null => false, limit: 255
      t.string   "service_user_name", limit: 255
      t.string   "service_domain", limit: 255
      t.string   "crypted_password", limit: 255
      t.string   "password_salt", limit: 255
      t.string   "type", limit: 255
      t.string   "workflow_state", :null => false, limit: 255
      t.string   "last_result_id", limit: 255
      t.datetime "refresh_at"
      t.boolean  "visible"
    end

    add_index "user_services", ["id", "type"], :name => "index_user_services_on_id_and_type"
    add_index "user_services", ["user_id"], :name => "index_user_services_on_user_id"

    create_table "users", :force => true do |t|
      t.string   "name", limit: 255
      t.string   "sortable_name", limit: 255
      t.string   "workflow_state", :null => false, limit: 255
      t.string   "time_zone", limit: 255
      t.string   "uuid", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "avatar_image_url", limit: 255
      t.string   "avatar_image_source", limit: 255
      t.datetime "avatar_image_updated_at"
      t.string   "phone", limit: 255
      t.string   "school_name", limit: 255
      t.string   "school_position", limit: 255
      t.string   "short_name", limit: 255
      t.datetime "deleted_at"
      t.boolean  "show_user_services",          :default => true
      t.string   "gender", limit: 255
      t.integer  "page_views_count",            :default => 0
      t.integer  "reminder_time_for_due_dates", :default => 172800
      t.integer  "reminder_time_for_grading",   :default => 0
      t.integer  "storage_quota", :limit => 8
      t.string   "visible_inbox_types", limit: 255
      t.datetime "last_user_note"
      t.boolean  "subscribe_to_emails"
      t.text     "features_used"
      t.text     "preferences"
      t.string   "avatar_state", limit: 255
      t.string   "locale", limit: 255
      t.string   "browser_locale", limit: 255
      t.integer  "unread_conversations_count", :default => 0
      t.text     "stuck_sis_fields"
      t.boolean  "public"
      t.datetime "birthdate"
      t.string   "otp_secret_key_enc", limit: 255
      t.string   "otp_secret_key_salt", limit: 255
      t.integer  "otp_communication_channel_id", :limit => 8
      t.string   "initial_enrollment_type", limit: 255
      t.integer  "crocodoc_id"
      t.timestamp "last_logged_out"
      t.string   "lti_context_id", limit: 255
      t.integer  "turnitin_id", limit: 8
    end

    add_index "users", ["avatar_state", "avatar_image_updated_at"], :name => "index_users_on_avatar_state_and_avatar_image_updated_at"
    add_index "users", ["uuid"], :name => "index_users_on_uuid"
    if (collkey = connection.extension_installed?(:pg_collkey))
      execute("CREATE INDEX index_users_on_sortable_name ON #{User.quoted_table_name} (#{collkey}.collkey(sortable_name, 'root', false, 0, true))")
    else
      execute("CREATE INDEX index_users_on_sortable_name ON #{User.quoted_table_name} (CAST(LOWER(replace(sortable_name, '\\', '\\\\')) AS bytea))")
    end
    if (trgm = connection.extension_installed?(:pg_trgm))
      add_index :users, "lower(name) #{trgm}.gist_trgm_ops", name: "index_trgm_users_name", using: :gist
      add_index :users, "LOWER(short_name) #{trgm}.gist_trgm_ops", name: "index_trgm_users_short_name", using: :gist
      add_index :users, "LOWER(short_name) #{trgm}.gist_trgm_ops",
                name: "index_trgm_users_short_name_active_only",
                using: :gist,
                where: "workflow_state IN ('registered', 'pre_registered')"
      add_index :users, "LOWER(name) #{trgm}.gist_trgm_ops",
                name: "index_trgm_users_name_active_only",
                using: :gist,
                where: "workflow_state IN ('registered', 'pre_registered')"
    end
    add_index :users, :lti_context_id, :unique => true
    add_index :users, :turnitin_id, unique: true, where: "turnitin_id IS NOT NULL"

    create_table :user_profiles do |t|
      t.text   :bio
      t.string :title, limit: 255
      t.references :user, :limit => 8

    end

    create_table :user_profile_links do |t|
      t.string :url, :limit => 4.kilobytes
      t.string :title, limit: 255
      t.references :user_profile, :limit => 8
      t.timestamps null: true
    end

    create_table :custom_data do |t|
      t.text :data
      t.string :namespace, limit: 255
      t.references :user, :limit => 8
      t.timestamps null: true
    end
    add_index :custom_data, [:user_id, :namespace],
      name: 'index_custom_data_on_user_id_and_namespace',
      unique: true

    create_table "versions", :force => true do |t|
      t.integer  "versionable_id", :limit => 8
      t.string   "versionable_type", limit: 255
      t.integer  "number"
      t.text     "yaml",             :limit => 16777215
      t.datetime "created_at"
    end

    add_index :versions, [:versionable_id, :versionable_type, :number], :unique => true, :name => "index_versions_on_versionable_object_and_number"

    create_table "web_conference_participants", :force => true do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "web_conference_id", :limit => 8
      t.string   "participation_type", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "web_conference_participants", ["user_id"], :name => "index_web_conference_participants_on_user_id"
    add_index "web_conference_participants", ["web_conference_id"], :name => "index_web_conference_participants_on_web_conference_id"

    create_table "web_conferences", :force => true do |t|
      t.string   "title", :null => false, limit: 255
      t.string   "conference_type", :null => false, limit: 255
      t.string   "conference_key", limit: 255
      t.integer  "context_id", :limit => 8, :null => false
      t.string   "context_type", :null => false, limit: 255
      t.string   "user_ids", limit: 255
      t.string   "added_user_ids", limit: 255
      t.integer  "user_id", :limit => 8, :null => false
      t.datetime "started_at"
      t.text     "description"
      t.float    "duration"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "uuid", limit: 255
      t.string   "invited_user_ids", limit: 255
      t.datetime "ended_at"
      t.datetime "start_at"
      t.datetime "end_at"
      t.string   "context_code", limit: 255
      t.string   "type", limit: 255
      t.text     "settings"
      t.boolean  "recording_ready"
    end

    add_index "web_conferences", ["context_id", "context_type"], :name => "index_web_conferences_on_context_id_and_context_type"
    add_index "web_conferences", ["user_id"], :name => "index_web_conferences_on_user_id"

    create_table "wiki_pages", :force => true do |t|
      t.integer  "wiki_id", :limit => 8, :null => false
      t.string   "title", limit: 255
      t.text     "body",                     :limit => 16777215
      t.string   "workflow_state", :null => false, limit: 255
      t.integer  "user_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "url"
      t.boolean  "protected_editing",                            :default => false
      t.string   "editing_roles", limit: 255
      t.integer  "view_count",                                   :default => 0
      t.datetime "revised_at"
      t.boolean  "could_be_locked"
      t.integer  "cloned_item_id", :limit => 8
      t.string   "migration_id", limit: 255
      t.integer  "assignment_id", :limit => 8
      t.integer  "old_assignment_id", :limit => 8
    end

    add_index "wiki_pages", ["user_id"], :name => "index_wiki_pages_on_user_id"
    add_index "wiki_pages", ["wiki_id"], :name => "index_wiki_pages_on_wiki_id"
    add_index :wiki_pages, [:assignment_id]
    add_index :wiki_pages, [:old_assignment_id]

    create_table "wikis", :force => true do |t|
      t.string   "title", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "front_page_url"
      t.boolean  "has_no_front_page"
    end

    if Rails.env.test?
      create_table :stories do |table|
        table.string :text
      end
    end

    change_column :schema_migrations, :version, :string, limit: 255

    self.connection.execute %Q(CREATE VIEW #{connection.quote_table_name('assignment_student_visibilities')} AS
      SELECT DISTINCT a.id as assignment_id,
      e.user_id as user_id,
      c.id as course_id

      FROM #{Assignment.quoted_table_name} a

      JOIN #{Course.quoted_table_name} c
        ON a.context_id = c.id
        AND a.context_type = 'Course'

      JOIN #{Enrollment.quoted_table_name} e
        ON e.course_id = c.id
        AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
        AND e.workflow_state != 'deleted'

      JOIN #{CourseSection.quoted_table_name} cs
        ON cs.course_id = c.id
        AND e.course_section_id = cs.id

      LEFT JOIN #{GroupMembership.quoted_table_name} gm
        ON gm.user_id = e.user_id
        AND gm.workflow_state = 'accepted'

      LEFT JOIN #{Group.quoted_table_name} g
        ON g.context_type = 'Course'
        AND g.context_id = c.id
        AND g.workflow_state = 'available'
        AND gm.group_id = g.id

      LEFT JOIN #{AssignmentOverrideStudent.quoted_table_name} aos
        ON aos.assignment_id = a.id
        AND aos.user_id = e.user_id

      LEFT JOIN #{AssignmentOverride.quoted_table_name} ao
        ON ao.assignment_id = a.id
        AND ao.workflow_state = 'active'
        AND (
          (ao.set_type = 'CourseSection' AND ao.set_id = cs.id)
          OR (ao.set_type = 'ADHOC' AND ao.set_id IS NULL AND ao.id = aos.assignment_override_id)
          OR (ao.set_type = 'Group' AND ao.set_id = g.id)
        )

      LEFT JOIN #{Submission.quoted_table_name} s
        ON s.user_id = e.user_id
        AND s.assignment_id = a.id
        AND s.score IS NOT NULL

      WHERE a.workflow_state NOT IN ('deleted','unpublished')
        AND(
          ( a.only_visible_to_overrides = 'true' AND (ao.id IS NOT NULL OR s.id IS NOT NULL))
          OR (COALESCE(a.only_visible_to_overrides, 'false') = 'false')
        )
      )

    self.connection.execute %Q(CREATE VIEW #{connection.quote_table_name('quiz_student_visibilities')} AS
      SELECT DISTINCT q.id as quiz_id,
      e.user_id as user_id,
      c.id as course_id

      FROM #{Quizzes::Quiz.quoted_table_name} q

      JOIN #{Course.quoted_table_name} c
        ON q.context_id = c.id
        AND q.context_type = 'Course'

      JOIN #{Enrollment.quoted_table_name} e
        ON e.course_id = c.id
        AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
        AND e.workflow_state != 'deleted'

      JOIN #{CourseSection.quoted_table_name} cs
        ON cs.course_id = c.id
        AND e.course_section_id = cs.id

      LEFT JOIN #{AssignmentOverrideStudent.quoted_table_name} aos
        ON aos.quiz_id = q.id
        AND aos.user_id = e.user_id

      LEFT JOIN #{AssignmentOverride.quoted_table_name} ao
        ON ao.quiz_id = q.id
        AND ao.workflow_state = 'active'
        AND (
          (ao.set_type = 'CourseSection' AND ao.set_id = cs.id)
          OR (ao.set_type = 'ADHOC' AND ao.set_id IS NULL AND ao.id = aos.assignment_override_id)
        )

      LEFT JOIN #{Assignment.quoted_table_name} a
        ON a.context_id = q.context_id
        AND a.submission_types LIKE 'online_quiz'
        AND a.id = q.assignment_id

      LEFT JOIN #{Submission.quoted_table_name} s
        ON s.user_id = e.user_id
        AND s.assignment_id = a.id
        AND s.score IS NOT NULL

      WHERE q.workflow_state NOT IN ('deleted','unpublished')
        AND(
          ( q.only_visible_to_overrides = 'true' AND (ao.id IS NOT NULL OR s.id IS NOT NULL))
          OR (COALESCE(q.only_visible_to_overrides, 'false') = 'false')
        )
      )

    add_foreign_key :abstract_courses, :accounts
    add_foreign_key :abstract_courses, :accounts, :column => :root_account_id
    add_foreign_key :abstract_courses, :enrollment_terms
    add_foreign_key :abstract_courses, :sis_batches
    add_foreign_key :access_tokens, :users
    add_foreign_key :account_authorization_configs, :accounts
    add_foreign_key :account_notification_roles, :account_notifications
    add_foreign_key :account_notification_roles, :roles
    add_foreign_key :account_notifications, :accounts
    add_foreign_key :account_notifications, :users
    add_foreign_key :account_reports, :accounts
    add_foreign_key :account_reports, :attachments
    add_foreign_key :account_reports, :users
    add_foreign_key :account_users, :accounts
    add_foreign_key :account_users, :roles
    add_foreign_key :account_users, :users
    add_foreign_key :accounts, :accounts, :column => :parent_account_id
    add_foreign_key :accounts, :accounts, :column => :root_account_id
    add_foreign_key :accounts, :brand_configs, column: 'brand_config_md5', primary_key: 'md5'
    add_foreign_key :accounts, :sis_batches
    add_foreign_key :alert_criteria, :alerts
    add_foreign_key :assessment_requests, :rubric_associations
    add_foreign_key :assessment_requests, :submissions, column: :asset_id
    add_foreign_key :assessment_requests, :users
    add_foreign_key :assessment_requests, :users, column: :assessor_id
    add_foreign_key :assignment_configuration_tool_lookups, :assignments
    add_foreign_key :assignment_groups, :cloned_items
    add_foreign_key :assignment_override_students, :assignment_overrides
    add_foreign_key :assignment_override_students, :assignments
    add_foreign_key :assignment_override_students, :quizzes
    add_foreign_key :assignment_override_students, :users
    add_foreign_key :assignment_overrides, :assignments
    add_foreign_key :assignment_overrides, :quizzes
    add_foreign_key :assignments, :cloned_items
    add_foreign_key :assignments, :group_categories
    add_foreign_key :attachments, :attachments, column: :replacement_attachment_id
    add_foreign_key :attachments, :attachments, column: :root_attachment_id
    add_foreign_key :attachments, :usage_rights, column: :usage_rights_id
    add_foreign_key :bookmarks_bookmarks, :users
    add_foreign_key :calendar_events, :calendar_events, :column => :parent_calendar_event_id
    add_foreign_key :calendar_events, :cloned_items
    add_foreign_key :calendar_events, :users
    add_foreign_key :canvadocs, :attachments
    add_foreign_key :collaborations, :users
    add_foreign_key :collaborators, :collaborations
    add_foreign_key :collaborators, :groups
    add_foreign_key :collaborators, :users
    add_foreign_key :communication_channels, :users
    add_foreign_key :content_exports, :attachments
    add_foreign_key :content_exports, :content_migrations
    add_foreign_key :content_exports, :users
    add_foreign_key :content_migrations, :attachments
    add_foreign_key :content_migrations, :attachments, column: :exported_attachment_id
    add_foreign_key :content_migrations, :attachments, column: :overview_attachment_id
    add_foreign_key :content_migrations, :courses, :column => :source_course_id
    add_foreign_key :content_migrations, :users
    add_foreign_key :content_participations, :users
    add_foreign_key :content_tags, :cloned_items
    add_foreign_key :content_tags, :context_modules
    add_foreign_key :content_tags, :learning_outcomes
    add_foreign_key :context_external_tool_assignment_lookups, :assignments
    add_foreign_key :context_external_tool_assignment_lookups, :context_external_tools
    add_foreign_key :context_external_tool_placements, :context_external_tools
    add_foreign_key :context_external_tools, :cloned_items
    add_foreign_key :context_module_progressions, :context_modules
    add_foreign_key :context_module_progressions, :users
    add_foreign_key :context_modules, :cloned_items
    add_foreign_key :conversation_batches, :conversation_messages, column: :root_conversation_message_id
    add_foreign_key :conversation_batches, :users
    add_foreign_key :conversation_message_participants, :conversation_messages
    add_foreign_key :conversation_messages, :conversations
    add_foreign_key :course_account_associations, :accounts
    add_foreign_key :course_account_associations, :course_sections
    add_foreign_key :course_account_associations, :courses
    add_foreign_key :course_sections, :accounts, :column => :root_account_id
    add_foreign_key :course_sections, :courses
    add_foreign_key :course_sections, :courses, :column => :nonxlist_course_id
    add_foreign_key :course_sections, :enrollment_terms
    add_foreign_key :course_sections, :sis_batches
    add_foreign_key :courses, :abstract_courses
    add_foreign_key :courses, :accounts
    add_foreign_key :courses, :accounts, :column => :root_account_id
    add_foreign_key :courses, :courses, :column => :template_course_id
    add_foreign_key :courses, :enrollment_terms
    add_foreign_key :courses, :sis_batches
    add_foreign_key :courses, :wikis
    add_foreign_key :custom_gradebook_column_data, :custom_gradebook_columns
    add_foreign_key :custom_gradebook_column_data, :users
    add_foreign_key :custom_gradebook_columns, :courses, :dependent => true
    add_foreign_key :delayed_messages, :communication_channels
    add_foreign_key :delayed_messages, :notification_policies
    add_foreign_key :discussion_entries, :discussion_entries, column: :parent_id
    add_foreign_key :discussion_entries, :discussion_entries, column: :root_entry_id
    add_foreign_key :discussion_entries, :discussion_topics
    add_foreign_key :discussion_entries, :users
    add_foreign_key :discussion_entries, :users, column: :editor_id
    add_foreign_key :discussion_entry_participants, :discussion_entries
    add_foreign_key :discussion_entry_participants, :users
    add_foreign_key :discussion_topic_materialized_views, :discussion_topics
    add_foreign_key :discussion_topic_participants, :discussion_topics
    add_foreign_key :discussion_topic_participants, :users
    add_foreign_key :discussion_topics, :assignments
    add_foreign_key :discussion_topics, :assignments, :column => :old_assignment_id
    add_foreign_key :discussion_topics, :attachments
    add_foreign_key :discussion_topics, :cloned_items
    add_foreign_key :discussion_topics, :discussion_topics, :column => :root_topic_id
    add_foreign_key :discussion_topics, :external_feeds
    add_foreign_key :discussion_topics, :group_categories
    add_foreign_key :discussion_topics, :users
    add_foreign_key :discussion_topics, :users, column: :editor_id
    add_foreign_key :enrollment_dates_overrides, :enrollment_terms
    add_foreign_key :enrollment_states, :enrollments
    add_foreign_key :enrollment_terms, :accounts, :column => :root_account_id
    add_foreign_key :enrollment_terms, :grading_period_groups
    add_foreign_key :enrollment_terms, :sis_batches
    add_foreign_key :enrollments, :accounts, :column => :root_account_id
    add_foreign_key :enrollments, :course_sections
    add_foreign_key :enrollments, :courses
    add_foreign_key :enrollments, :roles
    add_foreign_key :enrollments, :sis_batches
    add_foreign_key :enrollments, :users
    add_foreign_key :enrollments, :users, column: :associated_user_id
    add_foreign_key :eportfolio_categories, :eportfolios
    add_foreign_key :eportfolio_entries, :eportfolio_categories
    add_foreign_key :eportfolio_entries, :eportfolios
    add_foreign_key :eportfolios, :users
    add_foreign_key :epub_exports, :content_exports
    add_foreign_key :epub_exports, :courses
    add_foreign_key :epub_exports, :users
    add_foreign_key :external_feed_entries, :external_feeds
    add_foreign_key :external_feed_entries, :users
    add_foreign_key :external_feeds, :users
    add_foreign_key :favorites, :users
    add_foreign_key :folders, :cloned_items
    add_foreign_key :folders, :folders, :column => :parent_folder_id
    add_foreign_key :gradebook_csvs, :courses
    add_foreign_key :gradebook_csvs, :progresses
    add_foreign_key :gradebook_csvs, :users
    add_foreign_key :gradebook_uploads, :courses
    add_foreign_key :gradebook_uploads, :users
    add_foreign_key :gradebook_uploads, :progresses
    add_foreign_key :grading_period_groups, :accounts
    add_foreign_key :grading_period_groups, :courses
    add_foreign_key :grading_periods, :grading_period_groups
    add_foreign_key :grading_standards, :users
    add_foreign_key :group_memberships, :groups
    add_foreign_key :group_memberships, :sis_batches
    add_foreign_key :group_memberships, :users
    add_foreign_key :groups, :accounts
    add_foreign_key :groups, :accounts, :column => :root_account_id
    add_foreign_key :groups, :group_categories
    add_foreign_key :groups, :sis_batches
    add_foreign_key :groups, :users, column: :leader_id
    add_foreign_key :groups, :wikis
    add_foreign_key :ignores, :users
    add_foreign_key :learning_outcome_groups, :learning_outcome_groups
    add_foreign_key :learning_outcome_groups, :learning_outcome_groups, :column => :root_learning_outcome_group_id
    add_foreign_key :learning_outcome_results, :content_tags
    add_foreign_key :learning_outcome_results, :learning_outcomes
    add_foreign_key :learning_outcome_results, :users
    add_foreign_key :live_assessments_results, :live_assessments_assessments, column: :assessment_id
    add_foreign_key :live_assessments_results, :users, column: :assessor_id
    add_foreign_key :live_assessments_submissions, :live_assessments_assessments, column: :assessment_id
    add_foreign_key :live_assessments_submissions, :users
    add_foreign_key :lti_message_handlers, :lti_resource_handlers, column: :resource_handler_id
    add_foreign_key :lti_product_families, :accounts, column: :root_account_id
    add_foreign_key :lti_resource_handlers, :lti_tool_proxies, column: :tool_proxy_id
    add_foreign_key :lti_resource_placements, :lti_message_handlers, column: :message_handler_id
    add_foreign_key :lti_tool_proxies, :lti_product_families, column: :product_family_id
    add_foreign_key :lti_tool_proxy_bindings, :lti_tool_proxies, column: :tool_proxy_id
    add_foreign_key :master_courses_child_content_tags, :master_courses_child_subscriptions, column: "child_subscription_id"
    add_foreign_key :master_courses_child_subscriptions, :master_courses_master_templates, column: "master_template_id"
    # we may have to drop this foreign key at some point for cross-shard subscriptions
    add_foreign_key :master_courses_child_subscriptions, :courses, column: "child_course_id"
    add_foreign_key :master_courses_master_content_tags, :master_courses_master_migrations, column: "current_migration_id"
    add_foreign_key :master_courses_master_content_tags, :master_courses_master_templates, column: "master_template_id"
    add_foreign_key :master_courses_master_migrations, :master_courses_master_templates, column: "master_template_id"
    add_foreign_key :master_courses_master_templates, :courses
    add_foreign_key :master_courses_master_templates, :master_courses_master_migrations, column: "active_migration_id"
    add_foreign_key :media_objects, :accounts, :column => :root_account_id
    add_foreign_key :media_objects, :users
    add_foreign_key :migration_issues, :content_migrations
    add_foreign_key :moderated_grading_provisional_grades, :moderated_grading_provisional_grades,
                    :column => :source_provisional_grade_id, :name => 'provisional_grades_source_provisional_grade_fk'
    add_foreign_key :moderated_grading_provisional_grades, :submissions
    add_foreign_key :moderated_grading_provisional_grades, :users, column: :scorer_id
    add_foreign_key :moderated_grading_selections, :assignments
    add_foreign_key :moderated_grading_selections, :users, column: :student_id
    add_foreign_key :moderated_grading_selections, :moderated_grading_provisional_grades, column: :selected_provisional_grade_id
    add_foreign_key :notification_endpoints, :access_tokens
    add_foreign_key :notification_policies, :communication_channels
    add_foreign_key :oauth_requests, :users
    add_foreign_key :one_time_passwords, :users
    add_foreign_key :originality_reports, :attachments
    add_foreign_key :originality_reports, :attachments, column: :originality_report_attachment_id
    add_foreign_key :originality_reports, :submissions
    add_foreign_key :page_comments, :users
    add_foreign_key :page_views, :users
    add_foreign_key :page_views, :users, column: :real_user_id
    add_foreign_key :polling_poll_choices, :polling_polls, column: :poll_id
    add_foreign_key :polling_poll_sessions, :course_sections
    add_foreign_key :polling_poll_sessions, :courses
    add_foreign_key :polling_poll_submissions, :polling_poll_choices, column: :poll_choice_id
    add_foreign_key :polling_poll_submissions, :polling_poll_sessions, column: :poll_session_id
    add_foreign_key :polling_poll_submissions, :polling_polls, column: :poll_id
    add_foreign_key :polling_poll_submissions, :users
    add_foreign_key :polling_polls, :users
    add_foreign_key :profiles, :accounts, :column => 'root_account_id'
    add_foreign_key :pseudonyms, :account_authorization_configs, column: :authentication_provider_id
    add_foreign_key :pseudonyms, :accounts
    add_foreign_key :pseudonyms, :sis_batches
    add_foreign_key :pseudonyms, :users
    add_foreign_key :quiz_question_regrades, :quiz_questions
    add_foreign_key :quiz_question_regrades, :quiz_regrades
    add_foreign_key :quiz_regrade_runs, :quiz_regrades
    add_foreign_key :quiz_regrades, :quizzes
    add_foreign_key :quiz_regrades, :users
    add_foreign_key :quiz_statistics, :quizzes
    add_foreign_key :quiz_submission_events, :quiz_submissions
    add_foreign_key :quiz_submissions, :quizzes
    add_foreign_key :quiz_submissions, :users
    add_foreign_key :quizzes, :assignments
    add_foreign_key :quizzes, :cloned_items
    add_foreign_key :report_snapshots, :accounts
    add_foreign_key :role_overrides, :accounts, :column => :context_id
    add_foreign_key :role_overrides, :roles
    add_foreign_key :roles, :accounts
    add_foreign_key :roles, :accounts, column: :root_account_id
    add_foreign_key :rubric_assessments, :rubric_associations
    add_foreign_key :rubric_assessments, :rubrics
    add_foreign_key :rubric_assessments, :users
    add_foreign_key :rubric_assessments, :users, column: :assessor_id
    add_foreign_key :rubric_associations, :rubrics
    add_foreign_key :rubrics, :rubrics
    add_foreign_key :rubrics, :users
    add_foreign_key :scores, :enrollments
    add_foreign_key :scores, :grading_periods
    add_foreign_key :session_persistence_tokens, :pseudonyms
    add_foreign_key :shared_brand_configs, :brand_configs, column: 'brand_config_md5', primary_key: 'md5'
    add_foreign_key :sis_batches, :enrollment_terms, :column => :batch_mode_term_id
    add_foreign_key :sis_batches, :users
    add_foreign_key :sis_post_grades_statuses, :courses
    add_foreign_key :sis_post_grades_statuses, :course_sections
    add_foreign_key :sis_post_grades_statuses, :users
    add_foreign_key :stream_item_instances, :users
    add_foreign_key :submission_comment_participants, :users
    add_foreign_key :submission_comments, :moderated_grading_provisional_grades, column: :provisional_grade_id
    add_foreign_key :submission_comments, :submissions
    add_foreign_key :submission_comments, :users, column: :author_id
    add_foreign_key :submissions, :assignments
    add_foreign_key :submissions, :groups
    add_foreign_key :submissions, :media_objects
    add_foreign_key :submissions, :quiz_submissions
    add_foreign_key :submissions, :users
    add_foreign_key :switchman_shards, :switchman_shards, column: :delayed_jobs_shard_id
    add_foreign_key :user_account_associations, :accounts
    add_foreign_key :user_account_associations, :users
    add_foreign_key :user_merge_data, :users
    add_foreign_key :user_merge_data_records, :user_merge_data, column: :user_merge_data_id
    add_foreign_key :user_notes, :users
    add_foreign_key :user_notes, :users, column: :created_by_id
    add_foreign_key :user_observers, :users
    add_foreign_key :user_observers, :users, column: :observer_id
    add_foreign_key :user_profile_links, :user_profiles
    add_foreign_key :user_profiles, :users
    add_foreign_key :user_services, :users
    add_foreign_key :web_conference_participants, :users
    add_foreign_key :web_conference_participants, :web_conferences
    add_foreign_key :web_conferences, :users
    add_foreign_key :wiki_pages, :assignments
    add_foreign_key :wiki_pages, :assignments, column: :old_assignment_id
    add_foreign_key :wiki_pages, :cloned_items
    add_foreign_key :wiki_pages, :users
    add_foreign_key :wiki_pages, :wikis
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
