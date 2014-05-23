# This migration comes from switchman (originally 20130328212039)
class CreateSwitchmanShards < ActiveRecord::Migration
  tag :predeploy

  def self.runnable?
    CANVAS_RAILS3
  end

  def self.up
    unless table_exists?('switchman_shards')
      create_table :switchman_shards do |t|
        t.string :name
        t.string :database_server_id
        t.boolean :default, :default => false, :null => false
      end
    end
    add_column :switchman_shards, :settings, :text
  end

  def self.down
    drop_table :switchman_shards
  end
end
