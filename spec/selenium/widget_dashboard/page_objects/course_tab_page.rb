# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../../common"
require_relative "../../helpers/student_dashboard_common"
require_relative "../../helpers/files_common"

module CourseTabPage
  include StudentDashboardCommon
  include FilesCommon

  #------------------------------ Selectors -----------------------------

  def course_tab_selector
    "span[data-testid='tab-courses']"
  end

  def course_card_selector(course_name)
    "div.ic-DashboardCard[aria-label='#{course_name}']"
  end

  def course_card_title_link_selector(course_name)
    "div[aria-label='#{course_name}'] a.ic-DashboardCard__link"
  end

  def course_card_actions_selector(course_name, action_title)
    "a[title='#{action_title} - #{course_name}']"
  end

  def course_card_action_links_selector(course_name)
    "nav[aria-label='Actions for #{course_name}'] a"
  end

  def course_card_action_badge_selector
    "span.ic-DashboardCard__action-badge"
  end
  #------------------------------ Elements ------------------------------

  def course_tab
    f(course_tab_selector)
  end

  def course_card(course_name)
    f(course_card_selector(course_name))
  end

  def all_course_cards
    ff("[data-testid='draggable-card']")
  end

  def course_card_title_link(course_name)
    f(course_card_title_link_selector(course_name))
  end

  def course_card_action(course_name, action_title)
    f(course_card_actions_selector(course_name, action_title))
  end

  def all_action_links(course_name)
    ff(course_card_action_links_selector(course_name))
  end

  def course_card_action_badge(course_name, action_title)
    f("#{course_card_actions_selector(course_name, action_title)} #{course_card_action_badge_selector}")
  end

  #------------------------------ Actions -------------------------------

  def course_tab_setup
    dashboard_student_setup
    dashboard_announcement_setup
    dashboard_course_assignment_setup
    course_with_files_setup
    set_widget_dashboard_flag(feature_status: true)
    enable_widget_dashboard_for(@student)
  end

  def course_with_files_setup
    @course3 = course_factory(active_all: true, course_name: "Course 3 with files")
    @course3.enroll_student(@student, enrollment_state: :active)

    add_file(fixture_file_upload("a_file.txt", "text/plain"), @course3, "a_file.txt")
    add_file(fixture_file_upload("b_file.txt", "text/plain"), @course2, "b_file.txt")
  end

  def go_to_course_tab
    get "/"
    expect(course_tab).to be_displayed
    course_tab.click
    wait_for_ajaximations
  end
end
