# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/basic/settings_specs')

describe "root account basic settings" do
  let(:account) { Account.default }
  let(:account_settings_url) { "/accounts/#{account.id}/settings" }
  let(:reports_url) { "/accounts/#{account.id}/reports_tab" }
  let(:admin_tab_url) { "/accounts/#{account.id}/settings#tab-users" }
  include_examples "settings basic tests", :root_account

  it "should be able to disable enable_gravatar" do
    account_admin_user(:active_all => true)
    user_session(@admin)
    get account_settings_url

    f("#account_services_avatars").click
    f("#account_settings_enable_gravatar").click

    submit_form("#account_settings")
    wait_for_ajaximations
    expect(Account.default.reload.settings[:enable_gravatar]).to eq false
  end

  context 'editing slack API key' do
    before :once do
      account_admin_user(:account => Account.site_admin)
      @account = Account.default
    end

    before :each do
      user_session(@admin)
      @admin.account.enable_feature!(:slack_notifications)
    end

    it 'should be able to update slack key' do
      get "/accounts/#{@account.id}/settings"

      slack_api_input = f('*[placeholder="New Slack Api Key"]')
      set_value(slack_api_input, 'WHATEVER PEOPLE')
      submit_form('#account_settings')
      expect(f('#current_slack_api_key').text).to eq('WHAT***********')
    end
  end

  context 'Integrations' do
    context 'Microsoft Teams Sync' do
      context('microsoft_group_enrollments FF enabled') do
        let(:enabled) { true }
        let(:tenant) { 'canvastest2.onmicrosoft.com' }
        let(:login_attribute) { 'sis_user_id' }
        let(:suffix) { '@example.com' }
        let(:remote_attribute) { "mailNickname" }
        let(:expected_settings) do
          {
            microsoft_sync_enabled: enabled,
            microsoft_sync_tenant: tenant,
            microsoft_sync_login_attribute: login_attribute,
            microsoft_sync_login_attribute_suffix: suffix,
            microsoft_sync_remote_attribute: remote_attribute
          }
        end

        before :once do
          account.enable_feature!(:microsoft_group_enrollments_syncing)
        end

        before :each do
          account_admin_user(account: account)
          user_session(@admin)
        end

        it "lets a user update what settings they want to use" do
          get account_settings_url
          f("#tab-integrations-link").click

          tenant_input_area = fxpath('//input[@placeholder="microsoft_tenant_name.onmicrosoft.com"]')
          set_value(tenant_input_area, tenant)

          f("#microsoft_teams_sync_attribute_selector").click
          f("#sis_user_id").click

          suffix_input_area = fxpath('//input[@placeholder="@example.edu"]')
          set_value(suffix_input_area, suffix)

          f("#microsoft_teams_sync_remote_attribute_lookup_attribute_selector").click
          f("#remote_lookup_attribute_mail_nickname_option").click

          f("#microsoft_teams_sync_toggle_button").click
          wait_for_ajaximations

          account.reload
          expect(account.settings).to eq expected_settings
        end

        it "lets a user toggle Microsoft Teams sync" do
          account.settings = {
            microsoft_sync_enabled: !enabled,
            microsoft_sync_tenant: tenant,
            microsoft_sync_login_attribute: login_attribute,
            microsoft_sync_login_attribute_suffix: suffix,
            microsoft_sync_remote_attribute: remote_attribute
          }
          account.save!

          get account_settings_url
          f("#tab-integrations-link").click
          f("#microsoft_teams_sync_toggle_button").click
          wait_for_ajaximations

          account.reload
          expect(account.settings).to eq expected_settings
        end
      end
    end
  end

  it "downloads reports" do
    course_with_admin_logged_in
    account.account_reports.create!(
      user: @user,
      report_type: 'course_storage_csv'
    ).run_report(synchronous: true)
    get reports_url

    expect(f('#course_storage_csv .last-run a').attribute('href')).to match(/download_frd=1/)
  end

  it "has date pickers for reports tab" do
    course_with_admin_logged_in
    get account_settings_url
    f('#tab-reports-link').click()
    wait_for_ajax_requests
    f('#configure_zero_activity_csv').click()
    expect(f('#zero_activity_csv_form')).to contain_css('.ui-datepicker-trigger')
  end

  it "handles linking directly to reports tab" do
    course_with_admin_logged_in
    get account_settings_url + "#tab-reports"
    f('#configure_zero_activity_csv').click()
    expect(f('#zero_activity_csv_form')).to contain_css('.ui-datepicker-trigger')
  end

  it "should change the default user quota", priority: "1", test_id: 250002 do
    course_with_admin_logged_in
    group_model(context: @course)
    get account_settings_url

    f('#tab-quotas-link').click

    # update the quotas
    user_quota = account.default_user_storage_quota_mb
    user_quota_input = f('[name="default_user_storage_quota_mb"]')
    expect(user_quota_input).to have_value(user_quota.to_s)

    user_quota += 15
    replace_content(user_quota_input, user_quota.to_s)

    submit_form('#default-quotas')
    wait_for_ajax_requests

    # ensure the account was updated properly
    account.reload
    expect(account.default_user_storage_quota).to eq user_quota * 1048576

    # ensure the new value is reflected after a refresh
    get account_settings_url
    expect(fj('[name="default_user_storage_quota_mb"]')).to have_value(user_quota.to_s) # fj to avoid selenium caching
  end

  it "should be able to remove account quiz ip filters" do
    account.ip_filters = {"name" => "192.168.217.1/24"}
    account.save!

    course_with_admin_logged_in
    get account_settings_url

    expect_new_page_load { submit_form("#account_settings") }

    account.reload
    expect(account.settings[:ip_filters]).to be_present # should not have cleared them if we didn't do anything

    filter = ff('.ip_filter').detect{|fil| fil.displayed?}
    filter.find_element(:css, '.delete_filter_link').click

    expect_new_page_load { submit_form("#account_settings") }

    account.reload
    expect(account.settings[:ip_filters]).to be_blank
  end
end
