# frozen_string_literal: true

class AddBetterUserPreferenceValueIndex < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    UserPreferenceValue.where(value: UserPreferenceValue::EXTERNAL).delete_all

    DataFixup::DeleteDuplicateRows.run(UserPreferenceValue.where(sub_key: nil), :user_id, :key)

    add_index :user_preference_values,
              [:user_id, :key],
              unique: true,
              where: "sub_key IS NULL",
              name: "index_user_preference_values_on_key_no_sub_key",
              algorithm: :concurrently
  end

  def down
    remove_index :user_preference_values, name: "index_user_preference_values_on_key_no_sub_key"
  end
end
