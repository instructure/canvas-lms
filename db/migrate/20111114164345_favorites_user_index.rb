class FavoritesUserIndex < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_index :favorites, [:user_id]
  end

  def self.down
    remove_index :favorites, [:user_id]
  end
end
