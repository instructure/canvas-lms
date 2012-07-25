# coding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/common')

describe "profile" do
  it_should_behave_like "in-process server selenium tests"

  def click_edit
    driver.find_element(:css, '.edit_profile_link').click
    edit_form = driver.find_element(:id, 'update_profile_form')
    keep_trying_until { edit_form.should be_displayed }
    edit_form
  end

  def add_skype_service
    driver.find_element(:css, '#unregistered_service_skype > a').click
    skype_dialog = driver.find_element(:id, 'unregistered_service_skype_dialog')
    skype_dialog.find_element(:id, 'user_service_user_name').send_keys("jakesorce")
    driver.find_element(:css, '#unregistered_service_skype_dialog .button').click
    wait_for_ajaximations
    driver.find_element(:id, 'registered_services').should include_text("Skype")
  end

  def generate_access_token(purpose = 'testing', close_dialog = false)
    driver.find_element(:css, '.add_access_token_link').click
    access_token_form = driver.find_element(:id, 'access_token_form')
    access_token_form.find_element(:id, 'access_token_purpose').send_keys(purpose)
    submit_form(access_token_form)
    wait_for_ajax_requests
    details_dialog = driver.find_element(:id, 'token_details_dialog')
    details_dialog.should be_displayed
    if close_dialog
      close_visible_dialog
    end
  end

  it "should give error - wrong old password" do
    user_with_pseudonym({:active_user => true})
    login_as
    get '/profile/settings'
    old_password = 'oldpassword'
    wrong_old_password = 'wrongoldpassword'
    new_password = 'newpassword'
    edit_form = click_edit
    edit_form.find_element(:id, 'change_password_checkbox').click
    edit_form.find_element(:id, 'old_password').send_keys(wrong_old_password)
    edit_form.find_element(:id, 'pseudonym_password').send_keys(new_password)
    edit_form.find_element(:id, 'pseudonym_password_confirmation').send_keys(new_password)
    submit_form(edit_form)
    wait_for_ajaximations
    # check to see if error box popped up
    errorboxes = ff('.error_text')
    errorboxes.length.should > 1
    errorboxes.any? {|errorbox| errorbox.text =~ /Invalid old password for the login/}.should be_true
  end

  it "should change the password" do
    user_with_pseudonym({:active_user => true})
    login_as
    get '/profile/settings'
    old_password = 'asdfasdf'
    new_password = 'newpassword'
    edit_form = click_edit
    edit_form.find_element(:id, 'change_password_checkbox').click
    edit_form.find_element(:id, 'old_password').send_keys(old_password)
    edit_form.find_element(:id, 'pseudonym_password').send_keys(new_password)
    edit_form.find_element(:id, 'pseudonym_password_confirmation').send_keys(new_password)
    submit_form(edit_form)
    wait_for_ajaximations
    #login with new password
    login_as('nobody@example.com', new_password)
  end

  context "non password tests" do

    before (:each) do
      course_with_teacher_logged_in
    end

    def add_email_link
      f('#right-side .add_email_link').click
    end

    it "should add a new email address on profile settings page" do
      notification_model(:category => 'Grading')
      notification_policy_model(:notification_id => @notification.id)

      get '/profile/settings'
      add_email_link

      f('#communication_channels a[href="#register_sms_number"]').click
      replace_content(f('#register_sms_number #communication_channel_address'), 'test@example.com')
      f('#register_sms_number button[type="submit"]').should be_displayed
      f('#communication_channels a[href="#register_email_address"]').click
      form = f("#register_email_address")
      test_email = 'nobody+1234@example.com'
      form.find_element(:id, 'communication_channel_address').send_keys(test_email)
      submit_form(form)

      confirmation_dialog = f("#confirm_email_channel")
      keep_trying_until { confirmation_dialog.should be_displayed }
      driver.execute_script("return INST.errorCount;").should == 0
      submit_dialog(confirmation_dialog, '.cancel_button')
      confirmation_dialog.should_not be_displayed
      f('.email_channels').should include_text(test_email)
    end

    it "should display file uploader link on files page" do
      get "/profile/settings"
      expect_new_page_load { driver.find_element(:css, '#left-side .files').click }
      driver.find_element(:id, 'file_swfUploader').should be_displayed
    end

    it "should edit full name" do
      new_user_name = 'new user name'
      get "/profile/settings"
      edit_form = click_edit
      edit_form.find_element(:id, 'user_name').send_keys(new_user_name)
      submit_form(edit_form)
      wait_for_ajaximations
      keep_trying_until { driver.find_element(:css, '.full_name').text.should == new_user_name }
    end

    it "should edit display name and validate" do
      new_display_name = 'test name'
      get "/profile/settings"
      edit_form = click_edit
      edit_form.find_element(:id, 'user_short_name').send_keys(new_display_name)
      submit_form(edit_form)
      wait_for_ajaximations
      refresh_page
      keep_trying_until { driver.find_element(:css, '#topbar li.user_name').text.should == new_display_name }
    end

    it "should change the language" do
      get "/profile/settings"
      edit_form = click_edit
      click_option('#user_locale', 'Español')
      expect_new_page_load { submit_form(edit_form) }
      driver.find_element(:css, '.profile_table').should include_text('Nombre')
    end

    it "should change the language even if you can't update your name" do
      a = Account.default
      a.settings[:users_can_edit_name] = false
      a.save!

      get "/profile/settings"
      edit_form = click_edit
      edit_form.find_elements(:id, 'user_short_name').first.should be_nil
      click_option('#user_locale', 'Español')
      expect_new_page_load { submit_form(edit_form) }
      driver.find_element(:css, '.profile_table').should include_text('Nombre')
    end

    it "should add another contact method - sms" do
      test_cell_number = '8017121011'
      get "/profile/settings"
      driver.find_element(:css, '.add_contact_link').click
      register_form = driver.find_element(:id, 'register_sms_number')
      register_form.find_element(:css, '.sms_number').send_keys(test_cell_number)
      click_option('select.user_selected.carrier', 'AT&T')
      submit_form(register_form)
      wait_for_ajaximations
      close_visible_dialog
      keep_trying_until { driver.find_element(:css, '.other_channels .path').should include_text(test_cell_number) }
    end

    it "should register a service" do
      get "/profile/settings"
      add_skype_service
    end

    it "should delete a service" do
      get "/profile/settings"
      add_skype_service
      #had to use add class because tests were failing inconsistently in aws
      driver.execute_script("$('.service').addClass('service-hover')")
      driver.find_element(:css, '.delete_service_link').click
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      driver.find_element(:id, 'unregistered_services').should include_text("Skype")
    end

    it "should toggle service visibility" do
      get "/profile/settings"
      add_skype_service
      initial_state = @user.show_user_services

      driver.find_element(:id, 'show_user_services').click
      wait_for_ajaximations
      @user.reload.show_user_services.should_not eql initial_state

      driver.find_element(:id, 'show_user_services').click
      wait_for_ajaximations
      @user.reload.show_user_services.should eql initial_state
    end

    it "should generate a new access token" do
      get "/profile/settings"
      generate_access_token
    end

    it "should test canceling creating a new access token" do
      get "/profile/settings"
      driver.find_element(:css, '.add_access_token_link').click
      access_token_form = driver.find_element(:id, 'access_token_form')
      access_token_form.find_element(:css, '.cancel_button').click
      access_token_form.should_not be_displayed
    end

    it "should view the details of an access token" do
      get "/profile/settings"
      generate_access_token('testing', true)
      #had to use :visible because it was failing saying element wasn't visible
      find_with_jquery('#access_tokens .show_token_link:visible').click
      driver.find_element(:id, 'token_details_dialog').should be_displayed
    end

    it "should delete an access token" do
      get "/profile/settings"
      generate_access_token('testing', true)
      #had to use :visible because it was failing saying element wasn't visible
      find_with_jquery("#access_tokens .delete_key_link:visible").click
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      driver.find_element(:id, 'access_tokens').should_not be_displayed
    end

    it "should set the birthdate" do
      get "/profile/settings"
      edit_form = click_edit
      click_option('#user_birthdate_1i', '1980')
      click_option('#user_birthdate_2i', 'January')
      click_option('#user_birthdate_3i', '31')
      submit_form(edit_form)
      wait_for_ajaximations
      @user.reload
      @user.birthdate.should eql(Time.utc(1980, 1, 31))
    end

    it "should not accept a partial birthdate" do
      get "/profile/settings"
      edit_form = click_edit
      click_option('#user_birthdate_1i', '')
      click_option('#user_birthdate_2i', 'February')
      click_option('#user_birthdate_3i', '2')
      submit_form(edit_form)
      wait_for_ajaximations
      edit_form.should be_displayed    # not dismissed
      @user.reload
      @user.birthdate.should be_nil    # no default year assumed
    end

    it "should not allow the birthdate to be un-set" do
      @user.birthdate = Time.utc(1980, 1, 1)
      @user.save!
      get "/profile/settings"
      edit_form = click_edit
      lambda { click_option('#user_birthdate_1i', '') }.should raise_error(Selenium::WebDriver::Error::NoSuchElementError)
    end
  end
