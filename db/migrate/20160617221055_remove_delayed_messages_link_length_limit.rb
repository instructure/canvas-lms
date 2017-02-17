class RemoveDelayedMessagesLinkLengthLimit < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    change_column :delayed_messages, :link, :text
  end

  def down
    change_column :delayed_messages, :link, :text, length: 255
  end
end
