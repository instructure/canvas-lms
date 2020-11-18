# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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
