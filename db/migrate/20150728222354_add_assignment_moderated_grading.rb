class AddAssignmentModeratedGrading < ActiveRecord::Migration
  tag :predeploy

  def up
    add_column :assignments, :moderated_grading, :boolean
  end

  def down
    remove_column :assignments, :moderated_grading
  end
end
