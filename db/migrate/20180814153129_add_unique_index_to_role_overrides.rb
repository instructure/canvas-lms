# frozen_string_literal: true

class AddUniqueIndexToRoleOverrides < ActiveRecord::Migration[5.1]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    DataFixup::DeleteDuplicateRows.run(RoleOverride.where(context_type: "Account"), :context_id, :permission, :role_id)

    add_index :role_overrides,
              %i[context_id context_type role_id permission],
              unique: true,
              algorithm: :concurrently,
              name: "index_role_overrides_on_context_role_permission"
    remove_index :role_overrides, [:context_id, :context_type]
  end

  def down
    remove_index :role_overrides, name: "index_role_overrides_on_context_role_permission"
    add_index :role_overrides, [:context_id, :context_type]
  end
end
