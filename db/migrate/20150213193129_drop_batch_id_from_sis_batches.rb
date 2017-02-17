class DropBatchIdFromSisBatches < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    remove_column :sis_batches, :batch_id
  end

  def down
    add_column :sis_batches, :batch_id, :string
  end
end
