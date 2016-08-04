class AddNotInFinalGradeToAssignments < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :assignments, :omit_from_final_grade, :boolean
  end
end