end

shared_examples_for "profile pictures selenium tests" do
  it_should_behave_like "forked server selenium tests"

  it "should successfully upload profile pictures" do
    pending("intermittently fails")
    course_with_teacher_logged_in
    a = Account.default
    a.enable_service('avatars')
    a.save!
    IMAGE_SRC = ''

    get "/profile/settings"
    keep_trying_until { f(".profile_pic_link") }.click
    dialog = f("#profile_pic_dialog")
    dialog.should be_displayed
    dialog.find_elements(:css, ".profile_pic_list span.img").length.should == 2
    dialog.find_element(:css, ".add_pic_link").click
    filename, fullpath, data = get_file("graded.png")
    dialog.find_element(:id, 'attachment_uploaded_data').send_keys(fullpath)
    # Make ajax request slow down to verify transitional state
    FilesController.before_filter { sleep 5; true }

    submit_form('#add_pic_form')

    new_image = dialog.find_elements(:css, ".profile_pic_list span.img img").last
    new_image.attribute('src').should_not =~ %r{/images/thumbnails/}

    FilesController.filter_chain.pop

    keep_trying_until do
      spans = ffj("#profile_pic_dialog .profile_pic_list span.img")
      spans.length.should == 3
      spans.last.attribute('class') =~ /selected/
      uploaded_image = ffj("#profile_pic_dialog .profile_pic_list span.img img").last
      IMAGE_SRC = uploaded_image.attribute('src')
      IMAGE_SRC.should =~ %r{/images/thumbnails/}
      new_image.attribute('alt').should =~ /graded/
    end
    dialog.find_element(:css, '.select_button').click
    wait_for_ajaximations
    keep_trying_until do
      profile_pic = fj('.profile_pic_link img')
      profile_pic.attribute('src').should == IMAGE_SRC
    end
    Attachment.last.folder.should == @user.profile_pics_folder
  end
end

describe "profile pictures local tests" do
  it_should_behave_like "profile pictures selenium tests"
  prepend_before(:each) do
    Setting.set("file_storage_test_override", "local")
  end
end
