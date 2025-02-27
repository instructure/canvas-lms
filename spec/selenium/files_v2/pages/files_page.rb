# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

module FilesPage
  def content
    f("#content")
  end

  def heading
    f("#content h1")
  end

  def all_my_files_button
    fxpath("//button[descendant::text()[contains(., 'All My Files')]]")
  end

  def upload_button
    fxpath("//button[descendant::text()[contains(., 'Upload')]]")
  end

  def create_folder_button
    f("[data-testid='create-folder-button']")
  end

  def files_usage_text_selector
    "[data-testid='files-usage-text']"
  end

  def files_usage_text
    f(files_usage_text_selector)
  end

  def table_item_by_name(name)
    f("[data-testid='#{name}']")
  end

  def table_rows
    ff("tbody tr")
  end

  def all_files_table_rows
    driver.find_elements(:css, "tr[data-testid='table-row']")
  end

  def get_item_content_files_table(row_index, col_index)
    driver.find_element(:css, "tbody tr[data-testid='table-row']:nth-of-type(#{row_index}) td:nth-of-type(#{col_index})").text
  end

  def header_name_files_table
    f("[data-testid='name']")
  end

  def create_folder_input
    f("[name='folderName']")
  end

  def pagination_container
    f("[data-testid='files-pagination']")
  end

  # which button is next/current/previous depends on how many are being rendered
  def pagination_button_by_index(index)
    pagination_container.find_elements(:css, "button")[index]
  end

  def column_heading_by_name(name)
    f("[data-testid='#{name}']")
  end

  def search_input
    f("[data-testid='files-search-input']")
  end
end
