class SubmissionCommentConversationFix < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    Submission.find_by_sql("SELECT * FROM submissions WHERE id IN (SELECT asset_id FROM conversation_messages WHERE asset_id IS NOT NULL AND body = '')").each do |submission|
      submission.create_or_update_conversations!(:destroy) if submission.visible_submission_comments.empty?
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
