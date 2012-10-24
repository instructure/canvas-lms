class LengthenProfileLinksUrl < ActiveRecord::Migration
  tag :predeploy

  def self.up
    change_column :user_profile_links, :url, :string, :limit => 4.kilobytes
  end

  def self.down
    change_column :user_profile_links, :url, :string, :limit => 255
  end
end
