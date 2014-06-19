class AddIntegrationDataToAssignment < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :assignments, :integration_data, :text
  end

  def self.down
    remove_column :assignments, :integration_data
  end
end
