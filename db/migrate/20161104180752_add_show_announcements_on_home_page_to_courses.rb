class AddShowAnnouncementsOnHomePageToCourses < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :courses, :show_announcements_on_home_page, :boolean
  end
end
