class AddMaterializedDiscussions < ActiveRecord::Migration
  tag :predeploy

  def self.up
    # this is fixed in a later migration
    # rubocop:disable Migration/PrimaryKey
    create_table :discussion_topic_materialized_views, :id => false do |t|
      t.integer :discussion_topic_id, :limit => 8
      t.text :json_structure, :limit => 10.megabytes
      t.text :participants_array, :limit => 10.megabytes
      t.text :entry_ids_array, :limit => 10.megabytes

      t.timestamps null: true
    end
    add_index :discussion_topic_materialized_views, :discussion_topic_id, :unique => true, :name => "index_discussion_topic_materialized_views"
  end

  def self.down
    drop_table :discussion_topic_materialized_views
  end
end
