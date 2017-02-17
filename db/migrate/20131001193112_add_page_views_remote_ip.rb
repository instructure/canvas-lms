class AddPageViewsRemoteIp < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :page_views, :remote_ip, :string
  end

  def self.down
    remove_column :page_views, :remote_ip
  end
end
