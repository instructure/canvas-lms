# This migration comes from switchman (originally 20161206323434)
class AddBackDefaultStringLimitsSwitchman < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    add_string_limit_if_missing :switchman_shards, :name
    add_string_limit_if_missing :switchman_shards, :database_server_id
  end

  def add_string_limit_if_missing(table, column)
    return if column_exists?(table, column, :string, limit: 255)
    change_column table, column, :string, limit: 255
  end
end
