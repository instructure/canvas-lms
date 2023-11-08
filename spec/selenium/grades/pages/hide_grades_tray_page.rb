# frozen_string_literal: true

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

require_relative "../../common"

module HideGradesTray
  extend SeleniumDependencies

  def self.tray
    f('[role=dialog][aria-label="Hide grades tray"]')
  end

  def self.full_content
    fj("h3:contains('Hide Grades')", tray)
  end

  def self.hide_button
    fj('button:contains("Hide")', tray)
  end

  def self.specific_sections_toggle
    fj("label:contains('Specific Sections')", tray)
  end

  def self.section_checkbox(section_name:)
    fj("label:contains(#{section_name})", tray)
  end

  def self.spinner
    fj("svg:contains('Hiding grades')", tray)
  end

  def self.select_sections(sections:)
    return if sections.empty?

    specific_sections_toggle.click
    sections.each do |section|
      section_checkbox(section_name: section.name).click
    end
  end

  def self.select_section(section_name)
    specific_sections_toggle.click
    section_checkbox(section_name:).click
  end

  def self.hide_grades
    hide_button.click
    spinner # wait for spinner to appear
    # rubocop:disable Specs/NoWaitForNoSuchElement
    raise "spinner still spinning after waiting" unless wait_for_no_such_element timeout: 8 do
      # there's a small chance the job hasn't been queued
      # yet so keep looking for jobs just in case
      run_jobs
      spinner
    end
    # rubocop:enable Specs/NoWaitForNoSuchElement

    wait_for_animations
  end
end
