class CreateUserProfilesTable < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :user_profiles do |t|
      t.text   :bio
      t.string :title
      t.references :user, :limit => 8
    end
  end

  def self.down
    drop_table :user_profiles
  end
end
