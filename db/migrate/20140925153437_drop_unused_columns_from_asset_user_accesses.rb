class DropUnusedColumnsFromAssetUserAccesses < ActiveRecord::Migration
  tag :postdeploy

  def up
    remove_column :asset_user_accesses, :interaction_seconds
    remove_column :asset_user_accesses, :count
    remove_column :asset_user_accesses, :progress
  end

  def down
    add_column :asset_user_accesses, :interaction_seconds, :float
    add_column :asset_user_accesses, :count, :integer
    add_column :asset_user_accesses, :progress, :integer
  end
end
