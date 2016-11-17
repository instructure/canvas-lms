class AddStartedAtToSisBatches < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :sis_batches, :started_at, :datetime
  end
end
