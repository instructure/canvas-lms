class AddSisBatchDiffing < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column :sis_batches, :diffing_data_set_identifier, :string
    add_column :sis_batches, :diffing_remaster, :boolean
    add_column :sis_batches, :generated_diff_id, :integer, :limit => 8
    add_index :sis_batches, [:account_id, :diffing_data_set_identifier, :created_at],
      name: 'index_sis_batches_diffing',
      algorithm: :concurrently
  end

  def down
    remove_column :sis_batches, :generated_diff_id
    remove_column :sis_batches, :diffing_remaster
    remove_column :sis_batches, :diffing_data_set_identifier
  end
end
