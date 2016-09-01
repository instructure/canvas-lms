class CreateEpubExports < ActiveRecord::Migration
  tag :predeploy
  def self.up
    create_table :epub_exports do |t|
      t.integer :content_export_id, :course_id, :user_id, limit: 8
      t.string :workflow_state, default: "created"
      t.timestamps null: true
    end

    add_foreign_key_if_not_exists :epub_exports, :users, delay_validation: true
    add_foreign_key_if_not_exists :epub_exports, :courses, delay_validation: true
    add_foreign_key_if_not_exists :epub_exports, :content_exports, delay_validation: true

    add_index :epub_exports, :user_id
    add_index :epub_exports, :course_id
    add_index :epub_exports, :content_export_id

  end

  def self.down
    drop_table :epub_exports
  end
end
