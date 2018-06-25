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
require_relative '../common'

module NewUserSearchPage

  # ---------------------- Page ----------------------
  def visit(account)
    get("/accounts/#{account.id}/users")
    wait_for_ajaximations
  end

  def visit_subaccount(sub_account)
    get("/accounts/#{sub_account.id}/users")
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

  def add_user_button
    fj('button:has([name="IconPlusLine"]):contains("People")')
  end

  def more_options_button
    fj('button:contains("More People Options")')
  end

  def more_options_item(option_name)
    fj("button:has([role='menuitem']):contains(\"#{option_name}\")")
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
    fj("[data-automation='users list'] tr:contains('#{user_name}') [role=button]:has([name='IconMessageLine'])")
  end

  def edit_user_button(user_name)
    fj("[data-automation='users list'] tr:contains('#{user_name}') [role=button]:has([name='IconEdit'])")
  end

  def page_previous_button
    fj("[role=button]:has([title='Previous Page'])")
  end

  def page_next_button
    fj("[role=button]:has([title='Next Page'])")
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

  def click_message_button
    send_message_button.click
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
end
