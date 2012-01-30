class IndexCleanupPt1 < ActiveRecord::Migration
  # cleaning up unused and inefficient indexes
  def self.up
    if connection.adapter_name =~ /postgres/i
      # most attachments have a root_attachment_id of null, which we never query by directly
      # we *do* query by (context_type, context_id, file_state where root_attachment_id = null),
      # but that uses the context index.
      # so, we'll restrict this index to just non-null root_attachment_ids.
      execute %{create index index_attachments_on_root_attachment_id_not_null on attachments (root_attachment_id) where root_attachment_id is not null}
      remove_index "attachments", :name => "index_attachments_on_root_attachment_id"
    end

    # these are unused and heavily updated, so great targets for dropping
    remove_index "attachments", :name => "index_attachments_on_scribd_account_id"
    remove_index "enrollments", :name => "index_enrollments_on_sis_source_id"
    remove_index "courses", :name => "index_courses_on_grading_standard_id"
    remove_index "courses", :name => "index_courses_on_wiki_id"
    remove_index "messages", :name => "index_messages_on_asset_context_id_and_asset_context_type"
    remove_index "messages", :name => "index_messages_on_notification_name_workflow_state_created_at"
    remove_index "messages", :name => "index_messages_on_sa_ui_te_nc"
    remove_index "messages", :name => "index_messages_on_workflow_state_and_dispatch_at"
    remove_index "pseudonyms", :name => "index_pseudonyms_on_communication_channel_id"
    remove_index "assignment_groups", :name => "index_assignment_groups_on_context_code"
    remove_index "assessment_questions", :name => "index_assessment_questions_on_context_id_and_context_type"
    remove_index "assignments", :name => "index_assignments_on_workflow_state"
    remove_index "submissions", :name => "aid_submission_type_process_attempts"
    remove_index "submissions", :name => "index_submissions_on_grader_id"
    remove_index "submissions", :name => "index_submissions_on_group_id"
  end

  def self.down
    if connection.adapter_name =~ /postgres/i
      remove_index "attachments", :name => "index_attachments_on_root_attachment_id_not_null"
      add_index "attachments", ["root_attachment_id"], :name => "index_attachments_on_root_attachment_id"
    end
    add_index "attachments", ["scribd_account_id"], :name => "index_attachments_on_scribd_account_id"
    add_index "enrollments", ["sis_source_id"], :name => "index_enrollments_on_sis_source_id"
    add_index "courses", ["grading_standard_id"], :name => "index_courses_on_grading_standard_id"
    add_index "courses", ["wiki_id"], :name => "index_courses_on_wiki_id"
    add_index "messages", ["asset_context_id", "asset_context_type"], :name => "index_messages_on_asset_context_id_and_asset_context_type"
    add_index "messages", ["notification_name", "workflow_state", "created_at"], :name => "index_messages_on_notification_name_workflow_state_created_at"
    add_index "messages", ["sent_at", "to_email", "user_id", "notification_category"], :name => "index_messages_on_sa_ui_te_nc"
    add_index "messages", ["workflow_state", "dispatch_at"], :name => "index_messages_on_workflow_state_and_dispatch_at"
    add_index "pseudonyms", ["communication_channel_id"], :name => "index_pseudonyms_on_communication_channel_id"
    add_index "assignment_groups", ["context_code"], :name => "index_assignment_groups_on_context_code"
    add_index "assessment_questions", ["context_id", "context_type"], :name => "index_assessment_questions_on_context_id_and_context_type"
    add_index "assignments", ["workflow_state"], :name => "index_assignments_on_workflow_state"
    add_index "submissions", ["attachment_id", "submission_type", "process_attempts"], :name => "aid_submission_type_process_attempts"
    add_index "submissions", ["grader_id"], :name => "index_submissions_on_grader_id"
    add_index "submissions", ["group_id"], :name => "index_submissions_on_group_id"
  end
end
