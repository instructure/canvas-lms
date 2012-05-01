class ConversationDataUpdate < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    SubmissionComment.connection.select_all("SELECT DISTINCT submission_id AS id FROM submission_comments WHERE NOT hidden").
    map{ |r| r["id"] }.each_slice(1000) do |ids|
      Submission.send_later_if_production_enqueue_args(:batch_migrate_conversations!, {
        :priority => Delayed::LOWER_PRIORITY,
        :max_attempts => 1,
        :strand => "migrate_submission_conversations"
      }, ids)
    end

    Conversation.connection.select_all("SELECT id FROM conversations").
    map{ |r| r["id"] }.each_slice(1000) do |ids|
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
