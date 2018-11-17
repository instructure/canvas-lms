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

module NewCourseAddCourseModal


  # ---------------------- Controls ----------------------
  def add_course_modal
    f('[aria-label="Add a New Course"]')
  end

  def course_name_textbox
    fj('label:contains("Course Name") input', add_course_modal)
  end

  def reference_code_textbox
    fj('label:contains("Reference Code") input', add_course_modal)
  end

  def subaccount_select
    fj('label:contains("Subaccount") select', add_course_modal)
  end

  def enrollment_term_select
    fj('label:contains("Enrollment Term") select', add_course_modal)
  end

  #---------------------- Actions ----------------------

  def submit_new_course
    submit_form(add_course_modal)
    wait_for_ajaximations
  end

  def enter_course_name(course_name)
    set_value(course_name_textbox, course_name)
  end

  def enter_reference_code(ref_code)
    set_value(reference_code_textbox, ref_code)
  end

  def select_subaccount(subaccount)
    click_option(subaccount_select, subaccount.to_param, :value)
  end

  def select_enrollment_term(term_text)
    click_option(enrollment_term_select, term_text)
  end
end
