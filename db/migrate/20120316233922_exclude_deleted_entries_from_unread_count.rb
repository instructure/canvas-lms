class ExcludeDeletedEntriesFromUnreadCount < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::ExcludeDeletedEntriesFromUnreadCount.send_later_if_production(:run)
  end

  def self.down
  end
end
