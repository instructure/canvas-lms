class AddHomePageAnnouncementLimitToCourses < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :courses, :home_page_announcement_limit, :integer
  end
end
