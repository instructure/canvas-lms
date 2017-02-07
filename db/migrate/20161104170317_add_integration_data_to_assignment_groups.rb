class AddIntegrationDataToAssignmentGroups < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :assignment_groups, :integration_data, :text
  end

  def self.down
    remove_column :assignment_groups, :integration_data, :text
  end
end
