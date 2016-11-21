class DeleteEmptyConversations < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    DataFixup::DeleteEmptyConversations.send_later_if_production(:run)
  end
end
