class CreateOneTimePasswords < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :one_time_passwords do |t|
      t.integer :user_id, limit: 8, null: false
      t.string :code, null: false
      t.boolean :used, null: false, default: false
      t.timestamps null: false
    end
    add_index :one_time_passwords, [:user_id, :code], unique: true
    add_foreign_key :one_time_passwords, :users
  end
end
