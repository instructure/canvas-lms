class AddTemplateCourseIdToCourses < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :courses, :template_course_id, :integer, :limit => 8
    add_index :courses, [:template_course_id]
  end

  def self.down
    remove_index :courses, [:template_course_id]
    remove_column :courses, :template_course_id
  end
end
