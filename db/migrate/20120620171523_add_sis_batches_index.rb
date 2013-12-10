class AddSisBatchesIndex < ActiveRecord::Migration
  tag :predeploy

  disable_ddl_transaction!

  def self.up
    # this index may or may not have been created on dev boxes
    remove_index :sis_batches, :name => "index_sis_batches_for_accounts" rescue nil

    case connection.adapter_name
    when 'PostgreSQL'
      # select * from sis_batches where account_id = ? and workflow_state = 'created' order by created_at
      # select count(*) from sis_batches where account_id = ? and workflow_state = 'created'
      # this index is highly optimized for the sis batch job processor workflow
      add_index :sis_batches, [:account_id, :created_at], :algorithm => :concurrently, :where => "workflow_state='created'", name: "index_sis_batches_pending_for_accounts"
      # select * from sis_batches where account_id = ? order by created_at desc limit 1
    else
      add_index :sis_batches, [:workflow_state, :account_id, :created_at], :name => "index_sis_batches_pending_for_accounts"
    end
    add_index :sis_batches, [:account_id, :created_at], :algorithm => :concurrently, :name => "index_sis_batches_account_id_created_at"
  end

  def self.down
    remove_index :sis_batches, :name => "index_sis_batches_pending_for_accounts"
    remove_index :sis_batches, :name => "index_sis_batches_account_id_created_at"
  end
end
