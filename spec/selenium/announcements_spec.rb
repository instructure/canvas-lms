require File.expand_path(File.dirname(__FILE__) + '/common')

describe "announcements" do

  it_should_behave_like "in-process server selenium tests"

  def create_announcement(message = 'announcement message')
    @context = @course
    @announcement = announcement_model(:title => 'new announcement', :message => message)
  end

  def create_announcement_manual(css_checkbox)
    driver.find_element(:css, '.add_topic_link').click
    add_topic_form = driver.find_element(:css, '.add_topic_form_new')
    topic_title = driver.find_element(:css, '.add_topic_form_new input[name="discussion_topic[title]"]')
    topic_title.clear
    topic_title.send_keys "First Announcement"


    type_in_tiny('textarea.topic_content:first', 'Hi, this is my first announcement')
    if css_checkbox != nil
      driver.find_element(:css, '.more_options_link').click
      driver.find_element(:id, 'discussion_topic_is_announcement').click
      driver.find_element(:css, css_checkbox).click
    end
    add_topic_form
  end

  context "announcements as a student" do

    before (:each) do
      course_with_student_logged_in
    end

    it "should not show JSON when loading more announcements via pageless" do
      50.times { @course.announcements.create!(:title => 'Hi there!', :message => 'Announcement time!') }
      get "/courses/#{@course.id}/announcements"

      start = driver.find_elements(:css, "#topic_list .topic").length
      driver.execute_script('window.scrollTo(0, 100000)')
      keep_trying_until { driver.find_elements(:css, "#topic_list .topic").length > start }

      driver.find_element(:id, "topic_list").should_not include_text('discussion_topic')
    end
  end

  context "announcements as a teacher" do
    before (:each) do
      course_with_teacher_logged_in
    end

    it "should create an announcement" do
      first_text = 'Hi, this is my first announcement'

      get course_announcements_path(@course)
      submit_form(create_announcement_manual(nil))
      wait_for_ajaximations
      announcement = driver.find_element(:css, '#topic_list .topic')
      announcement.find_element(:link, "First Announcement").should be_displayed
      announcement.find_element(:css, '.message').should include_text(first_text)
    end

    it "should edit an announcement" do
      edit_title = 'edited title'
      edit_message = 'edited '

      create_announcement
      get course_announcements_path(@course)
      driver.execute_script("$('.communication_message').addClass('communication_message_hover')")
      driver.find_element(:css, '.edit_topic_link').click
      edit_form = driver.find_element(:css, '.add_topic_form_new')
      edit_form.should be_displayed
      replace_content(edit_form.find_element(:css, '.topic_title'), edit_title)
      wait_for_tiny(keep_trying_until { driver.find_element(:css, '.add_topic_form_new') })
      type_in_tiny('.topic_content', edit_message)
      submit_form(edit_form)
      wait_for_ajaximations
      communication_message = driver.find_element(:css, '.communication_message')
      communication_message.find_element(:css, '.title').text.should == edit_title
      communication_message.find_element(:css, '.user_content').should include_text(edit_message)
    end

    it "should delete an announcement" do
      create_announcement
      get course_announcements_path(@course)
      driver.execute_script("$('.communication_message').addClass('communication_message_hover')")
      driver.find_element(:css, '.delete_topic_link').click
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.accept
      keep_trying_until { driver.find_element(:id, 'no_topics_message').should be_displayed }
    end

    it "should create an announcement for grading" do
      get course_announcements_path(@course)
      add_form = create_announcement_manual('#discussion_topic_assignment_set_assignment')
      replace_content(add_form.find_element(:id, 'discussion_topic_assignment_points_possible'), "25")
      submit_form(add_form)
      wait_for_ajaximations
      driver.find_element(:css, '.for_assignment').should include_text('This topic is an assignment')
    end

    it "should crate an announcement with a podcast feed" do
      get course_announcements_path(@course)
      submit_form(create_announcement_manual('#discussion_topic_podcast_enabled'))
      wait_for_ajaximations
      find_with_jquery('img[title="This topic has a podcast feed."]').should be_displayed
    end

    it "should create a delayed announcement" do
      get course_announcements_path(@course)
      add_form = create_announcement_manual('#discussion_topic_delay_posting')
      driver.find_element(:css, '.ui-datepicker-trigger').click
      datepicker_next
      submit_form(add_form)
      wait_for_ajaximations
      driver.find_element(:css, '.delayed_posting').should include_text('This topic will not be visible')
    end

    it "should have a teacher add a new entry to its own announcement" do
      pending "delayed jobs"
      create_announcement
      get [@course, @announcement]

      driver.find_element(:css, ' #content .add_entry_link').click
      entry_text = 'new entry text'
      type_in_tiny('textarea.entry_content:first', entry_text)
      submit_form('#add_entry_form_entry_new')
      wait_for_ajaximations
      driver.find_element(:css, '#entry_list .discussion_entry .content').should include_text(entry_text)
      driver.find_element(:css, '#left-side .announcements').click
      driver.find_element(:css, '.topic_reply_count').text.should eql('1')
    end

    it "should add an external feed to announcements" do
      get course_announcements_path(@course)

      #add external feed to announcements
      feed_name = 'http://www.google.com'
      driver.find_element(:css, '.add_external_feed_link').click
      feed_form = driver.find_element(:id, 'add_external_feed_form')
      feed_form.find_element(:id, 'external_feed_url').send_keys(feed_name)
      unless feed_form.find_element(:id, 'external_feed_header_match').displayed?
        feed_form.find_element(:id, 'external_feed_add_header_match').click
      end
      feed_form.find_element(:id, 'external_feed_header_match').send_keys('blah')
      submit_form(feed_form)
      wait_for_ajaximations

      #delete external feed
      driver.find_element(:link, feed_name).should be_displayed
      find_with_jquery('#external_feeds li:nth-child(2) .delete_feed_link').click
      confirm_dialog = driver.switch_to.alert
      confirm_dialog.accept
      wait_for_ajaximations
      element_exists(feed_name).should be_false
      ExternalFeed.count.should eql(0)

      #cancel while adding an external feed
      driver.find_element(:css, '.add_external_feed_link').click
      feed_form.find_element(:id, 'external_feed_url').send_keys('http://www.yahoo.com')
      feed_form.find_element(:id, 'external_feed_header_match').send_keys('more blah')
      feed_form.find_element(:css, '#add_external_feed_form .cancel_button').click
      wait_for_animations
      driver.find_element(:id, 'add_external_feed_form').should_not be_displayed
    end

    it "should show announcements to student view student" do
      create_announcement
      enter_student_view
      get "/courses/#{@course.id}/announcements"

      announcement = f('#topic_list .topic')
      announcement.find_element(:css, '.message').should include_text(@announcement.message)
    end
  end
end
