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

module CalendarPage
  #------------------------- Selectors --------------------------
  def create_new_event_btn_selector
    '#create_new_event_link'
  end

  def edit_event_title_input_selector
    '#edit_calendar_event_form #calendar_event_title'
  end

  def edit_event_modal_submit_btn_selector
    '#edit_calendar_event_form button.event_button'
  end

  #------------------------- Elements ---------------------------
  def create_new_event_btn
    f(create_new_event_btn_selector)
  end

  def edit_event_title_input
    f(edit_event_title_input_selector)
  end

  def edit_event_modal_submit_btn
    f(edit_event_modal_submit_btn_selector)
  end

  #----------------------- Actions/Methods ----------------------
  def create_new_calendar_event
    create_new_event_btn.click
    wait_for_ajaximations
  end

  def add_calendar_event_title(title_text)
    replace_content(edit_event_title_input, title_text)
  end

  def submit_calendar_event_changes
    edit_event_modal_submit_btn.click
    wait_for_ajaximations
  end
end
