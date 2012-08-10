require File.expand_path(File.dirname(__FILE__) + '/helpers/discussions_common')

describe "discussions" do
  it_should_behave_like "discussions selenium tests"

  context "main page" do
    DISCUSSION_NAME = 'new discussion'

    before (:each) do
      course_with_teacher_logged_in
    end

    it "should start a new discussion topic" do
      get "/courses/#{@course.id}/discussion_topics"

      f('.add_topic_link').click
      edit_discussion(DISCUSSION_NAME, 'new topic')
    end

    it "should edit a discussion" do
      edit_name = 'edited discussion name'
      create_discussion(DISCUSSION_NAME, 'side_comment')
      get "/courses/#{@course.id}/discussion_topics"
      driver.action.move_to(f('.discussion_topic')).perform
      f('.edit_topic_link').click
      edit_discussion(edit_name, 'edit message')
    end

    it "should delete a discussion" do
      create_discussion(DISCUSSION_NAME, 'side_comment')
      get "/courses/#{@course.id}/discussion_topics"

      topic = DiscussionTopic.last
      driver.execute_script("$('#topic_#{topic.id}').addClass('communication_message_hover')")
      f("#topic_#{topic.id} .delete_topic_link").click
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      DiscussionTopic.last.workflow_state.should == 'deleted'
      f('#topic_list').should_not include_text(DISCUSSION_NAME)
      f('#no_topics_message').should be_displayed
    end

    it "should reorder topics" do
      pending("dragging and dropping does not work well with selenium")
      2.times { |i| create_discussion("new discussion #{i}", "side_comment") }
      get "/courses/#{@course.id}/discussion_topics"
      f('.reorder_topics_link').click
      f('#topics_reorder_list').should be_displayed
      topics = ff('#reorder_topics_form .topic')
      driver.action.drag_and_drop(topics[1], topics[0]).perform
      f('.reorder_topics_button').click
      wait_for_ajaximations
      main_topics = ff('#topic_list .discussion_topic')
      main_topics[0].should include_text('new discussion 0')
      main_topics[1].should include_text('new discussion 1')
    end

    it "should validate view topics and announcements and topics only button" do
      announcement_name = 'new announcement'
      create_discussion(DISCUSSION_NAME, 'side_comment')
      @context = @course
      @announcement = announcement_model(:title => announcement_name, :message => 'some announcement message')
      get "/courses/#{@course.id}/discussion_topics"
      f('#topic_list').should_not include_text(announcement_name)
      right_side_buttons = ff('#sidebar_content .button-sidebar-wide')
      expect_new_page_load { right_side_buttons[3].click }
      f('#topic_list').should include_text(announcement_name)
    end
  end

  context "as a teacher" do
    before (:each) do
      course_with_teacher_logged_in
    end

    it "should load both topics and images via pageless without conflict" do
      # create some topics. 11 is enough to trigger pageless with default value
      # of 10 per page
      11.times { |i| @course.discussion_topics.create!(:title => "Topic #{i}") }

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
        f('.add_topic_link').click
        ff('#editor_tabs .ui-tabs-nav li a').last.should be_displayed
      }
      ff('#editor_tabs .ui-tabs-nav li a').last.click

      # scroll window to trigger pageless for #topic_list
      driver.execute_script('window.scrollTo(0, 100000)')

      # wait till done
      wait_for_ajaximations

      # check all topics were loaded (11 we created, plus the blank template)
      ff("#topic_list .topic").length.should == 12

      # check images were loaded
      ff(".image_list .img_holder").length.should == 2
    end

    it "should work with graded assignments and pageless" do
      get "/courses/#{@course.id}/discussion_topics"

      # create some topics. 11 is enough to trigger pageless with default value
      # of 10 per page
      f('.add_topic_link').click
      type_in_tiny('#topic_content_topic_new', 'asdf')
      f('.more_options_link').click
      f('#discussion_topic_assignment_set_assignment').click
      submit_form('#add_topic_form_topic_new')
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
      f('.more_options_link').click
      is_checked('#discussion_topic_assignment_set_assignment').should_not be_nil
    end

    it "should create a podcast enabled topic" do
      get "/courses/#{@course.id}/discussion_topics"

      form = keep_trying_until do
        f(".add_topic_link").click
        f('#add_topic_form_topic_new')
      end

      form.find_element(:id, "discussion_topic_title").send_keys("This is my test title")
      type_in_tiny '#add_topic_form_topic_new .topic_content', 'This is the discussion description.'

      form.find_element(:css, '.more_options_link').click
      form.find_element(:id, 'discussion_topic_podcast_enabled').click

      submit_form(form)
      wait_for_ajaximations

      f('.discussion_topic .podcast img').click
      wait_for_animations
      f('.feed').should be_displayed
    end

    it "should display the current username when adding a reply" do
      create_and_go_to_topic
      get_all_replies.count.should == 0
      add_reply
      get_all_replies.count.should == 1
      @last_entry.find_element(:css, '.author').text.should == @user.name
    end

    it "should allow student view student to read/post" do
      enter_student_view
      create_and_go_to_topic
      get_all_replies.count.should == 0
      add_reply
      get_all_replies.count.should == 1
    end

    it "should validate editing a discussion" do
      edit_text = 'title edited'
      create_and_go_to_topic
      expect_new_page_load { click_topic_option('#discussion_topic', '#ui-menu-0-0') }
      replace_content(f('#discussion_topic_title'), edit_text)
      type_in_tiny(".topic_content", ' new message')
      submit_form('.add_topic_form_new')
      wait_for_ajaximations
      f('.discussion_topic').should include_text(edit_text)
    end

    # note: this isn't desirable, but it's the way it is for this release
    it "should show student view posts to teacher and other students" do
      @fake_student = @course.student_view_student
      @topic = @course.discussion_topics.create!
      @entry = @topic.reply_from(:user => @fake_student, :text => 'i am a figment of your imagination')
      @topic.create_materialized_view

      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      wait_for_ajax_requests
      get_all_replies.first.should include_text @fake_student.name
    end

    it "should validate editing a discussion" do
      edit_text = 'title edited'
      create_and_go_to_topic
      expect_new_page_load { click_topic_option('#discussion_topic', '#ui-menu-0-0') }
      wait_for_ajaximations
      d_title= keep_trying_until {f("#discussion_topic_title")}
      replace_content(d_title, edit_text)
      type_in_tiny("textarea", 'other message')
      submit_form(".add_topic_form_new")
      wait_for_ajaximations
      f(".discussion_topic").should include_text(edit_text)
    end

    it "should validate the deletion of a discussion" do
      create_and_go_to_topic
      click_topic_option('#discussion_topic', %([data-method="delete"]))
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      f('#no_topics_message').should be_displayed
      DiscussionTopic.last.workflow_state.should == 'deleted'
    end

    it "should validate closing the discussion for comments" do
      create_and_go_to_topic
      expect_new_page_load { submit_form('.edit_discussion_topic') }
      f('.discussion-fyi').text.should == 'This topic is closed for comments'
      ff('.discussion-reply-label').should be_empty
      DiscussionTopic.last.workflow_state.should == 'locked'
    end

    it "should validate reopening the discussion for comments" do
      create_and_go_to_topic('closed discussion', 'side_comment', true)
      expect_new_page_load { submit_form('.edit_discussion_topic') }
      ff('.discussion-reply-label').should_not be_empty
      DiscussionTopic.last.workflow_state.should == 'active'
    end

    it "should escape correctly when posting an attachment" do
      create_and_go_to_topic
      message = "message that needs escaping ' \" & !@#^&*()$%{}[];: blah"
      add_reply(message, 'graded.png')
      @last_entry.find_element(:css, '.message').text.should == message
    end
  end

  context "as a student" do
    before (:each) do
      course_with_teacher(:name => 'teacher@example.com')
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :name => 'student@example.com', :password => 'asdfasdf')
      @course.enroll_student(@student).accept
      @topic = @course.discussion_topics.create!(:user => @teacher, :message => 'new topic from teacher', :discussion_type => 'side_comment')
      @entry = @topic.discussion_entries.create!(:user => @teacher, :message => 'new entry from teacher')
      user_session(@student)
    end

    it "should create a discussion and validate that a student can see it and reply to it" do
      new_student_entry_text = 'new student entry'
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      wait_for_ajax_requests
      f('.message_wrapper').should include_text('new topic from teacher')
      f('#content').should_not include_text(new_student_entry_text)
      add_reply new_student_entry_text
      f('#content').should include_text(new_student_entry_text)
    end

    it "should let students post to a post-first discussion" do
      new_student_entry_text = 'new student entry'
      @topic.require_initial_post = true
      @topic.save
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      wait_for_ajax_requests
      # shouldn't see the existing entry until after posting
      f('#content').should_not include_text("new entry from teacher")
      add_reply new_student_entry_text
      # now they should see the existing entry, and their entry
      entries = get_all_replies
      entries.length.should == 2
      entries[0].should include_text("new entry from teacher")
      entries[1].should include_text(new_student_entry_text)
    end

    it "should still show entries without users" do
      @topic.discussion_entries.create!(:user => nil, :message => 'new entry from nobody')
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      wait_for_ajax_requests
      f('#content').should include_text('new entry from nobody')
    end

    it "should reply as a student and validate teacher can see reply" do
      pending "figure out delayed jobs"
      entry = @topic.discussion_entries.create!(:user => @student, :message => 'new entry from student')
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      fj("[data-id=#{entry.id}]").should include_text('new entry from student')
    end

    it "should embed user content in an iframe" do
      message = %{<p><object width="425" height="350" data="http://www.example.com/swf/software/flash/about/flash_animation.swf" type="application/x-shockwave-flash</object></p>"}
      @topic.discussion_entries.create!(:user => nil, :message => message)
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      wait_for_ajax_requests
      f('#content object').should_not be_present
      iframe = f('#content iframe.user_content_iframe')
      iframe.should be_present
      # the sizing isn't exact due to browser differences
      iframe.size.width.should be_between(405, 445)
      iframe.size.height.should be_between(330, 370)
      form = f('form.user_content_post_form')
      form.should be_present
      form['target'].should == iframe['name']
      in_frame(iframe) do
        keep_trying_until do
          src = driver.page_source
          doc = Nokogiri::HTML::DocumentFragment.parse(src)
          obj = doc.at_css('body object')
          obj.name.should == 'object'
          obj['data'].should == "http://www.example.com/swf/software/flash/about/flash_animation.swf"
        end
      end
    end

    it "should strip embed tags inside user content object tags" do
      # this avoids the js translation of user content trying to embed the same content twice
      message = %{<object width="560" height="315"><param name="movie" value="http://www.youtube.com/v/VHRKdpR1E6Q?version=3&amp;hl=en_US"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="http://www.youtube.com/v/VHRKdpR1E6Q?version=3&amp;hl=en_US" type="application/x-shockwave-flash" width="560" height="315" allowscriptaccess="always" allowfullscreen="true"></embed></object>}
      @topic.discussion_entries.create!(:user => nil, :message => message)
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      wait_for_ajax_requests
      f('#content object').should_not be_present
      f('#content embed').should_not be_present
      iframe = f('#content iframe.user_content_iframe')
      iframe.should be_present
      forms = ff('form.user_content_post_form')
      forms.size.should == 1
      form = forms.first
      form['target'].should == iframe['name']
    end

    context "side comments" do

      it "should add a side comment" do
        side_comment_text = 'new side comment'
        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
        wait_for_ajax_requests

        f('.add-side-comment-wrap .discussion-reply-label').click
        type_in_tiny '.reply-textarea', side_comment_text
        submit_form('.add-side-comment-wrap')
        wait_for_ajax_requests
        last_entry = DiscussionEntry.last
        validate_entry_text(last_entry, side_comment_text)
        last_entry.depth.should == 2
      end

      it "should create multiple side comments" do
        side_comment_number = 10
        side_comment_number.times { |i| @topic.discussion_entries.create!(:user => @student, :message => "new side comment #{i} from student", :parent_entry => @entry) }
        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
        wait_for_ajax_requests

        ff('.discussion-entries .entry').count.should == (side_comment_number + 1) # +1 because of the initial entry
        DiscussionEntry.last.depth.should == 2
      end

      it "should delete a side comment" do
        pending("intermittently fails")
        entry = @topic.discussion_entries.create!(:user => @student, :message => "new side comment from student", :parent_entry => @entry)
        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
        wait_for_ajax_requests

        delete_entry(entry)
      end

      it "should edit a side comment" do
        edit_text = 'this has been edited '
        entry = @topic.discussion_entries.create!(:user => @student, :message => "new side comment from student", :parent_entry => @entry)
        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
        wait_for_ajax_requests
        wait_for_js

        edit_entry(entry, edit_text)
      end
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
      ff('.can_be_marked_as_read.unread').length.should eql(reply_count + 1)
      f('.topic_unread_entries_count').text.should eql(reply_count.to_s)

      #wait for the discussionEntryReadMarker to run, make sure it marks everything as .just_read
      sleep 2
      ff('.can_be_marked_as_read.unread').should be_empty
      ff('.can_be_marked_as_read.just_read').length.should eql(reply_count + 1)
      f('.topic_unread_entries_count').text.should eql('')

      # refresh page and make sure nothing is unread/just_read and everthing is .read
      get("/courses/#{@course.id}/discussion_topics/#{@topic.id}", false)
      ['unread', 'just_read'].each do |state|
        ff(".can_be_marked_as_read.#{state}").should be_empty
      end
      f('.topic_unread_entries_count').text.should eql('')
    end
  end
end
