class AddSubscriptionIdToAssignmentConfigurationToolLookups < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :assignment_configuration_tool_lookups, :subscription_id, :string
  end
end
