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

require_relative '../../common'

module ImprovedOutcomeManagementPage

  # ---------------------- Elements ----------------------
  def state_standards_tree_button
    fj("button:contains('State Standards')")
  end

  def account_standards_tree_button
    fj("button:contains('Account Standards')")
  end

  def find_outcome_modal_items
    ff("div[data-testid='find-outcome-item']")
  end

  def nth_find_outcome_modal_item_title(index)
    ff("div[data-testid='find-outcome-item']")[index].text.split("\n")[1]
  end

  def add_button_nth_find_outcome_modal_item(index)
    ff("button[data-testid='add-find-outcome-item']")[index]
  end

  def create_outcome_title
    f("input[placeholder='Enter name or code']")
  end

  def edit_outcome_title_input
    f("input[data-testid='name-input']")
  end

  def state_standards_search_text
    f("input[placeholder='Search within State Standards']")
  end

  def create_button
    fj("button:contains('Create')")
  end

  def remove_button
    fj("button:contains('Remove')")
  end

  def move_button
    fj("button:contains('Move')")
  end

  def confirm_create_button
    # This button is obscured by an overlaying element, so we use force_click, which just
    # takes a jquery selector
    "span:contains('Create')"
  end

  def confirm_move_button
    # This button is obscured by an overlaying element, so we use force_click, which just
    # takes a jquery selector
    "span:contains('Move')"
  end

  def select_nth_outcome_for_bulk_action(index)
    # This button is obscured by an overlaying element, so we use force_click, which just
    # takes a jquery selector
    "input[type='checkbox']:eq(#{index})"
  end

  def tree_browser_root_group
    f('[data-testid="outcomes-management-target-group-selector"]')
  end

  def find_button
    fj("button:contains('Find')")
  end

  def done_button
    fj("button:contains('Done')")
  end

  def save_button
    fj("button:contains('Save')")
  end

  def individual_outcome_kabob_menu(index)
    ffj("button:contains('Outcome Menu')")[index]
  end

  def edit_outcome_button
    f("[data-testid='outcome-kebab-menu-edit']")
  end

  def remove_outcome_button
    f("span[data-testid='outcome-kebab-menu-remove']")
  end

  def move_outcome_button
    f("span[data-testid='outcome-kebab-menu-move']")
  end

  def create_new_group_in_move_modal_group_input
    f("input[placeholder='Enter new group name']")
  end

  def create_new_group_in_move_modal_button
    fj("button:contains('Create New Group')")
  end

  def confirm_new_group_in_move_modal_button
    f("[data-testid='outcomes-management-add-content-item']")
  end

  def confirm_remove_outcome_button
    fj("button:contains('Remove Outcome')")
  end

  def no_outcomes_billboard
    fj("span:contains('There are no outcomes in this group.')")
  end

  def tree_browser
    f("div[data-testid='outcomes-management-tree-browser']")
  end

  def tree_browser_outcome_groups
    ff("li[role='treeitem']")
  end

  def drilldown_outcome_groups
    ff("[role='listitem']")
  end

  def outcome_group_container
    f("div[data-testid='outcome-group-container']")
  end

  def rce
    f("#tinymce")
  end

  def individual_outcomes
    ff("div[data-testid='outcome-management-item']")
  end

  def nth_individual_outcome_title(index)
    ff("h4[data-testid='outcome-management-item-title']")[index].text
  end

  def outcome_remove_modal
    f("span[data-testid='outcome-management-remove-modal']")
  end


  # ---------------------- Actions -----------------------

  def goto_improved_state_outcomes(outcome_url = "/accounts/self/outcomes")
    get outcome_url
  end

  def enable_improved_outcomes_management(account)
    account.enable_feature!(:account_level_mastery_scales)
    account.enable_feature!(:improved_outcomes_management)
  end

  def open_find_modal
    find_button.click
  end

  def create_outcome(title)
    create_button.click
    insert_create_outcome_title(title)
    tree_browser_root_group.click
    # Create button is partially covered by neighboring span, so we force the click
    force_click(confirm_create_button)
  end

  def click_done_find_modal
    done_button.click
  end

  def click_save_edit_modal
    save_button.click
  end

  def click_remove_button
    remove_button.click
  end

  def click_confirm_remove_button
    confirm_remove_outcome_button.click
  end

  def click_confirm_new_group_in_move_modal_button
    confirm_new_group_in_move_modal_button.click
  end

  def click_move_outcome_button
    move_outcome_button.click
  end

  def click_move_button
    move_button.click
  end

  def click_remove_outcome_button
    remove_outcome_button.click
  end

  def click_create_new_group_in_move_modal_button
    create_new_group_in_move_modal_button.click
  end

  def insert_create_outcome_title(title)
    set_value(create_outcome_title, title)
  end

  def search_state_standards(title)
    set_value(state_standards_search_text, title)
  end

  def edit_outcome_title(title)
    wait_for(method: nil, timeout: 5) { rce.present? }
    set_value(edit_outcome_title_input, title)
  end

  def insert_new_group_name_in_move_modal(group_name)
    set_value(create_new_group_in_move_modal_group_input, group_name)
  end

  def outcome_group_container_title
    outcome_group_container.text.split("\n")[0]
  end

  def select_outcome_group_with_text(text)
    wait_for(method: nil, timeout: 2) {tree_browser.present?}
    tree_browser_outcome_groups.select{|group| group.text.split("\n")[0] == text}.first
  end

  def select_drilldown_outcome_group_with_text(text)
    drilldown_outcome_groups.select{|group| group.text.split("\n")[0] == text}.first
  end
end
