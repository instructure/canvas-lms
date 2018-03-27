class AddMyInfoSwitchToCourses < ActiveRecord::Migration
  tag :predeploy
  def change
    add_column :courses, :enable_my_info, :boolean
  end
end
