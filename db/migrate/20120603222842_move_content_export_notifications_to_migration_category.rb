class MoveContentExportNotificationsToMigrationCategory < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    DataFixup::MoveContentExportNotificationsToMigrationCategory.send_later_if_production(:run)
  end

  def self.down
    Notification.where(:name => ['Content Export Finished', 'Content Export Failed']).
        update_all(:category => 'Other')
  end
end
