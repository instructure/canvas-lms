# frozen_string_literal: true

# This migration comes from switchman_inst_jobs (originally 20200818130101)
class AddOnHoldToSwitchmanShards < ActiveRecord::Migration[5.2]
  tag :predeploy

  def change
    add_column :switchman_shards, :jobs_held, :bool, default: false
  end
end
