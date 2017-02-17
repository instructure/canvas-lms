class AddAssignmentModeratedGrading < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    add_column :assignments, :moderated_grading, :boolean
  end

  def down
    remove_column :assignments, :moderated_grading
  end
end
