# frozen_string_literal: true

class RenameSwitchmanShardsFkIfNecessary < ActiveRecord::Migration[5.1]
  tag :predeploy

  def up
    alter_constraint(:switchman_shards, find_foreign_key(:switchman_shards, :switchman_shards, column: :delayed_jobs_shard_id), new_name: "fk_rails_45bd80a9c8")
  end
end
