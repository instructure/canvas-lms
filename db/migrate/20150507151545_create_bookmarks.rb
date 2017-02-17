class CreateBookmarks < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    create_table :bookmarks_bookmarks do |t|
      t.integer :user_id, limit: 8, null: false
      t.string :name, null: false
      t.string :url, null: false
      t.integer :position
      t.text :json
    end

    add_foreign_key :bookmarks_bookmarks, :users
    add_index :bookmarks_bookmarks, :user_id
  end

  def down
    drop_table :bookmarks_bookmarks
  end
end
