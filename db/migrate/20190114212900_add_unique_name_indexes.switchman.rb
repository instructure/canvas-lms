# frozen_string_literal: true

class AddUniqueNameIndexes < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def change
    add_index :switchman_shards, [:database_server_id, :name], unique: true
    add_index :switchman_shards, :database_server_id, unique: true, where: "name IS NULL", name: 'index_switchman_shards_unique_primary_shard'
    add_index :switchman_shards, "(true)", unique: true, where: "database_server_id IS NULL AND name IS NULL", name: 'index_switchman_shards_unique_primary_db_and_shard'
  end
end
