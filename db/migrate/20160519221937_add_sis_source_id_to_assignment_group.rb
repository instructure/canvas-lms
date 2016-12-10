class AddSisSourceIdToAssignmentGroup < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :assignment_groups, :sis_source_id, :string
  end
end
