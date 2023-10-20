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
    @admin_user = account_admin_user(account:, active_all: true)
    account_admin_user(account: @sub_account, user: @admin_user)
    account_admin_user(account: @sub_sub_account, user: @admin_user)
  end

  before do
    user_session(@admin_user)
  end

  it "navigates to account calendar page when navigation link is clicked", :ignore_js_errors do
    get("/accounts/#{account.id}")

    click_account_calendar_navigation
    expect(driver.current_url).to include(account_calendar_settings_url)
  end

  context "account calendar listings and checkboxes" do
    it "shows multiple accounts and subaccounts with checkboxes" do
      get("/accounts/#{account.id}/calendar_settings")

      expect(account_folder(account.id)).to be_displayed
      expect(account_folder(@sub1_account.id)).to be_displayed
      expect(element_exists?(account_folder_selector(@sub2_account.id))).to be_falsey

      default_account_checkboxes = account_checkboxes(account.id)
      expect(default_account_checkboxes[0]).to include_text(account.name)
      expect(default_account_checkboxes[2]).to include_text(@sub2_account.name)

      click_account_folder(@sub1_account.id)
      sub1_account_checkboxes = account_checkboxes(@sub1_account.id)

      expect(sub1_account_checkboxes[0]).to include_text(@sub1_account.name)
      expect(sub1_account_checkboxes[2]).to include_text(@sub_sub_account.name)
    end

    context "with a non root origin account" do
      it "shows subaccounts and checkboxes properly for subaccount" do
        get("/accounts/#{@sub1_account.id}/calendar_settings")

        expect(account_folder(@sub1_account.id)).to be_displayed
        expect(element_exists?(account_folder_selector(@sub2_account.id))).to be_falsey

        sub1_account_checkboxes = account_checkboxes(@sub1_account.id)

        expect(sub1_account_checkboxes[0]).to include_text(@sub1_account.name)
        expect(sub1_account_checkboxes[2]).to include_text(@sub_sub_account.name)
      end
    end

    it "expands and hides accounts section" do
      get("/accounts/#{account.id}/calendar_settings")

      click_account_folder(account.id)
      expect(element_exists?(account_folder_selector(@sub1_account.id))).to be_falsey
      click_account_folder(account.id)
      expect(element_exists?(account_folder_selector(@sub1_account.id))).to be_truthy
    end

    it "enables the calendar in the list when clicked and applied" do
      get("/accounts/#{account.id}/calendar_settings")

      expect(apply_changes_button).to be_disabled

      click_account_checkbox(account_checkboxes(account.id)[2])

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

      click_account_checkbox(account_checkboxes(account.id)[2])

      expect(apply_changes_button).to be_enabled

      click_apply_changes_button

      @sub2_account.reload
      expect(@sub2_account.account_calendar_visible).to be_falsey
    end

    it "shows text at bottom of page with number of calendars selected" do
      get("/accounts/#{account.id}/calendar_settings")

      expect(calendars_selected_text).to include_text("No account calendars selected")

      click_account_checkbox(account_checkboxes(account.id)[0])

      expect(calendars_selected_text).to include_text("1 Account calendar selected")

      click_account_checkbox(account_checkboxes(account.id)[2])

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

  context "account calendar auto subscribe selection" do
    it "shows the auto-subscribe dropdown for selected account calendar" do
      @sub2_account.account_calendar_visible = true
      @sub2_account.save!

      get("/accounts/#{account.id}/calendar_settings")

      expect(auto_subscription_dropdowns[1]).to be_displayed
      expect(auto_subscription_dropdowns[1].enabled?).to be_truthy
      expect(auto_subscription_dropdowns[1].attribute("title")).to eq("Manual subscribe")
    end

    it "shows disabled auto-subscribe dropdown for non-selected account calendar" do
      get("/accounts/#{account.id}/calendar_settings")

      expect(auto_subscription_dropdowns[1]).to be_displayed
      expect(auto_subscription_dropdowns[1]).to be_disabled
    end

    it "makes apply changes button available when auto subscribe is selected" do
      @sub2_account.account_calendar_visible = true
      @sub2_account.save!

      get("/accounts/#{account.id}/calendar_settings")

      click_INSTUI_Select_option(auto_subscription_dropdowns[1], "Auto subscribe")
      expect(apply_changes_button).to be_enabled

      click_INSTUI_Select_option(auto_subscription_dropdowns[1], "Manual subscribe")
      expect(apply_changes_button).to be_disabled
    end

    it "provides confirmation modal to confirm auto subscribe changes" do
      @sub2_account.account_calendar_visible = true
      @sub2_account.save!

      get("/accounts/#{account.id}/calendar_settings")

      click_INSTUI_Select_option(auto_subscription_dropdowns[1], "Auto subscribe")
      click_apply_changes_button
      expect(auto_subscribe_confirm_modal).to be_displayed
    end

    it "does not provide confirmation modal to confirm change to manual subscribe" do
      @sub2_account.account_calendar_visible = true
      @sub2_account.account_calendar_subscription_type = "auto"
      @sub2_account.save!

      get("/accounts/#{account.id}/calendar_settings")

      click_INSTUI_Select_option(auto_subscription_dropdowns[1], "Manual subscribe")
      click_apply_changes_button
      expect(element_exists?(auto_subscribe_confirm_modal_selector)).to be_falsey
    end
  end

  context "auto-subscribe modal actions" do
    before :once do
      @sub2_account.account_calendar_visible = true
      @sub2_account.save!
    end

    it "updates to auto subscribe when confirmed on modal and apply changes is disabled" do
      get("/accounts/#{account.id}/calendar_settings")

      click_INSTUI_Select_option(auto_subscription_dropdowns[1], "Auto subscribe")
      click_apply_changes_button
      click_auto_subscribe_confirm_button
      expect(element_exists?(auto_subscribe_confirm_modal_selector)).to be_falsey
      expect(apply_changes_button).to be_disabled
    end

    it "does not update when canceled on modal and apply changes is enabled" do
      get("/accounts/#{account.id}/calendar_settings")

      click_INSTUI_Select_option(auto_subscription_dropdowns[1], "Auto subscribe")
      click_apply_changes_button
      click_auto_subscribe_cancel_button
      expect(element_exists?(auto_subscribe_confirm_modal_selector)).to be_falsey
      expect(apply_changes_button).to be_enabled
    end

    it "does not update when modal X is pressed and apply changes is enabled" do
      get("/accounts/#{account.id}/calendar_settings")

      click_INSTUI_Select_option(auto_subscription_dropdowns[1], "Auto subscribe")
      click_apply_changes_button
      click_auto_subscribe_x_close_button
      expect(element_exists?(auto_subscribe_confirm_modal_selector)).to be_falsey
      expect(apply_changes_button).to be_enabled
    end
  end
end
