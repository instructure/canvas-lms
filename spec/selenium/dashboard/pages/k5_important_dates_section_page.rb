# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module K5ImportantDatesSectionPageObject

  #------------------------- Selectors --------------------------

  def add_override_selector
    "#add_due_date"
  end
  def date_field_selector
    ".date_field[data-date-type='due_at']"
  end

  def edit_assignment_submit_selector
    "#edit_assignment_form"
  end

  def edit_discussion_submit_selector
    "#edit_discussion_form_buttons"
  end

  def edit_quiz_submit_selector
    "#quiz_edit_actions"
  end

  def important_date_icon_selector(icon_type)
    "svg[name='#{icon_type}']"
  end

  def important_date_link_selector
    "[data-testid='important-date-link']"
  end

  def important_date_subject_selector
    "[data-testid='important-date-subject']"
  end

  def important_dates_title_selector
    "h3:contains('Important Dates')"
  end

  def mark_important_dates_selector
    "input + label:contains('Mark as important date and show on homeroom sidebar')"
  end

  def mark_important_dates_input_selector
    "[name='important_dates']"
  end

  def no_important_dates_image_selector
    "[data-testid='important-dates-panda']"
  end

  #------------------------- Elements --------------------------

  def add_override
    f(add_override_selector)
  end

  def assignment_link(link_text)
    fln(link_text)
  end

  def date_field
    ff(date_field_selector)
  end

  def important_date_icon(icon_type)
    f(important_date_icon_selector(icon_type))
  end

  def important_date_link
    f(important_date_link_selector)
  end

  def important_date_subject
    f(important_date_subject_selector)
  end

  def important_dates_title
    fj(important_dates_title_selector)
  end

  def mark_important_dates
    fj(mark_important_dates_selector)
  end

  def mark_important_dates_input
    f(mark_important_dates_input_selector)
  end

  def no_important_dates_image
    f(no_important_dates_image_selector)
  end

  #----------------------- Actions & Methods -------------------------

  def important_date_icon_exists?(icon_name)
    element_exists?(important_date_icon_selector(icon_name))
  end

  def set_and_tab_out_of_date_field(date_field_index, due_at)
    date_field[date_field_index].send_keys(format_date_for_view(due_at), :tab)
  end

  def clear_date_field(date_field_index)
    date_field[date_field_index].clear
  end

  #----------------------- Click Items -------------------------------

  def click_add_override
    add_override.click
  end

  def click_important_date_link
    important_date_link.click
  end

  def click_mark_important_dates
    mark_important_dates.click
  end

  #------------------------------Retrieve Text----------------------#


  #----------------------------Element Management---------------------#

end
