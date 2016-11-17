class DropDataExports < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    drop_table :data_exports
  end

  def down
    create_table :data_exports do |t|
      t.integer :user_id, :limit => 8, :null => false
      t.integer :context_id, :limit => 8, :null => false
      t.string :context_type, :null => false
      t.string :workflow_state, :null => false
      t.datetime :created_at
      t.datetime :updated_at
    end
    add_index :data_exports, [:context_id, :context_type]
    add_index :data_exports, :user_id
    add_foreign_key :data_exports, :users
  end
end
