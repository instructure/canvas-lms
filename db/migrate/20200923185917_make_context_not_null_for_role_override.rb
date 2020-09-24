class MakeContextNotNullForRoleOverride < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    change_column_null :role_overrides, :context_id, false
    change_column_null :role_overrides, :context_type, false
  end

  def down
    change_column_null :role_overrides, :context_id, true
    change_column_null :role_overrides, :context_type, true
  end
end
