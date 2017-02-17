class AddAggregateCountsToCollections < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :collections, :followers_count, :integer, :default => 0
    add_column :collections, :items_count, :integer, :default => 0
  end

  def self.down
    remove_column :collections, :followers_count
    remove_column :collections, :items_count
  end
end
