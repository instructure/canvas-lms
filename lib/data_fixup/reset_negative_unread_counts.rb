module DataFixup
  module ResetNegativeUnreadCounts
    def self.run
      User.find_ids_in_ranges do |min_id, max_id|
        User.where(:id => min_id..max_id).where("unread_conversations_count < 0").update_all(:unread_conversations_count => 0)
      end
    end
  end
end