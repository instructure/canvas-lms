#
# Copyright (C) 2017 - present Instructure, Inc.
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


module CourseSettingsPage
  #------------------------- Selectors --------------------------
  def course_details_tab_link_selector
    '#course_details_tab'
  end

  def sections_tab_link_selector
    '#sections_tab'
  end

  def navigation_tab_link_selector
    '#navigation_tab'
  end

  def apps_tab_link_selector
    '#external_tools_tab'
  end

  def feature_options_tab_link_selector
    '#feature_flags_tab'
  end

  #------------------------- Elements ---------------------------
  def course_details_tab_link
    f(course_details_tab_link_selector)
  end

  def sections_tab_link
    f(sections_tab_link_selector)
  end

  def navigation_tab_link
    f(navigation_tab_link_selector)
  end

  def apps_tab_link
    f(apps_tab_link_selector)
  end

  def feature_options_tab_link
    f(feature_options_tab_link_selector)
  end

  #----------------------- Actions/Methods ----------------------
  def visit_course_settings(course)
    get "courses/#{course.id}/settings"
  end

  def visit_course_details_tab
    course_details_tab_link.click
  end

  def visit_sections_tab
    sections_tab_link.click
  end

  def visit_navigation_tab
    navigation_tab_link.click
  end

  def visit_apps_tab
    apps_tab_link.click
  end

  def visit_feature_options_tab
    feature_options_tab_link.click
  end
end
