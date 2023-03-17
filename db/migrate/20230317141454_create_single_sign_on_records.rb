# frozen_string_literal: true

class CreateSingleSignOnRecords < ActiveRecord::Migration[7.0]
  tag :predeploy

  def change
    create_table :single_sign_on_records do |t|
      t.integer :user_id, null: false
      t.integer :external_id, null: false
      t.text :last_payload, null: false

      t.timestamps
    end

    add_index :single_sign_on_records, :user_id, unique: true
    add_index :single_sign_on_records, :external_id, unique: true
  end
end
