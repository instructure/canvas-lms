#
# Copyright (C) 2017 - present Instructure, Inc.
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

module NewUserSearchPage

  # ---------------------- Page ----------------------
  def visit_users(account)
    get("/accounts/#{account.id}/users")
    wait_for_ajaximations
  end

  def visit_subaccount(sub_account)
    get("/accounts/#{sub_account.id}/users")
    wait_for_ajaximations
  end

  def visit_courses(account)
    get("/accounts/#{account.id}/")
    wait_for_ajaximations
  end

  # ---------------------- Controls ----------------------
  def role_dropdown
    f('select[type="text"]')
  end

  def role_item(item_name)
    fj("option:contains(\"#{item_name}\")")
  end

  def user_search_box
    f('input[placeholder="Search people..."]')
  end

  def add_user_button_jqcss
    'button:has([name="IconPlus"]):contains("People")'
  end

  def add_user_button
    fj(add_user_button_jqcss)
  end

  def more_options_button
    fj('button:contains("More People Options")')
  end

  def more_options_user_group
    fj('[role="menuitem"]:contains("View user groups")')
  end

  def more_options_profile_pictures
    fj('[role="menuitem"]:contains("Manage profile pictures")')
  end

  def column_sort_button(column_name)
    fj("button:contains(\"#{column_name}\")")
  end

  def user_name_link(user_name)
    fj("[data-automation='users list'] tr a:contains('#{user_name}')")
  end

  def user_row(user_name)
    fj("[data-automation='users list'] tr:contains('#{user_name}')")
  end

  def masquerade_button(user_name)
    fj("[data-automation='users list'] tr:contains('#{user_name}') [role=button]:has([name='IconMasquerade'])")
  end

  def send_message_button(user_name)
    fj("[data-automation='users list'] tr:contains('#{user_name}') [role=button]:has([name='IconMessage'])")
  end

  def edit_user_button(user_name)
    fj("[data-automation='users list'] tr:contains('#{user_name}') [role=button]:has([name='IconEdit'])")
  end

  def page_previous_jqcss
    'button:has([name="IconArrowOpenStart"])'
  end

  def page_previous_button
    fj(page_previous_jqcss)
  end

  def page_next_button
    fj("[role=button]:has([name='IconArrowOpenEnd'])")
  end

  def page_number_button(number)
    fj("nav button:contains(\"#{number}\")")
  end

  def results_alert
    f('#content .alert')
  end

  def results_body
    f('#content')
  end

  def all_results_users
    f('[data-automation="users list"]')
  end

  def all_results_courses
    f('[data-automation="courses list"]')
  end

  def results_row
    '[data-automation="users list"] tr'
  end

  def results_rows
    ff(results_row)
  end

  def left_navigation
    f('#left-side #section-tabs')
  end

  def users_left_navigation
    f('#section-tabs .users')
  end

  def courses_left_navigation
    f('#section-tabs .courses')
  end

  def breadcrumbs
    f("#breadcrumbs")
  end

  # ---------------------- Actions ----------------------
  def select_role(role_name)
    role_dropdown.click
    role_item(role_name).click
  end

  def enter_search(search_name)
    set_value(user_search_box, search_name)
    driver.action.send_keys(:enter).perform
    wait_for_ajaximations
  end

  def click_add_user
    add_user_button.click
  end

  def select_people_option(option)
    more_options_button.click
    more_options_item(option).click
  end

  def click_column_sort
    column_sort_button.click
  end

  def click_user_link(user_name)
    user_name_link(user_name).click
  end

  def click_masquerade_button(user_name)
    masquerade_button(user_name).click
  end

  def click_message_button(user_name)
    send_message_button(user_name).click
  end

  def click_edit_button(user_name)
    edit_user_button(user_name).click
  end

  def click_previous_button
    page_previous_button.click
  end

  def click_next_button
    page_next_button.click
  end

  def click_page_number_button(number)
    page_number_button(number).click
  end

  def click_people_more_options
    more_options_button.click
  end

  def click_view_user_groups_option
    more_options_user_group.click
  end

  def click_manage_profile_pictures_option
    more_options_profile_pictures.click
  end

  def click_left_nav_users
    users_left_navigation.click
  end

  def click_left_nav_courses
    courses_left_navigation.click
  end
end
