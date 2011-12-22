require File.expand_path(File.dirname(__FILE__) + '/common')

describe "profile tests" do
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
    access_token_form.submit
    wait_for_ajax_requests
    details_dialog = driver.find_element(:id, 'token_details_dialog')
    details_dialog.should be_displayed
    if close_dialog
      close_visible_dialog
    end
  end

  it "should change the password" do
    user_with_pseudonym({:active_user => true})
    login_as
    get '/profile'
    old_password = 'asdfasdf'
    new_password = 'newpassword'
    edit_form = click_edit
    edit_form.find_element(:id, 'change_password_checkbox').click
    edit_form.find_element(:id, 'old_password').send_keys(old_password)
    edit_form.find_element(:id, 'pseudonym_password').send_keys(new_password)
    edit_form.find_element(:id, 'pseudonym_password_confirmation').send_keys(new_password)
    edit_form.submit
    wait_for_ajax_requests
    #login with new password
    login_as('nobody@example.com', new_password)
    #check message to make sure the user was logged in successfully with the new password
    assert_flash_notice_message /Login successful/
  end

  context "non password tests" do

    before (:each) do
      course_with_teacher_logged_in
    end

    it "should add a new email address" do
      notification_model(:category => 'Grading')
      notification_policy_model(:notification_id => @notification.id)

      get "/profile"
      #Add email address to profile
      driver.find_element(:css, '#right-side .add_email_link').click
      driver.find_element(:css, '#communication_channels a[href="#register_sms_number"]').click
      driver.find_element(:css, '#communication_channels a[href="#register_email_address"]').click
      form = driver.find_element(:id, "register_email_address")
      test_email = 'nobody+1234@example.com'
      form.find_element(:id, 'pseudonym_unique_id').send_keys(test_email)
      form.find_element(:id, 'register_email_address').submit

      confirmation_dialog = driver.find_element(:id, "confirm_email_channel")
      keep_trying_until { confirmation_dialog.displayed? }
      driver.execute_script("return INST.errorCount;").should == 0
      confirmation_dialog.find_element(:css, "button").click
      confirmation_dialog.should_not be_displayed

      driver.find_element(:link, test_email).should be_displayed
    end

    it "should modify user notification policies" do
      second_email = 'nobody+1234@example.com'
      communication_channel_model(:user_id => @user.id, :path => second_email, :path_type => 'email')

      notification_model(:category => 'Grading')

      get "/profile"
      #Test modifying notifications
      driver.find_element(:css, '#section-tabs .notifications').click
      content_tbody = driver.find_element(:css, '#content > table > tbody')
      content_tbody.find_elements(:css, 'tr.preference').length.should == 1

      content_tbody.find_element(:css, 'tr:nth-child(2) > td').
          should include_text(I18n.t(:grading_description, 'For course grading alerts'))
      #add new notification and select different email
      content_tbody.find_element(:css, '.add_notification_link').click
      wait_for_animations
      email_select_css = '#content > table > tbody > tr:nth-child(3) > td > span > select'
      option_value = find_option_value(:css, email_select_css, second_email)

      find_with_jquery("#{email_select_css} > option[value=\"#{option_value}\"]'").click
      #change notification setting for first notification
      daily_select = content_tbody.find_element(:css, 'tr:nth-child(4) > td:nth-child(3) > div')
      daily_select.click
      daily_select.find_element(:xpath, '..').should have_class('selected_pending')
      #change notification setting for second notification
      never_select = content_tbody.find_element(:css, 'tr:nth-child(3) > td:nth-child(5) > div')
      never_select.click
      never_select.find_element(:xpath, '..').should have_class('selected_pending')
      driver.find_element(:css, '#content .save_preferences_button').click
      wait_for_ajax_requests
      refresh_page

      select_rows = [driver.find_element(:css, '#content > table > tbody > tr:nth-child(3)'),
                     driver.find_element(:css, '#content > table > tbody > tr:nth-child(4)')]
      select_rows.each do |row|
        if row.find_element(:css, 'td:nth-child(3)').attribute('class').match(/selected/)
          # the daily
          row.find_element(:css, 'td > span > select > option:checked').text.should == @user.email
        else
          # the never
          row.find_element(:css, 'td > span > select > option:checked').text.should == second_email
        end
      end
    end

    it "should successfully upload profile pictures" do
      a = Account.default
      a.enable_service('avatars')
      a.save!

      get "/profile"
      keep_trying_until { driver.find_element(:css, ".profile_pic_link.none") }.click
      dialog = driver.find_element(:id, "profile_pic_dialog")
      dialog.find_element(:css, ".profile_pic_list").find_elements(:css, "span.img").length.should == 2
      dialog.find_element(:css, ".add_pic_link").click
      filename, fullpath, data = get_file("graded.png")
      dialog.find_element(:id, 'attachment_uploaded_data').send_keys(fullpath)

      # Make ajax request slow down to verify transitional state
      FilesController.before_filter { sleep 5; true }

      dialog.find_element(:css, 'button[type="submit"]').click
      spans = dialog.find_element(:css, ".profile_pic_list").find_elements(:css, "span.img")
      spans.length.should == 3
      new_image = spans.last.find_element(:css, 'img')
      new_image.attribute('src').should_not =~ %r{/images/thumbnails/}

      FilesController.filter_chain.pop

      keep_trying_until do
        spans.last.attribute('class') =~ /selected/
        new_image.attribute('src').should =~ %r{/images/thumbnails/}
      end
      dialog.find_element(:css, 'button.select_button').click
      keep_trying_until { driver.find_element(:css, '.profile_pic_link img').attribute('src') =~ %r{/images/thumbnails/} }

      Attachment.last.folder.should == @user.profile_pics_folder
    end

    it "should display file uploader link on files page" do
      get "/profile"
      driver.find_element(:css, '#left-side .files').click
      wait_for_dom_ready
      driver.find_element(:id, 'file_swfUploader').should be_displayed
    end

    it "should edit full name" do
      new_user_name = 'new user name'
      get "/profile"
      edit_form = click_edit
      edit_form.find_element(:id, 'user_name').send_keys(new_user_name)
      edit_form.submit
      wait_for_ajaximations
      keep_trying_until { driver.find_element(:css, '.full_name').text.should == new_user_name }
    end

    it "should edit display name and validate" do
      new_display_name = 'test name'
      get "/profile"
      edit_form = click_edit
      edit_form.find_element(:id, 'user_short_name').send_keys(new_display_name)
      edit_form.submit
      wait_for_ajaximations
      refresh_page
      keep_trying_until { driver.find_element(:css, '#topbar li.user_name').text.should == new_display_name }
    end

    it "should change the language" do
      get "/profile"
      edit_form = click_edit
      click_option_by_text(edit_form.find_element(:id, 'user_locale'), "Español")
      expect_new_page_load { edit_form.submit }
      driver.find_element(:css, '.profile_table').should include_text('Nombre')
    end

    it "should add another contact method - sms" do
      test_cell_number = '8017121011'
      get "/profile"
      driver.find_element(:css, '.add_contact_link').click
      register_form = driver.find_element(:id, 'register_sms_number')
      register_form.find_element(:css, '.sms_number').send_keys(test_cell_number)
      click_option_by_text(register_form.find_element(:css, 'select.user_selected.carrier'), 'AT&T')
      register_form.submit
      wait_for_ajaximations
      close_visible_dialog
      keep_trying_until { driver.find_element(:css, '.other_channels .path').should include_text(test_cell_number) }
    end

    it "should register a service" do
      get "/profile"
      add_skype_service
    end

    it "should delete a service" do
      get "/profile"
      add_skype_service
      #had to use add class because tests were failing inconsistently in aws
      driver.execute_script("$('.service').addClass('service-hover')")
      driver.find_element(:css, '.delete_service_link').click
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      driver.find_element(:id, 'unregistered_services').should include_text("Skype")
    end

    it "should generate a new access token" do
      get "/profile"
      generate_access_token
    end

    it "should test canceling creating a new access token" do
      get "/profile"
      driver.find_element(:css, '.add_access_token_link').click
      access_token_form = driver.find_element(:id, 'access_token_form')
      access_token_form.find_element(:css, '.cancel_button').click
      access_token_form.should_not be_displayed
    end

    it "should view the details of an access token" do
      get "/profile"
      generate_access_token('testing', true)
      #had to use :visible because it was failing saying element wasn't visible
      find_with_jquery('#access_tokens .show_token_link:visible').click
      driver.find_element(:id, 'token_details_dialog').should be_displayed
    end

    it "should delete an access token" do
      get "/profile"
      generate_access_token('testing', true)
      #had to use :visible because it was failing saying element wasn't visible
      find_with_jquery("#access_tokens .delete_key_link:visible").click
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      driver.find_element(:id, 'access_tokens').should_not be_displayed
    end
  end
end

