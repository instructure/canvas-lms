class AddBetterUserPreferenceValueIndex < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    UserPreferenceValue.where(:value => UserPreferenceValue::EXTERNAL).delete_all

    first_run = true
    pairs_to_fix = []
    while first_run || pairs_to_fix.any?
      first_run = false
      pairs_to_fix = UserPreferenceValue.group(:user_id, :key).where("sub_key IS NULL").
        having("COUNT(*) > 1").pluck(:user_id, :key)
      pairs_to_fix.each do |user_id, key|
        UserPreferenceValue.where(:user_id => user_id, :key => key).where("sub_key IS NULL").
          order(:id => :desc).offset(1).delete_all
      end
    end

    add_index :user_preference_values, [:user_id, :key], unique: true, where: "sub_key IS NULL",
      name: "index_user_preference_values_on_key_no_sub_key", algorithm: :concurrently
  end

  def down
    remove_index :user_preference_values, name: "index_user_preference_values_on_key_no_sub_key"
  end
end
