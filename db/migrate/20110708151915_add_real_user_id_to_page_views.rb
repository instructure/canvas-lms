class AddRealUserIdToPageViews < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :page_views, :real_user_id, :integer, :limit => 8
  end

  def self.down
    remove_column :page_views, :real_user_id
  end
end
