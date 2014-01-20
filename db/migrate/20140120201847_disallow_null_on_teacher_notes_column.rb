class DisallowNullOnTeacherNotesColumn < ActiveRecord::Migration
  tag :predeploy

  def self.up
    change_column_null :custom_gradebook_columns, :teacher_notes, false
  end

  def self.down
    change_column_null :custom_gradebook_columns, :teacher_notes, true
  end
end
