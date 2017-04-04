class RemovePreferredPluginCourseIdFromCanvadocs < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def change
    remove_column :canvadocs, :preferred_plugin_course_id
  end
end
