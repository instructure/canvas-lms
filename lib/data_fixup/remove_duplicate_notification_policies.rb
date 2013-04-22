module DataFixup::RemoveDuplicateNotificationPolicies
  def self.run
    while true
      ccs = NotificationPolicy.connection.select_rows("
          SELECT communication_channel_id
          FROM notification_policies
          WHERE notification_id IS NULL
            AND frequency='daily'
          GROUP BY communication_channel_id
          HAVING count(*) > 1 LIMIT 50000")
      break if ccs.empty?
      ccs.each do |cc_id|
        scope = NotificationPolicy.where(:communication_channel_id => cc_id, :notification_id => nil, :frequency => 'daily')
        keeper = scope.limit(1).pluck(:id).first
        scope.where("id<>?", keeper).delete_all if keeper
      end
    end
  end
end
