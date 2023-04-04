# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

class PermissionsIndex
  class << self
    include SeleniumDependencies

    def visit(account)
      get("/accounts/#{account.id}/permissions")
    end

    # ---------------------- Controls ----------------------
    def course_roles_tab
      f("#tab-tab-panel-course")
    end

    def account_roles_tab
      f("#tab-tab-panel-account")
    end

    def search_box
      f('input[name="permission_search"]')
    end

    def filter_control
      f("#permissions-role-filter")
    end

    def filter_item(filter_item)
      selector = "li span:contains(#{filter_item})"
      wait_for(method: nil, timeout: 2) { fj(selector).displayed? }
      fj(selector)
    end

    def add_role_button
      f("#add_role")
    end

    def role_header
      f(".ic-permissions__top-header")
    end

    def role_link_css(role_name)
      "th[aria-label=#{role_name}] button"
    end

    def role_link(role_name)
      f(role_link_css(role_name))
    end

    def role_header_by_id(role)
      f("#role_#{role.id}")
    end

    # this is the button/link that opens the tray
    def permission_link(permission_name)
      f("#permission_#{permission_name}")
    end

    # this applies to parent permissions only
    def permission_cell(permission_name, role_id)
      f("##{permission_name}_role_#{role_id}")
    end

    def permission_tray_button(permission_name, role_id)
      f(".ic-permissions_role_tray ##{permission_name}_#{role_id}")
    end

    def permissions_tray_viewable_permissions
      ff(".ic-permissions__table tbody tr")
    end

    def permission_menu_item(item_name)
      f("#permission_table_#{item_name}_menu_item")
    end

    def permission_menu(permission_name)
      f(".#{permission_name}_tray_button")
    end

    def new_role_name_input
      f("#new_role_name")
    end

    def edit_role_icon
      f("#edit_button")
    end

    def add_role_input
      f("#add_role_input")
    end

    def role_name(role)
      f("#role_#{role.id}")
    end

    def edit_tray_header
      f("#edit_tray_header")
    end

    def add_role_submit_button
      f("#permissions-add-tray-submit-button")
    end

    def edit_name_box
      f('input[name="edit_name_box"]')
    end

    def role_tray_permission_state(permission, role)
      icon = fj("##{permission}_#{role} svg:first").attribute("name")
      state = ""
      case icon
      when "IconTrouble"
        state = "Disabled"
      when "IconPublish"
        state = "Enabled"
      end
      state
    end

    def grid_permission_state(permission, role)
      icons = ff("##{permission}_#{role} svg")
      if icons[icons.length - 2].attribute("name") == "IconTrouble"
        state = "Disabled"
      elsif icons[cons.length - 2].attribute("name") == "IconPublish"
        state = "Enabled"
      end
      state
    end

    def permission_state(permission_name, role)
      state = ""
      icons = ff("svg", permission_cell(permission_name, role))
      icons.each do |icon|
        case icon.name
        when "IconPublish"
          state = "Enabled" + state
        when "IconTrouble"
          state = "Disabled" + state
        when "IconLock"
          state += " Locked"
        end
      end
    end

    def manage_wiki_button
      f("button[data-testid='expand_manage_wiki']")
    end

    def expand_manage_wiki
      scroll_to_element(manage_wiki_button)
      manage_wiki_button.click
    end

    # ---------------------- Actions ----------------------
    def choose_tab(tab_name)
      name = tab_name.to_s.downcase
      tab = (name == "account") ? account_roles_tab : course_roles_tab
      tab.click
    end

    def close_role_tray_button
      f("#close-role-tray-button")
    end

    def close_role_tray
      close_role_tray_button.click
    end

    def close_add_role_tray_button
      f("#close-add-role-tray-button")
    end

    def close_permission_tray_button
      f("#close")
    end

    def disable_tray_permission(permission_name, role_id)
      permission_tray_button(permission_name, role_id).click
      permission_menu_item("disable").click
      wait_for_ajaximations
    end

    # Focus is being put on the close button after we start tryign to interact
    # with elements in the tray, causing a race condition where things fail if
    # we start interacting with elements before the focus has initially landed
    # on the close button. Wait for it here.
    def wait_for_tray_ready
      keep_trying_until(2) do
        disable_implicit_wait { yield == current_active_element }
      end
    end

    def open_edit_role_tray(role)
      role_name(role).click
      wait_for_tray_ready { close_role_tray_button }

      keep_trying_until do
        disable_implicit_wait { edit_role_icon.click }
        disable_implicit_wait { edit_name_box.displayed? }
      end
      # sometimes the input loads and the value takes longer, wait for value
      wait_for(method: nil, timeout: 1) { edit_name_box.attribute("value") == role.name }
    end

    def add_role(name)
      add_role_button.click
      wait_for_tray_ready { close_add_role_tray_button }
      add_role_input.click
      set_value(add_role_input, name)
      add_role_submit_button.click
      wait_for_ajaximations
    end

    def edit_role(role, new_name)
      open_edit_role_tray(role)
      replace_content(edit_name_box, new_name, tab_out: true)
      # click header since :tab does not tab out of input
      edit_tray_header.click
      wait_for_ajaximations
    end

    def enter_search(search_term)
      set_value(search_box, search_term)
      driver.action.send_keys(:enter).perform
      wait_for_ajaximations
    end

    def select_filter(filter)
      filter_control.click
      filter_item(filter).click
    end

    # setting in the same format as on the menu items
    def change_permission(permission, role_id, setting)
      permission_cell(permission, role_id).click
      wait_for(method: nil, timeout: 0.5) { permission_menu_item(setting).displayed? }
      permission_menu_item(setting).click
      wait_for_ajaximations
    end

    def open_permission_tray(permission_name)
      permission_link(permission_name).click
      wait_for_tray_ready { close_permission_tray_button }
    end
  end
end
