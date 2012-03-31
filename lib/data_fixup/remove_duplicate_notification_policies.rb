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
        scope = NotificationPolicy.scoped(:conditions => { :communication_channel_id => cc_id, :notification_id => nil, :frequency => 'daily' })
        keeper = scope.first(:select => "id")
        scope.delete_all(["id<>?", keeper.id]) if keeper
      end
    end
  end
end
