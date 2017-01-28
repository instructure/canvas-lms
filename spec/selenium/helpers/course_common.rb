require File.expand_path(File.dirname(__FILE__) + '/../common')

module CourseCommon
  # for helper methods than can be used throughout the entire course.

  # Deletes an item using the Gear Menu.
  # can be used in Discussions, Groups, Announcements, Pages, Quizzes, Assignments
  # feel free to note any other uses.
  def delete_via_gear_menu(num = 0)
    # Clicks the gear menu for announcement num
    ff('.al-trigger-gray')[num].click
    wait_for_ajaximations
    # Clicks delete menu item
    f('.icon-trash.ui-corner-all').click
    driver.switch_to.alert.accept
    wait_for_animations
  end
end
