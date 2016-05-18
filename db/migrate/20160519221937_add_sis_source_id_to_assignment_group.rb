class AddSisSourceIdToAssignmentGroup < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :assignment_groups, :sis_source_id, :string
  end
end
