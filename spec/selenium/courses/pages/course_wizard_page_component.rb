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

module CourseWizardPageComponent
  #------------------------- Selectors --------------------------
  def course_wizard_selector
    '.ic-wizard-box'
  end

  def close_btn_selector
    '.ic-Expand-link__trigger'
  end

  def checklist_item_selector(item)
    "#wizard_#{item}"
  end

  def completed_checklist_item_selector(item)
    checklist_item_selector(item) + ".ic-wizard-box__content-trigger--checked"
  end

  def incomplete_checklist_item_selector(item)
    checklist_item_selector(item) + ".ic-wizard-box__content-trigger"
  end

  def course_wizard_modal_selector
    ".ic-wizard-box__message-button a"
  end

  def publish_course_btn_selector
    ".Button:contains('Publish the Course')"
  end

  #------------------------- Elements ---------------------------
  def wizard_box
    f(course_wizard_selector)
  end

  def close_btn
    f(close_btn_selector)
  end

  def checklist_item(item)
    f(checklist_item_selector(item))
  end

  def course_wizard_modal_btn
    f(course_wizard_modal_selector)
  end

  def publish_course_btn
    fj(publish_course_btn_selector)
  end

  def completed_checklist_item(item)
    f(completed_checklist_item_selector(item))
  end

  def incomplete_checklist_item(item)
    f(incomplete_checklist_item_selector(item))
  end

  #----------------------- Actions/Methods ----------------------
  def close_course_wizard
    close_btn.click
  end

  def check_course_wizard_item(item)
    checklist_item(item).click
  end

  def choose_a_course_home_page
    check_course_wizard_item("home_page")
    wait_for_ajaximations
    course_wizard_modal_btn.click
  end

  def select_navigation_links
    check_course_wizard_item("select_navigation")
    wait_for_ajaximations
    course_wizard_modal_btn.click
  end

  def add_course_calendar_events
    check_course_wizard_item("course_calendar")
    wait_for_ajaximations
    course_wizard_modal_btn.click
  end

  def publish_the_course
    check_course_wizard_item("publish_course")
    wait_for_ajaximations
    publish_course_btn.click
  end
end
