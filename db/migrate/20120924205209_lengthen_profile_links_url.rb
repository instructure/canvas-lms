class LengthenProfileLinksUrl < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    change_column :user_profile_links, :url, :string, :limit => 4.kilobytes
  end

  def self.down
    change_column :user_profile_links, :url, :string, :limit => 255
  end
end
