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

require_relative "../../common"

module CourseIndexPage
  #------------------------- Selectors --------------------------
  def current_enrollments_selector
    "#my_courses_table"
  end

  def past_enrollments_selector
    "#past_enrollments_table"
  end

  def future_enrollments_selector
    "#future_enrollments_table"
  end

  def header_selector
    ".header-bar"
  end

  def row_with_text_selector(text)
    "tr:contains('#{text}')"
  end

  def favorites_column_selector
    ".course-list-star-column"
  end

  def title_column_selector
    ".course-list-course-title-column"
  end

  def favorite_icon_selector(course_name)
    "span[data-course-name='#{course_name}'] .course-list-favorite-icon"
  end

  #------------------------- Elements ---------------------------
  def current_enrollments
    f(current_enrollments_selector)
  end

  def past_enrollments
    f(past_enrollments_selector)
  end

  def future_enrollments
    f(future_enrollments_selector)
  end

  def header
    f(header_selector)
  end

  def row_with_text(text)
    fj(row_with_text_selector(text))
  end

  def favorite_icon(course_name)
    f(favorite_icon_selector(course_name))
  end
end
