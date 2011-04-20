class RenameLastCourseToNonxlistCourseInCourseSection < ActiveRecord::Migration
  def self.up
    rename_column :course_sections, :last_course_id, :nonxlist_course_id
  end
  
  def self.down
    rename_column :course_sections, :nonxlist_course_id, :last_course_id
  end
end
