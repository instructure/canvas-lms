module DataFixup::MoveContentExportNotificationsToMigrationCategory
  def self.run
    Notification.where(:name => ['Content Export Finished', 'Content Export Failed']).
        update_all(:category => 'Migration') if Shard.current.default?

    # send immediate notifications only work if you DON'T have a policy for that notification
    notification_ids_to_remove = Notification.where(:category => 'Migration').pluck(:id)
    if notification_ids_to_remove.present?
      NotificationPolicy.find_ids_in_ranges do |first_id, last_id|
        NotificationPolicy.where(:id => first_id..last_id, :notification_id => notification_ids_to_remove).delete_all
      end
    end
  end
end
