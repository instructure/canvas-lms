# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/common')

describe "profile" do
  include_context "in-process server selenium tests"

  def click_edit
    f('.edit_settings_link').click
    edit_form = f('#update_profile_form')
    expect(edit_form).to be_displayed
    edit_form
  end

  def add_skype_service
    f('#unregistered_service_skype > a').click
    skype_dialog = f('#unregistered_service_skype_dialog')
    skype_dialog.find_element(:id, 'skype_user_service_user_name').send_keys("jakesorce")
    submit_dialog(skype_dialog, '.btn')
    wait_for_ajaximations
    expect(f('#registered_services')).to include_text("Skype")
  end

  def generate_access_token(purpose = 'testing', close_dialog = false)
    generate_access_token_with_expiration(nil, purpose)
    if close_dialog
      close_visible_dialog
    end
  end

  def generate_access_token_with_expiration(date, purpose = 'testing')
    f('.add_access_token_link').click
    access_token_form = f('#access_token_form')
    access_token_form.find_element(:id, 'access_token_purpose').send_keys(purpose)
    access_token_form.find_element(:id, 'access_token_expires_at').send_keys(date) unless date.nil?
    submit_dialog_form(access_token_form)
    wait_for_ajax_requests
    details_dialog = f('#token_details_dialog')
    expect(details_dialog).to be_displayed
  end

  def log_in_to_settings
    user_with_pseudonym({active_user: true})
    create_session(@pseudonym)
    get '/profile/settings'
  end

  def change_password(old_password, new_password)
    edit_form = click_edit
    edit_form.find_element(:id, 'change_password_checkbox').click
    edit_form.find_element(:id, 'old_password').send_keys(old_password)
    edit_form.find_element(:id, 'pseudonym_password').send_keys(new_password)
    edit_form.find_element(:id, 'pseudonym_password_confirmation').send_keys(new_password)
    submit_form(edit_form)
    wait_for_ajaximations
  end

  it "should give error - wrong old password" do
    log_in_to_settings
    change_password('wrongoldpassword', 'newpassword')
    # check to see if error box popped up
    errorboxes = ff('.error_text')
    expect(errorboxes.length).to be > 1
    expect(errorboxes.any? { |errorbox| errorbox.text =~ /Invalid old password for the login/ }).to be_truthy
  end

  it "should change the password" do
    log_in_to_settings
    change_password('asdfasdf', 'newpassword')
    # login with new password
    expect(@pseudonym.reload).to be_valid_password('newpassword')
  end

  it "rejects passwords longer than 255 characters", priority: "2", test_id: 840136 do
    log_in_to_settings
    change_password('asdfasdf', SecureRandom.hex(128))
    errorboxes = ff('.error_text')
    expect(errorboxes.any? { |errorbox| errorbox.text =~ /Can't exceed 255 characters/ }).to be_truthy
  end

  it "rejects passwords shorter than 6 characters", priority: "2", test_id: 1055503 do
    log_in_to_settings
    change_password('asdfasdf', SecureRandom.hex(2))
    errorboxes = ff('.error_text')
    expect(errorboxes.any? { |errorbox| errorbox.text =~ /Must be at least 6 characters/ }).to be_truthy
  end

  context "non password tests" do

    before(:each) do
      course_with_teacher_logged_in
    end

    def add_email_link
      f('#right-side .add_email_link').click
    end

    it "should add a new email address on profile settings page" do
      @user.account.enable_feature!(:international_sms)
      notification_model(:category => 'Grading')
      notification_policy_model(:notification_id => @notification.id)

      get '/profile/settings'
      add_email_link

      f('#communication_channels a[href="#register_sms_number"]').click

      click_option('#communication_channel_sms_country', 'United States (+1)')
      replace_content(f('#register_sms_number #communication_channel_sms_email'), 'test@example.com')
      expect(f('#register_sms_number button[type="submit"]')).to be_displayed
      f('#communication_channels a[href="#register_email_address"]').click
      form = f("#register_email_address")
      test_email = 'nobody+1234@example.com'
      form.find_element(:id, 'communication_channel_email').send_keys(test_email)
      submit_form(form)

      confirmation_dialog = f("#confirm_email_channel")
      expect(confirmation_dialog).to be_displayed
      submit_dialog(confirmation_dialog, '.cancel_button')
      expect(confirmation_dialog).not_to be_displayed
      expect(f('.email_channels')).to include_text(test_email)
    end

    it "should change default email address" do
      channel = @user.communication_channels.create!(:path_type => 'email',
                                                     :path => 'walter_white@example.com')
      channel.confirm!

      get '/profile/settings'
      row = f("#channel_#{channel.id}")
      link = f("#channel_#{channel.id} td:first-of-type a")
      link.click
      wait_for_ajaximations
      expect(row).to have_class("default")
    end

    it "should edit full name" do
      new_user_name = 'new user name'
      get "/profile/settings"
      edit_form = click_edit
      replace_content(edit_form.find_element(:id, 'user_name'), new_user_name)
      submit_form(edit_form)
      wait_for_ajaximations
      expect(f('.full_name')).to include_text new_user_name
    end

    it "should edit display name and validate" do
      new_display_name = 'test name'
      get "/profile/settings"
      edit_form = click_edit
      replace_content(edit_form.find_element(:id, 'user_short_name'), new_display_name)
      submit_form(edit_form)
      refresh_page
      expect(displayed_username).to eq(new_display_name)
    end

    it "should change the language" do
      get "/profile/settings"
      edit_form = click_edit
      click_option('#user_locale', 'Español')
      expect_new_page_load { submit_form(edit_form) }
      expect(get_value('#user_locale')).to eq 'es'
    end

    it "should change the language even if you can't update your name" do
      a = Account.default
      a.settings[:users_can_edit_name] = false
      a.save!

      get "/profile/settings"
      edit_form = click_edit
      expect(edit_form.find_elements(:id, 'user_short_name').first).to be_nil
      click_option('#user_locale', 'Español')
      expect_new_page_load { submit_form(edit_form) }
      expect(get_value('#user_locale')).to eq 'es'
    end

    it "should add another contact method - sms" do
      @user.account.enable_feature!(:international_sms)
      test_cell_number = '8017121011'
      get "/profile/settings"
      f('.add_contact_link').click
      click_option('#communication_channel_sms_country', 'United States (+1)')
      register_form = f('#register_sms_number')
      register_form.find_element(:css, '.sms_number').send_keys(test_cell_number)
      click_option('select.user_selected.carrier', 'AT&T')
      driver.action.send_keys(:tab).perform
      submit_form(register_form)
      wait_for_ajaximations
      close_visible_dialog
      expect(f('.other_channels .path')).to include_text(test_cell_number)
    end

    it "should register a service" do
      get "/profile/settings"
      add_skype_service
    end

    it "should delete a service" do
      get "/profile/settings"
      add_skype_service
      driver.action.move_to(f('.service')).perform
      f('.delete_service_link').click
      expect(driver.switch_to.alert).not_to be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(f('#unregistered_services')).to include_text("Skype")
    end

    it "should toggle service visibility" do
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

    it "should generate a new access token without an expiration", priority: "2", test_id: 588918 do
      get "/profile/settings"
      generate_access_token('testing', true)
      # some jquery replaces the expiration which makes it hard to select until refresh
      driver.navigate.refresh
      expect(f('.access_token .expires')).to include_text('never')
    end

    it "should generate a new access token with an expiration", priority: "2", test_id: 588919 do
      Timecop.freeze do
        get "/profile/settings"
        generate_access_token_with_expiration(2.days.from_now.strftime("%m/%d/%Y"))
        close_visible_dialog
        # some jquery replaces the 'never' with the expiration which makes it hard to select until refresh
        driver.navigate.refresh
        expect(f('.access_token .expires')).to include_text(2.days.from_now.strftime("%b %d at 12am"))
      end
    end

    it "should regenerate a new access token", priority: "2", test_id: 588920 do
      get "/profile/settings"
      generate_access_token
      token = f('.visible_token').text
      f('.regenerate_token').click
      expect(driver.switch_to.alert).not_to be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      new_token = f('.visible_token').text
      expect(token).not_to eql(new_token)
    end

    it "should test canceling creating a new access token" do
      get "/profile/settings"
      f('.add_access_token_link').click
      access_token_form = f('#access_token_form')
      access_token_form.find_element(:xpath, '../..').find_element(:css, '.ui-dialog-buttonpane .cancel_button').click
      expect(access_token_form).not_to be_displayed
    end

    it "should view the details of an access token" do
      get "/profile/settings"
      generate_access_token('testing', true)
      # had to use :visible because it was failing saying element wasn't visible
      fj('#access_tokens .show_token_link:visible').click
      expect(f('#token_details_dialog')).to be_displayed
    end

    it "should delete an access token", priority: "2", test_id: 588921 do
      get "/profile/settings"
      generate_access_token('testing', true)
      # had to use :visible because it was failing saying element wasn't visible
      fj("#access_tokens .delete_key_link:visible").click
      expect(driver.switch_to.alert).not_to be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(f('#access_tokens')).not_to be_displayed
      check_element_has_focus f(".add_access_token_link")
    end

    it "should set focus to the previous access token when deleting and multiple exist" do
      @token1 = @user.access_tokens.create! purpose: 'token_one'
      @token2 = @user.access_tokens.create! purpose: 'token_two'
      get "/profile/settings"
      fj(".delete_key_link[rel$=#{@token2.id}]").click
      expect(driver.switch_to.alert).not_to be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      check_element_has_focus fj(".delete_key_link[rel$=#{@token1.id}]")
    end
  end

  context "services test" do
    before(:each) do
      course_with_teacher_logged_in
    end

    it "should link back to profile/settings in oauth callbacks" do
      get "/profile/settings"
      links = ff('#unregistered_services .service .content a')
      links.each do |l|
        expect(l).to have_attribute('href', 'profile%2Fsettings')
      end
    end
  end

  describe "profile pictures local tests" do
    before do
      local_storage!
    end

    it "should save admin profile pics setting", priority: "1", test_id: 68933 do
      site_admin_logged_in
      get "/accounts/#{Account.default.id}/settings"
      f('#account_services_avatars').click
      f('.Button.Button--primary[type="submit"]').click
      wait_for_ajaximations
      expect(is_checked('#account_services_avatars')).to be_truthy
    end

    # TODO: reimplement per CNVS-29610, but make sure we're testing at the right level
    it "should successfully upload profile pictures"

    it "should allow users to choose an avatar from their profile page" do
      course_with_teacher_logged_in

      account = Account.default
      account.enable_service('avatars')
      account.settings[:enable_profiles] = true
      account.save!

      get "/about/#{@user.to_param}"
      wait_for_ajaximations

      f('.profile-link').click
      wait_for_ajaximations

      expect(ff('.avatar-content').length).to eq 1
    end
  end

  describe "profile pictures s3 tests" do
    # TODO: reimplement per CNVS-29611, but make sure we're testing at the right level
    it "should successfully upload profile pictures"
  end

  describe "avatar reporting" do
    before :each do
      Account.default.enable_service(:avatars)
      Account.default.settings[:avatars] = 'enabled_pending'
      Account.default.save!

      course_with_student_logged_in(:active_all => true)
      @other_student = user
      @other_student.avatar_state = "submitted"
      @other_student.save!
      student_in_course(:course => @course, :user => @other_student, :active_all => true)
    end

    it "should be able to report inappropriate pictures without profiles enabled" do
      get "/courses/#{@course.id}/users/#{@other_student.id}"
      f('.report_avatar_picture_link').click
      wait_for_ajaximations
      expect(f('#content').text).to include("This image has been reported")
      @other_student.reload
      expect(@other_student.avatar_state).to eq :reported
    end

    it "should be able to report inappropriate pictures with profiles enabled" do
      Account.default.settings[:enable_profiles] = true
      Account.default.save!
      get "/courses/#{@course.id}/users/#{@other_student.id}"
      f('.report_avatar_link').click
      expect(alert_present?).to be_truthy
      accept_alert
      wait_for_ajaximations
      @other_student.reload
      expect(@other_student.avatar_state).to eq :reported
    end
  end
end
