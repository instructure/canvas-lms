class AddStartedAtToSisBatches < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :sis_batches, :started_at, :datetime
  end
end
