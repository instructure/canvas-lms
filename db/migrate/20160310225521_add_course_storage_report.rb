class AddCourseStorageReport < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    DataFixup::AddNewDefaultReport.send_later_if_production(:run, 'course_storage_csv')
  end
end
