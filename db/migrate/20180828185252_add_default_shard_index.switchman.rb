# This migration comes from switchman (originally 20180828183945)
class AddDefaultShardIndex < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def change
    Switchman::Shard.where(default: nil).update_all(default: false)
    change_column_default :switchman_shards, :default, false
    change_column_null :switchman_shards, :default, false
    options = if connection.adapter_name == 'PostgreSQL'
                { unique: true, where: "\"default\"" }
              else
                {}
              end
    add_index :switchman_shards, :default, options
  end
end
