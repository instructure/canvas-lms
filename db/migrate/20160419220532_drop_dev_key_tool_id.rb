class DropDevKeyToolId < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    remove_column :developer_keys, :tool_id
  end

  def down
    add_column :developer_keys, :tool_id, :string
    add_index :developer_keys, [:tool_id], unique: true
  end
end
