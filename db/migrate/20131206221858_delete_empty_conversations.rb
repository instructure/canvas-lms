class DeleteEmptyConversations < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::DeleteEmptyConversations.send_later_if_production(:run)
  end
end
