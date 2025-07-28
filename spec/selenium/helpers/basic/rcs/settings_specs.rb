# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative "../shared_examples_common"

shared_examples_for "settings basic tests" do
  include SharedExamplesCommon
  include_context "in-process server selenium tests"

  before do
    course_with_admin_logged_in
  end

  context "admins tab" do
    def add_account_admin
      address = "student1@example.com"
      f(".add_users_link").click
      f("textarea.user_list").send_keys(address)
      f(".verify_syntax_button").click
      wait_for_ajax_requests
      expect(f("#user_lists_processed_people .person").text).to eq address
      f(".add_users_button").click
      wait_for_ajax_requests
      user = User.where(name: address).first
      expect(user).to be_present
      admin = AccountUser.where(user_id: user).first
      expect(admin).to be_present
      expect(admin.role_id).to eq admin_role.id
      expect(f("#enrollment_#{admin.id} .email").text).to eq address
      admin.id
    end

    before do
      get "/accounts/#{account.id}/settings"
      f("#tab-users").click
    end

    it "adds an account admin", priority: "1" do
      add_account_admin
    end

    it "deletes an account admin", priority: "1" do
      skip_if_safari(:alert)
      admin_id = add_account_admin
      scroll_page_to_top # to get the flash alert out of the way
      f("#enrollment_#{admin_id} .remove_account_user_link").click
      driver.switch_to.alert.accept
      wait_for_ajax_requests
      expect(AccountUser.where(id: admin_id)).not_to be_exists
    end
  end

  context "account settings" do
    def click_submit
      submit_form("#account_settings")
      wait_for_ajax_requests
    end

    before do
      course_with_admin_logged_in
      group_model(context: @course)
      get account_settings_url
      wait_for_ajaximations
    end

    it "changes the account name", priority: "1" do
      new_account_name = "new default account name"
      replace_content(f("#account_name"), new_account_name)
      click_submit
      account.reload
      expect(account.name).to eq new_account_name
      expect(f("#account_name")).to have_value(new_account_name)
    end

    it "changes the default quotas", priority: "1" do
      f("#tab-quotas").click

      # update the quotas
      course_quota = account.default_storage_quota_mb
      course_quota_input = f('[name="default_storage_quota_mb"]')
      expect(course_quota_input).to have_value(course_quota.to_s)

      group_quota = account.default_group_storage_quota_mb
      group_quota_input = f('[name="default_group_storage_quota_mb"]')
      expect(group_quota_input).to have_value(group_quota.to_s)

      course_quota += 25
      replace_content(course_quota_input, course_quota.to_s)
      group_quota += 42
      replace_content(group_quota_input, group_quota.to_s)

      submit_form("[aria-label='Default Account Quotas form']")
      wait_for_ajax_requests

      # ensure the account was updated properly
      account.reload
      expect(account.default_storage_quota_mb).to eq course_quota
      expect(account.default_storage_quota).to eq course_quota * 1_000_000
      expect(account.default_group_storage_quota_mb).to eq group_quota
      expect(account.default_group_storage_quota).to eq group_quota * 1_000_000

      # ensure the new value is reflected after a refresh
      get account_settings_url
      expect(fj('[name="default_storage_quota_mb"]')).to have_value(course_quota.to_s) # fj to avoid selenium caching
      expect(fj('[name="default_group_storage_quota_mb"]')).to have_value(group_quota.to_s) # fj to avoid selenium caching
    end

    it "manually changes a course quota", priority: "1" do
      f("#tab-quotas").click

      search_form_selector = "[aria-label='Manually Settable Quotas search form']"
      click_option("#{search_form_selector} [name=resource]", "Course ID")
      id_input = f("#{search_form_selector} [name=id]")
      replace_content(id_input, @course.id.to_s)
      f("#{search_form_selector} [type=submit]").click

      wait_for_ajaximations

      update_form_selector = "[aria-label='Manually Settable Quotas update form']"
      link = f("#{update_form_selector} a[href='/courses/#{@course.id}']")
      expect(link).to include_text(@course.name)

      quota_input = f("#{update_form_selector} [name=storage_quota_mb]")
      expect(quota_input).to have_value(@course.storage_quota_mb.to_s)
      replace_content(quota_input, "42")

      f("#{update_form_selector} [type=submit]").click

      wait_for_ajax_requests

      # ensure the account was updated properly
      @course.reload
      expect(@course.storage_quota_mb).to eq 42
    end

    it "manually changes a group quota", priority: "1" do
      f("#tab-quotas").click

      search_form_selector = "[aria-label='Manually Settable Quotas search form']"
      click_option("#{search_form_selector} [name=resource]", "Group ID")
      id_input = f("#{search_form_selector} [name=id]")
      replace_content(id_input, @group.id.to_s)
      f("#{search_form_selector} [type=submit]").click

      wait_for_ajaximations

      update_form_selector = "[aria-label='Manually Settable Quotas update form']"
      link = f("#{update_form_selector} a[href='/groups/#{@group.id}']")
      expect(link).to include_text(@group.name)

      quota_input = f("#{update_form_selector} [name=storage_quota_mb]")
      expect(quota_input).to have_value(@group.storage_quota_mb.to_s)
      replace_content(quota_input, "42")

      f("#{update_form_selector} [type=submit]").click

      wait_for_ajax_requests

      # ensure the account was updated properly
      @group.reload
      expect(@group.storage_quota_mb).to eq 42
    end

    it "changes the default language to spanish", priority: "1" do
      f("#account_default_locale option[value='es']").click
      click_submit
      account.reload
      expect(account.default_locale).to eq "es"
      expect(get_value("#account_default_locale")).to eq "es"
    end
  end
end
