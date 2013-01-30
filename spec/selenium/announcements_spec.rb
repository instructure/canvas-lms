require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/discussion_announcement_specs')

describe "announcements" do
  it_should_behave_like "in-process server selenium tests"

  def create_announcement(message = 'announcement message')
    @context = @course
    @announcement = announcement_model(:title => 'new announcement', :message => message)
  end

  def create_announcement_manual(css_checkbox)
    expect_new_page_load { f('.btn-primary').click }
    replace_content(f('input[name=title]'), "First Announcement")

    type_in_tiny('textarea[name=message]', 'Hi, this is my first announcement')
    if css_checkbox != nil
      f(css_checkbox).click
    end
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
    expect_new_page_load { f('.btn-primary').click }
    replace_content(f('input[name=title]'), topic_title)
    type_in_tiny('textarea[name=message]', 'hi, first announcement')
    f('#require_initial_post').click
    wait_for_ajaximations
    expect_new_page_load { submit_form('.form-actions') }
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

      start = ff(".discussionTopicIndexList .discussion-topic").length
      driver.execute_script('window.scrollTo(0, 100000)')
      keep_trying_until { ffj(".discussionTopicIndexList .discussion-topic").length > start }

      f(".discussionTopicIndexList").should_not include_text('discussion_topic')
    end

    it "should validate that a student can not see an announcement with a delayed posting date" do
      announcement_title = 'Hi there!'
      announcement = @course.announcements.create!(:title => announcement_title, :message => 'Announcement time!', :delayed_post_at => Time.now + 1.day)
      get "/courses/#{@course.id}/announcements"
      wait_for_ajaximations

      f('#content').should include_text('There are no announcements to show')
      announcement.update_attributes(:delayed_post_at => nil)
      announcement.reload
      refresh_page # in order to see the announcement
      f(".discussion-topic").should include_text(announcement_title)
    end

    it "should allow a group member to create an announcement" do
      gc = @course.group_categories.create!
      group = gc.groups.create!(:context => @course)
      group.add_user(@student, 'accepted')

      get "/groups/#{group.id}/announcements"
      wait_for_ajaximations
      expect {
        create_announcement_manual(nil)
        expect_new_page_load { submit_form('.form-actions') }
      }.to change(Announcement, :count).by 1
    end
  end

  context "announcements as a teacher" do
    before (:each) do
      course_with_teacher_logged_in
    end

    describe "shared bulk topics specs" do
      let(:url) { "/courses/#{@course.id}/announcements/" }
      let(:what_to_create) { Announcement }
      it_should_behave_like "discussion and announcement main page tests"
    end

    describe "shared main page topics specs" do
      let(:url) { "/courses/#{@course.id}/announcements/" }
      let(:what_to_create) { Announcement }
      it_should_behave_like "discussion and announcement individual tests"
    end

    it "should create a delayed announcement" do
      get course_announcements_path(@course)
      create_announcement_manual('input[type=checkbox][name=delay_posting]')
      f('.ui-datepicker-trigger').click
      datepicker_next
      expect_new_page_load { submit_form('.form-actions') }
      f('.discussion-fyi').should include_text('This topic will not be visible')
    end

    it "should have a teacher add a new entry to its own announcement" do
      pending "delayed jobs"
      create_announcement
      get [@course, @announcement]

      f('#content .add_entry_link').click
      entry_text = 'new entry text'
      type_in_tiny('textarea[name=message]', entry_text)
      expect_new_page_load { submit_form('.form-actions') }
      f('#entry_list .discussion_entry .content').should include_text(entry_text)
      f('#left-side .announcements').click
      f('.topic_reply_count').text.should == '1'
    end

    it "should add and remove an external feed to announcements" do
      get "/courses/#{@course.id}/announcements"

      #add external feed to announcements
      feed_name = 'http://www.google.com'

      keep_trying_until do
      driver.execute_script("$('#add_external_feed_form').css('display', 'block')")
        f("#external_feed_url").should be_displayed
      end

      fj('#external_feed_url').send_keys(feed_name)
      fj('input[aria-controls=header_match_container]').click
      fj('input[name=header_match]').send_keys('blah')
      #using fj to avoid selenium caching
      expect {
        submit_form(f('#add_external_feed_form'))
        wait_for_ajaximations
      }.to change(ExternalFeed, :count).by(1)

      #delete external feed
      f(".external_feed").should include_text('feed')
      expect {
        fj('.external_feed .close').click
        wait_for_ajax_requests
        element_exists('.external_feed').should be_false
      }.to change(ExternalFeed, :count).by(-1)
      ExternalFeed.count.should == 0
    end

    it "should show announcements to student view student" do
      create_announcement
      enter_student_view
      get "/courses/#{@course.id}/announcements"

      announcement = f('.discussionTopicIndexList .discussion-topic')
      announcement.find_element(:css, '.discussion-summary').should include_text(@announcement.message)
    end
  end
end
