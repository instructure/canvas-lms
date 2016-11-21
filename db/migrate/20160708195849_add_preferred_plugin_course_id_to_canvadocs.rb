class AddPreferredPluginCourseIdToCanvadocs < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :canvadocs, :preferred_plugin_course_id, :string
  end
end
