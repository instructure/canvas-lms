# This migration comes from switchman (originally 20130328212039)
class CreateSwitchmanShards < ActiveRecord::Migration
  tag :predeploy

  def change
    create_table :switchman_shards do |t|
      t.string :name
      t.string :database_server_id
      t.boolean :default, :default => false, :null => false
    end
  end
end
