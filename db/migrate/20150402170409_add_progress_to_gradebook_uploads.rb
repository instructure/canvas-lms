class AddProgressToGradebookUploads < ActiveRecord::Migration
  tag :predeploy

  def change
    remove_column :gradebook_uploads, :context_type
    remove_column :gradebook_uploads, :context_id

    add_column :gradebook_uploads, :course_id, :integer, limit: 8, null: false
    add_column :gradebook_uploads, :user_id, :integer, limit: 8, null: false
    add_column :gradebook_uploads, :progress_id, :integer, limit: 8, null: false
    add_column :gradebook_uploads, :gradebook, :text, limit: 10.megabytes

    add_index :gradebook_uploads, [:course_id, :user_id], unique: true
    add_index :gradebook_uploads, :progress_id

    add_foreign_key :gradebook_uploads, :courses
    add_foreign_key :gradebook_uploads, :users
    add_foreign_key :gradebook_uploads, :progresses
  end
end

