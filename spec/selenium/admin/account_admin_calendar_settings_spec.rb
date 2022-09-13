# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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
require_relative "pages/account_calendar_settings_page"

describe "Account Calendar Settings" do
  include_context "in-process server selenium tests"
  include AccountCalendarSettingsPage

  let(:account) { Account.default }
  let(:account_calendar_settings_url) { "/accounts/#{account.id}/calendar_settings" }

  before :once do
    @sub1_account = Account.create!(name: "sub1", parent_account: account)
    @sub2_account = Account.create!(name: "sub2", parent_account: account)
    @sub_sub_account = Account.create!(name: "sub sub", parent_account: @sub1_account)
    @admin_user = account_admin_user(account: account, active_all: true)
    account_admin_user(account: @sub_account, user: @admin_user)
    account_admin_user(account: @sub_sub_account, user: @admin_user)
    Account.site_admin.enable_feature!(:account_calendar_events)
  end

  before do
    user_session(@admin_user)
  end

  it "navigates to account calendar page when navigation link is clicked", ignore_js_errors: true do
    get("/accounts/#{account.id}")

    click_account_calendar_navigation
    expect(driver.current_url).to include(account_calendar_settings_url)
  end

  context "account calendar listings and checkboxes" do
    it "shows multiple accounts and subaccounts with checkboxes" do
      get("/accounts/#{account.id}/calendar_settings")

      expect(account_folder(account.name, 3)).to be_displayed
      expect(account_folder(@sub1_account.name, 2)).to be_displayed
      expect(element_exists?(account_folder_selector(@sub2_account.name, 1))).to be_falsey

      default_account_checkboxes = account_checkboxes(account.name, 3)

      expect(default_account_checkboxes[0]).to include_text(account.name)
      expect(default_account_checkboxes[1]).to include_text(@sub2_account.name)

      click_account_folder(@sub1_account.name, 2)
      sub1_account_checkboxes = account_checkboxes(@sub1_account.name, 2)

      expect(sub1_account_checkboxes[0]).to include_text(@sub1_account.name)
      expect(sub1_account_checkboxes[1]).to include_text(@sub_sub_account.name)
    end

    it "expands and hides accounts section" do
      get("/accounts/#{account.id}/calendar_settings")

      click_account_folder(account.name, 3)
      expect(element_exists?(account_folder_selector(@sub1_account.name, 2))).to be_falsey
      click_account_folder(account.name, 3)
      expect(element_exists?(account_folder_selector(@sub1_account.name, 2))).to be_truthy
    end

    it "enables the calendar in the list when clicked and applied", ignore_js_errors: true do
      get("/accounts/#{account.id}/calendar_settings")

      expect(apply_changes_button).to be_disabled

      click_account_checkbox(account_checkboxes(account.name, 3)[1])

      expect(apply_changes_button).to be_enabled

      click_apply_changes_button
      @sub2_account.reload
      expect(@sub2_account.account_calendar_visible).to be_truthy
    end

    it "disables the calendar in the list when clicked and applied" do
      @sub2_account.account_calendar_visible = true
      @sub2_account.save!

      get("/accounts/#{account.id}/calendar_settings")

      expect(apply_changes_button).to be_disabled

      click_account_checkbox(account_checkboxes(account.name, 3)[1])

      expect(apply_changes_button).to be_enabled

      click_apply_changes_button

      @sub2_account.reload
      expect(@sub2_account.account_calendar_visible).to be_falsey
    end

    it "shows text at bottom of page with number of calendars selected" do
      get("/accounts/#{account.id}/calendar_settings")

      expect(calendars_selected_text).to include_text("No account calendars selected")

      click_account_checkbox(account_checkboxes(account.name, 3)[0])

      expect(calendars_selected_text).to include_text("1 Account calendar selected")

      click_account_checkbox(account_checkboxes(account.name, 3)[1])

      expect(calendars_selected_text).to include_text("2 Account calendars selected")
    end
  end

  context "account calendar searching and filtering" do
    it "can search with 2 characters and find accounts" do
      get("/accounts/#{account.id}/calendar_settings")
      input_search_string("su")
      expect(calendar_search_list.count).to eq(3)
    end

    it "receives no results found image/words when bad search" do
      get("/accounts/#{account.id}/calendar_settings")
      input_search_string("blarg")
      wait_for_ajaximations
      expect(search_empty_image).to be_displayed
    end

    it "filtering with no results renders 'no results' image" do
      get("/accounts/#{account.id}/calendar_settings")

      click_option(filter_dropdown_selector, "Show only enabled calendars")
      expect(search_empty_image).to be_displayed
    end

    it "can filter by enabled calendars" do
      @sub2_account.account_calendar_visible = true
      @sub2_account.save!

      get("/accounts/#{account.id}/calendar_settings")

      click_option(filter_dropdown_selector, "Show only enabled calendars")

      calendars_shown = visible_account_calendar_text

      expect(calendars_shown[0]).to include_text(@sub2_account.name)
    end

    it "can filter by disabled calendars" do
      account.account_calendar_visible = true
      account.save!

      get("/accounts/#{account.id}/calendar_settings")

      click_option(filter_dropdown_selector, "Show only disabled calendars")

      calendars_shown = visible_account_calendar_text.map(&:text)

      expect(calendars_shown).to eq([@sub_sub_account.name, @sub1_account.name, @sub2_account.name])
    end
  end
end
