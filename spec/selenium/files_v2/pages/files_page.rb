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

  def alert
    f("#flashalert_message_holder")
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

  def create_folder_form_selector
    '[aria-label="Create Folder"]'
  end

  def rename_folder_form_selector
    '[aria-label="Rename file/folder modal"]'
  end

  def rename_folder_component(name)
    f("[data-testid='rename-modal-#{name}']")
  end

  def delete_folder_form_selector
    '[aria-label="Delete Confirmation"]'
  end

  def delete_folder_delete_button
    f("[data-testid='modal-delete-button']")
  end

  def move_folder_form_selector
    '[aria-label="Copy"]'
  end

  def breadcrumb
    f('[aria-label="You are here:"]')
  end

  def move_folder_move_button
    f("[data-testid='move-move-button']")
  end

  def toolbox_menu_button(name)
    f("[data-testid='bulk-actions-#{name}']")
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

  def get_item_files_table(row_index, col_index)
    driver.find_element(:css, "tbody tr[data-testid='table-row']:nth-of-type(#{row_index}) td:nth-of-type(#{col_index})")
  end

  def get_row_header_files_table(row_index)
    driver.find_element(:css, "tbody tr[data-testid='table-row']:nth-of-type(#{row_index}) th:first-child")
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

  def search_button
    f("[data-testid='files-search-button']")
  end

  def action_menu_button
    f("[data-testid='action-menu-button-large']")
  end

  def action_menu_item_by_name(name)
    f("[data-testid='action-menu-button-#{name}']")
  end

  def body
    f("body")
  end

  def create_folder(name = "new folder")
    create_folder_button.click
    create_folder_input.send_keys(name)
    create_folder_input.send_keys(:return)
  end

  def edit_name_from_kebab_menu(item, file_name_new)
    get_item_files_table(item, 7).click
    action_menu_item_by_name("Rename").click
    expect(body).to contain_css(rename_folder_form_selector)
    file_name_textbox_el = rename_folder_component("input-folder-name")
    replace_content(file_name_textbox_el, file_name_new)
    file_name_textbox_el.send_keys(:return)
  end

  def delete_file_from(item = 1, way = :kebab_menu)
    case way
    when :kebab_menu
      get_item_files_table(item, 7).click
      action_menu_item_by_name("Delete").click
    when :toolbar_menu
      get_row_header_files_table(item).click
      toolbox_menu_button("delete-button").click
    end
    expect(body).to contain_css(delete_folder_form_selector)
    delete_folder_delete_button.click
  end

  def move_file_from(item = 1, way = :kebab_menu)
    case way
    when :kebab_menu
      get_item_files_table(item, 7).click
      action_menu_item_by_name("Move To...").click
    when :toolbar_menu
      get_row_header_files_table(item).click
      toolbox_menu_button("more-button").click
      toolbox_menu_button("move-button").click
    end
    expect(body).to contain_css(move_folder_form_selector)
    tree_selector.click
    move_folder_move_button.click
  end

  def move_files(items)
    items.map { |item| get_row_header_files_table(item).click }
    toolbox_menu_button("more-button").click
    toolbox_menu_button("move-button").click
    expect(body).to contain_css(move_folder_form_selector)
    tree_selector.click
    move_folder_move_button.click
  end

  def tree_selector
    f("ul[role='tree']")
  end
end
