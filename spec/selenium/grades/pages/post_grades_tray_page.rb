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

module PostGradesTray
  extend SeleniumDependencies

  def self.tray
    f('[role=dialog][aria-label="Post grades tray"]')
  end

  def self.full_content
    fj("h3:contains('Post Grades')", tray)
  end

  def self.unposted_count_indicator
    f("#PostAssignmentGradesTray__Layout__UnpostedSummary span[id]")
  end

  def self.unposted_count
    unposted_count_indicator.text
  end

  def self.post_button
    fj("button:contains('Post')", tray)
  end

  def self.post_type_radio_button(type)
    fj("label:contains(#{type.to_s.titleize})", tray)
  end

  def self.specific_sections_toggle
    fj("label:contains('Specific Sections')", tray)
  end

  def self.section_checkbox(section_name:)
    fj("label:contains(#{section_name})", tray)
  end

  def self.spinner
    fxpath("//*[text()='Posting grades']", tray)
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

  def self.post_grades
    post_button.click
    spinner # wait for spinner to appear
    wait_for(method: nil) { Delayed::Job.find_by(tag: "Assignment#post_submissions").present? }
    run_jobs
    # rubocop:disable Specs/NoWaitForNoSuchElement
    raise "spinner still spinning after waiting" unless wait_for_no_such_element(timeout: 8) { spinner }
    # rubocop:enable Specs/NoWaitForNoSuchElement
  end
end
