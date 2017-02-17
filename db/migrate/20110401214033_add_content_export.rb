class AddContentExport < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :content_exports do |t|
      t.integer :user_id, :limit => 8
      t.integer :course_id, :limit => 8
      t.integer :attachment_id, :limit => 8
      t.string :export_type
      t.text :settings
      t.float :progress
      t.string :workflow_state
      t.timestamps null: true
    end
    add_index :content_exports, [:course_id]
    add_index :content_exports, [:user_id]
  end

  def self.down
    drop_table :content_exports
  end
end
