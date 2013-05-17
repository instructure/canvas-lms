class CreateProgresses < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :progresses do |t|
      t.integer :context_id, :limit => 8
      t.string :context_type
      t.integer :user_id, :limit => 8
      t.string :tag, :null => false
      t.float :completion
      t.string :delayed_job_id
      t.string :workflow_state
      t.datetime :created_at
      t.datetime :updated_at
      t.text :message
    end
    add_index :progresses, [:context_id, :context_type], :name => "index_progresses_on_context_id_and_context_type"
    add_index :progresses, [:user_id], :name => "index_progresses_on_user_id"
  end

  def self.down
    drop_table :progresses
  end
end
