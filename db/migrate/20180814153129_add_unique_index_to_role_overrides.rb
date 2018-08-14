class AddUniqueIndexToRoleOverrides < ActiveRecord::Migration[5.1]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    Account.find_ids_in_ranges(:batch_size => 100) do |min_id, max_id|
      account_ids = Account.where(:id => min_id..max_id).pluck(:id)
      dups = RoleOverride.where(:context_type => "Account", :context_id => account_ids).
        group(:context_id, :permission, :role_id).having("COUNT(*) > 1").pluck(:context_id, :permission, :role_id)
      dups.each do |account_id, permission, role_id|
        RoleOverride.where(:context_type => "Account", :context_id => account_id, :permission => permission, :role_id => role_id).order(:id).offset(1).delete_all
      end
    end

    add_index :role_overrides, [:context_id, :context_type, :role_id, :permission], unique: true, algorithm: :concurrently,
      name: "index_role_overrides_on_context_role_permission"
    remove_index :role_overrides, [:context_id, :context_type]
  end

  def down
    remove_index :role_overrides, name: "index_role_overrides_on_context_role_permission"
    add_index :role_overrides, [:context_id, :context_type]
  end
end
