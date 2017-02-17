class CreateGradebookCsv < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :gradebook_csvs do |t|
      t.integer :user_id, limit: 8, null: false
      t.integer :attachment_id, limit: 8, null: false
      t.integer :progress_id, limit: 8, null: false
      t.integer :course_id, limit: 8, null: false
    end

    add_foreign_key :gradebook_csvs, :users
    add_foreign_key :gradebook_csvs, :attachments
    add_foreign_key :gradebook_csvs, :progresses
    add_foreign_key :gradebook_csvs, :courses

    add_index :gradebook_csvs, [:user_id, :course_id]
  end
end
