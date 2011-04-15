class AddLastCourseToCourseSection < ActiveRecord::Migration
  def self.up
    add_column :course_sections, :last_course_id, :integer, :limit => 8
  end
  
  def self.down
    remove_column :course_sections, :last_course_id
  end
end
