module DataFixup::ReintroduceDeletedEntriesToUnreadCount
  def self.run
    # Recalculate counts to include deleted entries
    DiscussionTopicParticipant.includes(:discussion_topic, :user).find_each do |participant|
      # since the previous code treated all deleted discussion entries as
      # hidden and not included in unread counts, we're going to update all
      # pre-existing deleted entries to be marked as read for all users
      #
      # and then the new behavior will only apply going forward
      topic = participant.discussion_topic
      topic.discussion_entries.deleted.each do |entry|
        entry.update_or_create_participant(:current_user => participant.user, :new_state => 'read')
      end

      # in theory this count won't need updating, but race conditions mean it
      # could be out of sync after the above, so we'll update it here. if it
      # doesn't change, the participant won't get re-saved
      read_count = topic.discussion_entry_participants.where(:user_id => participant.user_id, :workflow_state => "read").count
      participant.unread_entry_count = topic.discussion_entries.count - read_count
      participant.save
    end
  end
end
