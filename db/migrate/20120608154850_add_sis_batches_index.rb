class AddSisBatchesIndex < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_index :sis_batches, [:account_id, :workflow_state, :created_at], :name => "index_sis_batches_for_accounts"
  end

  def self.down
    remove_index :sis_batches, :name => "index_sis_batches_for_accounts"
  end
end
