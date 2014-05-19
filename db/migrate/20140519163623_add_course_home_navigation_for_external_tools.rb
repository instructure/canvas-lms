class AddCourseHomeNavigationForExternalTools < ActiveRecord::Migration
  tag :predeploy
  def self.up
    add_column :context_external_tools, :has_course_home_sub_navigation, :boolean
    add_index :context_external_tools, [:context_id, :context_type, :has_course_home_sub_navigation], :name => "external_tools_course_home_sub_navigation"
  end

  def self.down
    remove_column :context_external_tools, :has_course_home_sub_navigation
    remove_index :context_external_tools, :name => "external_tools_course_home_sub_navigation"
  end
end
