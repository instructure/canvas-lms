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

require_relative "../common"
require_relative "../helpers/basic/settings_specs"
require_relative "pages/admin_account_page"

describe "root account basic settings" do
  include AdminSettingsPage

  let(:account) { Account.default }
  let(:account_settings_url) { "/accounts/#{account.id}/settings" }
  let(:reports_url) { "/accounts/#{account.id}/reports_tab" }
  let(:admin_tab_url) { "/accounts/#{account.id}/settings#tab-users" }

  include_examples "settings basic tests"

  it "is able to disable enable_gravatar" do
    account_admin_user(active_all: true)
    user_session(@admin)
    get account_settings_url

    avatars = f("#account_services_avatars")
    avatars.location_once_scrolled_into_view
    avatars.click
    f("#account_settings_enable_gravatar").click

    submit_form("#account_settings")
    wait_for_ajaximations
    expect(Account.default.reload.settings[:enable_gravatar]).to be false
  end

  it "lets admins enable kill_joy on root account settings", :ignore_js_errors do
    account.settings[:kill_joy] = false
    account.save!

    user_session(@admin)
    get account_settings_url
    el = f("#account_settings_kill_joy")
    el.location_once_scrolled_into_view
    el.click
    submit_form("#account_settings")
    wait_for_ajaximations
    expect(Account.default.reload.settings[:kill_joy]).to be true
  end

  context "with restrict_quantitative_data" do
    before :once do
      account.enable_feature!(:restrict_quantitative_data)
    end

    it "lets admins enable restrict_quantitative_data on root account settings", :ignore_js_errors do
      account.settings[:restrict_quantitative_data] = { value: false, locked: false }
      account.save!

      user_session(@admin)
      get account_settings_url

      # click then close restrict quantitative data helper dialog
      button = fj("button:contains('About restrict quantitative data')")
      button.location_once_scrolled_into_view
      button.click
      expect("[data-testid='rqd-modal-test']").to be_present
      f("[data-testid='close-button']").click

      f("#account_settings_restrict_quantitative_data_value").click
      submit_form("#account_settings")
      wait_for_ajaximations
      expect(Account.default.reload.settings[:restrict_quantitative_data][:value]).to be true
    end

    context "restrict_quantitative_data enabled" do
      it "lets admins enable restrict_quantitative_data_lock on root account settings", :ignore_js_errors do
        account.settings[:restrict_quantitative_data] = { value: false, locked: false }
        account.save!

        user_session(@admin)
        get account_settings_url

        # restrict_quantitative_data is initially false, then locked is disabled & unchecked
        expect(is_checked("#account_settings_restrict_quantitative_data_value")).to be_falsey
        expect(f("#account_settings_restrict_quantitative_data_locked")).to be_disabled
        expect(is_checked("#account_settings_restrict_quantitative_data_locked")).to be_falsey

        # restrict_quantitative_data true, then locked is enabled
        el = f("#account_settings_restrict_quantitative_data_value")
        el.location_once_scrolled_into_view
        el.click
        expect(f("#account_settings_restrict_quantitative_data_locked")).to be_enabled
        f("#account_settings_restrict_quantitative_data_locked").click
        expect(is_checked("#account_settings_restrict_quantitative_data_locked")).to be_truthy

        # restrict_quantitative_data clicked false, then locked is disabled & unchecked
        f("#account_settings_restrict_quantitative_data_value").click
        expect(f("#account_settings_restrict_quantitative_data_locked")).to be_disabled
        expect(is_checked("#account_settings_restrict_quantitative_data_locked")).to be_falsey

        f("#account_settings_restrict_quantitative_data_value").click
        f("#account_settings_restrict_quantitative_data_locked").click
        submit_form("#account_settings")
        wait_for_ajaximations
        expect(Account.default.reload.settings[:restrict_quantitative_data][:locked]).to be true
      end
    end
  end

  it "lets admins enable suppress_notifications on root account settings", :ignore_js_errors do
    account.settings[:suppress_notifications] = false
    account.save!

    user_session(@admin)
    get account_settings_url
    el = f("#account_settings_suppress_notifications")
    el.location_once_scrolled_into_view
    el.click
    driver.switch_to.alert.accept
    submit_form("#account_settings")
    expect(Account.default.reload.settings[:suppress_notifications]).to be true
  end

  it "updates the account's allow_observers_in_appointment_groups setting" do
    expect(account.allow_observers_in_appointment_groups?).to be false

    user_session(@admin)
    get account_settings_url
    expect(is_checked(allow_observers_in_appointments_checkbox)).to be false
    allow_observers_in_appointments_checkbox.location_once_scrolled_into_view
    allow_observers_in_appointments_checkbox.click
    expect_new_page_load { submit_form("#account_settings") }
    expect(is_checked(allow_observers_in_appointments_checkbox)).to be true
    expect(account.reload.allow_observers_in_appointment_groups?).to be true
  end

  context "editing slack API key" do
    before :once do
      account_admin_user(account: Account.site_admin)
      @account = Account.default
    end

    before do
      user_session(@admin)
      @admin.account.enable_feature!(:slack_notifications)
    end

    it "is able to update slack key" do
      get "/accounts/#{@account.id}/settings"

      slack_api_input = f('*[placeholder="New Slack Api Key"]')
      set_value(slack_api_input, "WHATEVER PEOPLE")
      submit_form("#account_settings")
      expect(f("#current_slack_api_key").text).to eq("WHAT***********")
    end
  end

  context "Integrations" do
    context "Microsoft Teams Sync" do
      context("microsoft_group_enrollments FF enabled") do
        let(:enabled) { true }
        let(:tenant) { "canvastest2.onmicrosoft.com" }
        let(:login_attribute) { "sis_user_id" }
        let(:suffix) { "@example.com" }
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

        before do
          account_admin_user(account:)
          user_session(@admin)
        end

        it "lets a user update what settings they want to use" do
          get account_settings_url
          f("#tab-integrations").click

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
          expected_settings.each do |key, value|
            expect(account.settings[key]).to eq value
          end
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
          f("#tab-integrations").click
          f("#microsoft_teams_sync_toggle_button").click
          wait_for_ajaximations

          account.reload
          expected_settings.each do |key, value|
            expect(account.settings[key]).to eq value
          end
        end
      end
    end
  end

  context "reports" do
    before do
      course_with_admin_logged_in
    end

    def modal_body
      f("#configure_modal_body")
    end

    it "downloads reports" do
      course_with_admin_logged_in
      account.account_reports.create!(
        user: @user,
        report_type: "course_storage_csv"
      ).run_report(synchronous: true)
      get reports_url

      expect(f("#course_storage_csv .last-run a").attribute("href")).to match(/download_frd=1/)
    end

    it "has date pickers for reports tab" do
      course_with_admin_logged_in
      get account_settings_url
      f("#tab-reports").click
      wait_for_ajax_requests
      f("#configure_zero_activity_csv").click
      expect(modal_body.find('[data-testid="parameters[start_at]"]')).to be_present
    end

    it "handles linking directly to reports tab" do
      course_with_admin_logged_in
      get account_settings_url + "#tab-reports"
      f("#configure_zero_activity_csv").click
      expect(modal_body.find('[data-testid="parameters[start_at]"]')).to be_present
    end

    it "disables report options for provisioning report form when a report hasn't been selected" do
      course_with_admin_logged_in
      get account_settings_url + "#tab-reports"

      f("#configure_provisioning_csv").click
      expect(modal_body.find("#parameters_created_by_sis")).to be_disabled
      expect(modal_body.find("#parameters_include_deleted")).to be_disabled

      modal_body.find("#parameters_courses").click
      expect(modal_body.find("#parameters_created_by_sis")).to_not be_disabled
      expect(modal_body.find("#parameters_include_deleted")).to_not be_disabled
    end

    it "disables report options for SIS export report form when a report hasn't been selected" do
      course_with_admin_logged_in
      get account_settings_url + "#tab-reports"

      f("#configure_sis_export_csv").click
      expect(modal_body.find("#parameters_created_by_sis")).to be_disabled
      expect(modal_body.find("#parameters_include_deleted")).to be_disabled

      modal_body.find("#parameters_users").click
      expect(modal_body.find("#parameters_created_by_sis")).to_not be_disabled
      expect(modal_body.find("#parameters_include_deleted")).to_not be_disabled
    end

    it "creates a report with correct parameters" do
      course_with_admin_logged_in

      get account_settings_url + "#tab-reports"

      f("#configure_students_with_no_submissions_csv").click
      # change start_at date
      start_at = modal_body.find('[data-testid="parameters[start_at]"]')
      start_at.click
      start_at.clear
      start_at.send_keys("2023-01-01")

      # change end_at date
      end_at = modal_body.find('[data-testid="parameters[end_at]"]')
      end_at.click
      end_at.clear
      end_at.send_keys("2023-01-15")

      # change the enrollment state (select)
      enrollment_state = modal_body.find("select[name='parameters[enrollment_state][]']")
      enrollment_state.click
      enrollment_state.find('[value="active"').click

      f("[data-testid='run-report']").click

      report = Account.default.account_reports.last
      expect(report).to be_present
      params = report.parameters
      # unchecked params are excluded from the report
      expect(params["enrollment_term_id"]).to eq("")
      expect(params).to have_key("start_at")
      expect(params).to have_key("end_at")
      expect(params).not_to have_key("include_enrollment_state")
      expect(params["enrollment_state"]).to eq(["active"])
    end
  end

  it "changes the default user quota", priority: "1" do
    course_with_admin_logged_in
    group_model(context: @course)
    get account_settings_url

    f("#tab-quotas").click

    # update the quotas
    user_quota = account.default_user_storage_quota_mb
    user_quota_input = f('[name="default_user_storage_quota_mb"]')
    expect(user_quota_input).to have_value(user_quota.to_s)

    user_quota += 15
    replace_content(user_quota_input, user_quota.to_s)

    submit_form("[aria-label='Default Account Quotas form']")
    wait_for_ajax_requests

    # ensure the account was updated properly
    account.reload
    expect(account.default_user_storage_quota).to eq user_quota * 1_000_000

    # ensure the new value is reflected after a refresh
    get account_settings_url
    expect(fj('[name="default_user_storage_quota_mb"]')).to have_value(user_quota.to_s) # fj to avoid selenium caching
  end

  it "is able to remove account quiz ip filters" do
    account.ip_filters = { "name" => "192.168.217.1/24" }
    account.save!

    course_with_admin_logged_in
    get account_settings_url

    expect_new_page_load { submit_form("#account_settings") }

    account.reload
    expect(account.settings[:ip_filters]).to be_present # should not have cleared them if we didn't do anything

    filter = ff(%(span[data-testid="ip-filter"])).detect(&:displayed?)
    el = filter.find_element(:css, %([data-testid="delete-ip-filter"]))
    el.location_once_scrolled_into_view
    el.click

    expect_new_page_load { submit_form("#account_settings") }

    account.reload
    expect(account.settings[:ip_filters]).to be_blank
  end

  context "course creation settings" do
    before :once do
      account_admin_user(active_all: true)
    end

    before do
      user_session(@admin)
    end

    it "renders classic settings when :create_course_subaccount_picker is off" do
      get account_settings_url
      expect(f("#account_settings_teachers_can_create_courses")).to be_present
      expect(f("#account_settings_students_can_create_courses")).to be_present
      expect(f("#account_settings_no_enrollments_can_create_courses")).to be_present
    end

    context "with :create_course_subaccount_picker on" do
      before :once do
        account.enable_feature!(:create_course_subaccount_picker)
      end

      it "renders CourseCreationSettings component with correct default values" do
        account.settings[:teachers_can_create_courses] = true
        account.settings[:students_can_create_courses] = true
        account.settings[:teachers_can_create_courses_anywhere] = false
        account.save!

        get account_settings_url
        expect(f("[data-testid='course-creation-settings']")).to be_present
        expect(f("input[type='checkbox'][name='account[settings][teachers_can_create_courses]']")).to be_selected
        expect(f("input[type='checkbox'][name='account[settings][students_can_create_courses]']")).to be_selected
        expect(f("input[type='checkbox'][name='account[settings][no_enrollments_can_create_courses]']")).not_to be_selected
        expect(f("input[type='radio'][name='account[settings][teachers_can_create_courses_anywhere]'][value='0']")).to be_selected
      end

      it "allows settings to be updated" do
        account.settings[:teachers_can_create_courses] = true
        account.settings[:no_enrollments_can_create_courses] = true
        account.settings[:teachers_can_create_courses_anywhere] = false
        account.save!

        get account_settings_url
        teacher = f("input[type='radio'][name='account[settings][teachers_can_create_courses_anywhere]'][value='1'] + label")
        scroll_into_view(teacher)
        teacher.click

        student = f("input[type='checkbox'][name='account[settings][students_can_create_courses]'] + label")
        scroll_into_view(student)
        student.click

        radio = f("input[type='radio'][name='account[settings][students_can_create_courses_anywhere]'][value='0'] + label")
        scroll_into_view(radio)
        radio.click
        check = f("input[type='checkbox'][name='account[settings][no_enrollments_can_create_courses]'] + label")
        scroll_into_view(check)
        check.click
        expect_new_page_load { submit_form("#account_settings") }

        account.reload
        expect(account.teachers_can_create_courses?).to be_truthy
        expect(account.students_can_create_courses?).to be_truthy
        expect(account.no_enrollments_can_create_courses?).to be_falsey
        expect(account.teachers_can_create_courses_anywhere?).to be_truthy
        expect(account.students_can_create_courses_anywhere?).to be_falsey
      end
    end
  end

  context "Differentiation Tags" do
    before :once do
      account_admin_user(active_all: true)
    end

    before do
      user_session(@admin)
    end

    describe "allow_assign_to_differentiation_tags originally enabled" do
      before do
        account.enable_feature!(:assign_to_differentiation_tags)
        account.settings[:allow_assign_to_differentiation_tags] = true
        account.save!
        get account_settings_url
      end

      it "shows warning message when differentiation tags settings is unchecked" do
        differentiation_checkbox = f("#account_settings_allow_assign_to_differentiation_tags_value")
        expect(differentiation_checkbox.selected?).to be true
        scroll_into_view(differentiation_checkbox)
        differentiation_checkbox.click

        warning_message = f("#differentiation_tags_account_settings_warning_message")
        description = f("#differentiation_tags_account_settings_description_message")
        expect(warning_message).to be_displayed
        expect(description).not_to be_displayed
      end

      it "shows description message when differentiation tags settings is checked" do
        differentiation_checkbox = f("#account_settings_allow_assign_to_differentiation_tags_value")
        expect(differentiation_checkbox.selected?).to be true
        expect(f("#differentiation_tags_account_settings_warning_message")).not_to be_displayed
        expect(f("#differentiation_tags_account_settings_description_message")).to be_displayed
      end
    end
  end
end
