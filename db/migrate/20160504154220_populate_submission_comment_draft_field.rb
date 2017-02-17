class PopulateSubmissionCommentDraftField < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    DataFixup::PopulateSubmissionCommentDraftField.send_later_if_production_enqueue_args(
      :run,
      priority: Delayed::LOW_PRIORITY,
      strand: "populate_submission_comment_draft_field_fixup_#{Shard.current.database_server.id}",
      max_attempts: 1
    )
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
