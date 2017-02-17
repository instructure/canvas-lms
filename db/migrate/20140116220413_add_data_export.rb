class AddDataExport < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :data_exports do |t|
      t.integer :user_id, :limit => 8
      t.integer :context_id, :limit => 8
      t.string :context_type
      t.string :workflow_state
      t.datetime :created_at
      t.datetime :updated_at
    end
    add_index :data_exports, [:context_id, :context_type]
    add_index :data_exports, :user_id
    add_foreign_key :data_exports, :users
  end

  def self.down
    drop_table :data_exports
  end
end
