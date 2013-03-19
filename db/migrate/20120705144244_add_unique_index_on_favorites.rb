class AddUniqueIndexOnFavorites < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    # cleanup must happen synchronously in order to create the unique index
    # the extra subquery is necessary to avoid error 1093 on mysql
    Favorite.where("id NOT IN (SELECT * FROM (SELECT MIN(id) FROM favorites GROUP BY user_id, context_id, context_type) x)").delete_all
    add_index :favorites, [:user_id, :context_id, :context_type], :unique => true, :name => "index_favorites_unique_user_object"
  end

  def self.down
    remove_index :favorites, :name => "index_favorites_unique_user_object"
  end
end
