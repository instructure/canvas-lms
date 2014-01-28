class DisallowNullOnTeacherNotesColumn < ActiveRecord::Migration
  tag :predeploy

  def self.up
    CustomGradebookColumn.where(teacher_notes: nil).update_all(teacher_notes: false)
    change_column_null :custom_gradebook_columns, :teacher_notes, false
  end

  def self.down
    change_column_null :custom_gradebook_columns, :teacher_notes, true
  end
end
