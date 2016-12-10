class AddUniqueIndexOnFavorites < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    # cleanup must happen synchronously in order to create the unique index
    Favorite.where("id NOT IN (SELECT * FROM (SELECT MIN(id) FROM #{Favorite.quoted_table_name} GROUP BY user_id, context_id, context_type) x)").delete_all
    add_index :favorites, [:user_id, :context_id, :context_type], :unique => true, :name => "index_favorites_unique_user_object"
  end

  def self.down
    remove_index :favorites, :name => "index_favorites_unique_user_object"
  end
end
