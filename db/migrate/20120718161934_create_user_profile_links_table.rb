class CreateUserProfileLinksTable < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :user_profile_links do |t|
      t.string :url
      t.string :title
      t.references :user_profile, :limit => 8
      t.timestamps
    end
  end

  def self.down
    drop_table :user_profile_links
  end
end
