# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "../common"

module EportfoliosCommon
  def entry_verifier(opts = {})
    entry = @eportfolio.eportfolio_entries.first
    if opts[:section_type]
      expect(entry.content.first[:section_type]).to eq opts[:section_type]
    end

    if opts[:content]
      expect(entry.content.first[:content]).to include(opts[:content])
    end
  end

  def organize_sections
    f("#section_list_manage .manage_sections_link").click
    sections.each do |section|
      expect(section).to contain_jqcss(".section_settings_menu:visible")
    end
  end

  def add_eportfolio_section(name)
    wait_for_ajaximations
    f("button[data-testid='add-section-button']").click
    f("input[data-testid='add-field']").send_keys(name, :return)
  end

  def sections
    ff("#section_list_mount tr")
  end

  def delete_eportfolio_section(section)
    wait_for_ajaximations
    section.find("button").click
    f("[data-testid='delete-menu-option']").click
    fj("span[role='dialog'] button:contains('Delete')").click
  end

  def move_section_to_bottom(section)
    section.find_element(:css, ".section_settings_menu").click
    section.find_element(:css, ".move_section_link").click
    move_to_modal = f("[role=dialog][aria-label=\"Move Section\"]")
    click_option("#MoveToDialog__select", "-- At the bottom --", :text)
    move_to_modal.find_element(:css, "#MoveToDialog__move").click
  end

  def add_eportfolio_page(name)
    wait_for_ajaximations
    f("button[data-testid='add-page-button']").click
    f("input[data-testid='add-field']").send_keys(name, :return)
  end

  def delete_eportfolio_page(page)
    wait_for_ajaximations
    page.find("button").click
    f("[data-testid='delete-menu-option']").click
    fj("span[role='dialog'] button:contains('Delete')").click
  end

  def move_page_to_bottom(page)
    page.find_element(:css, ".page_settings_menu").click
    page.find_element(:css, ".move_page_link").click
    move_to_modal = f("[role=dialog][aria-label=\"Move Page\"]")
    click_option("#MoveToDialog__select", "-- At the bottom --", :text)
    move_to_modal.find_element(:css, "#MoveToDialog__move").click
  end

  def pages
    ff("#page_list_mount tr")
  end

  def organize_pages
    f(".manage_pages_link").click
    wait_for_animations
    pages.each do |page|
      expect(page).to contain_jqcss(".page_settings_menu:visible")
    end
    expect(f(".add_page_link")).to be_displayed
  end
end
