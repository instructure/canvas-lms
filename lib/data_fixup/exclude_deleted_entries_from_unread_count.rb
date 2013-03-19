module DataFixup::ExcludeDeletedEntriesFromUnreadCount
  def self.run
    # Deleted all partipant entries for deleted discussion entries
    DiscussionEntryParticipant.
        includes(:discussion_entry).
        where(:discussion_entries => { :workflow_state => 'deleted' }).
        destroy_all

    # Recalculate counts based on active entries minus read entries
    DiscussionTopicParticipant.includes(:discussion_topic).find_each do |participant|
      topic = participant.discussion_topic
      read_count = topic.discussion_entry_participants.where(:user_id => participant.user_id, :workflow_state => "read").count
      participant.unread_entry_count = topic.discussion_entries.active.count - read_count
      participant.save
    end
  end
end
