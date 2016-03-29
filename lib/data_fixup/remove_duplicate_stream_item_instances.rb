module DataFixup::RemoveDuplicateStreamItemInstances
  def self.run
    while (dups = StreamItemInstance.group(:stream_item_id, :user_id).having("COUNT(*) > 1").pluck(:stream_item_id, :user_id)) && dups.any?
      dups.each do |stream_item_id, user_id|
        StreamItemInstance.where(:stream_item_id => stream_item_id, :user_id => user_id).offset(1).delete_all
      end
    end
  end
end
