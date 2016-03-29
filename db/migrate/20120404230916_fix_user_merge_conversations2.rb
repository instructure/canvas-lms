class FixUserMergeConversations2 < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    # basically we are re-running lines 408-410 and 417-419 of
    # Conversation#merge_into (plus replicating some surrounding setup logic)
    # for any private conversations that were merged into existing private
    # conversations since 57d3a82.
    # the previous merging was done incorrectly due to a scoping issue
    
    # there are only about 100 that need to be fixed, so we just load them all
    convos = ConversationParticipant.where("NOT EXISTS (?)", Conversation.where("id=conversation_id"))
    convos.group_by(&:conversation_id).each do |conversation_id, cps|
      private_hash = Conversation.private_hash_for(cps.map(&:user_id))
      if target = Conversation.where(private_hash: private_hash).first
        new_participants = target.conversation_participants.inject({}){ |h,p| h[p.user_id] = p; h }
        cps.each do |cp|
          if new_cp = new_participants[cp.user_id]
            new_cp.update_attribute(:workflow_state, cp.workflow_state) if cp.unread? || new_cp.archived?
            cp.conversation_message_participants.update_all(:conversation_participant_id => new_cp)
            cp.destroy
          else
            $stderr.puts "couldn't find a target ConversationParticipant for id #{cp.id}"
          end
        end
        target.conversation_participants(true).each do |cp|
          cp.update_cached_data! :recalculate_count => true, :set_last_message_at => false, :regenerate_tags => false
        end
      else
        $stderr.puts "couldn't find a target Conversation for hash #{private_hash}"
      end
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
