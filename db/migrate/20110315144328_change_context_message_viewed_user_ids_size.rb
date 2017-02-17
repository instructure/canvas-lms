class ChangeContextMessageViewedUserIdsSize < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    change_column :context_messages, :viewed_user_ids, :text
  end

  def self.down
    change_column :context_messages, :viewed_user_ids, :string
  end
end
