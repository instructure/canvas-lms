class RemoveAssignmentIntegrationIdIndex < ActiveRecord::Migration
  tag :predeploy

  def self.up
    if index_exists? :assignments, 'index_assignments_on_integration_id', :name => 'index_assignments_on_integration_id'
      remove_index :assignments, :name => 'index_assignments_on_integration_id'
    end
  end

  def self.down
  end
end
