class AddForeignKeyIndexes3 < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :account_reports, :attachment_id, algorithm: :concurrently
    add_index :zip_file_imports, :attachment_id, algorithm: :concurrently
  end

  def self.down
    remove_index :account_reports, :attachment_id
    remove_index :zip_file_imports, :attachment_id
  end
end
