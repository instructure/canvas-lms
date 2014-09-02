class AddForeignKeyIndexes4 < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :account_reports, :attachment_id, algorithm: :concurrently
    add_index :attachments, :replacement_attachment_id, algorithm: :concurrently, where: "replacement_attachment_id IS NOT NULL"
    add_index :discussion_topics, :old_assignment_id, algorithm: :concurrently, where: "old_assignment_id IS NOT NULL"
    add_index :enrollment_terms, :sis_batch_id, algorithm: :concurrently, where: "sis_batch_id IS NOT NULL"
    add_index :zip_file_imports, :attachment_id, algorithm: :concurrently
    add_index :zip_file_imports, :folder_id, algorithm: :concurrently
  end

  def self.down
    remove_index :account_reports, :attachment_id
    remove_index :attachments, :replacement_attachment_id
    remove_index :discussion_topics, :old_assignment_id
    remove_index :enrollment_terms, :sis_batch_id
    remove_index :zip_file_imports, :attachment_id
    remove_index :zip_file_imports, :folder_id
  end
end
