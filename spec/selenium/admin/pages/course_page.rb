#
# Copyright (C) 2019 - present Instructure, Inc.
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
require_relative '../../common'

module CourseHomePage

  # ---------------------- Elements ----------------------

  def course_header
    f("#content h2")
  end

  def course_options
    f('.course-options')
  end

  def course_options_analytics2_link
    fj(".course-options a:contains('Analytics 2')")
  end

  def course_options_analytics1_link
    fj(".course-options a:contains('View Course Analytics')")
  end
  
  def course_nav_menu
    f('#section-tabs')
  end

  def course_nav_analytics2_link
    fj(".section a:contains('Analytics 2')")
  end

  def course_nav_analytics1_link
    fj(".section a:contains('View Course Analytics')")
  end

  def course_user_link(user_id)
    f("a[data-student_id='#{user_id}']")
  end

  def manage_user_link(user_name)
    fj("a:contains('Manage #{user_name}')")
  end

  def manage_user_options_list
    f("ul.al-options[aria-expanded='true']")
  end

  def manage_user_analytics_2_link
    fj(".al-options a:contains('Analytics 2')")
  end

  def manage_user_analytics_1_link
    fj(".al-options a:contains('Analytics')")
  end

  def user_profile_page_actions
    f("#right_nav")
  end

  def user_profile_actions_analytics_2_link
    fj("#right_nav a:contains('Analytics 2')")
  end

  def user_profile_actions_analytics_1_link
    fj("#right_nav a:contains('Analytics')")
  end

  # ---------------------- Actions ----------------------
  def visit_course_home_page(course_id)
    get "/courses/#{course_id}"
  end

  def visit_course_people_page(course_id)
    get "/courses/#{course_id}/users"
  end

  def visit_course_user_profile_page(course_id, user_id)
    get "/courses/#{course_id}/users/#{user_id}"
  end
end
