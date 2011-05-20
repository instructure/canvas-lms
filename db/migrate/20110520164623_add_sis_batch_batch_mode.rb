class AddSisBatchBatchMode < ActiveRecord::Migration
  def self.up
    add_column :sis_batches, :batch_mode, :boolean
    add_column :sis_batches, :batch_mode_term_id, :integer, :limit => 8
  end

  def self.down
    remove_column :sis_batches, :batch_mode
    remove_column :sis_batches, :batch_mode_term_id
  end
end
