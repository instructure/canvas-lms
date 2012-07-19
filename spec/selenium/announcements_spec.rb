require File.expand_path(File.dirname(__FILE__) + '/common')

describe "announcements" do

  it_should_behave_like "in-process server selenium tests"

  def create_announcement(message = 'announcement message')
    @context = @course
    @announcement = announcement_model(:title => 'new announcement', :message => message)
  end

  def create_announcement_manual(css_checkbox)
    f('.add_topic_link').click
    add_topic_form = f('.add_topic_form_new')
    topic_title = f('.add_topic_form_new input[name="discussion_topic[title]"]')
    replace_content(topic_title, "First Announcement")

    type_in_tiny('textarea.topic_content:first', 'Hi, this is my first announcement')
    if css_checkbox != nil
      f('.more_options_link').click
      f('#discussion_topic_is_announcement').click unless is_checked('#discussion_topic_is_announcement')
      f(css_checkbox).click
    end
    add_topic_form
  end

  it "should validate replies are not visible until after users post" do
    password = 'asdfasdf'
    student_2_entry = 'reply from student 2'
    topic_title = 'new replies hidden until post topic'

    course
    @course.offer
    student = user_with_pseudonym({:unique_id => 'student@example.com', :password => password})
    teacher = user_with_pseudonym({:unique_id => 'teacher@example.com', :password => password})
    @course.enroll_user(student, 'StudentEnrollment').accept!
    @course.enroll_user(teacher, 'TeacherEnrollment').accept!
    login_as(teacher.primary_pseudonym.unique_id, password)

    get "/courses/#{@course.id}/announcements"
    f('.add_topic_link').click
    replace_content(f('#discussion_topic_title'), topic_title)
    type_in_tiny('textarea.topic_content:first', 'hi, first announcement')
    f('.more_options_link').click
    f('#discussion_topic_require_initial_post').click
    submit_form('.add_topic_form_new')
    wait_for_ajaximations
    announcement = Announcement.find_by_title(topic_title)
    announcement[:require_initial_post].should == true
    student_2 = student_in_course.user
    announcement.discussion_entries.create!(:user => student_2, :message => student_2_entry)

    login_as(student.primary_pseudonym.unique_id, password)
    get "/courses/#{@course.id}/announcements/#{announcement.id}"
    f('#discussion_subentries h2').text.should == "Replies are only visible to those who have posted at least one reply."
    ff('.discussion_entry').each { |entry| entry.should_not include_text(student_2_entry) }
    f('.discussion-reply-label').click
    type_in_tiny('.reply-textarea', 'reply')
    submit_form('.discussion-reply-form')
    wait_for_ajaximations
    ff('.discussion_entry .message')[1].should include_text(student_2_entry)
  end

  context "announcements as a student" do
    before (:each) do
      course_with_student_logged_in
    end

    it "should not show JSON when loading more announcements via pageless" do
      50.times { @course.announcements.create!(:title => 'Hi there!', :message => 'Announcement time!') }
      get "/courses/#{@course.id}/announcements"

      start = ff("#topic_list .topic").length
      driver.execute_script('window.scrollTo(0, 100000)')
      keep_trying_until { ffj("#topic_list .topic").length > start }

      f("#topic_list").should_not include_text('discussion_topic')
    end

    it "should validate that a student can not see an announcement with a delayed posting date" do
      announcement_title = 'Hi there!'
      announcement = @course.announcements.create!(:title => announcement_title, :message => 'Announcement time!', :delayed_post_at => Time.now + 1.day)
      get "/courses/#{@course.id}/announcements"

      f('#no_topics_message').should be_displayed
      announcement.update_attributes(:delayed_post_at => nil)
      announcement.reload
      refresh_page # in order to see the announcement
      f('#no_topics_message').should_not be_displayed
      f("#topic_#{Announcement.find_by_title(announcement_title).id}").should include_text(announcement_title)
    end

    it "should allow a group member to create an announcment" do
      gc = @course.group_categories.create!
      group = gc.groups.create!(:context => @course)
      group.add_user(@student, 'accepted')

      get "/groups/#{group.id}/announcements"
      wait_for_ajaximations
      expect {
        announce_form = create_announcement_manual(nil)
        submit_form(announce_form)
        wait_for_ajaximations
      }.to change(Announcement, :count).by 1
    end
  end

  context "announcements as a teacher" do
    before (:each) do
      course_with_teacher_logged_in
    end

    it "should create an announcement" do
      first_text = 'Hi, this is my first announcement'
      title_text = 'First Announcement'
      get course_announcements_path(@course)
      submit_form(create_announcement_manual(nil))
      wait_for_ajaximations
      announcement = f('#topic_list .topic')
      announcement.find_element(:css, "#topic_#{Announcement.last.id} .title").should include_text(title_text)
      announcement.find_element(:css, '.message').should include_text(first_text)
      Announcement.find_by_title(title_text).should be_present
    end

    it "should attach a file" do
      filename, fullpath, data = get_file("testfile5.zip")
      get course_announcements_path(@course)
      f('.add_topic_link').click
      type_in_tiny('textarea.topic_content:first', 'Hi, file is attached!')
      f('.add_attachment_link').click
      f('.attachment_uploaded_data').send_keys(fullpath)
      submit_form('.add_topic_form_new')
      wait_for_ajaximations
      f('#topic_list .topic .attachment_data').should include_text(filename)
    end

    it "should edit an announcement" do
      edit_title = 'edited title'
      edit_message = 'edited '

      create_announcement
      get course_announcements_path(@course)
      driver.execute_script("$('.communication_message').addClass('communication_message_hover')")
      f('.edit_topic_link').click
      edit_form = f('.add_topic_form_new')
      edit_form.should be_displayed
      replace_content(edit_form.find_element(:css, '.topic_title'), edit_title)
      wait_for_tiny(keep_trying_until { f('.add_topic_form_new') })
      type_in_tiny('.topic_content', edit_message)
      submit_form(edit_form)
      wait_for_ajaximations
      communication_message = f('.communication_message')
      communication_message.find_element(:css, '.title').text.should == edit_title
      communication_message.find_element(:css, '.user_content').should include_text(edit_message)
      Announcement.last.title.should == edit_title
    end

    it "should delete an announcement" do
      create_announcement
      get course_announcements_path(@course)
      driver.execute_script("$('.communication_message').addClass('communication_message_hover')")
      f('.delete_topic_link').click
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.accept
      keep_trying_until { f('#no_topics_message').should be_displayed }
      Announcement.find_by_title(@announcement.title).workflow_state.should == 'deleted'
    end

    it "should create a delayed announcement" do
      get course_announcements_path(@course)
      add_form = create_announcement_manual('#discussion_topic_delay_posting')
      f('.ui-datepicker-trigger').click
      datepicker_next
      submit_form(add_form)
      wait_for_ajaximations
      f('.delayed_posting').should include_text('This topic will not be visible')
    end

    it "should have a teacher add a new entry to its own announcement" do
      pending "delayed jobs"
      create_announcement
      get [@course, @announcement]

      f(' #content .add_entry_link').click
      entry_text = 'new entry text'
      type_in_tiny('textarea.entry_content:first', entry_text)
      submit_form('#add_entry_form_entry_new')
      wait_for_ajaximations
      f('#entry_list .discussion_entry .content').should include_text(entry_text)
      f('#left-side .announcements').click
      f('.topic_reply_count').text.should eql('1')
    end

    it "should add an external feed to announcements" do
      get course_announcements_path(@course)

      #add external feed to announcements
      feed_name = 'http://www.google.com'
      f('.add_external_feed_link').click
      feed_form = f('#add_external_feed_form')
      feed_form.find_element(:id, 'external_feed_url').send_keys(feed_name)
      unless feed_form.find_element(:id, 'external_feed_header_match').displayed?
        feed_form.find_element(:id, 'external_feed_add_header_match').click
      end
      feed_form.find_element(:id, 'external_feed_header_match').send_keys('blah')
      submit_form(feed_form)
      wait_for_ajaximations

      #delete external feed
      f("#feed_#{ExternalFeed.last.id} .display_name").text.should == feed_name
      fj('#external_feeds li:nth-child(2) .delete_feed_link').click
      confirm_dialog = driver.switch_to.alert
      confirm_dialog.accept
      wait_for_ajaximations
      element_exists(feed_name).should be_false
      ExternalFeed.count.should eql(0)

      #cancel while adding an external feed
      f('.add_external_feed_link').click
      feed_form.find_element(:id, 'external_feed_url').send_keys('http://www.yahoo.com')
      feed_form.find_element(:id, 'external_feed_header_match').send_keys('more blah')
      feed_form.find_element(:css, '#add_external_feed_form .cancel_button').click
      wait_for_animations
      f('#add_external_feed_form').should_not be_displayed
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
