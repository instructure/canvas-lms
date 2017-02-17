class AddForeignKeyIndexes5 < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :discussion_topics, :external_feed_id, algorithm: :concurrently, where: "external_feed_id IS NOT NULL"
  end
end
