class ConversationDataUpdate < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    SubmissionComment.where("NOT hidden").uniq.pluck(:submission_id).each_slice(1000) do |ids|
      Submission.send_later_if_production_enqueue_args(:batch_migrate_conversations!, {
        :priority => Delayed::LOWER_PRIORITY,
        :max_attempts => 1,
        :strand => "migrate_submission_conversations"
      }, ids)
    end

    Conversation.pluck(:id).each_slice(1000) do |ids|
      Conversation.send_later_if_production_enqueue_args(:batch_migrate_context_tags!, {
        :priority => Delayed::LOWER_PRIORITY,
        :max_attempts => 1,
        :strand => "migrate_conversation_context_tags"
      }, ids)
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
