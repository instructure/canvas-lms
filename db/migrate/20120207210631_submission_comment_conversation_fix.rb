class SubmissionCommentConversationFix < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    Submission.where(id: ConversationMessage.select(:asset_id).
                         where("asset_id IS NOT NULL").
                         where(body: '')).each do |submission|
      submission.create_or_update_conversations!(:destroy) if submission.visible_submission_comments.empty?
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
