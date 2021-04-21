# frozen_string_literal: true

# This migration comes from switchman_inst_jobs (originally 20200822014259)
class AddBlockStrandedToSwitchmanShards < ActiveRecord::Migration[5.2]
  tag :predeploy

  def change
    add_column :switchman_shards, :block_stranded, :bool, default: false
  end
end
