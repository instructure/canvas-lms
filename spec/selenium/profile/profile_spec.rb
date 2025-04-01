# frozen_string_literal: true

# Copyright (C) 2011 - present Instructure, Inc.
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

describe "profile" do
  include_context "in-process server selenium tests"

  def click_edit
    f(".edit_settings_link").click
    edit_form = f("#update_profile_form")
    expect(edit_form).to be_displayed
    edit_form
  end

  def add_skype_service
    f("#unregistered_service_skype > a").click
    skype_dialog = f("[role=dialog][aria-label='Register Skype']")
    skype_dialog.find_element(:name, "username").send_keys("jakesorce")
    wait_for_new_page_load { submit_form(skype_dialog) }
    expect(f("#registered_services")).to include_text("Skype")
  end

  def generate_access_token(expiration: nil, purpose: "testing", close_dialog: true)
    f(".add_access_token_link").click
    access_token_dialog = f("[role=dialog][aria-label='New Access Token']")
    access_token_dialog.find_element(:name, "purpose").send_keys(purpose)
    if expiration.present?
      expiration_date = access_token_dialog.find_element(:css, "[data-testid='expiration-date']")
      expiration_date.send_keys(expiration)
      expiration_date.send_keys(:tab)
    end
    submit_form(access_token_dialog)
    wait_for_ajax_requests
    details_dialog = f("[role=dialog][aria-label='Access Token Details']")
    expect(details_dialog).to be_displayed
    if close_dialog
      close_instui_dialog
    end
  end

  def log_in_to_settings
    user_with_pseudonym({ active_user: true })
    create_session(@pseudonym)
    get "/profile/settings"
  end

  def change_password(old_password, new_password)
    edit_form = click_edit
    edit_form.find_element(:id, "change_password_checkbox").click
    edit_form.find_element(:id, "old_password").send_keys(old_password)
    edit_form.find_element(:id, "pseudonym_password").send_keys(new_password)
    edit_form.find_element(:id, "pseudonym_password_confirmation").send_keys(new_password)
    wait_for_new_page_load { submit_form(edit_form) }
  end

  def close_instui_dialog
    f("[role=dialog] [class*='closeButton']").click
  end

  it "gives error - wrong old password" do
    log_in_to_settings
    change_password("wrongoldpassword", "newpassword")
    # check to see if error box popped up
    errorboxes = ff(".error_text")
    expect(errorboxes.length).to be > 1
    expect(errorboxes.any? { |errorbox| errorbox.text.include?("Invalid old password for the login") }).to be_truthy
  end

  it "changes the password" do
    log_in_to_settings
    change_password("asdfasdf", "newpassword")
    # login with new password
    expect(@pseudonym.reload).to be_valid_password("newpassword")
  end

  it "rejects passwords longer than 255 characters", priority: "2" do
    log_in_to_settings
    change_password("asdfasdf", SecureRandom.hex(128))
    errorboxes = ff(".error_text")
    expect(errorboxes.any? { |errorbox| errorbox.text.include?("Can't exceed 255 characters") }).to be_truthy
  end

  it "rejects passwords shorter than 8 characters", priority: "2" do
    log_in_to_settings
    change_password("asdfasdf", SecureRandom.hex(2))
    errorboxes = ff(".error_text")
    expect(errorboxes.any? { |errorbox| errorbox.text.include?("Must be at least 8 characters") }).to be_truthy
  end

  context "non password tests" do
    before do
      course_with_teacher_logged_in
    end

    def add_email_link
      f("#right-side .add_email_link").click
    end

    it "adds a new email address on profile settings page" do
      notification_model(category: "Grading")
      notification_policy_model(notification_id: @notification.id)

      get "/profile/settings"
      add_email_link
      form = f("[role=dialog][aria-label='Register Communication']")
      test_email = "nobody+1234@example.com"
      form.find_element(:name, "email").send_keys(test_email)
      submit_form(form)

      confirmation_dialog_selector = "[role=dialog][aria-label='Confirm Email Address']"
      confirmation_dialog = f(confirmation_dialog_selector)
      expect(confirmation_dialog).to be_displayed
      submit_form(confirmation_dialog)
      expect(element_exists?(confirmation_dialog_selector)).to be_falsey
      expect(f(".email_channels")).to include_text(test_email)
    end

    it "changes default email address" do
      @user.communication_channel.confirm!
      channel = communication_channel(@user, { username: "walter_white@example.com", active_cc: true })

      get "/profile/settings"
      row = f("#channel_#{channel.id}")
      link = f("#channel_#{channel.id} td:first-of-type a")
      link.click
      wait_for_ajaximations
      expect(row).to have_class("default")
      expect(f(".default_email.display_data")).to include_text("walter_white@example.com")
    end

    it "edits full name" do
      new_user_name = "new user name"
      get "/profile/settings"
      edit_form = click_edit
      replace_content(edit_form.find_element(:id, "user_name"), new_user_name)
      wait_for_new_page_load { submit_form(edit_form) }
      expect(f(".full_name")).to include_text new_user_name
    end

    it "edits display name and validate" do
      new_display_name = "test name"
      get "/profile/settings"
      edit_form = click_edit
      replace_content(edit_form.find_element(:id, "user_short_name"), new_display_name)
      submit_form(edit_form)
      refresh_page
      expect(displayed_username).to eq(new_display_name)
    end

    it "changes the language" do
      skip("RAILS_LOAD_ALL_LOCALES=true") unless ENV["RAILS_LOAD_ALL_LOCALES"]

      get "/profile/settings"
      edit_form = click_edit
      click_option("#user_locale", "Español")
      expect_new_page_load { submit_form(edit_form) }
      expect(get_value("#user_locale")).to eq "es"
    end

    it "changes the language even if you can't update your name" do
      skip("RAILS_LOAD_ALL_LOCALES=true") unless ENV["RAILS_LOAD_ALL_LOCALES"]

      a = Account.default
      a.settings[:users_can_edit_name] = false
      a.save!

      get "/profile/settings"
      edit_form = click_edit
      expect(edit_form).not_to contain_css("#user_short_name")
      click_option("#user_locale", "Español")
      expect_new_page_load { submit_form(edit_form) }
      expect(get_value("#user_locale")).to eq "es"
    end

    context "when pronouns are enabled" do
      before do
        @user.account.settings = { can_add_pronouns: true }
        @user.account.save!
      end

      it "changes pronouns" do
        get "/profile/settings"
        desired_pronoun = "She/Her"
        edit_form = click_edit
        click_option("#user_pronouns", desired_pronoun)
        expect_new_page_load { submit_form(edit_form) }
        expect(get_value("#user_pronouns")).to eq desired_pronoun
      end
    end

    describe "adding SMS contact method" do
      let(:original_region) { Shard.current.database_server.config[:region] }

      after do
        # reset to original region after each test
        Shard.current.database_server.config[:region] = original_region
      end

      # scenario 1A: optional MFA, in US region
      it "shows the SMS number registration form when MFA is optional and in US region" do
        # temporarily set to a US region needed for SMS tab to appear
        Shard.current.database_server.config[:region] = "us-west-2"
        Account.default.settings[:mfa_settings] = :optional
        Account.default.save!
        test_cell_number = "8017121011"
        get "/profile/settings"
        f(".add_contact_link").click
        register_form = f("[role=dialog][aria-label='Register Communication']")
        register_form.find_element(:name, "sms").send_keys(test_cell_number)
        driver.action.send_keys(:tab).perform
        submit_form(register_form)
        wait_for_ajaximations
        close_instui_dialog
        expect(f(".other_channels .path")).to include_text(test_cell_number)
      end

      # scenario 1B: optional MFA, NOT in US region
      it "does not show the SMS number registration form when MFA is optional and not in US region" do
        # set to a non-US region
        Shard.current.database_server.config[:region] = "eu-central-1"
        Account.default.settings[:mfa_settings] = :optional
        Account.default.save!
        get "/profile/settings"
        f(".add_contact_link").click
        # ensure sms number registration tab is not present
        expect(element_exists?("[role=tab][aria-controls=sms]")).to be false
        # ensure email address registration tab is shown
        expect(f("[role=tab][aria-controls=email]")).to be_present
      end

      # scenario 2A: MFA disabled, in US region
      it "does not show the SMS number registration form when MFA is disabled and in US region" do
        # set to a non-US region
        Shard.current.database_server.config[:region] = "us-west-2"
        Account.default.settings[:mfa_settings] = :disabled
        Account.default.save!
        get "/profile/settings"
        f(".add_contact_link").click
        # ensure sms number registration tab is not present
        expect(element_exists?("[role=tab][aria-controls=sms]")).to be false
        # ensure email address registration tab is shown
        expect(f("[role=tab][aria-controls=email]")).to be_present
      end

      # scenario 2B: MFA disabled, NOT in US region
      it "does not show the SMS number registration form when MFA is disabled and not in US region" do
        # set to a non-US region
        Shard.current.database_server.config[:region] = "eu-central-1"
        Account.default.settings[:mfa_settings] = :disabled
        Account.default.save!
        get "/profile/settings"
        f(".add_contact_link").click
        # ensure sms number registration tab is not present
        expect(element_exists?("[role=tab][aria-controls=sms]")).to be false
        # ensure email address registration tab is shown
        expect(f("[role=tab][aria-controls=email]")).to be_present
      end

      # scenario 3A: MFA required for admins, in US region
      it "shows the SMS number registration form when MFA is required for admins and in US region" do
        # temporarily set to a US region needed for SMS tab to appear
        Shard.current.database_server.config[:region] = "us-west-2"
        Account.default.settings[:mfa_settings] = :required_for_admins
        Account.default.save!
        test_cell_number = "8017121011"
        get "/profile/settings"
        f(".add_contact_link").click
        register_form = f("[role=dialog][aria-label='Register Communication']")
        register_form.find_element(:name, "sms").send_keys(test_cell_number)
        driver.action.send_keys(:tab).perform
        submit_form(register_form)
        wait_for_ajaximations
        close_instui_dialog
        expect(f(".other_channels .path")).to include_text(test_cell_number)
      end

      # scenario 3B: MFA required for admins, NOT in US region
      it "does not show the SMS number registration form when MFA is required for admins and not in US region" do
        # set to a non-US region
        Shard.current.database_server.config[:region] = "eu-central-1"
        Account.default.settings[:mfa_settings] = :required_for_admins
        Account.default.save!
        get "/profile/settings"
        f(".add_contact_link").click
        # ensure sms number registration tab is not present
        expect(element_exists?("[role=tab][aria-controls=sms]")).to be false
        # ensure email address registration tab is shown
        expect(f("[role=tab][aria-controls=email]")).to be_present
      end

      # scenario 4A: MFA required, in US region
      it "shows the SMS number registration form when MFA is required and in US region" do
        # temporarily set to a US region needed for SMS tab to appear
        Shard.current.database_server.config[:region] = "us-west-2"
        Account.default.settings[:mfa_settings] = :required
        Account.default.save!
        test_cell_number = "8017121011"
        get "/profile/settings"
        f(".add_contact_link").click
        register_form = f("[role=dialog][aria-label='Register Communication']")
        register_form.find_element(:name, "sms").send_keys(test_cell_number)
        driver.action.send_keys(:tab).perform
        submit_form(register_form)
        wait_for_ajaximations
        close_instui_dialog
        expect(f(".other_channels .path")).to include_text(test_cell_number)
      end

      # scenario 4B: MFA required, NOT in US region
      it "does not show the SMS number registration form when MFA is required but not in US region" do
        # set to a non-US region
        Shard.current.database_server.config[:region] = "eu-central-1"
        Account.default.settings[:mfa_settings] = :required
        Account.default.save!
        get "/profile/settings"
        f(".add_contact_link").click
        # ensure sms number registration tab is not present
        expect(element_exists?("[role=tab][aria-controls=sms]")).to be false
        # ensure email address registration tab is shown
        expect(f("[role=tab][aria-controls=email]")).to be_present
      end
    end

    it "adds another contact method - slack" do
      @user.account.enable_feature!(:slack_notifications)
      test_slack_email = "sburnett@instructure.com"
      get "/profile/settings"
      f(".add_contact_link").click
      register_form = f("[role=dialog][aria-label='Register Communication']")
      f("[role=tab][aria-controls=slack]", register_form).click
      register_form.find_element(:name, "slack").send_keys(test_slack_email)
      submit_form(register_form)
      wait_for_ajaximations
      close_instui_dialog
      expect(f(".other_channels .path")).to include_text(test_slack_email)
    end

    it "registers a service" do
      get "/profile/settings"
      add_skype_service
    end

    it "deletes a service" do
      get "/profile/settings"
      add_skype_service
      driver.action.move_to(f(".service")).perform
      f(".delete_service_link").click
      expect(driver.switch_to.alert).not_to be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(f("#unregistered_services")).to include_text("Skype")
    end

    it "toggles user services visibility" do
      get "/profile/settings"
      add_skype_service
      selector = "#show_user_services"
      expect(f(selector).selected?).to be_truthy
      f(selector).click
      wait_for_ajaximations
      refresh_page
      expect(f(selector).selected?).to be_falsey

      f(selector).click
      wait_for_ajaximations
      refresh_page
      expect(f(selector).selected?).to be_truthy
    end

    it "generates a new access token without an expiration", priority: "2" do
      get "/profile/settings"
      generate_access_token
      expect(fj(".access_token:visible .expires")).to include_text("never")
    end

    it "generates a new access token with an expiration", priority: "2" do
      Timecop.freeze do
        get "/profile/settings"
        generate_access_token(expiration: format_date_for_view(2.days.from_now, :medium))
      end
      expect(fj(".access_token:visible .expires")).to include_text(format_time_for_view(2.days.from_now.midnight))
    end

    it "regenerates a new access token", priority: "2" do
      skip_if_safari(:alert)
      get "/profile/settings"
      generate_access_token(close_dialog: false)
      token_selector = "[data-testid='visible_token']"
      token = f(token_selector).text
      f("[type=submit][aria-label='Regenerate Token']").click
      expect(driver.switch_to.alert).not_to be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      new_token = f(token_selector).text
      expect(token).not_to eql(new_token)
    end

    it "tests canceling creating a new access token" do
      get "/profile/settings"
      f(".add_access_token_link").click
      access_token_dialog_selector = "[role=dialog][aria-label='New Access Token']"
      access_token_dialog = f(access_token_dialog_selector)
      access_token_dialog.find_element(:css, "[aria-label='Cancel']").click
      expect(element_exists?(access_token_dialog_selector)).to be_falsey
    end

    it "views the details of an access token" do
      get "/profile/settings"
      generate_access_token
      # using :visible because we don't want to grab the template element
      fj("#access_tokens .show_token_link:visible").click
      expect(f("[role=dialog][aria-label='Access Token Details']")).to be_displayed
    end

    it "deletes an access token", priority: "2" do
      skip_if_safari(:alert)
      get "/profile/settings"
      generate_access_token
      # using :visible because we don't want to grab the template element
      fj("#access_tokens .delete_key_link:visible").click
      expect(driver.switch_to.alert).not_to be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(f("#access_tokens")).not_to be_displayed
      check_element_has_focus f(".add_access_token_link")
    end

    it "sets focus to the previous access token when deleting and multiple exist" do
      @token1 = @user.access_tokens.create! purpose: "token_one"
      @token2 = @user.access_tokens.create! purpose: "token_two"
      get "/profile/settings"
      fj(".delete_key_link[rel$='#{@token2.token_hint}']").click
      expect(driver.switch_to.alert).not_to be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      check_element_has_focus fj(".delete_key_link[rel$='#{@token1.token_hint}']")
    end

    context "when access token restrictions are enabled" do
      before do
        @course.root_account.enable_feature!(:admin_manage_access_tokens)
        @course.root_account.settings[:limit_personal_access_tokens] = true
        @course.root_account.save!
      end

      it "the new token button is disabled for non-admins" do
        get "/profile/settings"
        expect(f(".add_access_token_link")).to be_disabled
      end

      it "doesn't show the regenerate button for non-admins" do
        @user.access_tokens.create! purpose: "token_one"
        get "/profile/settings"
        # using :visible because we don't want to grab the template element
        fj("#access_tokens .show_token_link:visible").click
        expect(element_exists?(".regenerate_token")).to be_falsey
      end
    end
  end

  context "services test" do
    before do
      course_with_teacher_logged_in
    end

    context "google drive" do
      it "links back to profile/settings in oauth callbacks" do
        allow(Canvas::Plugin).to receive(:find).and_call_original
        allow(Canvas::Plugin).to receive(:find).with(:google_drive).and_return(double(enabled?: true))
        @user.account.enable_service(:google_drive)
        @user.account.save!
        get "/profile/settings"

        f("#unregistered_service_google_drive > a").click

        dialog = f("[role=dialog][aria-label='Authorize Google Drive']")
        link = dialog.find_element(:css, "a[aria-label='Authorize Google Drive Access']")
        expect(link).to have_attribute("href", "profile%2Fsettings")
      end
    end
  end

  describe "profile pictures local tests" do
    before do
      local_storage!
    end

    it "saves admin profile pics setting", priority: "1" do
      site_admin_logged_in
      get "/accounts/#{Account.default.id}/settings"
      avatars = f("#account_services_avatars")
      scroll_into_view(avatars)
      avatars.click
      f('.Button.Button--primary[type="submit"]').click
      wait_for_ajaximations
      expect(is_checked("#account_services_avatars")).to be_truthy
    end

    # TODO: reimplement per CNVS-29610, but make sure we're testing at the right level
    it "should successfully upload profile pictures"

    it "allows users to choose an avatar from their profile page" do
      course_with_teacher_logged_in

      account = Account.default
      account.enable_service("avatars")
      account.settings[:enable_profiles] = true
      account.save!

      get "/about/#{@user.to_param}"
      wait_for_ajaximations

      f(".profile-link").click
      wait_for_ajaximations

      expect(ff(".avatar-content").length).to eq 1
    end
  end

  it "show /profile when enable_profiles = true" do
    user_logged_in
    account = Account.default
    account.settings[:enable_profiles] = true
    account.save!
    get "/profile"
    expect(fj("h1:contains('User Profile')")).to be_displayed
  end

  it "renders empty state messages when missing information in profile" do
    user_logged_in
    account = Account.default
    account.settings[:enable_profiles] = true
    account.settings[:enable_name_pronunciation] = true
    account.save!
    get "/profile"

    expect(f("#name_pronunciation_empty_message").text).to eq "No name pronunciation provided"
    expect(f("#biography_empty_message").text).to eq "No biography has been added"
    expect(f("#links_empty_message").text).to eq "No links have been added"
  end

  describe "profile pictures s3 tests" do
    # TODO: reimplement per CNVS-29611, but make sure we're testing at the right level
    it "should successfully upload profile pictures"
  end

  describe "avatar reporting" do
    before do
      Account.default.enable_service(:avatars)
      Account.default.settings[:avatars] = "enabled_pending"
      Account.default.save!

      course_with_student_logged_in(active_all: true)
      @other_student = user_factory
      @other_student.avatar_state = "submitted"
      @other_student.save!
      student_in_course(course: @course, user: @other_student, active_all: true)
    end

    it "is able to report inappropriate pictures without profiles enabled" do
      get "/courses/#{@course.id}/users/#{@other_student.id}"
      f(".report_avatar_picture_link").click
      wait_for_ajaximations
      expect(f("#content").text).to include("This image has been reported")
      @other_student.reload
      expect(@other_student.avatar_state).to eq :reported
    end

    it "is able to report inappropriate pictures with profiles enabled" do
      Account.default.settings[:enable_profiles] = true
      Account.default.save!
      get "/courses/#{@course.id}/users/#{@other_student.id}"
      f("#report_avatar_link").click
      expect(f('span[aria-label="Report Profile Picture"]')).to be_truthy
      f('button[data-testid="confirm-button"]').click
      wait_for_ajaximations
      assert_flash_notice_message("The profile picture has been reported.")
      @other_student.reload
      expect(@other_student.avatar_state).to eq :reported
    end

    it "shows a message when the profile picture has already been reported" do
      Account.default.settings[:enable_profiles] = true
      Account.default.save!
      get "/courses/#{@course.id}/users/#{@other_student.id}"
      f("#report_avatar_link").click
      expect(f('span[aria-label="Report Profile Picture"]')).to be_truthy
      f('button[data-testid="confirm-button"]').click
      wait_for_ajaximations
      assert_flash_notice_message("The profile picture has been reported.")
      get "/courses/#{@course.id}/users/#{@other_student.id}"
      reported = f("#avatar_is_reported")
      expect(reported).to be_truthy
      expect(reported.attribute(:innerHTML)).to eq "This image has been reported."
    end
  end

  describe "avatar removing" do
    before do
      Account.default.enable_service(:avatars)
      Account.default.settings[:avatars] = "enabled_pending"
      Account.default.save!

      course_with_teacher_logged_in(active_all: true)
      @other_student = user_factory
      @other_student.avatar_state = "submitted"
      @other_student.save!
      student_in_course(course: @course, user: @other_student, active_all: true)
    end

    it "is able to remove inappropriate pictures without profiles enabled" do
      get "/courses/#{@course.id}/users/#{@other_student.id}"
      f(".remove_avatar_picture_link").click
      expect(f('span[aria-label="Confirm Removal"]')).to be_truthy
      f('button[data-testid="confirm-button"]').click
      wait_for_ajaximations
      @other_student.reload
      expect(@other_student.avatar_image_url?).to be(false)
    end

    it "is able to remove inappropriate pictures with profiles enabled" do
      Account.default.settings[:enable_profiles] = true
      Account.default.save!
      get "/courses/#{@course.id}/users/#{@other_student.id}"
      f("#remove_avatar_link").click
      expect(f('span[aria-label="Confirm Removal"]')).to be_truthy
      f('button[data-testid="confirm-button"]').click
      wait_for_ajaximations
      assert_flash_notice_message("The profile picture has been removed.")
      @other_student.reload
      expect(@other_student.avatar_image_url?).to be(false)
    end
  end

  context "allow_opt_out_of_inbox" do
    it "does not show when feature is off", priority: "1" do
      course_with_teacher_logged_in
      get "/profile/settings"
      expect(f("#content")).not_to contain_css("#disable_inbox")
    end

    it "reveals when the feature flag is set", priority: "1" do
      course_with_teacher_logged_in
      @course.root_account.enable_feature!(:allow_opt_out_of_inbox)
      get "/profile/settings"
      expect(ff("#disable_inbox").count).to eq 1
    end
  end

  describe "MFA buttons behavior" do
    def element_with_text_exists?(selector, text)
      ff(selector).any? { |element| element.text.include?(text) }
    end

    context "when mfa_settings is optional" do
      before do
        Account.default.settings[:mfa_settings] = :optional
        Account.default.save!
        user_logged_in
      end

      it "shows specific MFA buttons" do
        get "/profile/settings"
        expect(element_exists?("#disable_mfa_link")).to be_falsey
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Disable Multi-Factor Authentication")).to be false
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Reconfigure Multi-Factor Authentication")).to be false
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Set Up Multi-Factor Authentication")).to be true
        expect(element_exists?("#otp_backup_codes_link")).to be_falsey
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Multi-Factor Authentication Backup Codes")).to be false
      end

      it "shows specific MFA buttons when user has OTP secret key" do
        @user.update!(otp_secret_key: SecureRandom.base64(32))
        get "/profile/settings"
        expect(element_exists?("#disable_mfa_link")).to be_truthy
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Disable Multi-Factor Authentication")).to be true
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Reconfigure Multi-Factor Authentication")).to be true
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Set Up Multi-Factor Authentication")).to be false
        expect(element_exists?("#otp_backup_codes_link")).to be_truthy
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Multi-Factor Authentication Backup Codes")).to be true
      end
    end

    context "when mfa_settings is disabled" do
      before do
        Account.default.settings[:mfa_settings] = :disabled
        Account.default.save!
        user_logged_in
      end

      it "hides all MFA buttons" do
        get "/profile/settings"
        expect(element_exists?("#disable_mfa_link")).to be_falsey
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Disable Multi-Factor Authentication")).to be false
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Reconfigure Multi-Factor Authentication")).to be false
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Set Up Multi-Factor Authentication")).to be false
        expect(element_exists?("#otp_backup_codes_link")).to be_falsey
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Multi-Factor Authentication Backup Codes")).to be false
      end

      it "hides all MFA buttons when user has OTP secret key" do
        @user.update!(otp_secret_key: SecureRandom.base64(32))
        get "/profile/settings"
        expect(element_exists?("#disable_mfa_link")).to be_falsey
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Disable Multi-Factor Authentication")).to be false
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Reconfigure Multi-Factor Authentication")).to be false
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Set Up Multi-Factor Authentication")).to be false
        expect(element_exists?("#otp_backup_codes_link")).to be_falsey
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Multi-Factor Authentication Backup Codes")).to be false
      end
    end

    context "when mfa_settings is required_for_admins" do
      before do
        Account.default.settings[:mfa_settings] = :required_for_admins
        Account.default.save!
      end

      context "for non-admin users" do
        before do
          user_logged_in
        end

        it "shows specific MFA buttons" do
          get "/profile/settings"
          expect(element_exists?("#disable_mfa_link")).to be_falsey
          expect(element_with_text_exists?(".btn.button-sidebar-wide", "Disable Multi-Factor Authentication")).to be false
          expect(element_with_text_exists?(".btn.button-sidebar-wide", "Reconfigure Multi-Factor Authentication")).to be false
          expect(element_with_text_exists?(".btn.button-sidebar-wide", "Set Up Multi-Factor Authentication")).to be true
          expect(element_exists?("#otp_backup_codes_link")).to be_falsey
          expect(element_with_text_exists?(".btn.button-sidebar-wide", "Multi-Factor Authentication Backup Codes")).to be false
        end

        it "shows specific MFA buttons when user has OTP secret key" do
          @user.update!(otp_secret_key: SecureRandom.base64(32))
          get "/profile/settings"
          expect(element_exists?("#disable_mfa_link")).to be_truthy
          expect(element_with_text_exists?(".btn.button-sidebar-wide", "Disable Multi-Factor Authentication")).to be true
          expect(element_with_text_exists?(".btn.button-sidebar-wide", "Reconfigure Multi-Factor Authentication")).to be true
          expect(element_with_text_exists?(".btn.button-sidebar-wide", "Set Up Multi-Factor Authentication")).to be false
          expect(element_exists?("#otp_backup_codes_link")).to be_truthy
          expect(element_with_text_exists?(".btn.button-sidebar-wide", "Multi-Factor Authentication Backup Codes")).to be true
        end
      end

      context "for admin users" do
        before do
          admin_logged_in
        end

        it "shows specific MFA buttons" do
          get "/profile/settings"
          expect(element_exists?("#disable_mfa_link")).to be_falsey
          expect(element_with_text_exists?(".btn.button-sidebar-wide", "Disable Multi-Factor Authentication")).to be false
          expect(element_with_text_exists?(".btn.button-sidebar-wide", "Reconfigure Multi-Factor Authentication")).to be false
          expect(element_with_text_exists?(".btn.button-sidebar-wide", "Set Up Multi-Factor Authentication")).to be true
          expect(element_exists?("#otp_backup_codes_link")).to be_falsey
          expect(element_with_text_exists?(".btn.button-sidebar-wide", "Multi-Factor Authentication Backup Codes")).to be false
        end

        it "shows specific MFA buttons when user has OTP secret key" do
          @user.update!(otp_secret_key: SecureRandom.base64(32))
          get "/profile/settings"
          expect(element_exists?("#disable_mfa_link")).to be_falsey
          expect(element_with_text_exists?(".btn.button-sidebar-wide", "Disable Multi-Factor Authentication")).to be false
          expect(element_with_text_exists?(".btn.button-sidebar-wide", "Reconfigure Multi-Factor Authentication")).to be true
          expect(element_with_text_exists?(".btn.button-sidebar-wide", "Set Up Multi-Factor Authentication")).to be false
          expect(element_exists?("#otp_backup_codes_link")).to be_truthy
          expect(element_with_text_exists?(".btn.button-sidebar-wide", "Multi-Factor Authentication Backup Codes")).to be true
        end
      end
    end

    context "when mfa_settings is required" do
      before do
        Account.default.settings[:mfa_settings] = :required
        Account.default.save!
        user_logged_in
      end

      it "shows specific MFA buttons" do
        get "/profile/settings"
        expect(element_exists?("#disable_mfa_link")).to be_falsey
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Disable Multi-Factor Authentication")).to be false
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Reconfigure Multi-Factor Authentication")).to be false
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Set Up Multi-Factor Authentication")).to be true
        expect(element_exists?("#otp_backup_codes_link")).to be_falsey
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Multi-Factor Authentication Backup Codes")).to be false
      end

      it "shows specific MFA buttons when user has OTP secret key" do
        @user.update!(otp_secret_key: SecureRandom.base64(32))
        get "/profile/settings"
        expect(element_exists?("#disable_mfa_link")).to be_falsey
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Disable Multi-Factor Authentication")).to be false
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Reconfigure Multi-Factor Authentication")).to be true
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Set Up Multi-Factor Authentication")).to be false
        expect(element_exists?("#otp_backup_codes_link")).to be_truthy
        expect(element_with_text_exists?(".btn.button-sidebar-wide", "Multi-Factor Authentication Backup Codes")).to be true
      end
    end
  end
end
