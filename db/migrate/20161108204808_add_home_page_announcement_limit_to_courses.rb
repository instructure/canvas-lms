class AddHomePageAnnouncementLimitToCourses < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :courses, :home_page_announcement_limit, :integer
  end
end
