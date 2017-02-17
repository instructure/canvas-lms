class AddSubmissionContextCodeToFolders < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  tag :predeploy

  def change
    add_column :folders, :submission_context_code, :string
    add_index :folders, [:submission_context_code, :parent_folder_id], unique: true, algorithm: :concurrently
  end
end
