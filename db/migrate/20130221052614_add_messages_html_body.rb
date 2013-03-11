class AddMessagesHtmlBody < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :messages, :html_body, :text
  end

  def self.down
    remove_column :messages, :html_body
  end
end
