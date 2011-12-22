require File.expand_path(File.dirname(__FILE__) + '/common')

describe "announcements selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  it "should not show JSON when loading more announcements via pageless" do
    course_with_student_logged_in
    
    50.times { @course.announcements.create!(:title => 'Hi there!', :message => 'Announcement time!') }
    get "/courses/#{@course.id}/announcements"
    
    start = driver.find_elements(:css, "#topic_list .topic").length
    driver.execute_script('window.scrollTo(0, 100000)')
    keep_trying_until { driver.find_elements(:css, "#topic_list .topic").length > start }
    
    driver.find_element(:id, "topic_list").should_not include_text('discussion_topic')
  end

  it "should create an announcement" do
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/announcements"

    #start creating announcement  
    driver.find_element(:css, '.add_topic_link').click
    topic_title = driver.find_element(:css, '.add_topic_form_new input[name="discussion_topic[title]"]')
    topic_title.clear
    topic_title.send_keys "First Announcement"

    first_text = 'Hi, this is my first announcement'
    type_in_tiny('textarea.topic_content:first', first_text)
    driver.find_element(:css, '.add_topic_form_new').submit
    wait_for_ajaximations
    announcement = driver.find_element(:css, '#topic_list .topic')
    announcement.find_element(:link, "First Announcement").should be_displayed
    announcement.find_element(:css, '.message').should include_text(first_text)
  end

  it "should have a teacher add a new entry to its own announcement" do
    course_with_teacher_logged_in
    @context = @course
    announcement_model
    get "/courses/#{@course.id}/announcements"

    driver.find_element(:css, '.content .replies').click
    driver.find_element(:css, '#content .add_entry_link').click
    entry_text = 'new entry text'
    type_in_tiny('textarea.entry_content:first', entry_text)
    driver.find_element(:id, 'add_entry_form_entry_new').submit
    wait_for_ajaximations
    driver.find_element(:css, '#entry_list .discussion_entry .content').should include_text(entry_text)
    driver.find_element(:css, '#left-side .announcements').click
    driver.find_element(:css, '#topic_list .replies').should include_text('1')
  end


  it "should add an external feed to announcements" do
    course_with_teacher_logged_in

    get "/courses/#{@course.id}/announcements"

    #add external feed to announcements
    feed_name = 'http://www.google.com'
    driver.find_element(:css, '.add_external_feed_link').click
    feed_form = driver.find_element(:id, 'add_external_feed_form')
    feed_form.find_element(:id, 'external_feed_url').send_keys(feed_name)
    unless feed_form.find_element(:id, 'external_feed_header_match').displayed?
      feed_form.find_element(:id, 'external_feed_add_header_match').click
    end
    feed_form.find_element(:id, 'external_feed_header_match').send_keys('blah')
    feed_form.submit
    wait_for_ajaximations

    #delete external feed
    driver.find_element(:link, feed_name).should be_displayed
    driver.find_element(:css, '#external_feeds li:nth-child(2) .delete_feed_link').click
    confirm_dialog = driver.switch_to.alert
    confirm_dialog.accept
    wait_for_ajaximations
    element_exists(:link, feed_name).should be_false
    ExternalFeed.count.should eql(0)

    #cancel while adding an external feed
    driver.find_element(:css, '.add_external_feed_link').click
    feed_form.find_element(:id, 'external_feed_url').send_keys('http://www.yahoo.com')
    feed_form.find_element(:id, 'external_feed_header_match').send_keys('more blah')
    feed_form.find_element(:css, '#add_external_feed_form .cancel_button').click
    wait_for_animations
    driver.find_element(:id,'add_external_feed_form').should_not be_displayed

  end

end
