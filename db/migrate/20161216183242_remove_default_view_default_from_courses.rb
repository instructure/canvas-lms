class RemoveDefaultViewDefaultFromCourses < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    change_column_default :courses, :default_view, nil
  end

  def down
    change_column_default :courses, :default_view, "feed"
  end
end
