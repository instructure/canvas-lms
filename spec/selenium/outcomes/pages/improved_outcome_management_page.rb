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

module ImprovedOutcomeManagementPage
  # ---------------------- Elements ----------------------
  def state_standards_tree_button
    fj("button:contains('State Standards')")
  end

  def common_core_standards_tree_button
    fj("button:contains('CCSS.ELA-Literacy.CCRA.W - Writing')")
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

  def friendly_description_textarea
    f("textarea[placeholder='Enter your friendly description here']")
  end

  def rce_iframe
    "textentry_text_ifr"
  end

  def edit_outcome_title_input
    f("input[data-testid='name-input']")
  end

  def common_core_search_text
    f("input[placeholder='Search within CCSS.ELA-Literacy.CCRA.W - Writing']")
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
    "label[for='Checkbox_#{index}']"
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
    ffj("button:contains('Menu for outcome')")[index]
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

  def nth_individual_outcome_text(index)
    ff("div[data-testid='outcome-management-item']")[index].text
  end

  def nth_individual_outcome_title(index)
    ff("h4[data-testid='outcome-management-item-title']")[index].text
  end

  def outcome_remove_modal
    f("span[data-testid='outcome-management-remove-modal']")
  end

  def expand_outcome_description_button(index)
    ff("button[data-testid='manage-outcome-item-expand-toggle']")[index]
  end

  def add_individual_rating_button
    f("button[data-testid='add-individual-rating-btn']")
  end

  def nth_individual_rating_description_input(index = nil)
    rating_descriptions = ff("input[data-testid='rating-description-input']")
    rating_descriptions[index.nil? ? rating_descriptions.length - 1 : index]
  end

  def nth_individual_rating_points_input(index = nil)
    rating_points = ff("input[data-testid='rating-points-input']")
    rating_points[index.nil? ? rating_points.length - 1 : index]
  end

  def nth_individual_rating_delete_button(index = nil)
    rating_delete_buttons = ff("button[data-testid='rating-delete-btn']")
    rating_delete_buttons[index.nil? ? rating_delete_buttons.length - 1 : index]
  end

  def confirm_delete_individual_rating_button
    fj("button:contains('Confirm')")
  end

  def calculation_int_input
    f("input[data-testid='calculation-int-input']")
  end

  def calculation_method_input
    f("input[data-testid='calculation-method-input']")
  end

  def alignments_tab
    f("div[id='tab-alignments']")
  end

  def alignment_summary_outcomes_list
    ff("div[data-testid='alignment-outcome-item']")
  end

  def alignment_summary_expand_outcome_description_button(index)
    ff("button[data-testid='alignment-summary-outcome-expand-toggle']")[index]
  end

  def alignment_summary_outcome_alignments(index)
    ff("span[data-testid='outcome-alignments']")[index].text
  end

  def alignment_summary_outcome_alignments_list
    ff("div[data-testid='outcome-alignments-list']")
  end

  def alignment_summary_filter_all_input
    f("input[value^='All']")
  end

  def alignment_summary_filter_with_alignments_input
    f("input[value^='With']")
  end

  def alignment_summary_alignment_stat_name(index)
    ff("span[data-testid='outcome-alignment-stat-name']")[index].text
  end

  def alignment_summary_alignment_stat_percent(index)
    ff("span[data-testid='outcome-alignment-stat-percent']")[index].text
  end

  def alignment_summary_alignment_stat_type(index)
    ff("span[data-testid='outcome-alignment-stat-type']")[index].text
  end

  def alignment_summary_alignment_stat_average(index)
    ff("span[data-testid='outcome-alignment-stat-average']")[index].text
  end

  def alignment_summary_alignment_stat_description(index)
    ff("span[data-testid='outcome-alignment-stat-description']")[index].text
  end
  # ---------------------- Actions -----------------------

  def goto_improved_state_outcomes(outcome_url = "/accounts/self/outcomes")
    get outcome_url
  end

  def enable_improved_outcomes_management(account)
    account.enable_feature!(:improved_outcomes_management)
  end

  def enable_account_level_mastery_scales(account)
    account.enable_feature!(:account_level_mastery_scales)
  end

  def enable_friendly_description
    Account.site_admin.enable_feature!(:outcomes_friendly_description)
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

  def enter_rce_description(desc)
    driver.switch_to.frame(rce_iframe)
    rce.send_keys(desc)
    driver.switch_to.default_content
  end

  def create_outcome_with_friendly_desc(title, desc, friendly_desc)
    create_button.click
    insert_create_outcome_title(title)
    wait_for(method: nil, timeout: 3) { rce.present? }
    enter_rce_description(desc)
    insert_friendly_description(friendly_desc)
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

  def insert_friendly_description(desc)
    set_value(friendly_description_textarea, desc)
  end

  def search_common_core(title)
    set_value(common_core_search_text, title)
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

  def select_outcome_group_with_text(text, timeout = 2)
    wait_for(method: nil, timeout:) { tree_browser.present? }
    tree_browser_outcome_groups.find { |group| group.text.split("\n")[0] == text }
  end

  def select_drilldown_outcome_group_with_text(text)
    drilldown_outcome_groups.find { |group| group.text.split("\n")[0] == text }
  end

  def disable_account_level_mastery_scales(account)
    account.disable_feature!(:account_level_mastery_scales)
  end

  def edit_individual_outcome_calculation_int(int)
    replace_content(calculation_int_input, int)
  end

  def edit_individual_outcome_calculation_method(method)
    click_option(calculation_method_input, method)
  end

  def add_individual_outcome_rating(description, points)
    add_individual_rating_button.click
    replace_content(nth_individual_rating_description_input, description)
    replace_content(nth_individual_rating_points_input, points)
  end

  def delete_nth_individual_outcome_rating(index = nil)
    nth_individual_rating_delete_button(index).click
    confirm_delete_individual_rating_button.click
  end

  def click_alignments_tab
    alignments_tab.click
  end
end
