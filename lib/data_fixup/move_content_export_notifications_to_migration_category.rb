module DataFixup::MoveContentExportNotificationsToMigrationCategory
  def self.run
    Notification.update_all({ :category => 'Migration' },
                            { :name => ['Content Export Finished', 'Content Export Failed'] })

    # send immediate notifications only work if you DON'T have a policy for that notification
    notification_ids_to_remove = Notification.scoped(
      :select => :id,
      :conditions => { :category => 'Migration' }
    ).map(&:id)
    if notification_ids_to_remove.present?
      NotificationPolicy.find_ids_in_ranges do |first_id, last_id|
        NotificationPolicy.delete_all(["id >= ? AND id <= ? AND notification_id IN (?)", first_id, last_id, notification_ids_to_remove])
      end
    end
  end
end
