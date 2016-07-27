module DataFixup::RemoveDuplicateStreamItemInstances
  def self.run
    while (dups = ActiveRecord::Base.connection.select_rows(%Q(SELECT stream_item_id, user_id FROM #{StreamItemInstance.quoted_table_name} GROUP BY stream_item_id, user_id HAVING COUNT(*) > 1))) && dups.any?
      dups.each do |stream_item_id, user_id|
        StreamItemInstance.where(:stream_item_id => stream_item_id, :user_id => user_id).offset(1).delete_all
      end
    end
  end
end
