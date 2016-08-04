class AddPreferredPluginCourseIdToCanvadocs < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :canvadocs, :preferred_plugin_course_id, :string
  end
end
