require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "profile selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  it "should add a new email address" do
    course_with_teacher_logged_in
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
    course_with_teacher_logged_in
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
    
    course_with_student_logged_in
    
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
    course_with_teacher_logged_in

    get "/profile"
    
    driver.find_element(:css, '#left-side .files').click
    wait_for_dom_ready
    driver.find_element(:id, 'file_swfUploader').should be_displayed

  end

end

describe "profile Windows-Firefox-Tests" do
  it_should_behave_like "profile selenium tests"
end
