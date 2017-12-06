class AddAllowMembershipServiceAccessToContextExternalTool < ActiveRecord::Migration[5.0]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column :context_external_tools, :allow_membership_service_access, :boolean
    change_column_default :context_external_tools, :allow_membership_service_access, false

    DataFixup::BackfillNulls.run(
      ContextExternalTool, [:allow_membership_service_access], default_value: false
    )

    change_column_null :context_external_tools, :allow_membership_service_access, false
  end

  def down
    remove_column :context_external_tools, :allow_membership_service_access, :boolean
  end
end
