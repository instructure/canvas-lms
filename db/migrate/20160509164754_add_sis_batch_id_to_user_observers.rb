class AddSisBatchIdToUserObservers < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  tag :predeploy
  def change
    add_column :user_observers, :sis_batch_id, :integer, limit: 8
    add_index :user_observers, :sis_batch_id, where: "sis_batch_id IS NOT NULL", algorithm: :concurrently
  end
end
