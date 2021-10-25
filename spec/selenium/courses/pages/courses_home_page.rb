# frozen_string_literal: true

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
require_relative './course_wizard_page_component'

module CoursesHomePage
  #------------------------- Sections ---------------------------
  # These are the sections that can be on this page. Use the page components/objects on their own, not included here
  # Global Nav
  # Main Content - can be anything, any type of home page, wikipages, recent activity stream, etc.
  # Course Menu
  # Right side secondary content
  # Course Wizard
  include CourseWizardPageComponent

  #------------------------- Selectors --------------------------
  def secondary_content_selector
    '.ic-app-main-content__secondary'
  end

  def choose_home_page_link_selector
    "#{secondary_content_selector} #choose_home_page"
  end

  def course_setup_checklist_selector
    "a.wizard_popup_link"
  end

  def accept_enrollment_alert_selector
    ".ic-notification button[name='accept']"
  end

  #------------------------- Elements ---------------------------
  def secondary_content
    f(secondary_content_selector)
  end

  def choose_home_page_btn
    f(choose_home_page_link_selector)
  end

  def course_setup_checklist_btn
    f(course_setup_checklist_selector)
  end

  def unpublish_btn
    fj("button:contains('Unpublish')")
  end

  def publish_btn
    fj("button:contains('Publish')")
  end

  def course_user_list
    ff('.roster .rosterUser')
  end

  def accept_enrollment_button
    f(accept_enrollment_alert_selector)
  end

  def decline_enrollment_button
    f(".ic-notification button[name=reject]")
  end

  def course_page_content
    f('#content')
  end

  #----------------------- Actions/Methods ----------------------
  def visit_course(course)
    get "/courses/#{course.id}"
  end

  def visit_course_people(course)
    get "/courses/#{@course.id}/users"
  end

  def open_course_wizard
    course_setup_checklist_btn.click
  end

  def go_to_checklist
    visit_course(@course)
    open_course_wizard
    wait_for(method: nil, timeout: 2) { wizard_box.displayed? }
  end
end
