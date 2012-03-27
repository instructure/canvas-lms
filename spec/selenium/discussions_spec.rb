require File.expand_path(File.dirname(__FILE__) + '/common')

describe "discussions" do
  it_should_behave_like "in-process server selenium tests"

  def create_and_go_to_topic
    topic = @course.discussion_topics.create!
    get "/courses/#{@course.id}/discussion_topics/#{topic.id}"
    wait_for_ajax_requests
  end

  def add_reply(message = 'message!')
    @last_entry ||= f('#discussion_topic')
    @last_entry.find_element(:css, '.discussion-reply-label').click
    type_in_tiny 'textarea', message
    f('.discussion-reply-form').submit
    wait_for_ajax_requests
    id = DiscussionEntry.last.id
    @last_entry = fj ".entry[data-id=#{id}]"
  end

  def get_all_replies
    ff('#discussion_subentries .discussion_entry')
  end

  context "discussions as a teacher" do
    before (:each) do
      course_with_teacher_logged_in
    end

    it "should load both topics and images via pageless without conflict" do
      # create some topics. 11 is enough to trigger pageless with default value
      # of 10 per page
      11.times do |i|
        @course.discussion_topics.create!(:title => "Topic #{i}")
      end

      # create some images
      2.times do |i|
        @attachment = @course.attachments.build
        @attachment.filename = "image#{i}.png"
        @attachment.file_state = 'available'
        @attachment.content_type = 'image/png'
        @attachment.save!
      end

      get "/courses/#{@course.id}/discussion_topics"

      # go to Images tab to trigger pageless for .image_list
      keep_trying_until {
        driver.find_element(:css, '.add_topic_link').click
        driver.find_elements(:css, '#editor_tabs .ui-tabs-nav li a').last.should be_displayed
      }
      driver.find_elements(:css, '#editor_tabs .ui-tabs-nav li a').last.click

      # scroll window to trigger pageless for #topic_list
      driver.execute_script('window.scrollTo(0, 100000)')

      # wait till done
      wait_for_ajaximations

      # check all topics were loaded (11 we created, plus the blank template)
      driver.find_elements(:css, "#topic_list .topic").length.should == 12

      # check images were loaded
      driver.find_elements(:css, ".image_list .img_holder").length.should == 2
    end

    it "should work with graded assignments and pageless" do
      get "/courses/#{@course.id}/discussion_topics"

      # create some topics. 11 is enough to trigger pageless with default value
      # of 10 per page
      driver.find_element(:css, '.add_topic_link').click
      type_in_tiny('#topic_content_topic_new', 'asdf')
      driver.find_element(:css, '.more_options_link').click
      driver.find_element(:id, 'discussion_topic_assignment_set_assignment').click
      driver.find_element(:css, '#add_topic_form_topic_new .submit_button').click

      wait_for_ajax_requests

      10.times do |i|
        @course.discussion_topics.create!(:title => "Topic #{i}")
      end

      get "/courses/#{@course.id}/discussion_topics"

      # scroll window to trigger pageless for #topic_list
      driver.execute_script('window.scrollTo(0, 100000)')
      wait_for_ajaximations
      driver.execute_script "$('.discussion_topic:visible:last').mouseover()"
      find_with_jquery('.edit_topic_link:visible:last').click
      driver.find_element(:css, '.more_options_link').click
      driver.find_element(:id, 'discussion_topic_assignment_set_assignment')['checked'].should_not be_nil
    end

    it "should not record a javascript error when creating the first topic" do
      get "/courses/#{@course.id}/discussion_topics"

      form = keep_trying_until {
        driver.find_element(:css, ".add_topic_link").click
        driver.find_element(:id, 'add_topic_form_topic_new')
      }
      driver.execute_script("return INST.errorCount;").should == 0

      form.find_element(:id, "discussion_topic_title").send_keys("This is my test title")
      type_in_tiny '#add_topic_form_topic_new .topic_content', 'This is the discussion description.'

      form.submit
      wait_for_ajax_requests
      keep_trying_until { DiscussionTopic.count.should == 1 }

      find_all_with_jquery(".add_topic_form_new:visible").length.should == 0
      driver.execute_script("return INST.errorCount;").should == 0
    end

    it "should create a podcast enabled topic" do
      get "/courses/#{@course.id}/discussion_topics"

      form = keep_trying_until {
        driver.find_element(:css, ".add_topic_link").click
        driver.find_element(:id, 'add_topic_form_topic_new')
      }

      form.find_element(:id, "discussion_topic_title").send_keys("This is my test title")
      type_in_tiny '#add_topic_form_topic_new .topic_content', 'This is the discussion description.'

      form.find_element(:css, '.more_options_link').click
      form.find_element(:id, 'discussion_topic_podcast_enabled').click

      form.submit
      wait_for_ajaximations

      driver.find_element(:css, '.discussion_topic .podcast img').click
      wait_for_animations
      driver.find_element(:css, '.feed').should be_displayed
    end

    it "should display the current username when adding a reply" do
      create_and_go_to_topic
      get_all_replies.count.should == 0
      add_reply
      get_all_replies.count.should == 1
      @last_entry.find_element(:css, '.author').text.should == @user.name
    end
  end

  context "discussions as a student" do
    before (:each) do
      course_with_teacher(:name => 'teacher@example.com')
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :name=> 'student@example.com', :password => 'asdfasdf')
      @course.enroll_student(@student).accept
      @topic = @course.discussion_topics.create!(:user => @teacher, :message => 'new topic from teacher')
      @topic.discussion_entries.create!(:user => @teacher, :message => 'new entry from teacher')
    end

    it "should create a discussion and validate that a student can see it and reply to it" do
      new_student_entry_text = 'new student entry'
      user_session(@student)
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      f('.message_wrapper').should include_text('new topic from teacher')
      f('#content').should_not include_text(new_student_entry_text)
      add_reply new_student_entry_text
      f('#content').should include_text(new_student_entry_text)
    end

    it "should reply as a student and validate teacher can see reply" do
      pending "figure out delayed jobs"
      user_session(@teacher)
      entry = @topic.discussion_entries.create!(:user => @student, :message => 'new entry from student')
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      fj("[data-id=#{entry.id}]").should include_text('new entry from student')
    end
  end

  context "marking as read" do
    it "should mark things as read" do
      pending "figure out delayed jobs"
      reply_count = 3
      course_with_teacher_logged_in
      @topic = @course.discussion_topics.create!
      reply_count.times { @topic.discussion_entries.create!(:message => 'Lorem ipsum dolor sit amet') }

      # make sure everything looks unread
      get("/courses/#{@course.id}/discussion_topics/#{@topic.id}", false)
      driver.find_elements(:css, '.can_be_marked_as_read.unread').length.should eql(reply_count + 1)
      driver.find_element(:css, '.topic_unread_entries_count').text.should eql(reply_count.to_s)

      #wait for the discussionEntryReadMarker to run, make sure it marks everything as .just_read
      sleep 2
      driver.find_elements(:css, '.can_be_marked_as_read.unread').should be_empty
      driver.find_elements(:css, '.can_be_marked_as_read.just_read').length.should eql(reply_count + 1)
      driver.find_element(:css, '.topic_unread_entries_count').text.should eql('')

      # refresh page and make sure nothing is unread/just_read and everthing is .read
      get("/courses/#{@course.id}/discussion_topics/#{@topic.id}", false)
      ['unread', 'just_read'].each do |state|
        driver.find_elements(:css, ".can_be_marked_as_read.#{state}").should be_empty
      end
      driver.find_element(:css, '.topic_unread_entries_count').text.should eql('')
    end
  end
end
