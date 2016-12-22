class AddShowAnnouncementsOnHomePageToCourses < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :courses, :show_announcements_on_home_page, :boolean
  end
end
