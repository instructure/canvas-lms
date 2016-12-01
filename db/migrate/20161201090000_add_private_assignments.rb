class AddPrivateAssignments < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :assignments, :hide_submissions_from_students, :boolean, default: false
    add_column :submissions, :hidden_from_students, :boolean, default: false
  end
end
