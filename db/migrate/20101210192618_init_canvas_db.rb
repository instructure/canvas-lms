# frozen_string_literal: true

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

# rubocop:disable Migration/AddIndex, Migration/ChangeColumn, Migration/Execute, Migration/IdColumn
# rubocop:disable Migration/PrimaryKey, Migration/RootAccountId, Rails/CreateTableWithTimestamps
# rubocop:disable Rails/ThreeStateBooleanColumn
class InitCanvasDb < ActiveRecord::Migration[7.0]
  prepend Canvas::ActiveRecord::Migration::DeferForeignKeys

  tag :predeploy

  def create_aua_log_partition(index)
    table_name = :"aua_logs_#{index}"
    create_table table_name do |t|
      t.references :asset_user_access, null: false, index: false
      t.timestamp :created_at, null: false
    end
    # Intentionally not adding FK on asset_user_access_id as the records are transient
    # and we're trying to do as little work as possible on the insert to these
    # and can be thrown away if they don't match anything anyway as the log is compacted.
  end

  def up
    connection.transaction(requires_new: true) do
      create_extension(:pg_collkey, schema: connection.shard.name, if_not_exists: true)
    rescue ActiveRecord::StatementInvalid
      raise ActiveRecord::Rollback
    end

    connection.transaction(requires_new: true) do
      create_extension(:pg_trgm, schema: connection.shard.name, if_not_exists: true)
    rescue ActiveRecord::StatementInvalid
      raise ActiveRecord::Rollback
    end

    execute(<<~SQL.squish)
      CREATE FUNCTION #{connection.quote_table_name("setting_as_int")}( IN p_setting TEXT ) RETURNS INT4 as $$
      DECLARE
          v_text text;
          v_int8 int8;
      BEGIN
          v_text := current_setting( p_setting, true );

          IF v_text IS NULL THEN
              RETURN NULL;
          END IF;

          IF NOT v_text ~ '^-?[0-9]{1,10}$' THEN
              RETURN NULL;
          END IF;

          v_int8 := v_text::INT8;
          IF v_int8 > 2147483647 OR v_int8 < -2147483648 THEN
              RETURN NULL;
          END IF;
          RETURN v_int8::int4;
      END;
      $$ language plpgsql;
    SQL

    execute(<<~SQL.squish)
      CREATE FUNCTION #{connection.quote_table_name("guard_excessive_updates")}() RETURNS TRIGGER AS $BODY$
      DECLARE
          record_count integer;
          max_record_count integer;
      BEGIN
          SELECT count(*) FROM oldtbl INTO record_count;
          max_record_count := COALESCE(setting_as_int('inst.max_update_limit.' || TG_TABLE_NAME), setting_as_int('inst.max_update_limit'), '#{PostgreSQLAdapterExtensions::DEFAULT_MAX_UPDATE_LIMIT}');
          IF record_count > max_record_count THEN
            IF current_setting('inst.max_update_fail', true) IS NOT DISTINCT FROM 'true' THEN
                RAISE EXCEPTION 'guard_excessive_updates: % to %.% failed', TG_OP, TG_TABLE_SCHEMA, TG_TABLE_NAME USING DETAIL = 'Would update ' || record_count || ' records but max is ' || max_record_count || ', orig query: ' || current_query();
            ELSE
                RAISE WARNING 'guard_excessive_updates: % to %.% was dangerous', TG_OP, TG_TABLE_SCHEMA, TG_TABLE_NAME USING DETAIL = 'Updated ' || record_count || ' records but threshold is ' || max_record_count || ', orig query: ' || current_query();
            END IF;
          END IF;
          RETURN NULL;
      END
      $BODY$ LANGUAGE plpgsql;
    SQL
    set_search_path("guard_excessive_updates")

    metadata = ActiveRecord::InternalMetadata
    metadata = metadata.new(connection) if $canvas_rails == "7.1"
    metadata[:guard_dangerous_changes_installed] = "true"

    # there may already be tables from plugins
    connection.tables.grep_v(/^_/).each do |table|
      add_guard_excessive_updates(table)
    end

    # these tables are referenced the most, so it's nice to put them first so we
    # don't have to defer creation of foreign keys to them
    create_table :accounts do |t|
      t.string :name, limit: 255
      t.timestamps precision: nil
      t.string :workflow_state, default: "active", null: false, limit: 255
      t.timestamp :deleted_at
      t.references :parent_account, foreign_key: { to_table: :accounts }, index: false
      t.string :sis_source_id, limit: 255
      t.references :sis_batch, foreign_key: true, index: { where: "sis_batch_id IS NOT NULL" }
      t.references :current_sis_batch, index: false
      t.references :root_account, null: false, foreign_key: { to_table: :accounts, deferrable: :immediate }, index: false
      t.references :last_successful_sis_batch, index: false
      t.string :membership_types, limit: 255
      t.string :default_time_zone, limit: 255
      t.string :external_status, default: "active", limit: 255
      t.bigint :storage_quota
      t.bigint :default_storage_quota
      t.boolean :enable_user_notes, default: false
      t.string :allowed_services, limit: 255
      t.text :turnitin_pledge
      t.text :turnitin_comments
      t.string :turnitin_account_id, limit: 255
      t.string :turnitin_salt, limit: 255
      t.string :turnitin_crypted_secret, limit: 255
      t.boolean :show_section_name_as_course_name, default: false
      t.boolean :allow_sis_import, default: false
      t.string :equella_endpoint, limit: 255
      t.text :settings
      t.string :uuid, limit: 255, index: { unique: true }
      t.string :default_locale, limit: 255
      t.text :stuck_sis_fields
      t.bigint :default_user_storage_quota
      t.string :lti_guid, limit: 255
      t.bigint :default_group_storage_quota
      t.string :turnitin_host, limit: 255
      t.string :integration_id, limit: 255
      t.string :lti_context_id, limit: 255, index: { unique: true }
      t.string :brand_config_md5, limit: 32, index: { where: "brand_config_md5 IS NOT NULL" }
      t.string :turnitin_originality, limit: 255
      t.string :account_calendar_subscription_type,
               default: "manual",
               null: false,
               limit: 255,
               index: { where: "account_calendar_subscription_type <> 'manual'" }
      t.references :latest_outcome_import,
                   foreign_key: { to_table: :outcome_imports },
                   index: { where: "latest_outcome_import_id IS NOT NULL" }
      t.references :course_template,
                   foreign_key: { to_table: :courses },
                   index: { where: "course_template_id IS NOT NULL" }
      t.boolean :account_calendar_visible, default: false, null: false
      t.references :grading_standard, foreign_key: true, index: { where: "grading_standard_id IS NOT NULL" }

      t.replica_identity_index
      t.index [:name, :parent_account_id]
      t.index [:parent_account_id, :root_account_id]
      t.index [:sis_source_id, :root_account_id], where: "sis_source_id IS NOT NULL", unique: true
      t.index [:integration_id, :root_account_id],
              unique: true,
              name: "index_accounts_on_integration_id",
              where: "integration_id IS NOT NULL"

      t.foreign_key :brand_configs, column: :brand_config_md5, primary_key: :md5
    end

    create_table :cloned_items do |t|
      t.bigint :original_item_id
      t.string :original_item_type, limit: 255
      t.timestamps precision: nil
    end

    create_table :courses do |t|
      t.string :name, limit: 255
      t.references :account, null: false, foreign_key: true
      t.string :group_weighting_scheme, limit: 255
      t.string :workflow_state, null: false, limit: 255
      t.string :uuid, limit: 255, index: true
      t.timestamp :start_at
      t.timestamp :conclude_at
      t.references :grading_standard, index: false
      t.boolean :is_public
      t.boolean :allow_student_wiki_edits
      t.timestamps precision: nil
      t.boolean :show_public_context_messages
      t.text :syllabus_body, limit: 16_777_215
      t.boolean :allow_student_forum_attachments, default: false
      t.string :default_wiki_editing_roles, limit: 255
      t.references :wiki, foreign_key: true, index: { where: "wiki_id IS NOT NULL" }
      t.boolean :allow_student_organized_groups, default: true
      t.string :course_code, limit: 255
      t.string :default_view, limit: 255
      t.references :abstract_course, foreign_key: true, index: { where: "abstract_course_id IS NOT NULL" }
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.references :enrollment_term, null: false, foreign_key: { deferrable: :immediate }
      t.string :sis_source_id, limit: 255
      t.references :sis_batch, foreign_key: true, index: { where: "sis_batch_id IS NOT NULL" }
      t.boolean :open_enrollment
      t.bigint :storage_quota
      t.text :tab_configuration
      t.boolean :allow_wiki_comments
      t.text :turnitin_comments
      t.boolean :self_enrollment
      t.string :license, limit: 255
      t.boolean :indexed
      t.boolean :restrict_enrollments_to_course_dates
      t.references :template_course, foreign_key: { to_table: :courses }
      t.string :locale, limit: 255
      t.text :settings
      t.references :replacement_course, index: false
      t.text :stuck_sis_fields
      t.text :public_description
      t.string :self_enrollment_code, limit: 255, index: { unique: true, where: "self_enrollment_code IS NOT NULL" }
      t.integer :self_enrollment_limit
      t.string :integration_id, limit: 255
      t.string :time_zone, limit: 255
      t.string :lti_context_id, limit: 255, index: { unique: true }
      t.bigint :turnitin_id, unique: true
      t.boolean :show_announcements_on_home_page
      t.integer :home_page_announcement_limit
      t.references :latest_outcome_import,
                   foreign_key: { to_table: :outcome_imports },
                   index: { where: "latest_outcome_import_id IS NOT NULL" }
      t.string :grade_passback_setting, limit: 255
      t.boolean :template, default: false, null: false
      t.boolean :homeroom_course, default: false, null: false, index: { where: "homeroom_course" }
      t.boolean :sync_enrollments_from_homeroom, default: false, null: false, index: { where: "sync_enrollments_from_homeroom" }
      t.references :homeroom_course, index: { where: "homeroom_course_id IS NOT NULL" }
      t.timestamp :deleted_at, precision: 6

      t.replica_identity_index
      t.index [:sis_source_id, :root_account_id], where: "sis_source_id IS NOT NULL", unique: true
      if (trgm = connection.extension(:pg_trgm)&.schema)
        t.index "(
            coalesce(lower(name), '') || ' ' ||
            coalesce(lower(sis_source_id), '') || ' ' ||
            coalesce(lower(course_code), '')
          ) #{trgm}.gin_trgm_ops",
                name: "index_gin_trgm_courses_composite_search",
                using: :gin
        t.index [:integration_id, :root_account_id],
                unique: true,
                name: "index_courses_on_integration_id",
                where: "integration_id IS NOT NULL"
      end
    end

    create_table :sis_batches do |t|
      t.references :account, null: false, index: false
      t.timestamp :ended_at
      t.string :workflow_state, null: false, limit: 255
      t.text :data
      t.timestamps precision: nil
      t.references :attachment
      t.integer :progress
      t.text :processing_errors, limit: 16_777_215
      t.text :processing_warnings, limit: 16_777_215
      t.boolean :batch_mode
      t.references :batch_mode_term,
                   foreign_key: { to_table: :enrollment_terms },
                   index: { where: "batch_mode_term_id IS NOT NULL" }
      t.text :options
      t.references :user, foreign_key: true, index: { where: "user_id IS NOT NULL" }
      t.timestamp :started_at
      t.string :diffing_data_set_identifier, limit: 255
      t.boolean :diffing_remaster
      t.references :generated_diff, index: false
      t.references :errors_attachment, foreign_key: { to_table: :attachments }
      t.integer :change_threshold
      t.boolean :diffing_threshold_exceeded, default: false, null: false
      t.bigint :job_ids, array: true, default: [], null: false

      t.index [:account_id, :created_at], name: "index_sis_batches_account_id_created_at"
      t.index %i[account_id diffing_data_set_identifier created_at],
              name: "index_sis_batches_diffing"
      t.index %i[account_id workflow_state created_at], name: "index_sis_batches_workflow_state_for_accounts"
    end

    create_table :users do |t|
      t.string :name, limit: 255
      t.string :sortable_name, limit: 255
      t.string :workflow_state, null: false, limit: 255, index: true
      t.string :time_zone, limit: 255
      t.string :uuid, limit: 255, index: { unique: true, name: "index_users_on_unique_uuid" }
      t.timestamps precision: nil
      t.string :avatar_image_url, limit: 255
      t.string :avatar_image_source, limit: 255
      t.timestamp :avatar_image_updated_at
      t.string :phone, limit: 255
      t.string :school_name, limit: 255
      t.string :school_position, limit: 255
      t.string :short_name, limit: 255
      t.timestamp :deleted_at
      t.boolean :show_user_services, default: true
      t.integer :page_views_count, default: 0
      t.integer :reminder_time_for_due_dates, default: 172_800
      t.integer :reminder_time_for_grading, default: 0
      t.bigint :storage_quota
      t.string :visible_inbox_types, limit: 255
      t.timestamp :last_user_note
      t.boolean :subscribe_to_emails
      t.text :features_used
      t.text :preferences
      t.string :avatar_state, limit: 255
      t.string :locale, limit: 255
      t.string :browser_locale, limit: 255
      t.integer :unread_conversations_count, default: 0
      t.text :stuck_sis_fields
      t.boolean :public
      t.string :otp_secret_key_enc, limit: 255
      t.string :otp_secret_key_salt, limit: 255
      t.references :otp_communication_channel, index: false
      t.string :initial_enrollment_type, limit: 255
      t.integer :crocodoc_id
      t.timestamp :last_logged_out
      t.string :lti_context_id, limit: 255, index: { unique: true }
      t.bigint :turnitin_id, index: { unique: true, where: "turnitin_id IS NOT NULL" }
      t.text :lti_id, index: { unique: true, name: "index_users_on_unique_lti_id" }
      t.string :pronouns
      t.bigint :root_account_ids, array: true, null: false, default: []
      t.references :merged_into_user,
                   foreign_key: { to_table: :users },
                   index: { where: "merged_into_user_id IS NOT NULL" }

      t.replica_identity_index :root_account_ids
      t.index [:avatar_state, :avatar_image_updated_at]
      if (trgm = connection.extension(:pg_trgm)&.schema)
        t.index "lower(name) #{trgm}.gin_trgm_ops", name: "index_gin_trgm_users_name", using: :gin
        t.index "LOWER(short_name) #{trgm}.gin_trgm_ops", name: "index_gin_trgm_users_short_name", using: :gin
        t.index "LOWER(name) #{trgm}.gin_trgm_ops",
                name: "index_gin_trgm_users_name_active_only",
                using: :gin,
                where: "workflow_state IN ('registered', 'pre_registered')"
      end
      t.index "#{User.best_unicode_collation_key("sortable_name")}, id", name: "index_users_on_sortable_name"
      t.index :id, where: "workflow_state <> 'deleted'", name: "index_active_users_on_id"
    end

    # most the rest is alphabetical, with a "natural" sort order (so that for example quizzes comes before quiz_submissions)
    create_table :abstract_courses do |t|
      t.string :sis_source_id, limit: 255, index: true
      t.references :sis_batch, foreign_key: true, index: { where: "sis_batch_id IS NOT NULL" }
      t.references :account, null: false, foreign_key: true
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.string :short_name, limit: 255
      t.string :name, limit: 255
      t.timestamps precision: nil
      t.references :enrollment_term, null: false, foreign_key: true
      t.string :workflow_state, null: false, limit: 255
      t.text :stuck_sis_fields

      t.index [:root_account_id, :sis_source_id]
    end

    create_table :access_tokens do |t|
      t.references :developer_key, null: false, index: false
      t.references :user, foreign_key: true
      t.timestamp :last_used_at
      t.timestamp :expires_at
      t.string :purpose, limit: 255
      t.timestamps precision: nil
      t.string :crypted_token, limit: 255, index: { unique: true }
      t.string :token_hint, limit: 255
      t.text :scopes
      t.boolean :remember_access
      t.string :crypted_refresh_token, limit: 255, index: { unique: true }
      t.string :workflow_state, default: "active", null: false, index: true
      t.references :root_account, null: false, index: false
      t.references :real_user,
                   foreign_key: { to_table: :users },
                   index: { where: "real_user_id IS NOT NULL" }
      t.timestamp :permanent_expires_at

      t.replica_identity_index
      t.index [:developer_key_id, :last_used_at]
    end

    create_table :account_notifications do |t|
      t.string :subject, limit: 255
      t.string :icon, default: "warning", limit: 255
      t.text :message
      t.references :account, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true
      t.timestamp :start_at, null: false
      t.timestamp :end_at, null: false
      t.timestamps precision: nil
      t.string :required_account_service, limit: 255
      t.integer :months_in_display_cycle
      t.boolean :domain_specific, default: false, null: false
      t.boolean :send_message, default: false, null: false
      t.timestamp :messages_sent_at

      t.index %i[account_id end_at start_at], name: "index_account_notifications_by_account_and_timespan"
    end

    create_table :account_notification_roles do |t|
      t.references :account_notification, null: false, foreign_key: true, index: false
      t.references :role,
                   foreign_key: true,
                   index: { where: "role_id IS NOT NULL", name: "index_account_notification_roles_only_on_role_id" }

      t.index [:account_notification_id, :role_id],
              unique: true,
              name: "index_account_notification_roles_on_role_id"
    end

    create_table :account_reports do |t|
      t.references :user, null: false, foreign_key: true
      t.text :message
      t.references :account, null: false, foreign_key: true, index: false
      t.references :attachment, foreign_key: true
      t.string :workflow_state, default: "created", null: false, limit: 255
      t.string :report_type, limit: 255
      t.integer :progress
      t.timestamps precision: nil
      t.text :parameters
      t.integer :current_line
      t.integer :total_lines
      t.timestamp :start_at
      t.timestamp :end_at
      t.bigint :job_ids, array: true, default: [], null: false

      t.index %i[account_id report_type created_at],
              order: { created_at: :desc },
              name: "index_account_reports_latest_of_type_per_account"
    end

    create_table :account_report_runners do |t|
      t.references :account_report, null: false, foreign_key: true
      t.string :workflow_state, null: false, default: "created", limit: 255
      t.string :batch_items, array: true, default: []
      t.timestamps precision: nil
      t.timestamp :started_at
      t.timestamp :ended_at
      t.bigint :job_ids, array: true, default: [], null: false
    end

    create_table :account_report_rows do |t|
      t.references :account_report, null: false, foreign_key: true
      t.references :account_report_runner, null: false, foreign_key: true
      t.integer :row_number
      t.string :row, array: true, default: []
      t.timestamp :created_at, null: false, index: true
      t.string :file, index: true
    end

    create_table :account_users do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps precision: nil
      t.references :role, null: false, foreign_key: true
      t.string :workflow_state, default: "active", null: false, index: true
      t.references :sis_batch, index: { where: "sis_batch_id IS NOT NULL" }
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false

      t.replica_identity_index
    end

    create_table :alerts do |t|
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.text :recipients, null: false
      t.integer :repetition
      t.timestamps precision: nil
    end

    create_table :alert_criteria do |t|
      t.references :alert, foreign_key: true, index: { where: "alert_id IS NOT NULL" }
      t.string :criterion_type, limit: 255
      t.float :threshold
    end

    create_table :anonymous_or_moderation_events do |t|
      t.references :assignment, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.references :submission, foreign_key: true
      t.references :canvadoc, foreign_key: true
      t.string :event_type, null: false
      t.jsonb :payload, null: false, default: {}
      t.timestamps precision: nil
      t.references :context_external_tool,
                   foreign_key: { name: "fk_rails_f492821432" },
                   index: { where: "context_external_tool_id IS NOT NULL",
                            name: "index_ame_on_context_external_tool_id" }
      t.references :quiz,
                   foreign_key: { name: "fk_rails_a862303024" },
                   index: { where: "quiz_id IS NOT NULL" }
    end

    create_table :appointment_groups do |t|
      t.string :title, limit: 255
      t.text :description
      t.string :location_name, limit: 255
      t.string :location_address, limit: 255
      t.string :context_code, limit: 255
      t.string :sub_context_code, limit: 255
      t.string :workflow_state, null: false, limit: 255
      t.timestamps precision: nil
      t.timestamp :start_at
      t.timestamp :end_at
      t.integer :participants_per_appointment
      t.integer :max_appointments_per_participant # nil means no limit
      t.integer :min_appointments_per_participant, default: 0
      t.string :participant_visibility, limit: 255
      t.boolean :allow_observer_signup, null: false, default: false
    end

    create_table :appointment_group_contexts do |t|
      t.references :appointment_group
      t.string :context_code, limit: 255
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.timestamps precision: nil
    end

    create_table :appointment_group_sub_contexts do |t|
      t.references :appointment_group
      t.bigint :sub_context_id
      t.string :sub_context_type, limit: 255
      t.string :sub_context_code, limit: 255
      t.timestamps precision: nil
    end

    create_table :assessment_question_banks do |t|
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.text :title
      t.string :workflow_state, null: false, limit: 255
      t.timestamp :deleted_at
      t.timestamps precision: nil
      t.string :migration_id, limit: 255
      t.references :root_account, foreign_key: { to_table: :accounts }

      t.index [:context_id, :context_type], name: "index_on_aqb_on_context_id_and_context_type"
      t.index %i[context_id context_type title id],
              name: "index_aqb_context_and_title"
    end

    create_table :assessment_question_bank_users do |t|
      t.references :assessment_question_bank, null: false, index: { name: "assessment_qbu_aqb_id" }
      t.references :user, null: false, index: { name: "assessment_qbu_u_id" }
      t.timestamps precision: nil
    end

    create_table :assessment_questions do |t|
      t.text :name
      t.text :question_data
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.string :workflow_state, limit: 255
      t.timestamps null: true, precision: nil
      t.references :assessment_question_bank, index: false
      t.timestamp :deleted_at
      t.string :migration_id, limit: 255
      t.integer :position
      t.references :root_account, foreign_key: { to_table: :accounts }

      t.index [:assessment_question_bank_id, :position], name: "question_bank_id_and_position"
    end

    create_table :assessment_requests do |t|
      t.references :rubric_assessment
      t.references :user, null: false, foreign_key: true
      t.references :asset, null: false, foreign_key: { to_table: :submissions }, index: false
      t.string :asset_type, null: false, limit: 255
      t.bigint :assessor_asset_id, null: false
      t.string :assessor_asset_type, null: false, limit: 255
      t.string :workflow_state, null: false, limit: 255
      t.timestamps precision: nil
      t.string :uuid, limit: 255
      t.references :rubric_association, foreign_key: true
      t.references :assessor, null: false, foreign_key: { to_table: :users }

      t.index [:assessor_asset_id, :assessor_asset_type], name: "aa_id_and_aa_type"
      t.index [:asset_id, :asset_type]
    end

    create_table :asset_user_accesses do |t|
      t.string :asset_code, limit: 255
      t.string :asset_group_code, limit: 255
      t.references :user, index: false
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.timestamp :last_access
      t.timestamps null: true, precision: nil
      t.string :asset_category, limit: 255
      t.float :view_score
      t.float :participate_score
      t.string :action_level, limit: 255
      t.text :display_name
      t.string :membership_type, limit: 255
      t.references :root_account, index: false, null: false

      t.replica_identity_index
      t.index [:user_id, :asset_code]
      t.index %i[context_id context_type user_id updated_at], name: "index_asset_user_accesses_on_ci_ct_ui_ua"
      t.index %i[user_id context_id asset_code id],
              name: "index_asset_user_accesses_on_user_id_context_id_asset_code"
    end

    # one table for each day of week, they'll periodically
    # be compacted and truncated.  This prevents having to
    # create and drop true partitions at a high rate
    (0..6).each { |i| create_aua_log_partition(i) }

    create_table :assignment_groups do |t|
      t.string :name, limit: 255
      t.text :rules
      t.string :default_assignment_name, limit: 255
      t.integer :position
      t.string :assignment_weighting_scheme, limit: 255
      t.float :group_weight
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.string :workflow_state, null: false, limit: 255
      t.timestamps precision: nil
      t.references :cloned_item, foreign_key: true, index: { where: "cloned_item_id IS NOT NULL" }
      t.string :context_code, limit: 255
      t.string :migration_id, limit: 255
      t.string :sis_source_id, limit: 255
      t.text :integration_data
      t.references :root_account, foreign_key: { to_table: :accounts }

      t.index [:context_id, :context_type]
    end

    create_table :assignments do |t|
      t.string :title, limit: 255
      t.text :description, limit: 16_777_215
      t.timestamp :due_at
      t.timestamp :unlock_at
      t.timestamp :lock_at
      t.float :points_possible
      t.float :min_score
      t.float :max_score
      t.float :mastery_score
      t.string :grading_type, limit: 255
      t.string :submission_types, limit: 255
      t.string :workflow_state, null: false, limit: 255, default: "published", index: true
      t.bigint :context_id, null: false, index: { where: "context_type='Course' AND workflow_state<>'deleted'",
                                                  name: "index_assignments_active" }
      t.string :context_type, null: false, limit: 255
      t.references :assignment_group
      t.references :grading_standard
      t.timestamps null: true, precision: nil
      t.string :group_category, limit: 255
      t.integer :submissions_downloads, default: 0
      t.integer :peer_review_count, default: 0
      t.timestamp :peer_reviews_due_at
      t.boolean :peer_reviews_assigned, default: false, null: false
      t.boolean :peer_reviews, default: false, null: false
      t.boolean :automatic_peer_reviews, default: false, null: false
      t.boolean :all_day, default: false, null: false
      t.date :all_day_date
      t.boolean :could_be_locked, default: false, null: false
      t.references :cloned_item, foreign_key: true, index: { where: "cloned_item_id IS NOT NULL" }
      t.integer :position
      t.string :migration_id, limit: 255
      t.boolean :grade_group_students_individually, default: false, null: false
      t.boolean :anonymous_peer_reviews, default: false, null: false
      t.string :time_zone_edited, limit: 255
      t.boolean :turnitin_enabled, default: false, null: false
      t.string :allowed_extensions, limit: 255
      t.text :turnitin_settings
      t.boolean :muted, default: false, null: false
      t.references :group_category, foreign_key: true, index: { where: "group_category_id IS NOT NULL" }
      t.boolean :freeze_on_copy, default: false, null: false
      t.boolean :copied, default: false, null: false
      t.boolean :only_visible_to_overrides, default: false, null: false
      t.boolean :post_to_sis, default: false, null: false
      t.string :integration_id, limit: 255
      t.text :integration_data
      t.bigint :turnitin_id, index: { unique: true, where: "turnitin_id IS NOT NULL" }
      t.boolean :moderated_grading, default: false, null: false
      t.timestamp :grades_published_at
      t.boolean :omit_from_final_grade, default: false, null: false
      t.boolean :vericite_enabled, default: false, null: false
      t.boolean :intra_group_peer_reviews, default: false, null: false
      t.string :lti_context_id, index: { unique: true }
      t.boolean :anonymous_instructor_annotations, default: false, null: false
      t.references :duplicate_of,
                   index: { where: "duplicate_of_id IS NOT NULL" },
                   foreign_key: { to_table: :assignments }
      t.boolean :anonymous_grading, default: false
      t.boolean :graders_anonymous_to_graders, default: false
      t.integer :grader_count, default: 0
      t.boolean :grader_comments_visible_to_graders, default: true
      t.references :grader_section,
                   foreign_key: { to_table: :course_sections },
                   index: { where: "grader_section_id IS NOT NULL" }
      t.references :final_grader,
                   foreign_key: { to_table: :users },
                   index: { where: "final_grader_id IS NOT NULL" }
      t.boolean :grader_names_visible_to_final_grader, default: true
      t.timestamp :duplication_started_at, index: { where: "duplication_started_at IS NOT NULL AND workflow_state = 'duplicating'" }
      t.timestamp :importing_started_at, index: { where: "importing_started_at IS NOT NULL AND workflow_state = 'importing'" }
      t.integer :allowed_attempts
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }
      t.string :sis_source_id
      t.references :migrate_from,
                   foreign_key: { to_table: :quizzes },
                   index: { where: "migrate_from_id IS NOT NULL" }
      t.jsonb :settings
      t.references :annotatable_attachment,
                   foreign_key: { to_table: :attachments },
                   index: { where: "annotatable_attachment_id IS NOT NULL" }
      t.boolean :important_dates, default: false, null: false, index: { where: "important_dates" }
      t.boolean :hide_in_gradebook, default: false, null: false
      t.string :ab_guid, array: true, default: [], null: false
      t.references :parent_assignment, foreign_key: { to_table: :assignments }
      t.string :type, null: false, limit: 255, default: "Assignment"
      t.string :sub_assignment_tag, limit: 255
      t.boolean :has_sub_assignments, null: false, default: false

      t.index [:context_id, :context_type]
      t.index [:sis_source_id, :root_account_id], where: "sis_source_id IS NOT NULL", unique: true
      t.index :duplication_started_at,
              where: "workflow_state = 'migrating' AND duplication_started_at IS NOT NULL",
              name: "index_assignments_duplicating_on_started_at"
    end

    create_table :assignment_configuration_tool_lookups do |t|
      t.references :assignment, null: false, foreign_key: true
      t.bigint :tool_id
      t.string :tool_type, null: false, limit: 255
      t.string :subscription_id
      t.string :tool_product_code
      t.string :tool_vendor_code
      t.string :tool_resource_type_code
      t.string :context_type, default: "Account", null: false

      t.index %i[tool_id tool_type assignment_id], unique: true, name: "index_tool_lookup_on_tool_assignment_id"
      t.index %i[tool_product_code tool_vendor_code tool_resource_type_code], name: "index_resource_codes_on_assignment_configuration_tool_lookups"
    end

    create_table :assignment_overrides do |t|
      t.timestamps precision: nil
      # generic info
      t.references :assignment, foreign_key: true
      t.integer :assignment_version
      t.references :set,
                   polymorphic: { limit: 255 },
                   index: { name: "index_assignment_overrides_on_set_type_and_set_id" }
      t.string :title, null: false, limit: 255
      t.string :workflow_state, null: false, limit: 255
      # due at override
      t.boolean :due_at_overridden, default: false, null: false
      t.timestamp :due_at, index: { where: "due_at_overridden", name: "index_assignment_overrides_due_at_when_overridden" }
      t.boolean :all_day
      t.date :all_day_date
      # unlock at override
      t.boolean :unlock_at_overridden, default: false, null: false
      t.timestamp :unlock_at
      # lock at override
      t.boolean :lock_at_overridden, default: false, null: false
      t.timestamp :lock_at
      t.references :quiz, foreign_key: true
      t.integer :quiz_version
      t.references :root_account, foreign_key: { to_table: :accounts }
      t.references :context_module, foreign_key: true, index: { where: "context_module_id IS NOT NULL" }
      t.boolean :unassign_item, default: false, null: false
      t.references :wiki_page, foreign_key: true, index: { where: "wiki_page_id IS NOT NULL" }
      t.references :discussion_topic, foreign_key: true, index: { where: "discussion_topic_id IS NOT NULL" }
      t.references :attachment, foreign_key: true, index: { where: "attachment_id IS NOT NULL" }

      t.check_constraint <<~SQL.squish, name: "require_association"
        workflow_state='deleted' OR
        assignment_id IS NOT NULL OR
        quiz_id IS NOT NULL OR context_module_id IS NOT NULL OR
        wiki_page_id IS NOT NULL OR
        discussion_topic_id IS NOT NULL OR
        attachment_id IS NOT NULL
      SQL

      t.index %i[assignment_id set_type set_id],
              name: "index_assignment_overrides_on_assignment_and_set",
              unique: true,
              where: "workflow_state='active' and set_id is not null"
      t.index %i[context_module_id set_id set_type],
              unique: true,
              where: "context_module_id IS NOT NULL AND workflow_state = 'active' AND set_id IS NOT NULL",
              name: "index_assignment_overrides_on_context_module_id_and_set"
      t.index %i[wiki_page_id set_id set_type],
              unique: true,
              where: "wiki_page_id IS NOT NULL AND workflow_state = 'active' AND set_id IS NOT NULL",
              name: "index_assignment_overrides_on_wiki_page_id_and_set"
      t.index %i[discussion_topic_id set_id set_type],
              unique: true,
              where: "discussion_topic_id IS NOT NULL AND workflow_state = 'active' AND set_id IS NOT NULL",
              name: "index_assignment_overrides_on_discussion_topic_id_and_set"
      t.index %i[attachment_id set_id set_type],
              unique: true,
              where: "attachment_id IS NOT NULL AND workflow_state = 'active' AND set_id IS NOT NULL",
              name: "index_assignment_overrides_on_attachment_id_and_set"
    end

    create_table :assignment_override_students do |t|
      t.timestamps precision: nil
      t.references :assignment, foreign_key: true
      t.references :assignment_override, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: { deferrable: :immediate }
      t.references :quiz, foreign_key: true
      t.string :workflow_state, default: "active", null: false, index: true
      t.references :root_account, foreign_key: { to_table: :accounts }
      t.references :context_module, foreign_key: true, index: false
      t.references :wiki_page, foreign_key: true, index: false
      t.references :discussion_topic, foreign_key: true, index: false
      t.references :attachment, foreign_key: true, index: false

      t.index [:assignment_id, :user_id], unique: true, where: "workflow_state = 'active'"
      t.index [:user_id, :quiz_id]
      t.index [:context_module_id, :user_id],
              where: "context_module_id IS NOT NULL",
              unique: true,
              name: "index_assignment_override_students_on_context_module_and_user"
      t.index [:wiki_page_id, :user_id], unique: true, where: "wiki_page_id IS NOT NULL"
      t.index [:discussion_topic_id, :user_id],
              unique: true,
              where: "discussion_topic_id IS NOT NULL",
              name: "index_assignment_override_students_on_discussion_topic_and_user"
      t.index [:attachment_id, :user_id],
              unique: true,
              where: "attachment_id IS NOT NULL"
    end

    create_table :attachments do |t|
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.bigint :size
      t.references :folder, index: false
      t.string :content_type, limit: 255
      t.text :filename
      t.string :uuid, limit: 255
      t.text :display_name
      t.timestamps null: true, precision: nil
      t.string :workflow_state, limit: 255
      t.references :user
      t.boolean :locked, default: false
      t.string :file_state, limit: 255
      t.timestamp :deleted_at
      t.integer :position
      t.timestamp :lock_at
      t.timestamp :unlock_at
      t.boolean :could_be_locked
      t.references :root_attachment,
                   foreign_key: { to_table: :attachments },
                   index: { where: "root_attachment_id IS NOT NULL", name: "index_attachments_on_root_attachment_id_not_null" }
      t.references :cloned_item
      t.string :migration_id, limit: 255
      t.string :namespace, limit: 255, index: true
      t.string :media_entry_id, limit: 255, index: true
      t.string :md5, limit: 255
      t.string :encoding, limit: 255
      t.boolean :need_notify, index: { where: "need_notify" }
      t.text :upload_error_message
      t.references :replacement_attachment,
                   foreign_key: { to_table: :attachments },
                   index: { where: "replacement_attachment_id IS NOT NULL" }
      t.references :usage_rights, foreign_key: true, index: { where: "usage_rights_id IS NOT NULL" }
      t.timestamp :modified_at
      t.timestamp :viewed_at
      t.string :instfs_uuid, index: { where: "instfs_uuid IS NOT NULL" }
      t.references :root_account
      t.string :category, default: "uncategorized", null: false
      t.integer :word_count
      t.string :visibility_level, limit: 32, default: "inherit", null: false
      t.boolean :only_visible_to_overrides, null: false, default: false

      t.index [:context_id, :context_type]
      t.index [:md5, :namespace]
      t.index [:workflow_state, :updated_at]
      t.index %i[folder_id file_state position]
      t.index [:folder_id, :position], where: "folder_id IS NOT NULL"
      t.index %i[context_id context_type migration_id],
              where: "migration_id IS NOT NULL",
              name: "index_attachments_on_context_and_migration_id"
      t.index %i[md5 namespace content_type],
              where: "root_attachment_id IS NULL and filename IS NOT NULL"
      t.index %i[context_id context_type migration_id],
              opclass: { migration_id: :text_pattern_ops },
              where: "migration_id IS NOT NULL",
              name: "index_attachments_on_context_and_migration_id_pattern_ops"
      t.index :created_at, where: "context_type IN ('ContentExport', 'ContentMigration') and file_state NOT IN ('deleted', 'broken') and root_attachment_id is null"
      t.index :context_type, where: "workflow_state = 'deleted' and file_state = 'deleted'"
    end

    execute(<<~SQL) # rubocop:disable Rails/SquishedSQLHeredocs
      CREATE FUNCTION #{connection.quote_table_name("attachment_before_insert_verify_active_folder__tr_fn")} () RETURNS trigger AS $$
      DECLARE
        folder_state text;
      BEGIN
        SELECT workflow_state INTO folder_state FROM folders WHERE folders.id = NEW.folder_id FOR SHARE;
        if folder_state = 'deleted' then
          RAISE EXCEPTION 'Cannot create attachments in deleted folders --> %', NEW.folder_id;
        end if;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    set_search_path("attachment_before_insert_verify_active_folder__tr_fn")

    execute(<<~SQL.squish)
      CREATE TRIGGER attachment_before_insert_verify_active_folder__tr
        BEFORE INSERT ON #{Attachment.quoted_table_name}
        FOR EACH ROW
        EXECUTE PROCEDURE #{connection.quote_table_name("attachment_before_insert_verify_active_folder__tr_fn")}()
    SQL

    create_table :attachment_associations do |t|
      t.references :attachment
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.references :root_account

      t.index [:context_id, :context_type], name: "attachment_associations_a_id_a_type"
    end

    create_table :attachment_upload_statuses do |t|
      t.references :attachment, null: false, foreign_key: true
      t.text :error, null: false
      t.timestamp :created_at, null: false
    end

    create_table :auditor_authentication_records do |t|
      t.string :uuid, null: false, index: { unique: true, name: "index_auth_audits_on_unique_uuid" }
      t.references :account, null: false, foreign_key: true
      t.string :event_type, null: false
      t.references :pseudonym, null: false, foreign_key: true
      t.string :request_id, null: false
      t.references :user, null: false, foreign_key: true
      t.timestamp :created_at, null: false
    end

    create_table :auditor_course_records do |t|
      t.string :uuid, null: false, index: { unique: true, name: "index_course_audits_on_unique_uuid" }
      t.references :account, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.text :data
      t.string :event_source, null: false
      t.string :event_type, null: false
      t.string :request_id, null: false
      t.references :sis_batch
      t.references :user, foreign_key: true
      t.timestamp :created_at, null: false
    end

    create_table :auditor_feature_flag_records do |t|
      t.string :uuid, null: false, index: true
      t.references :feature_flag, null: false
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }
      t.references :context, polymorphic: true, index: false
      t.string :feature_name
      t.string :event_type, null: false
      t.string :state_before, null: false
      t.string :state_after, null: false
      t.string :request_id, null: false
      t.references :user, foreign_key: true
      t.timestamp :created_at, null: false
    end

    create_table :auditor_grade_change_records do |t|
      t.string :uuid, null: false, index: { unique: true, name: "index_grade_audits_on_unique_uuid" }
      t.references :account, null: false, foreign_key: true
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.references :assignment, foreign_key: true
      t.bigint :context_id, null: false
      t.string :context_type, null: false
      t.string :event_type, null: false
      t.boolean :excused_after, null: false
      t.boolean :excused_before, null: false
      t.string :grade_after
      t.string :grade_before
      t.boolean :graded_anonymously
      t.references :grader, foreign_key: { to_table: :users }
      t.float :points_possible_after
      t.float :points_possible_before
      t.string :request_id, null: false
      t.float :score_after
      t.float :score_before
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :submission, foreign_key: true
      t.integer :submission_version_number
      t.timestamp :created_at, null: false
      t.references :grading_period, foreign_key: true, index: { where: "grading_period_id IS NOT NULL" }

      # next index covers cassandra previous indices by course_id, course_id -> assignment_id,
      # course_id -> assignment_id -> grader_id -> student_id,
      # course_id -> assignment_id -> student_id
      # (the claim is that those subsets are small enough filtering the results from the simpler index is fine)
      t.index %i[context_type context_id assignment_id], name: "index_auditor_grades_by_course_and_assignment"
      t.index [:root_account_id, :grader_id], name: "index_auditor_grades_by_account_and_grader"
      t.index [:root_account_id, :student_id], name: "index_auditor_grades_by_account_and_student"
      # next index overs cassandra previous indices by course_id -> grader_id,
      # and course_id -> grader_id -> student_id (same theory as above)
      t.index %i[context_type context_id grader_id], name: "index_auditor_grades_by_course_and_grader"
      t.index %i[context_type context_id student_id], name: "index_auditor_grades_by_course_and_student"
    end

    create_table :auditor_pseudonym_records do |t|
      t.references :pseudonym, null: false, foreign_key: true
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }
      t.references :performing_user, null: false, index: false
      t.string :action, null: false
      t.string :hostname, null: false
      t.string :pid, null: false
      t.string :uuid, null: false, index: true
      t.string :event_type, null: false
      t.string :request_id

      t.timestamp :created_at, null: false
    end

    create_table :authentication_providers do |t|
      t.references :account, null: false, foreign_key: true
      t.integer :auth_port
      t.string :auth_host, limit: 255
      t.string :auth_base, limit: 255
      t.string :auth_username, limit: 255
      t.string :auth_crypted_password, limit: 2048
      t.string :auth_password_salt, limit: 255
      t.string :auth_type, limit: 255
      t.string :auth_over_tls, limit: 255, default: "start_tls"
      t.timestamps precision: nil
      t.string :log_in_url, limit: 255
      t.string :log_out_url, limit: 255
      t.string :identifier_format, limit: 255
      t.text :certificate_fingerprint
      t.string :entity_id, limit: 255
      t.text :auth_filter
      t.string :requested_authn_context, limit: 255
      t.timestamp :last_timeout_failure
      t.text :login_attribute
      t.string :idp_entity_id, limit: 255
      t.integer :position
      t.boolean :parent_registration, default: false, null: false
      t.string :workflow_state, default: "active", null: false, limit: 255, index: true
      t.boolean :jit_provisioning, default: false, null: false
      t.string :metadata_uri, limit: 255, index: { where: "metadata_uri IS NOT NULL" }
      t.json :settings, default: {}, null: false
      t.text :internal_ca
      # this field will be removed after VERIFY_NONE is removed entirely
      t.boolean :verify_tls_cert_opt_in, default: false, null: false
    end

    create_table :blackout_dates do |t|
      t.references :context, polymorphic: true, index: { name: "index_blackout_dates_on_context_type_and_context_id" }, null: false
      t.date :start_date, :end_date, null: false
      t.string :event_title, limit: 255, null: false
      t.timestamps precision: 6
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false

      t.replica_identity_index
    end

    create_table :bookmarks_bookmarks do |t|
      t.references :user, null: false, foreign_key: true
      t.text :name, null: false
      t.text :url, null: false
      t.integer :position
      t.text :json
    end

    create_table :brand_configs, id: false do |t|
      t.primary_keys [:md5]

      t.string :md5, limit: 32, null: false, unique: true
      t.text :variables
      t.boolean :share, default: false, null: false, index: true
      t.string :name, limit: 255
      t.timestamp :created_at, null: false
      t.text :js_overrides
      t.text :css_overrides
      t.text :mobile_js_overrides
      t.text :mobile_css_overrides
      t.string :parent_md5, limit: 255
    end

    create_table :calendar_events do |t|
      t.string :title, limit: 255
      t.text :description, limit: 16_777_215
      t.text :location_name
      t.text :location_address
      t.timestamp :start_at, index: { where: "workflow_state<>'deleted'" }
      t.timestamp :end_at
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.string :workflow_state, null: false, limit: 255
      t.timestamps precision: nil
      t.references :user, foreign_key: true
      t.boolean :all_day
      t.date :all_day_date
      t.timestamp :deleted_at
      t.references :cloned_item, foreign_key: true, index: { where: "cloned_item_id IS NOT NULL" }
      t.string :context_code, limit: 255, index: true
      t.string :migration_id, limit: 255
      t.string :time_zone_edited, limit: 255
      t.references :parent_calendar_event, foreign_key: { to_table: :calendar_events }
      t.string :effective_context_code, limit: 255, index: { where: "effective_context_code IS NOT NULL" }
      t.integer :participants_per_appointment
      t.boolean :override_participants_per_appointment
      t.text :comments
      t.string :timetable_code, limit: 255
      t.references :web_conference, foreign_key: true, index: { where: "web_conference_id IS NOT NULL" }
      t.references :root_account, foreign_key: { to_table: :accounts }
      t.boolean :important_dates, default: false, null: false, index: { where: "important_dates" }
      t.string :rrule, limit: 255
      t.uuid :series_uuid, index: true
      t.boolean :series_head
      t.boolean :blackout_date, default: false, null: false

      t.index [:context_id, :context_type]
      t.index %i[context_id context_type timetable_code], where: "timetable_code IS NOT NULL", unique: true, name: "index_calendar_events_on_context_and_timetable_code"
    end

    create_table :canvadocs do |t|
      t.string :document_id, limit: 255, index: { unique: true }
      t.string :process_state, limit: 255
      t.references :attachment, null: false, foreign_key: true
      t.timestamps precision: nil
      t.boolean :has_annotations
    end

    create_table :canvadocs_annotation_contexts do |t|
      t.references :attachment, foreign_key: true, index: false, null: false
      t.references :submission, null: false, foreign_key: true
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }
      t.string :launch_id, null: false
      t.integer :submission_attempt
      t.timestamps precision: nil

      t.index %i[attachment_id submission_attempt submission_id],
              name: "index_attachment_attempt_submission",
              unique: true
      t.index [:attachment_id, :submission_id],
              where: "submission_attempt IS NULL",
              name: "index_attachment_submission",
              unique: true
    end

    create_table :canvadocs_submissions do |t|
      t.references :canvadoc
      t.references :crocodoc_document, index: { where: "crocodoc_document_id IS NOT NULL" }
      t.references :submission, null: false

      t.index [:submission_id, :canvadoc_id],
              where: "canvadoc_id IS NOT NULL",
              name: "unique_submissions_and_canvadocs",
              unique: true
      t.index [:submission_id, :crocodoc_document_id],
              where: "crocodoc_document_id IS NOT NULL",
              name: "unique_submissions_and_crocodocs",
              unique: true
    end

    create_table :canvas_metadata do |t|
      t.string :key, null: false, index: { unique: true }
      t.jsonb :payload, null: false
      t.timestamps precision: nil
    end

    create_table :collaborations do |t|
      t.string :collaboration_type, limit: 255
      t.string :document_id, limit: 255
      t.references :user, foreign_key: true
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.string :url, limit: 255
      t.string :uuid, limit: 255
      t.text :data
      t.timestamps precision: nil
      t.text :description
      t.string :title, null: false, limit: 255
      t.string :workflow_state, default: "active", null: false, limit: 255
      t.timestamp :deleted_at
      t.string :context_code, limit: 255
      t.string :type, limit: 255
      t.uuid :resource_link_lookup_uuid

      t.index [:context_id, :context_type]
    end

    create_table :collaborators do |t|
      t.references :user, foreign_key: true
      t.references :collaboration, foreign_key: true
      t.timestamps precision: nil
      t.string :authorized_service_user_id, limit: 255
      t.references :group, foreign_key: true
    end

    create_table :comment_bank_items do |t|
      t.references :course, null: false, foreign_key: true
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }
      t.references :user, null: false, foreign_key: true
      t.text :comment, null: false
      t.timestamps precision: 6
      t.string :workflow_state, null: false, default: "active"

      t.index :user_id,
              where: "workflow_state <> 'deleted'",
              name: "index_active_comment_bank_items_on_user"
      t.replica_identity_index
    end

    create_table :communication_channels do |t|
      t.string :path, null: false, limit: 255
      t.string :path_type, default: "email", null: false, limit: 255
      t.integer :position
      t.references :user, null: false, foreign_key: true, index: false
      t.references :pseudonym, index: false
      t.integer :bounce_count, default: 0
      t.string :workflow_state, null: false, limit: 255
      t.string :confirmation_code, limit: 255, index: true
      t.timestamps precision: nil
      t.boolean :build_pseudonym_on_confirm
      t.timestamp :last_bounce_at, index: { where: "bounce_count > 0" }
      # last_bounce_details was originally intended to have limit: 32768, but
      # it was typoed as "length" instead of "limit" so it did not apply
      t.text :last_bounce_details
      t.timestamp :last_suppression_bounce_at
      t.timestamp :last_transient_bounce_at
      # last_transient_bounce_details was originally intended to have limit:
      # 32768, but it was typoed as "length" instead of "limit" so it did not apply
      t.text :last_transient_bounce_details
      t.timestamp :confirmation_code_expires_at
      t.integer :confirmation_sent_count, default: 0, null: false
      t.bigint :root_account_ids, array: true
      t.string :confirmation_redirect

      t.index [:pseudonym_id, :position]
      t.index [:user_id, :position]
      t.index "LOWER(path), path_type", name: "index_communication_channels_on_path_and_path_type"
      if (trgm = connection.extension(:pg_trgm)&.schema)
        t.index "lower(path) #{trgm}.gin_trgm_ops", name: "index_gin_trgm_communication_channels_path", using: :gin
        t.index "user_id, LOWER(path), path_type",
                unique: true,
                name: "index_communication_channels_on_user_id_and_path_and_path_type"
      end
    end

    create_table :conditional_release_rules do |t|
      t.references :course, foreign_key: true
      t.references :trigger_assignment, foreign_key: { to_table: :assignments }
      t.timestamp :deleted_at
      t.references :root_account,
                   foreign_key: { to_table: :accounts },
                   null: false,
                   index: { name: "index_cr_rules_on_root_account_id" }
      t.timestamps precision: nil

      t.index [:root_account_id, :course_id], where: "deleted_at IS NULL", name: "index_cr_rules_on_account_and_course"
    end

    create_table :conditional_release_scoring_ranges do |t|
      t.references :rule,
                   foreign_key: { to_table: :conditional_release_rules },
                   index: { where: "deleted_at IS NULL", name: "index_cr_scoring_ranges_on_rule_id" },
                   null: false
      t.decimal :lower_bound
      t.decimal :upper_bound
      t.integer :position
      t.timestamp :deleted_at
      t.references :root_account,
                   foreign_key: { to_table: :accounts },
                   null: false,
                   index: { name: "index_cr_scoring_ranges_on_root_account_id" }
      t.timestamps precision: nil

      t.index :rule_id
    end

    create_table :conditional_release_assignment_sets do |t|
      t.references :scoring_range,
                   foreign_key: { to_table: :conditional_release_scoring_ranges },
                   index: { where: "deleted_at IS NULL", name: "index_cr_assignment_sets_on_scoring_range_id" },
                   null: false
      t.integer :position
      t.timestamp :deleted_at
      t.references :root_account,
                   foreign_key: { to_table: :accounts },
                   null: false,
                   index: { name: "index_cr_assignment_sets_on_root_account_id" }
      t.timestamps precision: nil

      t.index :scoring_range_id
    end

    create_table :conditional_release_assignment_set_associations do |t|
      t.references :assignment_set,
                   foreign_key: { to_table: :conditional_release_assignment_sets },
                   index: { name: "index_crasa_on_assignment_set_id", where: "assignment_set_id IS NOT NULL" }
      t.references :assignment,
                   foreign_key: true,
                   index: { where: "deleted_at IS NULL", name: "index_cr_assignment_set_associations_on_set" }
      t.integer :position
      t.timestamp :deleted_at
      t.references :root_account,
                   foreign_key: { to_table: :accounts },
                   null: false,
                   index: { name: "index_cr_assignment_set_associations_on_root_account_id" }
      t.timestamps precision: nil

      t.index [:assignment_id, :assignment_set_id],
              unique: true,
              where: "deleted_at IS NULL",
              name: "index_cr_assignment_set_associations_on_assignment_and_set"
      t.index :assignment_id, name: "index_crasa_on_assignment_id", where: "assignment_id IS NOT NULL"
    end

    create_table :conditional_release_assignment_set_actions do |t|
      t.string :action, null: false
      t.string :source, null: false
      t.references :student, null: false, index: false
      t.references :actor, null: false, index: false
      t.references :assignment_set, index: false
      t.timestamp :deleted_at
      t.references :root_account,
                   foreign_key: { to_table: :accounts },
                   null: false,
                   index: { name: "index_cr_assignment_set_actions_on_root_account_id" }
      t.timestamps precision: nil

      t.index :assignment_set_id,
              where: "deleted_at IS NULL",
              name: "index_cr_assignment_set_actions_on_assignment_set_id"
      t.index %i[assignment_set_id student_id created_at],
              order: { created_at: :desc },
              where: "deleted_at IS NULL",
              name: "index_cr_assignment_set_actions_on_set_and_student"
    end

    create_table :content_exports do |t|
      t.references :user, foreign_key: true, index: { where: "user_id IS NOT NULL" }
      t.references :attachment, foreign_key: true
      t.string :export_type, limit: 255
      t.text :settings
      t.float :progress
      t.string :workflow_state, null: false, limit: 255
      t.timestamps precision: nil
      t.references :content_migration
      t.references :context, polymorphic: { limit: 255 }, index: false
      t.boolean :global_identifiers, default: false, null: false

      t.index [:context_id, :context_type]
    end

    create_table :content_migrations do |t|
      t.bigint :context_id, null: false, index: true
      t.references :user, foreign_key: true, index: { where: "user_id IS NOT NULL" }
      t.string :workflow_state, null: false, limit: 255
      t.text :migration_settings
      t.timestamp :started_at
      t.timestamp :finished_at
      t.timestamps precision: nil
      t.float :progress
      t.string :context_type, limit: 255
      t.references :attachment, index: { where: "attachment_id IS NOT NULL" }
      t.references :overview_attachment,
                   foreign_key: { to_table: :attachments },
                   index: { where: "overview_attachment_id IS NOT NULL" }
      t.references :exported_attachment,
                   foreign_key: { to_table: :attachments },
                   index: { where: "exported_attachment_id IS NOT NULL" }
      t.references :source_course, index: { where: "source_course_id IS NOT NULL" }
      t.string :migration_type, limit: 255
      t.references :child_subscription,
                   foreign_key: { to_table: :master_courses_child_subscriptions },
                   index: { where: "child_subscription_id IS NOT NULL" }
      t.references :root_account, foreign_key: { to_table: :accounts }
      t.references :asset_map_attachment, index: { where: "asset_map_attachment_id IS NOT NULL" }, foreign_key: { to_table: :attachments }

      t.index [:context_id, :id], name: "index_content_migrations_on_context_id_and_id_no_clause"
      t.index [:context_id, :id], where: "workflow_state='queued'"
      t.index [:context_id, :started_at],
              name: "index_content_migrations_blocked_migrations",
              where: "started_at IS NOT NULL"
    end

    create_table :content_participations do |t|
      t.references :content, polymorphic: { limit: 255 }, null: false, index: false
      t.references :user, null: false, foreign_key: true
      t.string :workflow_state, null: false, limit: 255
      t.references :root_account, foreign_key: { to_table: :accounts }
      t.string :content_item, null: false, default: "grade"

      t.index %i[content_id content_type user_id content_item],
              name: "index_content_participations_by_type_uniquely",
              unique: true
      t.index :user_id,
              name: "index_content_participations_on_user_id_unread",
              where: "workflow_state = 'unread'"
    end

    create_table :content_participation_counts do |t|
      t.string :content_type, limit: 255
      t.references :context, polymorphic: { limit: 255 }, index: false
      t.references :user, index: false
      t.integer :unread_count, default: 0
      t.timestamps precision: nil
      t.references :root_account, foreign_key: { to_table: :accounts }

      t.index %i[context_id context_type user_id content_type], name: "index_content_participation_counts_uniquely", unique: true
    end

    create_table :content_shares do |t|
      t.text :name, null: false
      t.timestamps precision: nil
      t.references :user, null: false, foreign_key: true, index: false
      t.references :content_export, null: false
      t.references :sender, foreign_key: { to_table: :users }, index: { where: "sender_id IS NOT NULL" }
      t.string :read_state, limit: 255, null: false
      t.string :type, limit: 255, null: false
      t.references :root_account

      t.index %i[user_id content_export_id sender_id],
              unique: true,
              name: "index_content_shares_on_user_and_content_export_and_sender_ids"
    end

    create_table :content_tags do |t|
      t.bigint :content_id
      t.string :content_type, limit: 255
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.text :title
      t.string :tag, limit: 255
      t.text :url
      t.timestamps precision: nil
      t.text :comments
      t.string :tag_type, default: "default", limit: 255
      t.references :context_module, foreign_key: true
      t.integer :position
      t.integer :indent
      t.string :migration_id, limit: 255
      t.references :learning_outcome, foreign_key: true, index: { where: "learning_outcome_id IS NOT NULL" }
      t.string :context_code, limit: 255
      t.float :mastery_score
      t.references :rubric_association, index: false
      t.string :workflow_state, default: "active", null: false, limit: 255
      t.references :cloned_item, foreign_key: true, index: { where: "cloned_item_id IS NOT NULL" }
      t.bigint :associated_asset_id
      t.string :associated_asset_type, limit: 255
      t.boolean :new_tab
      t.jsonb :link_settings
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.jsonb :external_data

      t.replica_identity_index
      t.index [:content_id, :content_type]
      t.index [:context_id, :context_type]
      t.index [:associated_asset_id, :associated_asset_type], name: "index_content_tags_on_associated_asset"
      t.index %i[context_id context_type content_type],
              where: "workflow_state = 'active'",
              name: "index_content_tags_on_context_when_active"
      t.index %i[content_type context_type context_id],
              where: "workflow_state<>'deleted'",
              name: "index_content_tags_for_due_date_cacher"
    end

    create_table :context_external_tools do |t|
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.string :domain, limit: 255
      t.string :url, limit: 4.kilobytes
      t.text :shared_secret, null: false
      t.text :consumer_key, null: false, index: true
      t.string :name, null: false, limit: 255
      t.text :description
      t.text :settings
      t.string :workflow_state, null: false, limit: 255
      t.timestamps precision: nil
      t.string :migration_id, limit: 255
      t.references :cloned_item, foreign_key: true, index: { where: "cloned_item_id IS NOT NULL" }
      t.string :tool_id, limit: 255, index: true
      t.boolean :not_selectable
      t.string :app_center_id, limit: 255
      t.boolean :allow_membership_service_access, default: false, null: false
      t.references :developer_key
      t.references :root_account, null: false, index: false
      t.boolean :is_rce_favorite, default: false, null: false
      t.string :identity_hash, limit: 64, index: { where: "identity_hash <> 'duplicate'" }
      t.text :lti_version, null: false, limit: 8, default: "1.1"

      t.replica_identity_index
      t.index [:context_id, :context_type]
      t.index %i[context_id context_type migration_id], where: "migration_id IS NOT NULL", name: "index_external_tools_on_context_and_migration_id"
    end

    create_table :context_external_tool_placements do |t|
      t.string :placement_type, limit: 255
      t.references :context_external_tool, null: false, foreign_key: true, index: { name: "external_tool_placements_tool_id" }

      t.index [:placement_type, :context_external_tool_id], unique: true, name: "external_tool_placements_type_and_tool_id"
    end

    create_table :context_modules do |t|
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.text :name
      t.integer :position
      t.text :prerequisites
      t.text :completion_requirements
      t.timestamps precision: nil
      t.string :workflow_state, default: "active", null: false, limit: 255
      t.timestamp :deleted_at
      t.timestamp :unlock_at
      t.string :migration_id, limit: 255
      t.boolean :require_sequential_progress
      t.references :cloned_item, foreign_key: true, index: { where: "cloned_item_id IS NOT NULL" }
      t.text :completion_events
      t.integer :requirement_count
      t.references :root_account, foreign_key: { to_table: :accounts }

      t.index [:context_id, :context_type]
    end

    create_table :context_module_progressions do |t|
      t.references :context_module, foreign_key: true
      t.references :user, foreign_key: true, index: false
      t.text :requirements_met
      t.string :workflow_state, null: false, limit: 255
      t.timestamps precision: nil
      t.boolean :collapsed
      t.integer :current_position
      t.timestamp :completed_at
      t.boolean :current
      t.integer :lock_version, default: 0, null: false
      t.timestamp :evaluated_at
      t.text :incomplete_requirements
      t.references :root_account, foreign_key: { to_table: :accounts }

      t.index [:user_id, :context_module_id], unique: true, name: "index_cmp_on_user_id_and_module_id"
    end

    create_table :conversations do |t|
      # for quick lookups so we know whether or not we need to create a new one
      t.string :private_hash, limit: 255, index: { unique: true }
      t.boolean :has_attachments, default: false, null: false
      t.boolean :has_media_objects, default: false, null: false
      t.text :tags
      t.text :root_account_ids
      t.string :subject, limit: 255
      t.references :context, polymorphic: { limit: 255 }, index: false
      t.timestamp :updated_at
    end

    create_table :conversation_batches do |t|
      t.string :workflow_state, null: false, limit: 255
      t.references :user, null: false, foreign_key: true, index: false
      t.text :recipient_ids
      t.references :root_conversation_message, null: false, foreign_key: { to_table: :conversation_messages }
      t.text :conversation_message_ids
      t.text :tags
      t.timestamps precision: nil
      t.references :context, polymorphic: { limit: 255 }, index: false
      t.string :subject, limit: 255
      t.boolean :group
      t.boolean :generate_user_note

      t.index [:user_id, :workflow_state]
    end

    create_table :conversation_messages do |t|
      t.references :conversation, foreign_key: true, index: false
      t.references :author
      t.timestamp :created_at
      t.boolean :generated
      t.text :body
      t.text :forwarded_message_ids
      t.string :media_comment_id, limit: 255
      t.string :media_comment_type, limit: 255
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.bigint :asset_id
      t.string :asset_type, limit: 255
      t.text :attachment_ids
      t.boolean :has_attachments
      t.boolean :has_media_objects
      t.text :root_account_ids

      t.index [:conversation_id, :created_at]
    end

    create_table :conversation_message_participants do |t|
      t.references :conversation_message,
                   foreign_key: true,
                   index: { name: "index_conversation_message_participants_on_message_id" }
      t.references :conversation_participant, index: false
      t.text :tags
      t.references :user, index: false
      t.string :workflow_state, limit: 255
      t.timestamp :deleted_at, index: true
      t.text :root_account_ids

      t.index [:conversation_participant_id, :conversation_message_id], name: "index_cmp_on_cpi_and_cmi"
      t.index [:user_id, :conversation_message_id], name: "index_conversation_message_participants_on_uid_and_message_id", unique: true
    end

    create_table :conversation_participants do |t|
      t.references :conversation, null: false, index: false
      t.references :user, null: false, index: {
        where: "workflow_state = 'unread'",
        name: "index_conversation_participants_unread_on_user_id"
      }
      t.timestamp :last_message_at
      t.boolean :subscribed, default: true
      t.string :workflow_state, null: false, limit: 255
      t.timestamp :last_authored_at
      t.boolean :has_attachments, default: false, null: false
      t.boolean :has_media_objects, default: false, null: false
      t.integer :message_count, default: 0
      t.string :label, limit: 255
      t.text :tags
      t.timestamp :visible_last_authored_at
      t.text :root_account_ids
      t.string :private_hash, limit: 255
      t.timestamp :updated_at

      t.index [:user_id, :last_message_at]
      t.index [:conversation_id, :user_id], unique: true
      t.index [:private_hash, :user_id], where: "private_hash IS NOT NULL", unique: true
    end

    create_table :course_account_associations do |t|
      t.references :course, null: false, foreign_key: true, index: false
      t.references :account, null: false, foreign_key: true, index: false
      t.integer :depth, null: false
      t.timestamps precision: nil
      t.references :course_section, foreign_key: true
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false

      t.replica_identity_index
      t.index [:account_id, :depth], name: "index_course_account_associations_on_account_id_and_depth_id"
      t.index %i[course_id course_section_id account_id], unique: true, name: "index_caa_on_course_id_and_section_id_and_account_id"
    end

    create_table :course_paces do |t|
      t.references :course, null: false, foreign_key: true
      t.references :course_section, index: false
      t.references :user, index: false
      t.string :workflow_state, default: "unpublished", null: false, limit: 255
      t.date :end_date
      t.boolean :exclude_weekends, null: false, default: true
      t.boolean :hard_end_dates, null: false, default: false
      t.timestamps precision: 6
      t.timestamp :published_at
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.string :migration_id

      t.replica_identity_index
      t.index :course_id, unique: true, where: "course_section_id IS NULL AND user_id IS NULL AND workflow_state='active'", name: "course_paces_unique_primary_plan_index"
      t.index :course_section_id, unique: true, where: "workflow_state='active'"
      t.index [:course_id, :user_id], unique: true, where: "workflow_state='active'"
    end

    create_table :course_pace_module_items do |t|
      t.references :course_pace, foreign_key: true
      t.integer :duration, null: false, default: 0
      t.references :module_item, foreign_key: { to_table: :content_tags }
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.timestamps precision: 6
      t.string :migration_id

      t.replica_identity_index
    end

    create_table :course_score_statistics do |t|
      t.references :course, null: false, foreign_key: true, index: { unique: true }
      t.decimal :average, precision: 8, scale: 2, null: false
      t.integer :score_count, null: false
      t.timestamps precision: nil
    end

    create_table :course_sections do |t|
      t.string :sis_source_id, limit: 255
      t.references :sis_batch, foreign_key: true, index: { where: "sis_batch_id IS NOT NULL" }
      t.references :course, null: false, foreign_key: true
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.references :enrollment_term, foreign_key: true
      t.string :name, null: false, limit: 255
      t.boolean :default_section
      t.boolean :accepting_enrollments
      t.boolean :can_manually_enroll
      t.timestamp :start_at
      t.timestamp :end_at
      t.timestamps precision: nil
      t.string :workflow_state, default: "active", null: false, limit: 255
      t.boolean :restrict_enrollments_to_section_dates
      t.references :nonxlist_course,
                   foreign_key: { to_table: :courses },
                   index: { where: "nonxlist_course_id IS NOT NULL",
                            name: "index_course_sections_on_nonxlist_course" }
      t.text :stuck_sis_fields
      t.string :integration_id, limit: 255

      t.replica_identity_index
      t.index [:sis_source_id, :root_account_id], where: "sis_source_id IS NOT NULL", unique: true
      t.index [:integration_id, :root_account_id],
              unique: true,
              name: "index_sections_on_integration_id",
              where: "integration_id IS NOT NULL"
      t.index :course_id,
              unique: true,
              where: "default_section = 't' AND workflow_state <> 'deleted'",
              name: "index_course_sections_unique_default_section"
    end

    create_table :crocodoc_documents do |t|
      t.string :uuid, limit: 255, index: true
      t.string :process_state, limit: 255, index: true
      t.references :attachment
      t.timestamps null: true, precision: nil
    end

    create_table :csp_domains do |t|
      t.references :account, null: false, foreign_key: true, index: false
      t.string :domain, null: false, limit: 255
      t.string :workflow_state, null: false, limit: 255
      t.timestamps precision: nil

      t.index [:account_id, :domain], unique: true
      t.index [:account_id, :workflow_state]
    end

    create_table :custom_data do |t|
      t.text :data
      t.string :namespace, limit: 255
      t.references :user, index: false
      t.timestamps precision: nil

      t.index [:user_id, :namespace], unique: true
    end

    create_table :custom_grade_statuses do |t|
      t.string :color, limit: 7, null: false
      t.string :name, null: false, limit: 14
      t.string :workflow_state, null: false, default: "active", limit: 255
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :deleted_by, foreign_key: { to_table: :users }
      t.timestamps precision: 6
      t.boolean :applies_to_submissions, null: false, default: true
      t.boolean :applies_to_final_grade, null: false, default: true
      t.boolean :allow_final_grade_value, null: false, default: true

      t.replica_identity_index
    end

    create_table :custom_gradebook_columns do |t|
      t.string :title, null: false, limit: 255
      t.integer :position, null: false
      t.string :workflow_state, default: "active", null: false, limit: 255
      t.references :course, null: false, foreign_key: {  dependent: true }
      t.timestamps precision: nil
      t.boolean :teacher_notes, default: false, null: false
      t.boolean :read_only, default: false, null: false
      t.references :root_account, foreign_key: { to_table: :accounts }
    end

    create_table :custom_gradebook_column_data do |t|
      t.string :content, null: false, limit: 255
      t.references :user, null: false, foreign_key: true
      t.references :custom_gradebook_column, null: false, foreign_key: true, index: false
      t.references :root_account, foreign_key: { to_table: :accounts }

      t.index [:custom_gradebook_column_id, :user_id],
              unique: true,
              name: "index_custom_gradebook_column_data_unique_column_and_user"
    end

    create_table :delayed_messages do |t|
      t.references :notification, index: false
      t.references :notification_policy, foreign_key: true
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.references :communication_channel, foreign_key: true, index: false
      t.string :frequency, limit: 255
      t.string :workflow_state, limit: 255
      t.timestamp :batched_at
      t.timestamps null: true, precision: nil
      t.timestamp :send_at, index: { name: "by_sent_at" }
      t.text :link
      t.text :name_of_topic
      t.text :summary
      t.references :root_account, index: false
      t.references :notification_policy_override,
                   foreign_key: true,
                   index: { where: "notification_policy_override_id IS NOT NULL" }

      t.index [:workflow_state, :send_at], name: "ws_sa"
      t.index %i[communication_channel_id root_account_id workflow_state send_at], name: "ccid_raid_ws_sa"
      t.index :send_at, where: "workflow_state = 'pending'", name: "index_delayed_messages_pending"
    end

    create_table :delayed_notifications do |t|
      t.references :notification, null: false, index: false
      t.bigint :asset_id, null: false
      t.string :asset_type, null: false, limit: 255
      t.text :recipient_keys
      t.string :workflow_state, null: false, limit: 255
      t.timestamps precision: nil
    end

    create_table :developer_keys do |t|
      t.string :api_key, limit: 255
      t.string :email, limit: 255
      t.string :user_name, limit: 255
      t.references :account, index: false
      t.timestamps precision: nil
      t.references :user, index: false
      t.string :name, limit: 255
      t.string :redirect_uri, limit: 255
      t.string :icon_url, limit: 255
      t.string :sns_arn, limit: 255
      t.boolean :trusted
      t.boolean :force_token_reuse
      t.string :workflow_state, default: "active", null: false, limit: 255
      t.boolean :replace_tokens
      t.boolean :auto_expire_tokens, default: false, null: false
      t.string :redirect_uris, array: true, default: [], null: false, limit: 4096
      t.text :notes
      t.integer :access_token_count, default: 0, null: false
      t.string :vendor_code, index: true
      t.boolean :visible, default: false, null: false
      t.text :scopes
      t.boolean :require_scopes, default: false, null: false
      t.boolean :test_cluster_only, default: false, null: false
      t.jsonb :public_jwk
      t.boolean :internal_service, default: false, null: false
      t.text :oidc_initiation_url
      t.string :public_jwk_url
      t.boolean :is_lti_key, default: false, null: false
      t.boolean :allow_includes, default: false, null: false
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.string :client_credentials_audience
      t.references :service_user, foreign_key: { to_table: :users }, index: { where: "service_user_id IS NOT NULL" }

      t.replica_identity_index
    end

    create_table :developer_key_account_bindings do |t|
      t.references :account, null: false, foreign_key: true, index: false
      t.references :developer_key, null: false
      t.string :workflow_state, null: false, default: "off"
      t.timestamps precision: nil
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false

      t.replica_identity_index
      t.index %i[account_id developer_key_id], name: "index_dev_key_bindings_on_account_id_and_developer_key_id", unique: true
    end

    create_table :discussion_entries do |t|
      t.text :message
      t.references :discussion_topic, foreign_key: true, index: false
      t.references :user, foreign_key: true
      t.references :parent, foreign_key: { to_table: :discussion_entries }
      t.timestamps precision: nil
      t.references :attachment, index: false
      t.string :workflow_state, default: "active", limit: 255
      t.timestamp :deleted_at
      t.string :migration_id, limit: 255
      t.references :editor, foreign_key: { to_table: :users }, index: { where: "editor_id IS NOT NULL" }
      t.references :root_entry, foreign_key: { to_table: :discussion_entries }, index: false
      t.integer :depth
      t.integer :rating_count
      t.integer :rating_sum
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.boolean :legacy, default: true, null: false
      t.boolean :include_reply_preview, default: false, null: false
      t.boolean :is_anonymous_author, default: false, null: false
      t.references :quoted_entry, foreign_key: { to_table: :discussion_entries }

      t.replica_identity_index
      t.index %i[root_entry_id workflow_state created_at], name: "index_discussion_entries_root_entry"
      t.index %i[discussion_topic_id updated_at created_at], name: "index_discussion_entries_for_topic"
      t.index [:user_id, :discussion_topic_id],
              where: "workflow_state <> 'deleted'",
              name: "index_discussion_entries_active_on_user_id_and_topic"
    end

    create_table :discussion_entry_drafts do |t|
      t.references :discussion_topic, null: false, foreign_key: true
      t.references :discussion_entry, foreign_key: true, index: false
      t.references :root_entry, foreign_key: { to_table: :discussion_entries }
      t.references :parent, foreign_key: { to_table: :discussion_entries }
      t.references :attachment, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :message
      t.boolean :include_reply_preview, null: false, default: false
      t.timestamps precision: 6

      t.index %i[discussion_topic_id user_id],
              name: "unique_index_on_topic_and_user",
              where: "discussion_entry_id IS NULL AND root_entry_id IS NULL",
              unique: true
      t.index %i[root_entry_id user_id],
              name: "unique_index_on_root_entry_and_user",
              where: "discussion_entry_id IS NULL",
              unique: true
      t.index %i[discussion_entry_id user_id],
              name: "unique_index_on_entry_and_user",
              unique: true
    end

    create_table :discussion_entry_participants do |t|
      t.references :discussion_entry, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true
      t.string :workflow_state, null: false, limit: 255
      t.boolean :forced_read_state
      t.integer :rating
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.string :report_type, limit: 255
      t.timestamp :read_at

      t.replica_identity_index
      t.index [:discussion_entry_id, :user_id], name: "index_entry_participant_on_entry_id_and_user_id", unique: true
    end

    create_table :discussion_entry_versions do |t|
      t.references :discussion_entry, null: false, foreign_key: true
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.references :user, foreign_key: true
      t.bigint :version
      t.text :message
      t.timestamps precision: 6

      t.replica_identity_index
    end

    create_table :discussion_topics do |t|
      t.string :title, limit: 255
      t.text :message, limit: 16_777_215
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.string :type, limit: 255
      t.references :user, foreign_key: true
      t.string :workflow_state, null: false, limit: 255, index: true
      t.timestamp :last_reply_at
      t.timestamps precision: nil
      t.timestamp :delayed_post_at
      t.timestamp :posted_at
      t.references :assignment, foreign_key: true
      t.references :attachment, foreign_key: true, index: { where: "attachment_id IS NOT NULL" }
      t.timestamp :deleted_at
      t.references :root_topic, foreign_key: { to_table: :discussion_topics }
      t.boolean :could_be_locked, default: false, null: false
      t.references :cloned_item, foreign_key: true, index: { where: "cloned_item_id IS NOT NULL" }
      t.string :context_code, limit: 255
      t.integer :position
      t.string :migration_id, limit: 255
      t.references :old_assignment, foreign_key: { to_table: :assignments }, index: { where: "old_assignment_id IS NOT NULL" }
      t.timestamp :subtopics_refreshed_at
      t.references :last_assignment, index: false
      t.references :external_feed, foreign_key: true, index: { where: "external_feed_id IS NOT NULL" }
      t.references :editor, foreign_key: { to_table: :users }, index: { where: "editor_id IS NOT NULL" }
      t.boolean :podcast_enabled, default: false, null: false
      t.boolean :podcast_has_student_posts, default: false, null: false
      t.boolean :require_initial_post, default: false, null: false
      t.string :discussion_type, limit: 255
      t.timestamp :lock_at
      t.boolean :pinned, default: false, null: false
      t.boolean :locked, default: false, null: false
      t.references :group_category, foreign_key: true, index: { where: "group_category_id IS NOT NULL" }
      t.boolean :allow_rating, default: false, null: false
      t.boolean :only_graders_can_rate, default: false, null: false
      t.boolean :sort_by_rating, default: false, null: false
      t.timestamp :todo_date
      t.boolean :is_section_specific, default: false, null: false
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.string :anonymous_state, limit: 255
      t.boolean :is_anonymous_author, default: false, null: false
      t.integer :reply_to_entry_required_count, null: false, default: 0
      t.timestamp :unlock_at, precision: 6
      t.boolean :only_visible_to_overrides, null: false, default: false

      t.replica_identity_index
      t.index [:context_id, :position]
      t.index [:id, :type]
      t.index %i[context_id context_type root_topic_id], unique: true, name: "index_discussion_topics_unique_subtopic_per_context"
      t.index [:context_id, :last_reply_at], name: "index_discussion_topics_on_context_and_last_reply_at"
      if (trgm = connection.extension(:pg_trgm)&.schema)
        t.index "LOWER(title) #{trgm}.gin_trgm_ops", name: "index_gin_trgm_discussion_topics_title", using: :gin
      end
    end

    create_table :discussion_topic_materialized_views, id: false do |t|
      t.primary_keys [:discussion_topic_id]

      t.references :discussion_topic, null: false, foreign_key: true, index: false
      t.text :json_structure
      t.text :participants_array
      t.text :entry_ids_array

      t.timestamps precision: nil
      t.timestamp :generation_started_at
    end

    create_table :discussion_topic_participants do |t|
      t.references :discussion_topic, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true
      t.integer :unread_entry_count, default: 0, null: false
      t.string :workflow_state, null: false, limit: 255
      t.boolean :subscribed
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false

      t.replica_identity_index
      t.index [:discussion_topic_id, :user_id], name: "index_topic_participant_on_topic_id_and_user_id", unique: true
    end

    create_table :discussion_topic_section_visibilities do |t|
      t.references :discussion_topic, null: false, foreign_key: true, index: { name: "idx_discussion_topic_section_visibility_on_topic" }
      t.references :course_section, null: false, foreign_key: true, index: { name: "idx_discussion_topic_section_visibility_on_section" }
      t.timestamps precision: nil
      t.string :workflow_state, null: false, limit: 255
    end

    create_table :enrollment_dates_overrides do |t|
      t.references :enrollment_term, foreign_key: true
      t.string :enrollment_type, limit: 255
      t.bigint :context_id, null: false
      t.string :context_type, limit: 255
      t.timestamp :start_at
      t.timestamp :end_at
      t.timestamps precision: nil
      t.references :root_account, foreign_key: { to_table: :accounts }

      t.replica_identity_index :context_id
    end

    create_table :enrollment_states, id: false do |t|
      t.primary_keys [:enrollment_id]

      t.references :enrollment, null: false, foreign_key: true, index: false
      t.string :state, limit: 255, index: true
      t.boolean :state_is_current, null: false, default: false
      t.timestamp :state_started_at
      t.timestamp :state_valid_until, index: true
      t.boolean :restricted_access, null: false, default: false
      t.boolean :access_is_current, null: false, default: false
      t.integer :lock_version, default: 0, null: false
      t.timestamp :updated_at
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false

      t.replica_identity_index
      t.index [:state_is_current, :access_is_current], name: "index_enrollment_states_on_currents"
    end

    create_table :enrollment_terms do |t|
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.string :name, limit: 255
      t.string :term_code, limit: 255
      t.string :sis_source_id, limit: 255
      t.references :sis_batch, foreign_key: true, index: { where: "sis_batch_id IS NOT NULL" }
      t.timestamp :start_at
      t.timestamp :end_at
      t.boolean :accepting_enrollments
      t.boolean :can_manually_enroll
      t.timestamps precision: nil
      t.string :workflow_state, default: "active", null: false, limit: 255
      t.text :stuck_sis_fields
      t.string :integration_id, limit: 255
      t.references :grading_period_group, foreign_key: true

      t.replica_identity_index
      t.index [:sis_source_id, :root_account_id], where: "sis_source_id IS NOT NULL", unique: true
      t.index [:integration_id, :root_account_id],
              unique: true,
              name: "index_terms_on_integration_id",
              where: "integration_id IS NOT NULL"
    end

    create_table :enrollments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course,
                   foreign_key: true,
                   null: false,
                   index: { where: "workflow_state = 'active'", name: "index_enrollments_on_course_when_active" }
      t.string :type, null: false, limit: 255
      t.string :uuid, limit: 255, index: true
      t.string :workflow_state, null: false, limit: 255, index: true
      t.timestamps precision: nil
      t.references :associated_user, foreign_key: { to_table: :users }, index: { where: "associated_user_id IS NOT NULL" }
      t.references :sis_batch, foreign_key: true, index: { where: "sis_batch_id IS NOT NULL" }
      t.timestamp :start_at
      t.timestamp :end_at
      t.references :course_section, null: false, foreign_key: true, index: false
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.timestamp :completed_at
      t.boolean :self_enrolled
      t.string :grade_publishing_status, default: "unpublished", limit: 255
      t.timestamp :last_publish_attempt_at
      t.text :stuck_sis_fields
      t.text :grade_publishing_message
      t.boolean :limit_privileges_to_course_section, default: false, null: false
      t.timestamp :last_activity_at
      t.integer :total_activity_time
      t.references :role, null: false, foreign_key: true, index: false
      t.timestamp :graded_at
      t.references :sis_pseudonym
      t.timestamp :last_attended_at
      t.references :temporary_enrollment_source_user, foreign_key: { to_table: :users }, index: false
      t.references :temporary_enrollment_pairing, foreign_key: true, index: { where: "temporary_enrollment_pairing_id IS NOT NULL" }

      t.replica_identity_index
      t.index [:course_id, :workflow_state]
      t.index [:root_account_id, :course_id]
      t.index %i[user_id type role_id course_section_id associated_user_id],
              where: "associated_user_id IS NOT NULL",
              name: "index_enrollments_on_user_type_role_section_associated_user",
              unique: true
      t.index %i[user_id type role_id course_section_id],
              where: "associated_user_id IS NULL ",
              name: "index_enrollments_on_user_type_role_section",
              unique: true
      t.index [:course_id, :user_id]
      t.index [:role_id, :user_id]
      t.index [:course_section_id, :id]
      t.index [:course_id, :id]
      t.index %i[temporary_enrollment_source_user_id user_id type role_id course_section_id],
              where: "temporary_enrollment_source_user_id IS NOT NULL",
              name: "index_enrollments_on_temp_enrollment_user_type_role_section",
              unique: true
    end

    create_table :eportfolios do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, limit: 255
      t.boolean :public
      t.timestamps precision: nil
      t.string :uuid, limit: 255
      t.string :workflow_state, default: "active", null: false, limit: 255
      t.timestamp :deleted_at
      t.string :spam_status, index: true
    end

    create_table :eportfolio_categories do |t|
      t.references :eportfolio, null: false, foreign_key: true
      t.string :name, limit: 255
      t.integer :position
      t.string :slug, limit: 255
      t.timestamps precision: nil
    end

    create_table :eportfolio_entries do |t|
      t.references :eportfolio, null: false, foreign_key: true
      t.references :eportfolio_category, null: false, foreign_key: true
      t.integer :position
      t.string :name, limit: 255
      t.boolean :allow_comments
      t.boolean :show_comments
      t.string :slug, limit: 255
      t.text :content, limit: 16_777_215
      t.timestamps precision: nil
    end

    create_table :epub_exports do |t|
      t.references :content_export, :course, :user, foreign_key: true
      t.string :workflow_state, default: "created", limit: 255
      t.timestamps precision: nil
      t.string :type, limit: 255
    end

    create_table :error_reports do |t|
      t.text :backtrace
      t.text :url
      t.text :message
      t.text :comments
      t.references :user, index: false
      t.timestamps null: true, precision: nil
      t.string :email, limit: 255
      t.boolean :during_tests, default: false
      t.text :user_agent
      t.string :request_method, limit: 255
      t.text :http_env, limit: 16_777_215
      t.text :subject
      t.string :request_context_id, limit: 255
      t.references :account, index: false
      t.bigint :zendesk_ticket_id, index: true
      t.text :data
      t.string :category, limit: 255, index: true

      t.index :created_at, name: "error_reports_created_at"
    end

    create_table :event_stream_failures do |t|
      t.string :operation, null: false, limit: 255
      t.string :event_stream, null: false, limit: 255
      t.string :record_id, null: false, limit: 255
      t.text :payload, null: false
      t.text :exception
      t.text :backtrace
      t.timestamps precision: nil
    end

    create_table :external_feeds do |t|
      t.references :user, foreign_key: true, index: { where: "user_id IS NOT NULL" }
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.integer :consecutive_failures
      t.integer :failures
      t.timestamp :refresh_at
      t.string :title, limit: 255
      t.string :url, null: false, limit: 255
      t.string :header_match, limit: 255
      t.timestamps precision: nil
      t.string :verbosity, limit: 255
      t.string :migration_id, limit: 255

      t.index [:context_id, :context_type]
      t.index %i[context_id context_type url verbosity], unique: true, where: "header_match IS NULL", name: "index_external_feeds_uniquely_1"
      t.index %i[context_id context_type url header_match verbosity], unique: true, where: "header_match IS NOT NULL", name: "index_external_feeds_uniquely_2"
    end

    create_table :external_feed_entries do |t|
      t.references :user, foreign_key: true, index: { where: "user_id IS NOT NULL" }
      t.references :external_feed, null: false, foreign_key: true
      t.text :title
      t.text :message
      t.string :source_name, limit: 255
      t.text :source_url
      t.timestamp :posted_at
      t.string :workflow_state, null: false, limit: 255
      t.text :url, index: true
      t.string :author_name, limit: 255
      t.string :author_email, limit: 255
      t.text :author_url
      t.bigint :asset_id
      t.string :asset_type, limit: 255
      t.string :uuid, limit: 255, index: true
      t.timestamps precision: nil
    end

    create_table :external_integration_keys do |t|
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.string :key_value, null: false, limit: 255
      t.string :key_type, null: false, limit: 255
      t.timestamps precision: nil

      t.index %i[context_id context_type key_type], name: "index_external_integration_keys_unique", unique: true
    end

    create_table :favorites do |t|
      t.references :user, foreign_key: true
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.timestamps precision: nil
      t.references :root_account, index: false, null: false

      t.replica_identity_index
      t.index %i[user_id context_id context_type], unique: true, name: "index_favorites_unique_user_object"
    end

    create_table :feature_flags do |t|
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.string :feature, null: false, limit: 255
      t.string :state, default: "allowed", null: false, limit: 255
      t.timestamps precision: nil

      t.index %i[context_id context_type feature], unique: true, name: "index_feature_flags_on_context_and_feature"
    end

    create_table :folders do |t|
      t.string :name, limit: 255
      t.text :full_name
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.references :parent_folder, foreign_key: { to_table: :folders }
      t.string :workflow_state, null: false, limit: 255
      t.timestamps precision: nil
      t.timestamp :deleted_at
      t.boolean :locked
      t.timestamp :lock_at
      t.timestamp :unlock_at
      t.references :cloned_item
      t.integer :position
      t.string :submission_context_code, limit: 255
      t.string :unique_type
      t.references :root_account, index: false, null: false

      t.replica_identity_index
      t.index [:context_id, :context_type]
      t.index [:context_id, :context_type], unique: true, name: "index_folders_on_context_id_and_context_type_for_root_folders", where: "parent_folder_id IS NULL AND workflow_state<>'deleted'"
      t.index [:submission_context_code, :parent_folder_id], unique: true
      t.index %i[unique_type context_id context_type],
              unique: true,
              where: "unique_type IS NOT NULL AND workflow_state <> 'deleted'"
    end

    execute(<<~SQL) # rubocop:disable Rails/SquishedSQLHeredocs
      CREATE FUNCTION #{connection.quote_table_name("folder_before_insert_verify_active_parent_folder__tr_fn")} () RETURNS trigger AS $$
      DECLARE
        parent_state text;
      BEGIN
        SELECT workflow_state INTO parent_state FROM folders WHERE folders.id = NEW.parent_folder_id FOR SHARE;
        if parent_state = 'deleted' then
          RAISE EXCEPTION 'Cannot create sub-folders in deleted folders --> %', NEW.parent_folder_id;
        end if;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    set_search_path("folder_before_insert_verify_active_parent_folder__tr_fn")

    execute(<<~SQL.squish)
      CREATE TRIGGER folder_before_insert_verify_active_parent_folder__tr
        BEFORE INSERT ON #{Folder.quoted_table_name}
        FOR EACH ROW
        EXECUTE PROCEDURE #{connection.quote_table_name("folder_before_insert_verify_active_parent_folder__tr_fn")}()
    SQL

    create_table :gradebook_csvs do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :attachment, null: false, index: false
      t.references :progress, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true

      t.index [:user_id, :course_id]
    end

    create_table :gradebook_filters do |t|
      t.references :course, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true
      t.string :name, limit: 255, null: false
      t.jsonb :payload, null: false, default: {}
      t.timestamps precision: 6

      t.index [:course_id, :user_id]
    end

    create_table :gradebook_uploads do |t|
      t.timestamps precision: nil
      t.references :course, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true
      t.references :progress, null: false, foreign_key: true
      t.text :gradebook

      t.index [:course_id, :user_id], unique: true
    end

    create_table :grading_period_groups do |t|
      t.references :course, foreign_key: true
      t.references :account, foreign_key: true
      t.timestamps precision: nil
      t.string :workflow_state, default: "active", null: false, limit: 255, index: true
      t.string :title, limit: 255
      t.boolean :weighted
      t.boolean :display_totals_for_all_grading_periods, default: false, null: false
      t.references :root_account, foreign_key: { to_table: :accounts }, index: { where: "root_account_id IS NOT NULL" }
    end

    create_table :grading_periods do |t|
      t.float :weight
      t.timestamp :start_date, null: false
      t.timestamp :end_date, null: false
      t.timestamps precision: nil
      t.string :title, limit: 255
      t.string :workflow_state, default: "active", null: false, limit: 255, index: true
      # someone used change_column instead of change_column_null and
      # accidentally lost the limit: 8 on this foreign key
      # (went from bigint -> int). needs to be fixed.
      t.references :grading_period_group, type: :integer, null: false, foreign_key: true
      t.timestamp :close_date
      t.references :root_account, foreign_key: { to_table: :accounts }
    end

    create_table :grading_standards do |t|
      t.string :title, limit: 255
      t.text :data
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.timestamps precision: nil
      t.references :user, foreign_key: true, index: { where: "user_id IS NOT NULL" }
      t.integer :usage_count
      t.string :context_code, limit: 255, index: true
      t.string :workflow_state, null: false, limit: 255
      t.string :migration_id, limit: 255
      t.integer :version
      t.references :root_account, foreign_key: { to_table: :accounts }
      t.boolean :points_based, default: false, null: false
      t.decimal :scaling_factor, precision: 5, scale: 2, default: 1.0, null: false

      t.index [:context_id, :context_type]
    end

    create_table :group_categories do |t|
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.string :name, limit: 255
      t.string :role, limit: 255, index: true
      t.timestamp :deleted_at
      t.string :self_signup, limit: 255
      t.integer :group_limit
      t.string :auto_leader, limit: 255
      t.timestamps null: true, precision: nil
      t.string :sis_source_id
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.references :sis_batch, foreign_key: true

      t.replica_identity_index
      t.index [:context_id, :context_type], name: "index_group_categories_on_context"
      t.index [:root_account_id, :sis_source_id], where: "sis_source_id IS NOT NULL", unique: true
    end

    create_table :groups do |t|
      t.string :name, limit: 255
      t.string :workflow_state, null: false, limit: 255
      t.timestamps precision: nil
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.string :category, limit: 255
      t.integer :max_membership
      t.boolean :is_public
      t.references :account, null: false, foreign_key: true
      t.references :wiki, foreign_key: true, index: { where: "wiki_id IS NOT NULL" }
      t.timestamp :deleted_at
      t.string :join_level, limit: 255
      t.string :default_view, default: "feed", limit: 255
      t.string :migration_id, limit: 255
      t.bigint :storage_quota
      t.string :uuid, null: false, limit: 255, index: { unique: true }
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.string :sis_source_id, limit: 255
      t.references :sis_batch, foreign_key: true, index: { where: "sis_batch_id IS NOT NULL" }
      t.text :stuck_sis_fields
      t.references :group_category, foreign_key: true
      t.text :description
      t.references :avatar_attachment, index: false
      t.references :leader, foreign_key: { to_table: :users }, index: { where: "leader_id IS NOT NULL" }
      t.string :lti_context_id, limit: 255

      t.replica_identity_index
      t.index [:context_id, :context_type]
      t.index [:sis_source_id, :root_account_id], where: "sis_source_id IS NOT NULL", unique: true
    end

    create_table :group_memberships do |t|
      t.references :group, null: false, foreign_key: true
      t.string :workflow_state, null: false, limit: 255, index: true
      t.timestamps precision: nil
      t.references :user, null: false, foreign_key: true
      t.string :uuid, null: false, limit: 255, index: { unique: true }
      t.references :sis_batch, foreign_key: true, index: { where: "sis_batch_id IS NOT NULL" }
      t.boolean :moderator
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false

      t.replica_identity_index
      t.index [:group_id, :user_id], unique: true, where: "workflow_state <> 'deleted'"
    end

    create_table :group_and_membership_importers do |t|
      t.references :group_category, null: false, foreign_key: true
      t.references :attachment, foreign_key: true, index: { where: "attachment_id IS NOT NULL" }
      t.string :workflow_state, null: false, default: "active"
      t.timestamps precision: nil
    end

    create_table :ignores do |t|
      t.references :asset, polymorphic: { limit: 255 }, null: false, index: false
      t.references :user, null: false, foreign_key: true
      t.string :purpose, null: false, limit: 255
      t.boolean :permanent, null: false, default: false
      t.timestamps precision: nil

      t.index %i[asset_id asset_type user_id purpose], unique: true, name: "index_ignores_on_asset_and_user_id_and_purpose"
    end

    create_table :late_policies do |t|
      t.references :course, null: false, foreign_key: true, index: { unique: true }
      t.boolean :missing_submission_deduction_enabled, null: false, default: false
      t.decimal :missing_submission_deduction, precision: 5, scale: 2, null: false, default: 100
      t.boolean :late_submission_deduction_enabled, null: false, default: false
      t.decimal :late_submission_deduction, precision: 5, scale: 2, null: false, default: 0
      t.string :late_submission_interval, limit: 16, null: false, default: "day"
      t.boolean :late_submission_minimum_percent_enabled, null: false, default: false
      t.decimal :late_submission_minimum_percent, precision: 5, scale: 2, null: false, default: 0
      t.timestamps precision: nil
      t.references :root_account, foreign_key: { to_table: :accounts }
    end

    create_table :learning_outcomes do |t|
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.string :short_description, null: false, limit: 255
      t.string :context_code, limit: 255
      t.text :description
      t.text :data
      t.string :workflow_state, null: false, limit: 255
      t.timestamps precision: nil
      t.string :migration_id, limit: 255
      t.string :vendor_guid, limit: 255, index: true
      t.string :low_grade, limit: 255
      t.string :high_grade, limit: 255
      t.string :display_name, limit: 255
      t.string :calculation_method, limit: 255
      t.integer :calculation_int, limit: 2
      t.string :vendor_guid_2, limit: 255, index: true
      t.string :migration_id_2, limit: 255
      t.references :outcome_import, index: false
      t.bigint :root_account_ids, array: true, index: { using: :gin }
      t.references :copied_from_outcome, index: { where: "copied_from_outcome_id IS NOT NULL" }
      t.timestamp :archived_at, precision: 6, default: nil

      t.index [:context_id, :context_type]
    end

    create_table :learning_outcome_groups do |t|
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.string :title, null: false, limit: 255
      t.references :learning_outcome_group, foreign_key: true, index: { where: "learning_outcome_group_id IS NOT NULL" }
      t.references :root_learning_outcome_group,
                   foreign_key: { to_table: :learning_outcome_groups },
                   index: { where: "root_learning_outcome_group_id IS NOT NULL" }
      t.string :workflow_state, null: false, limit: 255
      t.text :description
      t.timestamps precision: nil
      t.string :migration_id, limit: 255
      t.string :vendor_guid, limit: 255, index: true
      t.string :low_grade, limit: 255
      t.string :high_grade, limit: 255
      t.string :vendor_guid_2, limit: 255, index: true
      t.string :migration_id_2, limit: 255
      t.references :outcome_import, index: false
      t.references :root_account, foreign_key: { to_table: :accounts }
      t.references :source_outcome_group,
                   index: { where: "source_outcome_group_id IS NOT NULL" },
                   foreign_key: { to_table: :learning_outcome_groups }
      t.timestamp :archived_at, precision: 6, default: nil

      t.index [:context_id, :context_type]
      t.index %i[context_type context_id vendor_guid_2], name: "index_learning_outcome_groups_on_context_and_vendor_guid"
    end

    create_table :learning_outcome_question_results do |t|
      t.references :learning_outcome_result, index: { name: "index_LOQR_on_learning_outcome_result_id" }
      t.references :learning_outcome
      t.bigint :associated_asset_id
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
      t.timestamp :assessed_at
      t.timestamps precision: nil
      t.timestamp :submitted_at
      t.references :root_account, foreign_key: { to_table: :accounts }
    end

    create_table :learning_outcome_results do |t|
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.string :context_code, limit: 255
      t.bigint :association_id
      t.string :association_type, limit: 255
      t.references :content_tag, foreign_key: true
      t.references :learning_outcome, foreign_key: true, index: { where: "learning_outcome_id IS NOT NULL" }
      t.boolean :mastery
      t.references :user, foreign_key: true, index: false
      t.float :score
      t.timestamps precision: nil
      t.integer :attempt
      t.float :possible
      t.float :original_score
      t.float :original_possible
      t.boolean :original_mastery
      t.bigint :artifact_id
      t.string :artifact_type, limit: 255
      t.timestamp :assessed_at
      t.string :title, limit: 255
      t.float :percent
      t.bigint :associated_asset_id
      t.string :associated_asset_type, limit: 255
      t.timestamp :submitted_at
      t.boolean :hide_points, default: false, null: false
      t.boolean :hidden, default: false, null: false
      t.string :user_uuid, limit: 255
      t.references :root_account, foreign_key: { to_table: :accounts }
      t.string :workflow_state, default: "active", null: false

      t.index %i[user_id content_tag_id association_id association_type associated_asset_id associated_asset_type],
              unique: true,
              name: "index_learning_outcome_results_association"
      t.index [:artifact_id, :artifact_type], name: "lor_artifact_id_idx"
    end

    create_table :live_assessments_assessments do |t|
      t.string :key, null: false, limit: 255
      t.string :title, null: false, limit: 255
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.timestamps precision: nil

      t.index %i[context_id context_type key], unique: true, name: "index_live_assessments"
    end

    create_table :live_assessments_results do |t|
      t.references :user, null: false
      t.references :assessor, null: false, foreign_key: { to_table: :users }
      t.references :assessment, null: false, foreign_key: { to_table: :live_assessments_assessments }, index: false
      t.boolean :passed, null: false
      t.timestamp :assessed_at, null: false

      t.index [:assessment_id, :user_id]
    end

    create_table :live_assessments_submissions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :assessment, null: false, foreign_key: { to_table: :live_assessments_assessments }, index: false
      t.float :possible
      t.float :score
      t.timestamp :assessed_at
      t.timestamps precision: nil

      t.index [:assessment_id, :user_id], unique: true
    end

    create_table :lti_ims_registrations do |t|
      t.jsonb :lti_tool_configuration, null: false
      t.references :developer_key, null: false, foreign_key: true
      t.string :application_type, null: false
      t.text :grant_types, array: true, default: [], null: false
      t.text :response_types, array: true, default: [], null: false
      t.text :redirect_uris, array: true, default: [], null: false
      t.text :initiate_login_uri, null: false
      t.string :client_name, null: false
      t.text :jwks_uri, null: false
      t.text :logo_uri
      t.string :token_endpoint_auth_method, null: false
      t.string :contacts, array: true, default: [], null: false, limit: 255
      t.text :client_uri
      t.text :policy_uri
      t.text :tos_uri
      t.text :scopes, array: true, default: [], null: false
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.timestamps precision: 6
      t.string :guid
      t.jsonb :registration_overlay, default: {}

      t.replica_identity_index
    end

    create_table :lti_line_items do |t|
      t.float :score_maximum, null: false
      t.string :label, null: false
      t.string :resource_id, index: true
      t.string :tag, index: true
      t.references :lti_resource_link, foreign_key: true
      t.references :assignment, null: false, foreign_key: true
      t.timestamps precision: nil
      t.bigint :client_id, null: false, index: true
      t.string :workflow_state, default: "active", null: false, index: true
      t.jsonb :extensions, default: {}
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.boolean :coupled, default: true, null: false
      t.timestamp :end_date_time

      t.replica_identity_index
    end

    create_table :lti_links do |t|
      t.string :resource_link_id, null: false, index: { unique: true }
      t.string :vendor_code, null: false
      t.string :product_code, null: false
      t.string :resource_type_code, null: false
      t.bigint :linkable_id
      t.string :linkable_type
      t.text :custom_parameters
      t.text :resource_url
      t.timestamps precision: nil

      t.index [:linkable_id, :linkable_type]
    end

    create_table :lti_message_handlers do |t|
      t.string :message_type, null: false, limit: 255
      t.string :launch_path, null: false, limit: 255
      t.text :capabilities
      t.text :parameters
      t.references :resource_handler,
                   null: false,
                   foreign_key: { to_table: :lti_resource_handlers },
                   index: false
      t.timestamps precision: nil
      t.references :tool_proxy, foreign_key: { to_table: :lti_tool_proxies }

      t.index [:resource_handler_id, :message_type],
              name: "index_lti_message_handlers_on_resource_handler_and_type",
              unique: true
    end

    create_table :lti_product_families do |t|
      t.string :vendor_code, null: false, limit: 255
      t.string :product_code, null: false, limit: 255
      t.string :vendor_name, null: false, limit: 255
      t.text :vendor_description
      t.string :website, limit: 255
      t.string :vendor_email, limit: 255
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }
      t.timestamps precision: nil
      t.references :developer_key

      t.index %i[product_code vendor_code root_account_id developer_key_id],
              unique: true,
              name: "product_family_uniqueness"
    end

    create_table :lti_resource_handlers do |t|
      t.string :resource_type_code, null: false, limit: 255
      t.string :placements, limit: 255
      t.string :name, null: false, limit: 255
      t.text :description
      t.text :icon_info
      t.references :tool_proxy,
                   null: false,
                   foreign_key: { to_table: :lti_tool_proxies },
                   index: false
      t.timestamps precision: nil

      t.index [:tool_proxy_id, :resource_type_code],
              name: "index_lti_resource_handlers_on_tool_proxy_and_type_code",
              unique: true
    end

    create_table :lti_resource_links do |t|
      t.timestamps precision: nil
      t.references :context_external_tool, null: false, foreign_key: { to_table: :context_external_tools }
      t.string :workflow_state, default: "active", null: false, index: true
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.bigint :context_id, null: false
      t.string :context_type, limit: 255, null: false
      t.jsonb :custom
      t.uuid :lookup_uuid, null: false
      t.uuid :resource_link_uuid, null: false, index: { unique: true }
      t.string :url
      t.string :lti_1_1_id, index: { unique: true, where: "lti_1_1_id IS NOT NULL" }
      t.string :title

      t.replica_identity_index
      t.index [:context_id, :context_type], name: "index_lti_resource_links_by_context_id_context_type"
      t.index %i[lookup_uuid context_id context_type],
              unique: true,
              name: "index_lti_resource_links_unique_lookup_uuid_on_context"
    end

    create_table :lti_resource_placements do |t|
      t.string :placement, null: false, limit: 255
      t.timestamps precision: nil
      t.references :message_handler,
                   foreign_key: { to_table: :lti_message_handlers },
                   index: { where: "message_handler_id IS NOT NULL" }

      t.index [:placement, :message_handler_id],
              unique: true,
              where: "message_handler_id IS NOT NULL",
              name: "index_resource_placements_on_placement_and_message_handler"
    end

    create_table :lti_results do |t|
      t.float :result_score
      t.float :result_maximum
      t.text :comment
      t.string :activity_progress
      t.string :grading_progress
      t.references :lti_line_item, null: false, foreign_key: true
      t.references :submission, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps precision: nil
      t.string :workflow_state, default: "active", null: false, index: true
      t.jsonb :extensions, default: {}
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false

      t.replica_identity_index
      t.index %i[lti_line_item_id user_id], unique: true
    end

    create_table :lti_tool_configurations do |t|
      t.references :developer_key, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :settings, null: false
      t.timestamps precision: nil
      t.string :disabled_placements, array: true, default: []
      t.string :privacy_level
    end

    create_table :lti_tool_consumer_profiles do |t|
      t.text :services
      t.text :capabilities
      t.string :uuid, null: false, index: { unique: true }
      t.references :developer_key, null: false, foreign_key: true, index: { unique: true }
      t.timestamps precision: nil
    end

    create_table :lti_tool_proxies do |t|
      t.text :shared_secret, null: false
      t.string :guid, null: false, limit: 255, index: true
      t.string :product_version, null: false, limit: 255
      t.string :lti_version, null: false, limit: 255
      t.references :product_family, null: false, foreign_key: { to_table: :lti_product_families }
      t.bigint :context_id, null: false
      t.string :workflow_state, null: false, limit: 255
      t.text :raw_data, null: false
      t.timestamps precision: nil
      # NOTE: I think the original migration didn't want this to remain the
      # default, but they didn't remove it properly, so it still is.
      t.string :context_type, null: false, default: "Account", limit: 255
      t.string :name, limit: 255
      t.text :description
      t.text :update_payload
      t.text :registration_url
      t.string :subscription_id
    end

    create_table :lti_tool_proxy_bindings do |t|
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.references :tool_proxy, null: false, foreign_key: { to_table: :lti_tool_proxies }
      t.timestamps precision: nil
      t.boolean :enabled, null: false, default: true

      t.index %i[context_id context_type tool_proxy_id], name: "index_lti_tool_proxy_bindings_on_context_and_tool_proxy", unique: true
    end

    create_table :lti_tool_settings do |t|
      t.references :tool_proxy, index: false
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.text :resource_link_id
      t.text :custom
      t.timestamps precision: nil
      t.string :product_code
      t.string :vendor_code
      t.string :resource_type_code
      t.text :custom_parameters
      t.text :resource_url

      t.index %i[resource_link_id context_type context_id tool_proxy_id], name: "index_lti_tool_settings_on_link_context_and_tool_proxy", unique: true
    end

    create_table :master_courses_child_content_tags do |t|
      # mainly for bulk loading on import
      t.references :child_subscription,
                   null: false,
                   foreign_key: { to_table: :master_courses_child_subscriptions },
                   index: { name: "index_child_content_tags_on_subscription" }
      t.references :content,
                   polymorphic: { limit: 255 },
                   null: false,
                   index: { unique: true, name: "index_child_content_tags_on_content" }
      t.text :downstream_changes
      t.string :migration_id, index: { name: "index_child_content_tags_on_migration_id" }
      t.references :root_account, foreign_key: { to_table: :accounts }

      t.index [:child_subscription_id, :migration_id],
              opclass: { migration_id: :text_pattern_ops },
              name: "index_mc_child_content_tags_on_sub_and_migration_id_pattern_ops"
    end

    create_table :master_courses_child_subscriptions do |t|
      t.references :master_template, null: false, foreign_key: { to_table: :master_courses_master_templates }
      # we may have to drop this foreign key at some point for cross-shard subscriptions
      t.references :child_course,
                   foreign_key: { to_table: :courses },
                   null: false,
                   index: { name: "index_child_subscriptions_on_child_course_id" }
      t.string :workflow_state, null: false, limit: 255
      # we can use this to keep track of which subscriptions are new
      # vs. which ones have been getting regular updates and we can use a selective copy for
      t.boolean :use_selective_copy, null: false, default: false
      t.timestamps precision: nil
      t.references :root_account, foreign_key: { to_table: :accounts }

      t.index [:master_template_id, :child_course_id],
              unique: true,
              where: "workflow_state <> 'deleted'",
              name: "index_mc_child_subscriptions_on_template_id_and_course_id"
    end

    create_table :master_courses_master_content_tags do |t|
      t.references :master_template, null: false, foreign_key: { to_table: :master_courses_master_templates }
      # should we add a workflow state and make this soft-deletable?
      # maybe someday if we decide to use these to define the template content aets
      t.references :content, polymorphic: { limit: 255 }, null: false, index: false
      # when we export an object for a master migration we'll set this column on the tag
      # when we update the content we'll erase this
      # so now we'll know what's been updated since the last successful export
      t.references :current_migration,
                   foreign_key: { to_table: :master_courses_master_migrations },
                   index: { where: "current_migration_id IS NOT NULL",
                            name: "index_master_content_tags_on_current_migration_id" }
      t.text :restrictions # we might not leave this at settings/content
      t.string :migration_id, index: { unique: true, name: "index_master_content_tags_on_migration_id" }
      t.boolean :use_default_restrictions, default: false, null: false
      t.references :root_account, foreign_key: { to_table: :accounts }

      t.index %i[master_template_id content_type content_id],
              unique: true,
              name: "index_master_content_tags_on_template_id_and_content"
    end

    create_table :master_courses_master_migrations do |t|
      t.references :master_template, null: false, foreign_key: { to_table: :master_courses_master_templates }
      t.references :user, index: false # exports use a bunch of terrible user-dependent stuff
      # we can just use serialized columns here to store the rest of the data
      # instead of a million rows
      # since we won't really be needing any of it separately
      t.text :export_results # we can store the initial export details here
      t.timestamp :exports_started_at
      t.timestamp :imports_queued_at
      t.string :workflow_state, null: false, limit: 255
      t.timestamps precision: nil
      t.timestamp :imports_completed_at
      t.text :comment
      t.boolean :send_notification, default: false, null: false
      t.text :migration_settings
      t.references :root_account, foreign_key: { to_table: :accounts }
    end

    create_table :master_courses_master_templates do |t|
      t.references :course, null: false, foreign_key: true
      t.boolean :full_course, null: false, default: true # we may not ever get around to allowing selective collection sets out but just in case
      t.string :workflow_state, limit: 255
      t.timestamps precision: nil
      # due to paranoia about race conditions around trying to make multiple migrations at once
      # we'll lock the template before we create the migration
      # and mark this column with the new migration unless there's already a currently running one, in which case we'll abort
      t.references :active_migration,
                   foreign_key: { to_table: :master_courses_master_migrations },
                   index: { where: "active_migration_id IS NOT NULL" }
      t.text :default_restrictions
      t.boolean :use_default_restrictions_by_type, default: false, null: false
      t.text :default_restrictions_by_type
      t.references :root_account, foreign_key: { to_table: :accounts }

      t.index :course_id,
              unique: true,
              where: "full_course AND workflow_state <> 'deleted'",
              name: "index_master_templates_unique_on_course_and_full"
    end

    create_table :master_courses_migration_results do |t|
      t.references :master_migration,
                   null: false,
                   foreign_key: { to_table: :master_courses_master_migrations },
                   index: false
      t.references :content_migration, null: false, foreign_key: true
      t.references :child_subscription, null: false, foreign_key: { to_table: :master_courses_child_subscriptions }
      t.string :import_type, null: false
      t.string :state, null: false
      t.text :results
      t.references :root_account, foreign_key: { to_table: :accounts }

      t.index [:master_migration_id, :state],
              name: "index_mc_migration_results_on_master_mig_id_and_state"
      t.index [:master_migration_id, :content_migration_id],
              unique: true,
              name: "index_mc_migration_results_on_master_and_content_migration_ids"
    end

    create_table :media_objects do |t|
      t.references :user, foreign_key: true, index: { where: "user_id IS NOT NULL" }
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.string :workflow_state, null: false, limit: 255
      t.string :user_type, limit: 255
      t.string :title, limit: 255
      t.string :user_entered_title, limit: 255
      t.string :media_id, null: false, limit: 255, index: true
      t.string :media_type, limit: 255
      t.integer :duration
      t.integer :max_size
      t.references :root_account, foreign_key: { to_table: :accounts }
      t.text :data
      t.timestamps precision: nil
      t.references :attachment
      t.integer :total_size
      t.string :old_media_id, limit: 255, index: true

      t.index [:context_id, :context_type]
    end

    create_table :media_tracks do |t|
      t.references :user, index: false
      t.references :media_object, null: false, index: false
      t.string :kind, default: "subtitles", limit: 255
      t.string :locale, default: "en", limit: 255
      t.text :content, null: false
      t.timestamps precision: nil
      t.text :webvtt_content
      t.references :attachment, index: false

      t.index [:media_object_id, :locale], name: "media_object_id_locale"
      t.index [:attachment_id, :locale], where: "attachment_id IS NOT NULL", unique: true
    end

    create_table :mentions do |t|
      t.references :discussion_entry, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.string :workflow_state, default: "active", null: false, limit: 255
      t.timestamps precision: 6

      t.replica_identity_index
    end

    create_table :messages do |t|
      t.text :to
      t.text :from
      t.text :subject
      t.text :body
      t.integer :delay_for, default: 120
      t.timestamp :dispatch_at
      t.timestamp :sent_at, index: { where: "sent_at IS NOT NULL" }
      t.string :workflow_state, limit: 255
      t.text :transmission_errors
      t.boolean :is_bounced
      t.references :notification
      t.references :communication_channel
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.references :user, index: false
      t.timestamps null: true, precision: nil
      t.string :notification_name, limit: 255
      t.text :url
      t.string :path_type, limit: 255
      t.text :from_name
      t.boolean :to_email
      t.text :html_body
      t.references :root_account
      t.string :reply_to_name, limit: 255

      t.index %i[context_id context_type notification_name to user_id], name: "existing_undispatched_message"
      t.index %i[user_id to_email dispatch_at], name: "index_messages_user_id_dispatch_at_to_email"
      t.index :created_at
    end

    create_table :microsoft_sync_groups do |t|
      t.references :course, foreign_key: true, index: { unique: true }, null: false
      t.string :workflow_state, null: false, default: "pending"
      t.string :job_state
      t.timestamp :last_synced_at
      t.timestamp :last_manually_synced_at
      t.text :last_error
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.timestamps precision: 6
      t.string :ms_group_id
      t.references :last_error_report, index: false
      t.text :debug_info

      t.replica_identity_index
    end

    create_table :microsoft_sync_partial_sync_changes do |t|
      t.references :course, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.string :enrollment_type, null: false
      t.timestamps precision: 6

      t.replica_identity_index
      t.index %i[course_id user_id enrollment_type],
              unique: true,
              name: "index_microsoft_sync_partial_sync_changes_course_user_enroll"
    end

    create_table :microsoft_sync_user_mappings do |t|
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.references :user, null: false, foreign_key: true, index: false
      t.string :aad_id
      t.timestamps precision: 6
      t.boolean :needs_updating, default: false, null: false

      t.replica_identity_index
      t.index [:user_id, :root_account_id], unique: true, name: "index_microsoft_sync_user_mappings_ra_id_user_id"
    end

    create_table :migration_issues do |t|
      t.references :content_migration, null: false, foreign_key: true
      t.text :description
      t.string :workflow_state, null: false, limit: 255
      t.text :fix_issue_html_url
      t.string :issue_type, null: false, limit: 255
      t.references :error_report, index: false
      t.text :error_message
      t.timestamps precision: nil
    end

    create_table :moderation_graders do |t|
      t.string :anonymous_id, limit: 5, null: false
      t.references :assignment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true, index: false
      t.timestamps precision: nil
      t.boolean :slot_taken, default: true, null: false

      t.index [:assignment_id, :anonymous_id], unique: true
      t.index [:user_id, :assignment_id], unique: true
    end

    create_table :moderated_grading_provisional_grades do |t|
      t.string :grade, limit: 255
      t.float :score
      t.timestamp :graded_at
      t.references :scorer, null: false, foreign_key: { to_table: :users }
      t.references :submission, null: false, foreign_key: true
      t.timestamps precision: nil
      t.boolean :final, null: false, default: false
      t.references :source_provisional_grade,
                   foreign_key: { to_table: :moderated_grading_provisional_grades,
                                  name: "provisional_grades_source_provisional_grade_fk" },
                   index: { where: "source_provisional_grade_id IS NOT NULL",
                            name: "index_provisional_grades_on_source_grade" }
      t.boolean :graded_anonymously

      t.index :submission_id,
              unique: true,
              where: "final = TRUE",
              name: "idx_mg_provisional_grades_unique_submission_when_final"
      t.index [:submission_id, :scorer_id],
              unique: true,
              name: "idx_mg_provisional_grades_unique_sub_scorer_when_not_final",
              where: "final = FALSE"
    end

    create_table :moderated_grading_selections do |t|
      t.references :assignment, null: false, foreign_key: true, index: false
      t.references :student, null: false, foreign_key: {  to_table: :users }
      t.references :selected_provisional_grade,
                   foreign_key: { to_table: :moderated_grading_provisional_grades },
                   index: { where: "selected_provisional_grade_id IS NOT NULL",
                            name: "index_moderated_grading_selections_on_selected_grade" }
      t.timestamps precision: nil

      t.index [:assignment_id, :student_id],
              unique: true,
              name: "idx_mg_selections_unique_on_assignment_and_student"
    end

    create_table :notification_endpoints do |t|
      t.references :access_token, null: false, foreign_key: true
      t.string :token, null: false, limit: 255
      t.string :arn, null: false, limit: 255
      t.timestamps precision: nil
      t.string :workflow_state, default: "active", null: false, index: true

      t.index [:access_token_id, :arn],
              where: "workflow_state='active'",
              unique: true
    end

    create_table :notifications do |t|
      t.string :name, limit: 255, index: { unique: true, name: "index_notifications_unique_on_name" }
      t.string :subject, limit: 255
      t.string :category, limit: 255
      t.integer :delay_for, default: 120
      t.timestamps precision: nil
      t.string :main_link, limit: 255
      t.boolean :priority, default: false, null: false
    end

    create_table :notification_policies do |t|
      t.references :notification
      t.references :communication_channel, null: false, foreign_key: true, index: false
      t.string :frequency, default: "immediately", null: false, limit: 255
      t.timestamps precision: nil

      t.index [:communication_channel_id, :notification_id], unique: true, name: "index_notification_policies_on_cc_and_notification_id"
    end

    create_table :notification_policy_overrides do |t|
      t.references :context,
                   polymorphic: { default: "Course" },
                   null: false,
                   index: { name: "index_notification_policy_overrides_on_context" }
      t.references :communication_channel, null: false, foreign_key: true
      t.references :notification
      t.string :workflow_state, default: "active", null: false
      t.string :frequency
      t.timestamps precision: nil

      t.index %i[communication_channel_id notification_id],
              name: "index_notification_policies_overrides_on_cc_id_and_notification"
      t.index %i[context_id context_type communication_channel_id notification_id],
              where: "notification_id IS NOT NULL",
              unique: true,
              name: "index_notification_policies_overrides_uniq_context_notification"
      t.index %i[context_id context_type communication_channel_id],
              where: "notification_id IS NULL",
              unique: true,
              name: "index_notification_policies_overrides_uniq_context_and_cc"
    end

    create_table :oauth_requests do |t|
      t.string :token, limit: 255
      t.string :secret, limit: 255
      t.string :user_secret, limit: 255
      t.string :return_url, limit: 4.kilobytes
      t.string :workflow_state, limit: 255
      t.references :user, foreign_key: true, index: { where: "user_id IS NOT NULL" }
      t.string :original_host_with_port, limit: 255
      t.string :service, limit: 255
      t.timestamps precision: nil
    end

    create_table :observer_alert_thresholds do |t|
      t.string :alert_type, null: false
      t.string :threshold
      t.string :workflow_state, default: "active", null: false
      t.timestamps precision: nil
      t.references :user, null: false, foreign_key: true
      t.references :observer, null: false, foreign_key: { to_table: :users }

      t.index %i[alert_type user_id observer_id], unique: true, name: "observer_alert_thresholds_on_alert_type_and_observer_and_user"
    end

    create_table :observer_alerts do |t|
      t.references :observer_alert_threshold, null: false, foreign_key: true
      t.references :context, polymorphic: true, index: { name: "index_observer_alerts_on_context_type_and_context_id" }
      t.string :alert_type, null: false
      t.string :workflow_state, default: "unread", null: false, index: true
      t.timestamp :action_date, null: false
      t.string :title, null: false
      t.timestamps precision: nil
      t.references :user, null: false, foreign_key: true
      t.references :observer, null: false, foreign_key: { to_table: :users }
    end

    create_table :observer_pairing_codes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :code, null: false, limit: 10
      t.timestamp :expires_at, null: false, index: true
      t.string :workflow_state, default: "active", null: false
      t.timestamps precision: nil
    end

    create_table :one_time_passwords do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :code, null: false
      t.boolean :used, null: false, default: false
      t.timestamps precision: nil

      t.index [:user_id, :code], unique: true
    end

    create_table :originality_reports do |t|
      t.references :attachment
      t.float :originality_score
      t.references :originality_report_attachment
      t.text :originality_report_url
      t.text :originality_report_lti_url
      t.timestamps precision: nil
      t.references :submission, null: false, foreign_key: true
      t.string :workflow_state, null: false, default: "pending", index: true
      t.text :link_id
      t.text :error_message
      t.timestamp :submission_time, index: true
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false

      t.replica_identity_index
    end

    create_table :outcome_calculation_methods do |t|
      t.references :context,
                   polymorphic: { limit: 255 },
                   null: false,
                   index: { unique: true, name: "index_outcome_calculation_methods_on_context" }
      t.integer :calculation_int, limit: 2
      t.string :calculation_method, null: false, limit: 255
      t.string :workflow_state, null: false, default: "active"
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }
      t.timestamps precision: nil
    end

    create_table :outcome_friendly_descriptions do |t|
      t.references :context, polymorphic: { limit: 255 }, null: false, index: false
      t.string :workflow_state, null: false, default: "active"
      t.references :root_account, foreign_key: { to_table: :accounts }
      t.text :description, null: false
      t.timestamps precision: nil
      t.references :learning_outcome, null: false, foreign_key: true

      t.index %i[context_type context_id learning_outcome_id], unique: true, name: "index_outcome_friendly_description_on_context_and_outcome"
    end

    create_table :outcome_imports do |t|
      t.string :workflow_state, null: false
      t.bigint :context_id, null: false
      t.string :context_type, null: false
      t.references :user, foreign_key: true
      t.references :attachment, foreign_key: true
      t.integer :progress
      t.timestamp :ended_at
      t.timestamps precision: nil
      t.json :data
      t.references :learning_outcome_group

      t.index %i[context_type context_id]
    end

    create_table :outcome_import_errors do |t|
      t.references :outcome_import, null: false, foreign_key: true
      t.string :message, null: false, limit: 255
      t.timestamps precision: nil
      t.integer :row
      t.boolean :failure, default: false, null: false
    end

    create_table :outcome_proficiencies do |t|
      t.timestamps precision: nil
      t.references :root_account, foreign_key: { to_table: :accounts }
      t.bigint :context_id, null: false
      t.string :context_type, limit: 255, null: false
      t.string :workflow_state, default: "active", null: false

      t.index [:context_id, :context_type],
              unique: true,
              where: "context_id IS NOT NULL"
    end

    create_table :outcome_proficiency_ratings do |t|
      t.references :outcome_proficiency, null: false, foreign_key: true
      t.string :description, null: false, limit: 255
      t.float :points, null: false
      t.boolean :mastery, null: false
      t.string :color, null: false
      t.timestamps precision: nil
      t.references :root_account, foreign_key: { to_table: :accounts }
      t.string :workflow_state, default: "active", null: false

      t.index [:outcome_proficiency_id, :points],
              name: "index_outcome_proficiency_ratings_on_proficiency_and_points"
    end

    create_table :page_comments do |t|
      t.text :message
      t.bigint :page_id
      t.string :page_type, limit: 255
      t.references :user, foreign_key: true
      t.timestamps precision: nil

      t.index [:page_id, :page_type]
    end

    create_table :page_views, id: false do |t|
      t.primary_keys [:request_id]

      t.string :request_id, limit: 255
      t.string :session_id, limit: 255
      t.references :user, null: false, foreign_key: true, index: false
      t.text :url
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.bigint :asset_id
      t.string :asset_type, limit: 255
      t.string :controller, limit: 255
      t.string :action, limit: 255
      t.float :interaction_seconds
      t.timestamps precision: nil
      t.references :developer_key, index: false
      t.boolean :user_request
      t.float :render_time
      t.text :user_agent
      t.references :asset_user_access, index: { name: "index_page_views_asset_user_access_id" }
      t.boolean :participated
      t.boolean :summarized
      t.references :account, index: false
      t.references :real_user, foreign_key: { to_table: :users }, index: { where: "real_user_id IS NOT NULL" }
      t.string :http_method, limit: 255
      t.string :remote_ip, limit: 255

      t.index [:account_id, :created_at]
      t.index [:context_type, :context_id]
      t.index [:summarized, :created_at], name: "index_page_views_summarized_created_at"
      t.index [:user_id, :created_at]
    end

    create_table :parallel_importers do |t|
      t.references :sis_batch, null: false, foreign_key: true
      t.string :workflow_state, null: false, limit: 255
      t.bigint :index, null: false
      t.bigint :batch_size, null: false
      t.timestamps precision: nil
      t.timestamp :started_at
      t.timestamp :ended_at
      t.string :importer_type, null: false, limit: 255
      t.references :attachment, null: false, foreign_key: true
      t.integer :rows_processed, default: 0, null: false
      t.bigint :job_ids, array: true, default: [], null: false
    end

    create_table :planner_notes do |t|
      t.timestamp :todo_date, null: false
      t.string :title, null: false
      t.text :details
      t.references :user, null: false, foreign_key: true
      t.references :course, index: false
      t.string :workflow_state, null: false
      t.timestamps precision: nil
      t.references :linked_object, polymorphic: true, index: false

      t.index %i[user_id linked_object_id linked_object_type],
              where: "linked_object_id IS NOT NULL AND workflow_state<>'deleted'",
              unique: true,
              name: "index_planner_notes_on_user_id_and_linked_object"
    end

    create_table :planner_overrides do |t|
      t.references :plannable, polymorphic: true, null: false, index: false
      t.references :user, null: false, foreign_key: true
      t.string :workflow_state
      t.boolean :marked_complete, null: false, default: false
      t.timestamp :deleted_at
      t.timestamps precision: nil
      t.boolean :dismissed, default: false, null: false

      t.index %i[plannable_type plannable_id user_id], unique: true, name: "index_planner_overrides_on_plannable_and_user"
    end

    create_table :plugin_settings do |t|
      t.string :name, default: "", null: false, limit: 255, index: true
      t.text :settings
      t.timestamps precision: nil
      t.boolean :disabled
    end

    create_table :polling_polls do |t|
      t.string :question, limit: 255
      t.string :description, limit: 255
      t.timestamps precision: nil
      t.references :user, null: false, foreign_key: true
    end

    create_table :polling_poll_choices do |t|
      t.string :text, limit: 255
      t.boolean :is_correct, null: false, default: false
      t.references :poll, null: false, foreign_key: { to_table: :polling_polls }
      t.timestamps precision: nil
      t.integer :position
    end

    create_table :polling_poll_sessions do |t|
      t.boolean :is_published, null: false, default: false
      t.boolean :has_public_results, null: false, default: false
      t.references :course, null: false, foreign_key: true
      t.references :course_section, foreign_key: true
      t.references :poll, null: false
      t.timestamps precision: nil
    end

    create_table :polling_poll_submissions do |t|
      t.references :poll, null: false, foreign_key: { to_table: :polling_polls }
      t.references :poll_choice, null: false, foreign_key: { to_table: :polling_poll_choices }
      t.references :user, null: false, foreign_key: true
      t.timestamps precision: nil
      t.references :poll_session, null: false, foreign_key: { to_table: :polling_poll_sessions }
    end

    create_table :post_policies do |t|
      t.boolean :post_manually, null: false, default: false
      t.references :course, foreign_key: true
      t.references :assignment, foreign_key: true
      t.index [:course_id, :assignment_id], unique: true
      t.timestamps precision: nil
      t.references :root_account, foreign_key: { to_table: :accounts }
    end

    create_table :profiles do |t|
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.references :context,
                   polymorphic: { limit: 255 },
                   null: false,
                   index: { unique: true, name: "index_profiles_on_context_type_and_context_id" }
      t.string :title, limit: 255
      t.string :path, limit: 255
      t.text :description
      t.text :data
      t.string :visibility, limit: 255
      t.integer :position

      t.index [:root_account_id, :path], unique: true
    end

    create_table :progresses do |t|
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.references :user, index: false
      t.string :tag, null: false, limit: 255
      t.float :completion
      t.string :delayed_job_id, limit: 255
      t.string :workflow_state, null: false, limit: 255
      t.timestamps precision: nil
      t.text :message
      t.string :cache_key_context, limit: 255
      t.text :results

      t.index [:context_id, :context_type]
    end

    create_table :pseudonyms do |t|
      t.references :user, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true, index: false
      t.string :workflow_state, null: false, limit: 255
      t.string :unique_id, null: false, limit: 255
      t.string :crypted_password, null: false, limit: 255
      t.string :password_salt, null: false, limit: 255
      t.string :persistence_token, null: false, limit: 255, index: true
      t.string :single_access_token, null: false, limit: 255, index: true
      t.string :perishable_token, null: false, limit: 255
      t.integer :login_count, default: 0, null: false
      t.integer :failed_login_count, default: 0, null: false
      t.timestamp :last_request_at
      t.timestamp :last_login_at
      t.timestamp :current_login_at
      t.string :last_login_ip, limit: 255
      t.string :current_login_ip, limit: 255
      t.string :reset_password_token, default: "", null: false, limit: 255
      t.integer :position
      t.timestamps precision: nil
      t.boolean :password_auto_generated
      t.timestamp :deleted_at
      t.references :sis_batch, foreign_key: true, index: { where: "sis_batch_id IS NOT NULL" }
      t.string :sis_user_id, limit: 255
      t.string :sis_ssha, limit: 255
      t.references :communication_channel, index: false
      t.references :sis_communication_channel
      t.text :stuck_sis_fields
      t.string :integration_id, limit: 255
      t.references :authentication_provider, foreign_key: true, index: { where: "authentication_provider_id IS NOT NULL" }
      t.string :declared_user_type, limit: 255

      t.replica_identity_index :account_id
      if (trgm = connection.extension(:pg_trgm)&.schema)
        t.index "lower(sis_user_id) #{trgm}.gin_trgm_ops", name: "index_gin_trgm_pseudonyms_sis_user_id", using: :gin
        t.index "lower(unique_id) #{trgm}.gin_trgm_ops", name: "index_gin_trgm_pseudonyms_unique_id", using: :gin
      end
      t.index [:sis_user_id, :account_id], where: "sis_user_id IS NOT NULL", unique: true
      t.index [:integration_id, :account_id],
              unique: true,
              name: "index_pseudonyms_on_integration_id",
              where: "integration_id IS NOT NULL"
      t.index "LOWER(unique_id), account_id, authentication_provider_id",
              name: "index_pseudonyms_unique_with_auth_provider",
              unique: true,
              where: "workflow_state IN ('active', 'suspended')"
      t.index "LOWER(unique_id), account_id",
              name: "index_pseudonyms_unique_without_auth_provider",
              unique: true,
              where: "workflow_state IN ('active', 'suspended') AND authentication_provider_id IS NULL"
      t.index "LOWER(unique_id), account_id", name: "index_pseudonyms_on_unique_id_and_account_id"
    end
    execute "CREATE UNIQUE INDEX index_pseudonyms_on_unique_id_and_account_id_and_authentication_provider_id ON #{Pseudonym.quoted_table_name} (LOWER(unique_id), account_id, authentication_provider_id) WHERE workflow_state='active'"
    execute "CREATE UNIQUE INDEX index_pseudonyms_on_unique_id_and_account_id_no_authentication_provider_id ON #{Pseudonym.quoted_table_name} (LOWER(unique_id), account_id) WHERE workflow_state='active' AND authentication_provider_id IS NULL"

    create_table :purgatories do |t|
      t.references :attachment, null: false, foreign_key: true, index: { unique: true }
      t.references :deleted_by_user, foreign_key: { to_table: :users }
      t.timestamps precision: nil
      t.string :workflow_state, null: false, default: "active", index: true
      t.string :old_filename, null: false
      t.string :old_display_name, limit: 255
      t.string :old_content_type, limit: 255
      t.string :new_instfs_uuid
      t.string :old_file_state
      t.string :old_workflow_state
    end

    create_table :quizzes do |t|
      t.string :title, limit: 255
      t.text :description, limit: 16_777_215
      t.text :quiz_data, limit: 16_777_215
      t.float :points_possible
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.references :assignment, foreign_key: true, index: { unique: true }
      t.string :workflow_state, null: false, limit: 255
      t.boolean :shuffle_answers, default: false, null: false
      t.boolean :show_correct_answers, default: true, null: false
      t.integer :time_limit
      t.integer :allowed_attempts
      t.string :scoring_policy, limit: 255
      t.string :quiz_type, limit: 255
      t.timestamps precision: nil
      t.timestamp :lock_at
      t.timestamp :unlock_at
      t.timestamp :deleted_at
      t.boolean :could_be_locked, default: false, null: false
      t.references :cloned_item, foreign_key: true, index: { where: "cloned_item_id IS NOT NULL" }
      t.string :access_code, limit: 255
      t.string :migration_id, limit: 255
      t.integer :unpublished_question_count, default: 0
      t.timestamp :due_at
      t.integer :question_count
      t.references :last_assignment, index: false
      t.timestamp :published_at
      t.timestamp :last_edited_at
      t.boolean :anonymous_submissions, default: false, null: false
      t.references :assignment_group, index: false
      t.string :hide_results, limit: 255
      t.string :ip_filter, limit: 255
      t.boolean :require_lockdown_browser, default: false, null: false
      t.boolean :require_lockdown_browser_for_results, default: false, null: false
      t.boolean :one_question_at_a_time, default: false, null: false
      t.boolean :cant_go_back, default: false, null: false
      t.timestamp :show_correct_answers_at
      t.timestamp :hide_correct_answers_at
      t.boolean :require_lockdown_browser_monitor, default: false, null: false
      t.text :lockdown_browser_monitor_data
      t.boolean :only_visible_to_overrides, default: false, null: false
      t.boolean :one_time_results, default: false, null: false
      t.boolean :show_correct_answers_last_attempt, default: false, null: false
      t.references :root_account, foreign_key: { to_table: :accounts }
      t.boolean :disable_timer_autosubmission, default: false, null: false

      t.index [:context_id, :context_type]
    end

    create_table :quiz_groups do |t|
      t.references :quiz, null: false
      t.string :name, limit: 255
      t.integer :pick_count
      t.float :question_points
      t.integer :position
      t.timestamps precision: nil
      t.string :migration_id, limit: 255
      t.references :assessment_question_bank, index: false
      t.references :root_account, foreign_key: { to_table: :accounts }
    end

    create_table :quiz_migration_alerts do |t|
      t.references :migration, polymorphic: true, index: { name: "index_quiz_migration_alerts_on_migration_type_and_migration_id" }
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.timestamps precision: 6
    end

    create_table :quiz_questions do |t|
      t.references :quiz, index: false
      t.references :quiz_group, index: { name: "quiz_questions_quiz_group_id" }
      t.references :assessment_question, index: { where: "assessment_question_id IS NOT NULL" }
      t.text :question_data
      t.integer :assessment_question_version
      t.integer :position
      t.timestamps null: true, precision: nil
      t.string :migration_id, limit: 255
      t.string :workflow_state, limit: 255
      t.integer :duplicate_index
      t.references :root_account

      t.index [:quiz_id, :assessment_question_id], name: "idx_qqs_on_quiz_and_aq_ids"
      t.index %i[assessment_question_id quiz_group_id duplicate_index],
              name: "index_generated_quiz_questions",
              where: "assessment_question_id IS NOT NULL AND quiz_group_id IS NOT NULL AND workflow_state='generated'",
              unique: true
    end

    create_table :quiz_regrades do |t|
      t.references :user, null: false, foreign_key: true
      t.references :quiz, null: false, foreign_key: true, index: false
      t.integer :quiz_version, null: false
      t.timestamps precision: nil

      t.index [:quiz_id, :quiz_version], unique: true
    end

    create_table :quiz_question_regrades do |t|
      t.references :quiz_regrade, null: false, foreign_key: true, index: false
      t.references :quiz_question, null: false, foreign_key: true, index: { name: "index_qqr_on_qq_id" }
      t.string :regrade_option, null: false, limit: 255
      t.timestamps precision: nil

      t.index [:quiz_regrade_id, :quiz_question_id], unique: true, name: "index_qqr_on_qr_id_and_qq_id"
    end

    create_table :quiz_regrade_runs do |t|
      t.references :quiz_regrade, null: false, foreign_key: true
      t.timestamp :started_at
      t.timestamp :finished_at
      t.timestamps precision: nil
    end

    create_table :quiz_statistics do |t|
      t.references :quiz, foreign_key: true, index: false
      t.boolean :includes_all_versions
      t.boolean :anonymous
      t.timestamps precision: nil
      t.string :report_type, limit: 255
      t.boolean :includes_sis_ids

      t.index [:quiz_id, :report_type]
    end

    create_table :quiz_submissions do |t|
      t.references :quiz, null: false, foreign_key: true, index: false
      t.integer :quiz_version
      t.references :user, foreign_key: { deferrable: :immediate }
      t.text :submission_data, limit: 16_777_215
      t.references :submission
      t.float :score
      t.float :kept_score
      t.text :quiz_data, limit: 16_777_215
      t.timestamp :started_at
      t.timestamp :end_at
      t.timestamp :finished_at
      t.integer :attempt
      t.string :workflow_state, null: false, limit: 255
      t.timestamps precision: nil
      t.integer :fudge_points, default: 0
      t.float :quiz_points_possible
      t.integer :extra_attempts
      t.string :temporary_user_code, limit: 255, index: true
      t.integer :extra_time
      t.boolean :manually_unlocked
      t.boolean :manually_scored
      t.string :validation_token, limit: 255
      t.float :score_before_regrade
      t.boolean :was_preview
      t.boolean :has_seen_results
      t.boolean :question_references_fixed
      t.references :root_account, foreign_key: { to_table: :accounts }

      t.index [:quiz_id, :user_id], unique: true
    end
    # If the column is created as a float with default 0, it becomes 0.0, which
    # would be fine, but it's easier to compare schema consistency this way.
    change_column :quiz_submissions, :fudge_points, :float

    create_table :quiz_submission_events do |t|
      t.integer :attempt, null: false
      t.string :event_type, null: false, limit: 255
      t.references :quiz_submission, null: false, foreign_key: true, index: false
      t.text :event_data
      t.timestamp :created_at, null: false, index: true
      t.timestamp :client_timestamp
      t.references :root_account, foreign_key: { to_table: :accounts }

      t.index %i[quiz_submission_id attempt created_at],
              name: "event_predecessor_locator_index"
    end

    create_table :quiz_submission_snapshots do |t|
      t.references :quiz_submission
      t.integer :attempt
      t.text :data
      t.timestamps null: true, precision: nil
    end

    create_table :report_snapshots do |t|
      t.string :report_type, limit: 255
      t.text :data, limit: 16_777_215
      t.timestamps precision: nil
      t.references :account, foreign_key: true, index: { where: "account_id IS NOT NULL" }

      t.index %i[report_type account_id created_at], name: "index_on_report_snapshots"
    end

    create_table :roles do |t|
      t.string :name, null: false, limit: 255, index: true
      t.string :base_role_type, null: false, limit: 255
      t.references :account, foreign_key: true
      t.string :workflow_state, null: false, limit: 255
      t.timestamps precision: nil
      t.timestamp :deleted_at
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false

      t.replica_identity_index
      t.index [:account_id, :name], unique: true, name: "index_roles_unique_account_name_where_active", where: "workflow_state = 'active'"
    end

    create_table :role_overrides do |t|
      t.string :permission, limit: 255
      t.boolean :enabled, default: true, null: false
      t.boolean :locked, default: false, null: false
      t.references :context, null: false, foreign_key: { to_table: :accounts }, index: false
      t.string :context_type, limit: 255, null: false
      t.timestamps null: true, precision: nil
      t.boolean :applies_to_self, default: true, null: false
      t.boolean :applies_to_descendants, default: true, null: false
      t.references :role, null: false, foreign_key: true
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false

      t.replica_identity_index
      t.index %i[context_id context_type role_id permission],
              unique: true,
              name: "index_role_overrides_on_context_role_permission"
    end

    create_table :rubrics do |t|
      t.references :user, foreign_key: true
      t.references :rubric, foreign_key: true, index: { where: "rubric_id IS NOT NULL" }
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.text :data
      t.float :points_possible
      t.string :title, limit: 255
      t.text :description
      t.timestamps precision: nil
      t.boolean :reusable, default: false
      t.boolean :public, default: false
      t.boolean :read_only, default: false
      t.integer :association_count, default: 0
      t.boolean :free_form_criterion_comments
      t.string :context_code, limit: 255
      t.string :migration_id, limit: 255
      t.boolean :hide_score_total
      t.string :workflow_state, default: "active", null: false, limit: 255
      t.references :root_account, foreign_key: { to_table: :accounts }

      t.index [:context_id, :context_type]
    end

    create_table :rubric_associations do |t|
      t.references :rubric, null: false, foreign_key: true
      t.bigint :association_id, null: false
      t.string :association_type, null: false, limit: 255
      t.boolean :use_for_grading
      t.timestamps precision: nil
      t.string :title, limit: 255
      t.text :summary_data
      t.string :purpose, null: false, limit: 255
      t.string :url, limit: 255
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.boolean :hide_score_total
      t.boolean :bookmarked, default: true
      t.string :context_code, limit: 255, index: true
      t.boolean :hide_points, default: false
      t.boolean :hide_outcome_results, default: false
      t.references :root_account
      t.string :workflow_state, default: "active", null: false

      t.index [:association_id, :association_type], name: "index_rubric_associations_on_aid_and_atype"
      t.index [:context_id, :context_type]
    end

    create_table :rubric_assessments do |t|
      t.references :user, foreign_key: true
      t.references :rubric, null: false, foreign_key: true
      t.references :rubric_association, foreign_key: true
      t.float :score
      t.text :data
      t.timestamps precision: nil
      t.bigint :artifact_id, null: false
      t.string :artifact_type, null: false, limit: 255
      t.string :assessment_type, null: false, limit: 255
      t.references :assessor, foreign_key: { to_table: :users }
      t.integer :artifact_attempt
      t.boolean :hide_points, default: false, null: false
      t.references :root_account, foreign_key: { to_table: :accounts }

      t.index [:artifact_id, :artifact_type]
    end

    create_table :rubric_criteria do |t|
      t.references :rubric, null: false, foreign_key: { to_table: :rubrics }
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.text :description
      t.text :long_description
      t.integer :order, null: false
      t.decimal :points, null: false
      t.boolean :criterion_use_range, null: false, default: false
      t.references :learning_outcome, foreign_key: { to_table: :learning_outcomes }
      t.decimal :mastery_points
      t.boolean :ignore_for_scoring, null: false, default: false
      t.string :workflow_state, null: false, default: "active", limit: 255
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :deleted_by, foreign_key: { to_table: :users }
      t.timestamps

      t.replica_identity_index
    end

    create_table :scheduled_smart_alerts do |t|
      t.string :context_type, null: false
      t.string :alert_type, null: false
      t.bigint :context_id, null: false
      t.timestamp :due_at, null: false, index: true
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }
      t.timestamps precision: nil

      t.index %i[context_type context_id alert_type root_account_id], name: "index_unique_scheduled_smart_alert"
    end

    create_table :scores do |t|
      t.references :enrollment, null: false, foreign_key: true, index: { name: "index_enrollment_scores" }
      t.references :grading_period, foreign_key: true, index: { where: "grading_period_id IS NOT NULL" }
      t.string :workflow_state, default: :active, null: false, limit: 255
      t.float :current_score
      t.float :final_score
      t.timestamps null: true, precision: nil
      t.references :assignment_group
      t.boolean :course_score, default: false, null: false
      t.float :unposted_current_score
      t.float :unposted_final_score
      t.float :current_points
      t.float :unposted_current_points
      t.float :final_points
      t.float :unposted_final_points
      t.float :override_score
      t.references :root_account, foreign_key: { to_table: :accounts }
      t.references :custom_grade_status, foreign_key: true, index: { where: "custom_grade_status_id IS NOT NULL" }

      t.index %i[enrollment_id grading_period_id],
              unique: true,
              where: "grading_period_id IS NOT NULL",
              name: "index_grading_period_scores"
      t.index %i[enrollment_id assignment_group_id],
              unique: true,
              where: "assignment_group_id IS NOT NULL",
              name: "index_assignment_group_scores"
      t.index :enrollment_id, unique: true, where: "course_score", name: "index_course_scores"
    end

    create_table :score_metadata do |t|
      t.references :score, null: false, foreign_key: true, index: { unique: true }
      t.json :calculation_details, default: {}, null: false
      t.timestamps precision: nil
      t.string :workflow_state, default: "active", null: false
    end

    create_table :score_statistics do |t|
      t.references :assignment, null: false, index: { unique: true }, foreign_key: true
      t.float :minimum, null: false
      t.float :maximum, null: false
      t.float :mean, null: false
      t.integer :count, null: false
      t.timestamps precision: nil
      t.references :root_account, foreign_key: { to_table: :accounts }
      t.float :lower_q
      t.float :median
      t.float :upper_q
    end

    create_table :sessions do |t|
      t.string :session_id, null: false, limit: 255, index: true
      t.text :data
      t.timestamps precision: nil

      t.index :updated_at
    end

    create_table :session_persistence_tokens do |t|
      t.string :token_salt, null: false, limit: 255
      t.string :crypted_token, null: false, limit: 255
      t.references :pseudonym, null: false, foreign_key: true
      t.timestamps precision: nil
    end

    create_table :settings do |t|
      t.string :name, limit: 255, index: { unique: true }
      t.text :value
      t.timestamps precision: nil
      t.boolean :secret, default: false, null: false
    end

    create_table :shared_brand_configs do |t|
      t.string :name, limit: 255
      t.references :account, foreign_key: true
      t.string :brand_config_md5, limit: 32, null: false, index: true
      t.timestamps precision: nil

      t.foreign_key :brand_configs, column: :brand_config_md5, primary_key: :md5
    end

    create_table :sis_batch_errors do |t|
      t.references :sis_batch, null: false, foreign_key: true
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }
      t.text :message, null: false
      t.text :backtrace
      t.string :file, limit: 255
      t.boolean :failure, default: false, null: false
      t.integer :row
      t.timestamp :created_at, null: false, index: true
      t.text :row_info
    end

    create_table :sis_batch_roll_back_data do |t|
      t.references :sis_batch, null: false, foreign_key: true
      t.references :context, polymorphic: { limit: 255 }, null: false, index: false
      t.string :previous_workflow_state, null: false, limit: 255
      t.string :updated_workflow_state, null: false, limit: 255
      t.boolean :batch_mode_delete, null: false, default: false
      t.string :workflow_state, null: false, limit: 255, default: "active", index: true
      t.timestamps precision: nil

      t.index %i[updated_workflow_state previous_workflow_state],
              name: "index_sis_batch_roll_back_context_workflow_states"
    end

    create_table :sis_post_grades_statuses do |t|
      t.references :course, null: false, foreign_key: true
      t.references :course_section, foreign_key: true
      t.references :user, foreign_key: true
      t.string :status, null: false, limit: 255
      t.string :message, null: false, limit: 255
      t.timestamp :grades_posted_at, null: false
      t.timestamps precision: nil
    end

    create_table :standard_grade_statuses do |t|
      t.string :color, limit: 7, null: false
      t.string :status_name, null: false
      t.boolean :hidden, default: false, null: false
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.timestamps precision: 6

      t.replica_identity_index
      t.index [:status_name, :root_account_id], unique: true, name: "index_standard_status_on_name_and_root_account_id"
    end

    create_table :stream_items do |t|
      t.text :data, null: false
      t.timestamps precision: nil
      t.references :context, polymorphic: { limit: 255 }, index: false
      t.string :asset_type, null: false, limit: 255
      t.bigint :asset_id
      t.string :notification_category, limit: 255

      t.index [:asset_type, :asset_id], unique: true
      t.index :updated_at
    end

    create_table :stream_item_instances do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :stream_item, null: false
      t.boolean :hidden, default: false, null: false
      t.string :workflow_state, limit: 255
      t.references :context, polymorphic: { limit: 255 }, index: { name: "index_stream_item_instances_on_context_type_and_context_id" }

      t.index %i[user_id hidden id stream_item_id], name: "index_stream_item_instances_global"
      t.index [:stream_item_id, :user_id], unique: true
    end

    create_table :submissions do |t|
      t.text :body, limit: 16_777_215
      t.string :url, limit: 255
      t.references :attachment, index: false
      t.string :grade, limit: 255
      t.float :score
      t.timestamp :submitted_at, index: true
      t.references :assignment, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: { deferrable: :immediate }, index: false
      t.string :submission_type, limit: 255
      t.string :workflow_state, null: false, limit: 255
      t.timestamps null: true, precision: nil
      t.references :group, foreign_key: true, index: { where: "group_id IS NOT NULL" }
      t.text :attachment_ids
      t.boolean :processed
      t.boolean :grade_matches_current_submission
      t.float :published_score
      t.string :published_grade, limit: 255
      t.timestamp :graded_at, index: { using: :brin }
      t.float :student_entered_score
      t.references :grader, index: false
      t.string :media_comment_id, limit: 255
      t.string :media_comment_type, limit: 255
      t.references :quiz_submission, foreign_key: true, index: { where: "quiz_submission_id IS NOT NULL" }
      t.integer :submission_comments_count
      t.integer :attempt
      t.references :media_object, foreign_key: true, index: { where: "media_object_id IS NOT NULL" }
      t.text :turnitin_data
      t.timestamp :cached_due_date, index: true
      t.boolean :excused
      t.boolean :graded_anonymously
      t.string :late_policy_status, limit: 16, index: { where: "workflow_state<>'deleted' AND late_policy_status IS NOT NULL" }
      t.decimal :points_deducted, precision: 6, scale: 2
      t.references :grading_period, foreign_key: true, index: { where: "grading_period_id IS NOT NULL" }
      t.bigint :seconds_late_override
      t.string :lti_user_id
      t.string :anonymous_id, limit: 5
      t.timestamp :last_comment_at
      t.integer :extra_attempts
      t.timestamp :posted_at
      t.boolean :cached_quiz_lti, default: false, null: false, index: true
      t.string :cached_tardiness, limit: 16
      t.references :course, foreign_key: true, index: false, null: false
      t.references :root_account, foreign_key: { to_table: :accounts }
      t.boolean :redo_request, default: false, null: false
      t.uuid :resource_link_lookup_uuid
      t.references :proxy_submitter, foreign_key: { to_table: :users }
      t.references :custom_grade_status, foreign_key: true, index: { where: "custom_grade_status_id IS NOT NULL" }
      t.string :sticker, limit: 255

      t.index [:assignment_id, :submission_type]
      t.index [:user_id, :assignment_id], unique: true
      t.index [:assignment_id, :user_id]
      t.index :assignment_id, name: "index_submissions_needs_grading", where: <<~SQL.squish
        submissions.submission_type IS NOT NULL
        AND (submissions.excused = 'f' OR submissions.excused IS NULL)
        AND (submissions.workflow_state = 'pending_review'
          OR (submissions.workflow_state IN ('submitted', 'graded')
            AND (submissions.score IS NULL OR NOT submissions.grade_matches_current_submission)
          )
        )
      SQL
      t.index [:assignment_id, :grading_period_id],
              name: "index_active_submissions",
              where: "workflow_state <> 'deleted'"
      t.index [:assignment_id, :grading_period_id],
              where: "workflow_state<>'deleted' AND grading_period_id IS NOT NULL",
              name: "index_active_submissions_gp"
      t.index %i[assignment_id anonymous_id], unique: true, where: "anonymous_id IS NOT NULL"
      t.index "user_id, GREATEST(submitted_at, created_at)", name: "index_submissions_on_user_and_greatest_dates"
      t.index :user_id,
              where: "(score IS NOT NULL AND workflow_state = 'graded') OR excused = TRUE",
              name: "index_submissions_graded_or_excused_on_user_id"
      t.index :assignment_id,
              where: "workflow_state <> 'deleted' AND ((score IS NOT NULL AND workflow_state = 'graded') OR excused = TRUE)",
              name: "index_submissions_graded_or_excused_on_assignment_id"
      t.index [:user_id, :cached_due_date]
      t.index [:user_id, :course_id]
      t.index [:user_id, :course_id],
              where: "(score IS NOT NULL OR grade IS NOT NULL) AND workflow_state<>'deleted'",
              name: "index_submissions_with_grade"
      t.index [:course_id, :cached_due_date]
      t.index :user_id, where: "late_policy_status='missing'", name: "index_on_submissions_missing_for_user"
    end

    create_table :submission_comments do |t|
      t.text :comment
      t.references :submission, foreign_key: true
      t.references :author, foreign_key: { to_table: :users }
      t.string :author_name, limit: 255
      t.string :group_comment_id, limit: 255
      t.timestamps precision: nil
      t.text :attachment_ids
      t.references :assessment_request, index: false
      t.string :media_comment_id, limit: 255
      t.string :media_comment_type, limit: 255
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.text :cached_attachments
      t.boolean :anonymous
      t.boolean :teacher_only_comment, default: false
      t.boolean :hidden, default: false
      t.references :provisional_grade, foreign_key: { to_table: :moderated_grading_provisional_grades }, index: { where: "provisional_grade_id IS NOT NULL" }
      t.boolean :draft, default: false, null: false, index: true
      t.timestamp :edited_at
      t.integer :attempt, index: true
      t.references :root_account, foreign_key: { to_table: :accounts }
      t.string :workflow_state, default: "active", null: false

      t.index [:context_id, :context_type]
    end

    create_table :submission_drafts do |t|
      t.references :submission, null: false, foreign_key: true
      t.integer :submission_attempt, index: true, null: false
      t.text :body
      t.text :url
      t.string :active_submission_type
      # This is actually the media_id e.g. m-123456 rather than the media_object.id
      t.string :media_object_id
      t.references :context_external_tool, index: false
      t.text :lti_launch_url
      t.uuid :resource_link_lookup_uuid
    end

    create_table :submission_draft_attachments do |t|
      t.references :submission_draft, null: false
      t.references :attachment, null: false

      t.index [:submission_draft_id, :attachment_id],
              name: "index_submission_draft_and_attachment_unique",
              unique: true
    end

    create_table :submission_versions do |t|
      t.bigint :context_id
      t.string :context_type, limit: 255
      t.references :version
      t.references :user, index: false
      t.references :assignment, index: false
      t.references :root_account, foreign_key: { to_table: :accounts }

      t.index %i[context_id version_id user_id assignment_id],
              name: "index_submission_versions",
              where: "context_type='Course'",
              unique: true
    end

    # rubocop:disable Rails/SquishedSQLHeredocs
    execute(<<~SQL)
      CREATE FUNCTION #{connection.quote_table_name("submission_comment_after_save_set_last_comment_at__tr_fn")} () RETURNS trigger AS $$
      BEGIN
        UPDATE submissions
        SET last_comment_at = (
           SELECT MAX(submission_comments.created_at) FROM submission_comments
            WHERE submission_comments.submission_id=submissions.id AND
            submission_comments.author_id <> submissions.user_id AND
            submission_comments.draft <> 't' AND
            submission_comments.provisional_grade_id IS NULL
        ) WHERE id = NEW.submission_id;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    execute(<<~SQL)
      CREATE FUNCTION #{connection.quote_table_name("submission_comment_after_delete_set_last_comment_at__tr_fn")} () RETURNS trigger AS $$
      BEGIN
        UPDATE submissions
        SET last_comment_at = (
           SELECT MAX(submission_comments.created_at) FROM submission_comments
            WHERE submission_comments.submission_id=submissions.id AND
            submission_comments.author_id <> submissions.user_id AND
            submission_comments.draft <> 't' AND
            submission_comments.provisional_grade_id IS NULL
        ) WHERE id = OLD.submission_id;
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    # rubocop:enable Rails/SquishedSQLHeredocs

    set_search_path("submission_comment_after_save_set_last_comment_at__tr_fn", "()")
    set_search_path("submission_comment_after_delete_set_last_comment_at__tr_fn", "()")

    execute(<<~SQL.squish)
      CREATE TRIGGER submission_comment_after_insert_set_last_comment_at__tr
        AFTER INSERT ON #{SubmissionComment.quoted_table_name}
        FOR EACH ROW
        WHEN (NEW.draft <> 't' AND NEW.provisional_grade_id IS NULL)
        EXECUTE PROCEDURE #{connection.quote_table_name("submission_comment_after_save_set_last_comment_at__tr_fn")}()
    SQL

    execute(<<~SQL.squish)
      CREATE TRIGGER submission_comment_after_update_set_last_comment_at__tr
        AFTER UPDATE OF draft, provisional_grade_id ON #{SubmissionComment.quoted_table_name}
        FOR EACH ROW
        EXECUTE PROCEDURE #{connection.quote_table_name("submission_comment_after_save_set_last_comment_at__tr_fn")}()
    SQL

    execute(<<~SQL.squish)
      CREATE TRIGGER submission_comment_after_delete_set_last_comment_at__tr
        AFTER DELETE ON #{SubmissionComment.quoted_table_name}
        FOR EACH ROW
        WHEN (OLD.draft <> 't' AND OLD.provisional_grade_id IS NULL)
        EXECUTE PROCEDURE #{connection.quote_table_name("submission_comment_after_delete_set_last_comment_at__tr_fn")}()
    SQL

    create_table :switchman_shards do |t|
      t.string :name, limit: 255
      t.string :database_server_id, limit: 255, index: { unique: true,
                                                         where: "name IS NULL",
                                                         name: "index_switchman_shards_unique_primary_shard" }
      t.boolean :default, default: false, null: false, index: { unique: true, where: '"default"' }
      t.text :settings
      t.references :delayed_jobs_shard,
                   foreign_key: { to_table: :switchman_shards },
                   index: { where: "delayed_jobs_shard_id IS NOT NULL" }
      t.timestamps precision: nil
      t.boolean :block_stranded, default: false
      t.boolean :jobs_held, default: false

      t.index [:database_server_id, :name], unique: true
      t.index "(true)",
              unique: true,
              where: "database_server_id IS NULL AND name IS NULL",
              name: "index_switchman_shards_unique_primary_db_and_shard"
    end

    create_table :temporary_enrollment_pairings, if_not_exists: true do |t|
      t.references :root_account, foreign_key: { to_table: :accounts }, null: false, index: false
      t.string :workflow_state, null: false, default: "active", limit: 255
      t.timestamps
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :deleted_by, foreign_key: { to_table: :users }

      t.replica_identity_index
    end

    create_table :terms_of_service_contents do |t|
      t.text :content, null: false
      t.timestamps precision: nil
      t.timestamp :terms_updated_at, null: false
      t.string :workflow_state, null: false
      t.references :account, foreign_key: true, index: { unique: true }
    end

    create_table :terms_of_services do |t|
      t.string :terms_type, null: false, default: "default"
      t.boolean :passive, null: false, default: true
      t.references :terms_of_service_content, index: false
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.timestamps precision: nil
      t.string :workflow_state, null: false
    end

    create_table :thumbnails do |t|
      t.references :parent
      t.string :content_type, null: false, limit: 255
      t.string :filename, null: false, limit: 255
      t.string :thumbnail, limit: 255
      t.integer :size, null: false
      t.integer :width
      t.integer :height
      t.timestamps precision: nil
      t.string :uuid, limit: 255
      t.string :namespace, limit: 255

      t.index [:parent_id, :thumbnail], unique: true, name: "index_thumbnails_size"
    end

    create_table :usage_rights do |t|
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.string :use_justification, null: false, limit: 255
      t.string :license, null: false, limit: 255
      t.text :legal_copyright

      t.index [:context_id, :context_type], name: "usage_rights_context_idx"
    end

    create_table :user_account_associations do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :account, null: false, foreign_key: true
      t.integer :depth
      t.timestamps precision: nil
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false

      t.replica_identity_index
      t.index [:user_id, :account_id], unique: true
    end

    create_table :user_lmgb_outcome_orderings do |t|
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.references :learning_outcome, null: false, foreign_key: true
      t.integer :position, null: false
      t.timestamps precision: 6

      t.replica_identity_index
      t.index %i[learning_outcome_id user_id course_id],
              unique: true,
              name: "index_user_lmgb_outcome_orderings"
    end

    create_table :user_merge_data do |t|
      t.references :user, null: false, foreign_key: true
      t.references :from_user, null: false
      t.timestamps precision: nil
      t.string :workflow_state, null: false, default: "active", limit: 255
    end

    create_table :user_merge_data_items do |t|
      t.references :user_merge_data, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :item_type, null: false, limit: 255
      t.text :item, null: false
    end

    create_table :user_merge_data_records do |t|
      t.references :user_merge_data, null: false, foreign_key: true
      t.bigint :context_id, null: false
      t.references :previous_user, null: false, index: false
      t.string :context_type, null: false, limit: 255
      t.string :previous_workflow_state, limit: 255

      t.index %i[context_id context_type user_merge_data_id previous_user_id],
              name: "index_user_merge_data_records_on_context_id_and_context_type"
    end

    create_table :user_notes do |t|
      t.references :user, foreign_key: true, index: false
      t.text :note
      t.string :title, limit: 255
      t.references :created_by, foreign_key: { to_table: :users }
      t.string :workflow_state, default: "active", null: false, limit: 255
      t.timestamp :deleted_at
      t.timestamps precision: nil
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false

      t.replica_identity_index
      t.index [:user_id, :workflow_state]
    end

    create_table :user_observers do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :observer, null: false, foreign_key: { to_table: :users }
      t.string :workflow_state, default: "active", null: false, limit: 255, index: true
      t.timestamps precision: nil
      t.references :sis_batch, index: { where: "sis_batch_id IS NOT NULL" }
      t.references :root_account, null: false, index: false

      t.index %i[user_id observer_id root_account_id],
              unique: true,
              name: "index_user_observers_on_user_id_and_observer_id_and_ra"
    end

    create_table :user_past_lti_ids do |t|
      t.references :user, null: false, foreign_key: true
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.string :user_uuid, null: false, limit: 255, index: true
      t.text :user_lti_id, null: false
      t.string :user_lti_context_id, limit: 255, index: true

      t.index %i[user_id context_id context_type], name: "user_past_lti_ids_index", unique: true
    end

    create_table :user_preference_values do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :key, null: false
      t.string :sub_key
      t.text :value

      t.index %i[user_id key sub_key], unique: true, name: "index_user_preference_values_on_keys"
      t.index [:user_id, :key],
              unique: true,
              where: "sub_key IS NULL",
              name: "index_user_preference_values_on_key_no_sub_key"
    end

    create_table :user_profiles do |t|
      t.text :bio
      t.string :title, limit: 255
      t.references :user, foreign_key: true
    end

    create_table :user_profile_links do |t|
      t.string :url, limit: 4.kilobytes
      t.string :title, limit: 255
      t.references :user_profile, foreign_key: true, index: { where: "user_profile_id IS NOT NULL" }
      t.timestamps precision: nil
    end

    create_table :user_services do |t|
      t.references :user, null: false, foreign_key: true
      t.text :token
      t.string :secret, limit: 255
      t.string :protocol, limit: 255
      t.string :service, null: false, limit: 255
      t.timestamps precision: nil
      t.string :service_user_url, limit: 255
      t.string :service_user_id, null: false, limit: 255
      t.string :service_user_name, limit: 255
      t.string :service_domain, limit: 255
      t.string :crypted_password, limit: 255
      t.string :password_salt, limit: 255
      t.string :type, limit: 255
      t.string :workflow_state, null: false, limit: 255
      t.string :last_result_id, limit: 255
      t.timestamp :refresh_at
      t.boolean :visible

      t.index [:id, :type]
    end

    create_table :versions do |t|
      t.bigint :versionable_id
      t.string :versionable_type, limit: 255
      t.integer :number
      t.text :yaml, limit: 16_777_215
      t.timestamp :created_at

      t.index %i[versionable_id versionable_type number], unique: true, name: "index_versions_on_versionable_object_and_number"
    end

    create_table :viewed_submission_comments do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :submission_comment, null: false, foreign_key: true
      t.timestamp :viewed_at, null: false

      t.index [:user_id, :submission_comment_id], name: "index_viewed_submission_comments_user_comment", unique: true
    end

    create_table :web_conferences do |t|
      t.string :title, null: false, limit: 255
      t.string :conference_type, null: false, limit: 255
      t.string :conference_key, limit: 255
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.string :user_ids, limit: 255
      t.string :added_user_ids, limit: 255
      t.references :user, null: false, foreign_key: true
      t.timestamp :started_at
      t.text :description
      t.float :duration
      t.timestamps precision: nil
      t.string :uuid, limit: 255
      t.string :invited_user_ids, limit: 255
      t.timestamp :ended_at
      t.timestamp :start_at
      t.timestamp :end_at
      t.string :context_code, limit: 255
      t.string :type, limit: 255
      t.text :settings
      t.boolean :recording_ready
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false

      t.replica_identity_index
      t.index [:context_id, :context_type]
    end

    create_table :web_conference_participants do |t|
      t.references :user, foreign_key: true
      t.references :web_conference, foreign_key: true
      t.string :participation_type, limit: 255
      t.timestamps precision: nil
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false

      t.replica_identity_index
    end

    create_table :wikis do |t|
      t.string :title, limit: 255
      t.timestamps precision: nil
      t.text :front_page_url
      t.boolean :has_no_front_page
      t.references :root_account, foreign_key: { to_table: :accounts }
    end

    create_table :wiki_pages do |t|
      t.references :wiki, null: false, foreign_key: true
      t.string :title, limit: 255
      t.text :body, limit: 16_777_215
      t.string :workflow_state, null: false, limit: 255
      t.references :user, foreign_key: true
      t.timestamps precision: nil
      t.text :url
      t.boolean :protected_editing, default: false
      t.string :editing_roles, limit: 255
      t.timestamp :revised_at
      t.boolean :could_be_locked
      t.references :cloned_item, foreign_key: true, index: { where: "cloned_item_id IS NOT NULL" }
      t.string :migration_id, limit: 255
      t.references :assignment, foreign_key: true
      t.references :old_assignment, foreign_key: { to_table: :assignments }
      t.timestamp :todo_date
      t.bigint :context_id, null: false
      t.string :context_type, null: false
      t.references :root_account, foreign_key: { to_table: :accounts }
      t.timestamp :publish_at
      t.references :current_lookup, foreign_key: { to_table: :wiki_page_lookups }
      t.timestamp :unlock_at, precision: 6
      t.timestamp :lock_at, precision: 6
      t.boolean :only_visible_to_overrides, null: false, default: false

      t.index [:context_id, :context_type]
      t.index [:wiki_id, :todo_date], where: "todo_date IS NOT NULL"
    end

    create_table :wiki_page_lookups do |t|
      t.text :slug, null: false, index: false
      t.references :wiki_page, null: false, foreign_key: { deferrable: :deferred, on_delete: :cascade }
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.bigint :context_id, null: false
      t.string :context_type, null: false, limit: 255
      t.timestamps precision: 6

      t.replica_identity_index
      t.index %i[context_id context_type slug],
              name: "unique_index_on_context_and_slug",
              unique: true
    end

    if Rails.env.test?
      create_table :stories do |t|
        t.string :text
      end
    end

    unless Rails.env.production?
      # this user is *not* used in production! it's only used to simulate a read-only secondary database in dev/test

      # the user is cluster-wide ...
      unless readonly_user_exists?
        execute("CREATE USER canvas_readonly_user")
      end

      quoted_schema = connection.quote_local_table_name(Shard.current.name)

      # ... but needs permissions on each shard's schema
      execute("GRANT USAGE ON SCHEMA #{quoted_schema} TO canvas_readonly_user")
      execute("GRANT SELECT ON ALL TABLES IN SCHEMA #{quoted_schema} TO canvas_readonly_user")
      execute("ALTER DEFAULT PRIVILEGES IN SCHEMA #{quoted_schema} GRANT SELECT ON TABLES TO canvas_readonly_user")
    end

    change_column :schema_migrations, :version, :string, limit: 255

    execute(<<~SQL.squish)
      CREATE VIEW #{connection.quote_table_name("assignment_student_visibilities")} AS
      SELECT DISTINCT a.id as assignment_id,
        e.user_id as user_id,
        e.course_id as course_id
      FROM #{Assignment.quoted_table_name} a
      JOIN #{Enrollment.quoted_table_name} e
        ON e.course_id = a.context_id
        AND a.context_type = 'Course'
        AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
        AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')
      WHERE a.workflow_state NOT IN ('deleted','unpublished')
        AND COALESCE(a.only_visible_to_overrides, 'false') = 'false'

      UNION

      SELECT DISTINCT a.id as assignment_id,
        e.user_id as user_id,
        e.course_id as course_id
      FROM #{Assignment.quoted_table_name} a
      JOIN #{Enrollment.quoted_table_name} e
        ON e.course_id = a.context_id
        AND a.context_type = 'Course'
        AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
        AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')
      INNER JOIN #{AssignmentOverride.quoted_table_name} ao
        ON a.id = ao.assignment_id
        AND ao.set_type = 'ADHOC'
      INNER JOIN #{AssignmentOverrideStudent.quoted_table_name} aos
        ON ao.id = aos.assignment_override_id
        AND aos.user_id = e.user_id
      WHERE ao.workflow_state = 'active'
        AND aos.workflow_state <> 'deleted'
        AND a.workflow_state NOT IN ('deleted','unpublished')
        AND a.only_visible_to_overrides = 'true'

      UNION

      SELECT DISTINCT a.id as assignment_id,
        e.user_id as user_id,
        e.course_id as course_id
      FROM #{Assignment.quoted_table_name} a
      JOIN #{Enrollment.quoted_table_name} e
        ON e.course_id = a.context_id
        AND a.context_type = 'Course'
        AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
        AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')
      INNER JOIN #{AssignmentOverride.quoted_table_name} ao
        ON a.id = ao.assignment_id
        AND ao.set_type = 'Group'
      INNER JOIN #{Group.quoted_table_name} g
        ON g.id = ao.set_id
      INNER JOIN #{GroupMembership.quoted_table_name} gm
        ON gm.group_id = g.id
        AND gm.user_id = e.user_id
      WHERE gm.workflow_state <> 'deleted'
        AND g.workflow_state <> 'deleted'
        AND ao.workflow_state = 'active'
        AND a.workflow_state NOT IN ('deleted','unpublished')
        AND a.only_visible_to_overrides = 'true'

      UNION

      SELECT DISTINCT a.id as assignment_id,
        e.user_id as user_id,
        e.course_id as course_id
      FROM #{Assignment.quoted_table_name} a
      JOIN #{Enrollment.quoted_table_name} e
        ON e.course_id = a.context_id
        AND a.context_type = 'Course'
        AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
        AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')
      INNER JOIN #{AssignmentOverride.quoted_table_name} ao
        ON e.course_section_id = ao.set_id
        AND ao.set_type = 'CourseSection'
        AND ao.assignment_id = a.id
      WHERE a.workflow_state NOT IN ('deleted','unpublished')
        AND a.only_visible_to_overrides = 'true'
        AND ao.workflow_state = 'active'
    SQL

    execute(<<~SQL.squish)
      CREATE VIEW #{connection.quote_table_name("quiz_student_visibilities")} AS
      SELECT DISTINCT q.id as quiz_id,
        e.user_id as user_id,
        e.course_id as course_id
      FROM #{Quizzes::Quiz.quoted_table_name} q
      JOIN #{Enrollment.quoted_table_name} e
        ON e.course_id = q.context_id
        AND q.context_type = 'Course'
        AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
        AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')
      WHERE q.workflow_state NOT IN ('deleted','unpublished')
        AND COALESCE(q.only_visible_to_overrides, 'false') = 'false'

      UNION

      SELECT DISTINCT q.id as quiz_id,
        e.user_id as user_id,
        e.course_id as course_id
      FROM #{Quizzes::Quiz.quoted_table_name} q
      JOIN #{Enrollment.quoted_table_name} e
        ON e.course_id = q.context_id
        AND q.context_type = 'Course'
        AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
        AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')
      INNER JOIN #{AssignmentOverride.quoted_table_name} ao
        ON q.id = ao.quiz_id
        AND ao.set_type = 'ADHOC'
      INNER JOIN #{AssignmentOverrideStudent.quoted_table_name} aos
        ON ao.id = aos.assignment_override_id
        AND aos.user_id = e.user_id
      WHERE ao.workflow_state = 'active'
        AND aos.workflow_state <> 'deleted'
        AND q.workflow_state NOT IN ('deleted','unpublished')
        AND q.only_visible_to_overrides = 'true'

      UNION

      SELECT DISTINCT q.id as quiz_id,
        e.user_id as user_id,
        e.course_id as course_id
      FROM #{Quizzes::Quiz.quoted_table_name} q
      JOIN #{Enrollment.quoted_table_name} e
        ON e.course_id = q.context_id
        AND q.context_type = 'Course'
        AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
        AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')
      INNER JOIN #{AssignmentOverride.quoted_table_name} ao
        ON e.course_section_id = ao.set_id
        AND ao.set_type = 'CourseSection'
        AND ao.quiz_id = q.id
      WHERE q.workflow_state NOT IN ('deleted','unpublished')
        AND q.only_visible_to_overrides = 'true'
        AND ao.workflow_state = 'active'
    SQL

    execute(MigrationHelpers::StudentVisibilities::StudentVisibilitiesV4.view(connection.quote_table_name("assignment_student_visibilities_v2"), Assignment.quoted_table_name, is_assignment: true))
    execute(MigrationHelpers::StudentVisibilities::StudentVisibilitiesV4.view(connection.quote_table_name("quiz_student_visibilities_v2"), Quizzes::Quiz.quoted_table_name))
  end

  def readonly_user_exists?
    !!connection.select_value("SELECT 1 AS one FROM pg_roles WHERE rolname='canvas_readonly_user'")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
# rubocop:enable Migration/AddIndex, Migration/ChangeColumn, Migration/Execute, Migration/IdColumn
# rubocop:enable Migration/PrimaryKey, Migration/RootAccountId, Rails/CreateTableWithTimestamps
# rubocop:enable Rails/ThreeStateBooleanColumn
