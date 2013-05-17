class DropAllowStudentAssignmentEditsFromCourses < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    remove_column :courses, :allow_student_assignment_edits
  end

  def self.down
    add_column :courses, :allow_student_assignment_edits, :boolean
  end
end
