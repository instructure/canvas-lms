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

module AdminSettingsPage
  # ---------------------- Elements ----------------------
  def admin_left_nav_menu
    f("#section-tabs")
  end

  def analytics_menu_item
    f("a.analytics_plugin")
  end

  def global_nav_profile_link
    f("#global_nav_profile_link")
  end

  def profile_tray
    f("div[role='dialog'][aria-label='Profile tray']")
  end

  def profile_tray_menu_items
    f("div[role='dialog'][aria-label='Profile tray'] ul")
  end

  def profile_tray_content_share_link
    fj("a:contains('Shared Content')")
  end

  def profile_tray_spinner
    fj("li title:contains('Loading')")
  end

  def allow_observers_in_appointments_checkbox
    f("#account_settings_allow_observers_in_appointment_groups_value")
  end

  # ---------------------- Actions -----------------------

  def visit_admin_settings_tab(account_id)
    get "/accounts/#{account_id}/settings"
  end

  # ---------------------- Methods -----------------------

  def wait_for_profile_tray_spinner
    begin
      spinner = profile_tray_spinner
      keep_trying_until(3) { (spinner.displayed? == false) }
    rescue Selenium::WebDriver::Error::TimeoutError
      # ignore - sometimes spinner doesn't appear in Chrome
    end
    wait_for_ajaximations
  end
end
