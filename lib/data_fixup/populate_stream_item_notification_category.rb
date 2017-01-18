module DataFixup
  module PopulateStreamItemNotificationCategory
    def self.run
      categories_to_ids = {}
      StreamItem.where(:asset_type => "Message", :notification_category => nil).find_each do |item|
        category = item.get_notification_category
        categories_to_ids[category] ||= []
        categories_to_ids[category] << item.id
      end
      categories_to_ids.each do |category, all_ids|
        all_ids.each_slice(1000) do |item_ids|
          StreamItem.where(:id => item_ids).update_all(:notification_category => category)
        end
      end
    end
  end
end
