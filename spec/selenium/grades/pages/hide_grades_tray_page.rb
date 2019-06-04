#
# Copyright (C) 2019 - present Instructure, Inc.
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

module HideGradesTray
  extend SeleniumDependencies

  def self.full_content
    fj("h3:contains('Hide Grades')")
  end

  def self.hide_button
    fj("button:contains('Hide')")
  end

  def self.specific_sections_toggle
    fj("label:contains('Specific Sections')")
  end

  def self.section_checkbox(section_name)
    fj("label:contains(#{section_name})")
  end

  def self.select_section(section_name)
    specific_sections_toggle.click
    section_checkbox(section_name).click
  end

  def self.spinner
    fxpath("//div[@data-cid='Spinner']")
  end

  def self.hide_grades
    hide_button.click
    spinner
    run_jobs
    wait_for_no_such_element { PostGradesTray.spinner }
  end
end
