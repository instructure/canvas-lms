class CreateUserMergeData < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :user_merge_data do |t|
      t.integer :user_id, limit: 8, null: false
      t.integer :from_user_id, limit: 8, null: false
      t.timestamps null: false
      t.string :workflow_state, null: false, default: 'active'
    end

    create_table :user_merge_data_records do |t|
      t.integer :user_merge_data_id, limit: 8, null: false
      t.integer :context_id, limit: 8, null: false
      t.integer :previous_user_id, limit: 8, null: false
      t.string :context_type, null: false
      t.string :previous_workflow_state
    end

    add_index :user_merge_data, :user_id
    add_index :user_merge_data, :from_user_id
    add_index :user_merge_data_records, :user_merge_data_id
    add_index :user_merge_data_records, [:context_id, :context_type, :user_merge_data_id, :previous_user_id],
              unique: true, name: "index_user_merge_data_records_on_context_id_and_context_type"

    add_foreign_key :user_merge_data, :users
    add_foreign_key :user_merge_data_records, :user_merge_data, column: :user_merge_data_id
  end
end
