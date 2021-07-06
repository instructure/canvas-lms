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
  #

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

  def no_important_dates_image_selector
    "[data-testid='important-dates-panda']"
  end

  #------------------------- Elements --------------------------

  def assignment_link(link_text)
    fln(link_text)
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

  def no_important_dates_image
    f(no_important_dates_image_selector)
  end

  #----------------------- Actions & Methods -------------------------

  def important_date_icon_exists?(icon_name)
    element_exists?(important_date_icon_selector(icon_name))
  end

  #----------------------- Click Items -------------------------------

  def click_important_date_link
    important_date_link.click
  end

  #------------------------------Retrieve Text----------------------#


  #----------------------------Element Management---------------------#

end
