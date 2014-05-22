class RemoveAssignmentIntegrationIdIndex < ActiveRecord::Migration
  tag :predeploy

  def up
    if index_exists?(:assignments, :integration_id)
      remove_index :assignments, :integration_id
    end
  end

  def down
  end
end
