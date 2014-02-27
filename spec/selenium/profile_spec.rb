# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/common')

describe "profile" do
  include_examples "in-process server selenium tests"

  def click_edit
    f('.edit_settings_link').click
    edit_form = f('#update_profile_form')
    keep_trying_until { edit_form.should be_displayed }
    edit_form
  end

  def add_skype_service
    f('#unregistered_service_skype > a').click
    skype_dialog = f('#unregistered_service_skype_dialog')
    skype_dialog.find_element(:id, 'user_service_user_name').send_keys("jakesorce")
    submit_dialog(skype_dialog, '.btn')
    wait_for_ajaximations
    f('#registered_services').should include_text("Skype")
  end

  def generate_access_token(purpose = 'testing', close_dialog = false)
    f('.add_access_token_link').click
    access_token_form = f('#access_token_form')
    access_token_form.find_element(:id, 'access_token_purpose').send_keys(purpose)
    submit_form(access_token_form)
    wait_for_ajax_requests
    details_dialog = f('#token_details_dialog')
    details_dialog.should be_displayed
    if close_dialog
      close_visible_dialog
    end
  end

  it "should give error - wrong old password" do
    user_with_pseudonym({:active_user => true})
    login_as
    get '/profile/settings'
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
    errorboxes.any? { |errorbox| errorbox.text =~ /Invalid old password for the login/ }.should be_true
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
    keep_trying_until { login_as('nobody@example.com', new_password) }
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
      replace_content(f('#register_sms_number #communication_channel_sms_email'), 'test@example.com')
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

    it "should change default email address" do
      channel = @user.communication_channels.create!(:path_type => 'email',
                                                     :path => 'walter_white@example.com')
      channel.confirm!

      get '/profile/settings'
      row = f("#channel_#{channel.id}")
      link = f("#channel_#{channel.id} td:first-child a")
      link.click
      wait_for_ajaximations
      row.should have_class("default")
    end

    it "should edit full name" do
      new_user_name = 'new user name'
      get "/profile/settings"
      edit_form = click_edit
      edit_form.find_element(:id, 'user_name').send_keys(new_user_name)
      submit_form(edit_form)
      wait_for_ajaximations
      keep_trying_until { f('.full_name').text.should == new_user_name }
    end

    it "should edit display name and validate" do
      new_display_name = 'test name'
      get "/profile/settings"
      edit_form = click_edit
      edit_form.find_element(:id, 'user_short_name').send_keys(new_display_name)
      submit_form(edit_form)
      wait_for_ajaximations
      refresh_page
      keep_trying_until { f('#topbar li.user_name').text.should == new_display_name }
    end

    it "should change the language" do
      get "/profile/settings"
      edit_form = click_edit
      click_option('#user_locale', 'Español')
      expect_new_page_load { submit_form(edit_form) }
      get_value('#user_locale').should == 'es'
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
      get_value('#user_locale').should == 'es'
    end

    it "should add another contact method - sms" do
      test_cell_number = '8017121011'
      get "/profile/settings"
      f('.add_contact_link').click
      register_form = f('#register_sms_number')
      register_form.find_element(:css, '.sms_number').send_keys(test_cell_number)
      click_option('select.user_selected.carrier', 'AT&T')
      submit_form(register_form)
      wait_for_ajaximations
      close_visible_dialog
      keep_trying_until { f('.other_channels .path').should include_text(test_cell_number) }
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
      f('.delete_service_link').click
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      f('#unregistered_services').should include_text("Skype")
    end

    it "should toggle service visibility" do
      get "/profile/settings"
      add_skype_service
      initial_state = @user.show_user_services

      f('#show_user_services').click
      wait_for_ajaximations
      @user.reload.show_user_services.should_not == initial_state

      f('#show_user_services').click
      wait_for_ajaximations
      @user.reload.show_user_services.should == initial_state
    end

    it "should generate a new access token" do
      get "/profile/settings"
      generate_access_token
    end

    it "should test canceling creating a new access token" do
      get "/profile/settings"
      f('.add_access_token_link').click
      access_token_form = f('#access_token_form')
      access_token_form.find_element(:xpath, '../..').find_element(:css, '.ui-dialog-buttonpane .cancel_button').click
      access_token_form.should_not be_displayed
    end

    it "should view the details of an access token" do
      get "/profile/settings"
      generate_access_token('testing', true)
      #had to use :visible because it was failing saying element wasn't visible
      fj('#access_tokens .show_token_link:visible').click
      f('#token_details_dialog').should be_displayed
    end

    it "should delete an access token" do
      get "/profile/settings"
      generate_access_token('testing', true)
      #had to use :visible because it was failing saying element wasn't visible
      fj("#access_tokens .delete_key_link:visible").click
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      f('#access_tokens').should_not be_displayed
    end
  end

  context "services test" do
    before (:each) do
      course_with_teacher_logged_in
    end

    it "should link back to profile/settings in oauth callbacks" do
      get "/profile/settings"
      links = ffj('#unregistered_services .service .content a')
      links.each do |l|
        url = l.attribute('href')
        query = URI.parse(url).query
        CGI.unescape(query).should match /profile\/settings/
      end
    end
  end

  describe "profile pictures local tests" do
    before do
      local_storage!
    end

    it "should successfully upload profile pictures" do
      pending("intermittently fails")
      course_with_teacher_logged_in
      a = Account.default
      a.enable_service('avatars')
      a.save!
      image_src = ''

      get "/profile/settings"
      keep_trying_until { f(".profile_pic_link") }.click
      dialog = f("#profile_pic_dialog")
      dialog.should be_displayed
      dialog.find_element(:css, ".add_pic_link").click
      filename, fullpath, data = get_file("graded.png")
      dialog.find_element(:id, 'attachment_uploaded_data').send_keys(fullpath)
      # Make ajax request slow down to verify transitional state
      FilesController.before_filter { sleep 5; true }

      submit_form('#add_pic_form')

      new_image = dialog.find_elements(:css, ".profile_pic_list span.img img").last
      new_image.attribute('src').should_not =~ %r{/images/thumbnails/}

      if CANVAS_RAILS2
        FilesController.filter_chain.pop
      else
        FilesController._process_action_callbacks.pop
      end

      keep_trying_until do
        spans = ffj("#profile_pic_dialog .profile_pic_list span.img")
        spans.last.attribute('class') =~ /selected/
        uploaded_image = ffj("#profile_pic_dialog .profile_pic_list span.img img").last
        image_src = uploaded_image.attribute('src')
        image_src.should =~ %r{/images/thumbnails/}
        new_image.attribute('alt').should =~ /graded/
      end
      dialog.find_element(:css, '.select_button').click
      wait_for_ajaximations
      keep_trying_until do
        profile_pic = fj('.profile_pic_link img')
        profile_pic.should have_attribue('src', image_src)
      end
      Attachment.last.folder.should == @user.profile_pics_folder
    end

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

      f('#profile_pic_dialog').should_not be_nil
    end
  end

  describe "profile pictures s3 tests" do
    before do
      s3_storage!(:stubs => false)
    end

    it "should successfully upload profile pictures" do
      pending("intermittently fails")
      course_with_teacher_logged_in
      a = Account.default
      a.enable_service('avatars')
      a.save!
      image_src = ''

      get "/profile/settings"
      keep_trying_until { f(".profile_pic_link") }.click
      dialog = f("#profile_pic_dialog")
      dialog.should be_displayed
      dialog.find_element(:css, ".add_pic_link").click
      filename, fullpath, data = get_file("graded.png")
      dialog.find_element(:id, 'attachment_uploaded_data').send_keys(fullpath)
      # Make ajax request slow down to verify transitional state
      FilesController.before_filter { sleep 5; true }

      submit_form('#add_pic_form')

      new_image = dialog.find_elements(:css, ".profile_pic_list span.img img").last
      new_image.attribute('src').should_not =~ %r{/images/thumbnails/}

      if CANVAS_RAILS2
        FilesController.filter_chain.pop
      else
        FilesController._process_action_callbacks.pop
      end

      keep_trying_until do
        spans = ffj("#profile_pic_dialog .profile_pic_list span.img")
        spans.last.attribute('class') =~ /selected/
        uploaded_image = ffj("#profile_pic_dialog .profile_pic_list span.img img").last
        image_src = uploaded_image.attribute('src')
        image_src.should =~ %r{/images/thumbnails/}
        new_image.attribute('alt').should =~ /graded/
      end
      dialog.find_element(:css, '.select_button').click
      wait_for_ajaximations
      keep_trying_until do
        profile_pic = fj('.profile_pic_link img')
        profile_pic.should have_attribue('src', image_src)
      end
      Attachment.last.folder.should == @user.profile_pics_folder
    end
  end
end

