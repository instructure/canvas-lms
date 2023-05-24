# frozen_string_literal: true

class AddUniqueTypeToFolders < ActiveRecord::Migration[5.1]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_column :folders, :unique_type, :string
    add_index :folders,
              %i[unique_type context_id context_type],
              unique: true,
              where: "unique_type IS NOT NULL AND workflow_state <> 'deleted'",
              algorithm: :concurrently
  end
end
