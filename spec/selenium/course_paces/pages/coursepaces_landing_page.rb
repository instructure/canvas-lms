# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module CoursePacesLandingPageObject
  #------------------------- Selectors -------------------------------
  def create_default_pace_button_selector
    "[data-testid='go-to-default-pace']"
  end

  def default_duration_selector
    "[data-testid='default-pace-duration']"
  end

  def get_started_button_selector
    "[data-testid='get-started-button']"
  end

  def number_of_sections_selector
    "[data-testid='number-of-sections']"
  end

  def number_of_students_selector
    "[data-testid='number-of-students']"
  end

  #------------------------- Elements --------------------------------

  def create_default_pace_button
    f(create_default_pace_button_selector)
  end

  def default_duration
    f(default_duration_selector)
  end

  def get_started_button
    f(get_started_button_selector)
  end

  def number_of_sections
    f(number_of_sections_selector)
  end

  def number_of_students
    f(number_of_students_selector)
  end

  #----------------------- Actions & Methods -------------------------
  #----------------------- Click Items -------------------------------
  def click_get_started_button
    get_started_button.click
  end

  def click_create_default_pace_button
    create_default_pace_button.click
  end
  #------------------------Retrieve Text -----------------------------
  #------------------------Element Management ------------------------
end
