class AddCourseHomeNavigationForExternalTools < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_column :context_external_tools, :has_course_home_sub_navigation, :boolean
    add_index :context_external_tools, [:context_id, :context_type, :has_course_home_sub_navigation], :name => "external_tools_course_home_sub_navigation", :algorithm => :concurrently
  end

  def self.down
    remove_column :context_external_tools, :has_course_home_sub_navigation
    remove_index :context_external_tools, :name => "external_tools_course_home_sub_navigation"
  end
end
