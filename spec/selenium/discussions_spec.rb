require File.expand_path(File.dirname(__FILE__) + '/helpers/discussion_announcement_specs')

describe "discussions" do
  it_should_behave_like "discussions selenium tests"

  describe "shared topics permissions specs" do
    let(:url) { "/courses/#{@course.id}/discussion_topics/" }
    let(:what_to_create) { DiscussionTopic }
    it_should_behave_like "discussion and announcement permissions tests"
  end

  context "as a teacher" do

    before (:each) do
      course_with_teacher_logged_in
    end

    describe "shared bulk topics specs" do
      let(:url) { "/courses/#{@course.id}/discussion_topics/" }
      let(:what_to_create) { DiscussionTopic }
      it_should_behave_like "discussion and announcement main page tests"
    end

    context "individual topic" do
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

      it "should validate closing the discussion for comments" do
        create_and_go_to_topic
        f("#discussion-toolbar .al-trigger-inner").click
        expect_new_page_load { f("#ui-id-3").click }
        f('.discussion-fyi').text.should == 'This topic is closed for comments'
        ff('.discussion-reply-label').should be_empty
        DiscussionTopic.last.workflow_state.should == 'locked'
      end

      it "should validate reopening the discussion for comments" do
        create_and_go_to_topic('closed discussion', 'side_comment', true)
        f("#discussion-toolbar .al-trigger-inner").click
        expect_new_page_load { f("#ui-id-3").click }
        ff('.discussion-reply-label').should_not be_empty
        DiscussionTopic.last.workflow_state.should == 'active'
      end

      it "should escape correctly when posting an attachment" do
        create_and_go_to_topic
        message = "message that needs escaping ' \" & !@#^&*()$%{}[];: blah"
        add_reply(message, 'graded.png')
        @last_entry.find_element(:css, '.message').text.should == message
      end

      it "should show attachments after showing hidden replies" do
        @topic = @course.discussion_topics.create!(:title => 'test', :message => 'attachment test', :user => @user)
        @entry = @topic.discussion_entries.create!(:user => @user, :message => 'blah')
        @replies = []
        5.times do
          attachment = @course.attachments.create!(:context => @course, :filename => "text.txt", :user => @user, :uploaded_data => StringIO.new("testing"))
          reply = @entry.discussion_subentries.create!(
            :user => @user, :message => 'i haz attachments', :discussion_topic => @topic, :attachment => attachment)
          @replies << reply
        end
        @topic.create_materialized_view
        go_to_topic
        ffj('.comment_attachments').count.should == 3
        fj('.showMore').click
        wait_for_ajaximations
        ffj('.comment_attachments').count.should == @replies.count
      end

      it "should show only 10 root replies per page"
      it "should paginate root entries"
      it "should show only three levels deep"
      it "should show only three children of a parent"
      it "should display unrendered unread and total counts accurately"
      it "should expand descendents"
      it "should expand children"
      it "should deep link to an entry rendered on the first page"
      it "should deep link to an entry rendered on a different page"
      it "should deep link to a non-rendered child entry of a rendered parent"
      it "should deep link to a child entry of a non-rendered parent"
      it "should allow users to 'go to parent'"
      it "should collapse a thread"
      it "should filter entries by user display name search term"
      it "should filter entries by content search term"
      it "should filter entries by unread"
      it "should filter entries by unread and search term"
      it "should link to an entry in context of the discussion when clicked in result view"
    end

    context "main page" do
      describe "shared main page topics specs" do
        let(:url) { "/courses/#{@course.id}/discussion_topics/" }
        let(:what_to_create) { DiscussionTopic }
        it_should_behave_like "discussion and announcement individual tests"
      end

      it "should allow teachers to edit discussions settings" do
        assignment_name = 'topic assignment'
        title = 'assignment topic title'
        @course.allow_student_discussion_topics.should == true
        @course.discussion_topics.create!(:title => title, :user => @user, :assignment => @course.assignments.create!(:name => assignment_name))
        get "/courses/#{@course.id}/discussion_topics"
        f('#edit_discussions_settings').click
        wait_for_ajax_requests
        f('#allow_student_discussion_topics').click
        submit_form('.dialogFormView')
        wait_for_ajax_requests
        @course.reload
        @course.allow_student_discussion_topics.should == false
      end

      it "should filter by assignments" do
        assignment_name = 'topic assignment'
        title = 'assignment topic title'
        @course.discussion_topics.create!(:title => title, :user => @user, :assignment => @course.assignments.create!(:name => assignment_name))
        get "/courses/#{@course.id}/discussion_topics"
        f('#onlyGraded').click
        ff('.discussionTopicIndexList .discussion-topic').count.should == 1
        f('.discussionTopicIndexList .discussion-topic').should include_text(title)
      end

      it "should filter by unread and assignments" do
        assignment_name = 'topic assignment'
        title = 'assignment topic title'
        expected_topic = @course.discussion_topics.create!(:title => title, :user => @user, :assignment => @course.assignments.create!(:name => assignment_name))
        @course.discussion_topics.create!(:title => title, :user => @user)
        expected_topic.change_read_state('unread', @user)
        get "/courses/#{@course.id}/discussion_topics"
        f('#onlyGraded').click
        f('#onlyUnread').click
        ff('.discussionTopicIndexList .discussion-topic').count.should == 1
        f('.discussionTopicIndexList .discussion-topic').should include_text(title)
      end

      it "should validate the discussion reply counter" do
        @topic = create_discussion('new topic', 'side_comment')
        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
        add_reply('new reply')

        get "/courses/#{@course.id}/discussion_topics"
        f('.total-items').text.should == '1'
      end

      it "should create a podcast enabled topic" do
        get "/courses/#{@course.id}/discussion_topics"
        wait_for_ajaximations

        expect_new_page_load { f('.btn-primary').click }
        replace_content(f('input[name=title]'), "This is my test title")
        type_in_tiny('textarea[name=message]', 'This is the discussion description.')

        f('input[type=checkbox][name=podcast_enabled]').click
        expect_new_page_load { submit_form('.form-actions') }
        get "/courses/#{@course.id}/discussion_topics"
        f('.discussion-topic .icon-rss').should be_displayed
        DiscussionTopic.last.podcast_enabled.should be_true
      end
    end

    context "editing" do
      it "should save and display all changes" do
        @topic = @course.discussion_topics.create!(:title => "topic", :user => @user)

        def confirm(state)
          checkbox_state = state == :on ? 'true' : nil
          get "/courses/#{@course.id}/discussion_topics/#{@topic.id}/edit"
          wait_for_ajaximations

          f('input[type=checkbox][name=threaded]')[:checked].should == checkbox_state
          f('input[type=checkbox][name=delay_posting]')[:checked].should == checkbox_state
          f('input[type=checkbox][name=require_initial_post]')[:checked].should == checkbox_state
          f('input[type=checkbox][name=podcast_enabled]')[:checked].should == checkbox_state
          f('input[type=checkbox][name=podcast_has_student_posts]')[:checked].should == checkbox_state
          f('input[type=checkbox][name="assignment[set_assignment]"]')[:checked].should == checkbox_state
        end

        def toggle(state)
          f('input[type=checkbox][name=threaded]').click
          f('input[type=checkbox][name=delay_posting]').click
          set_value f('input[name=delayed_post_at]'), 2.weeks.from_now.strftime('%m/%d/%Y') if state == :on
          f('input[type=checkbox][name=require_initial_post]').click
          f('input[type=checkbox][name=podcast_enabled]').click
          f('input[type=checkbox][name=podcast_has_student_posts]').click if state == :on
          f('input[type=checkbox][name="assignment[set_assignment]"]').click

          f('.form-actions button[type=submit]').click
          wait_for_ajaximations
        end

        confirm(:off)
        toggle(:on)
        confirm(:on)
        toggle(:off)
        confirm(:off)
      end
    end
  end

  context "with blank pages fetched from server" do
    before(:each) do
      course_with_student_logged_in
    end

    it "should display empty version of view if there are no topics" do
      get "/courses/#{@course.id}/discussion_topics"
      wait_for_ajaximations
      f('.btn-large').should be_present
      f('.btn-large').should be_displayed
    end

    it "should display empty version of view if all pages are empty" do
      (1..15).each do |n|
        @course.discussion_topics.create!({
          :title => "general topic #{n}",
          :discussion_type => 'side_comment',
          :delayed_post_at => 5.days.from_now,
        })
      end

      get "/courses/#{@course.id}/discussion_topics"
      wait_for_ajaximations
      f('.btn-large').should be_present
      f('.btn-large').should be_displayed
    end
    
    it "should display topics even if first page is blank but later pages have data" do
      # topics that should be visible
      (1..5).each do |n|
        @course.discussion_topics.create!({
          :title => "general topic #{n}",
          :discussion_type => 'side_comment',
        })
      end
      # a page worth of invisible topics
      (6..15).each do |n|
        @course.discussion_topics.create!({
          :title => "general topic #{n}",
          :discussion_type => 'side_comment',
          :delayed_post_at => 5.days.from_now,
        })
      end

      get "/courses/#{@course.id}/discussion_topics"
      wait_for_ajaximations
      f('.btn-large').should be_nil
    end
  end

  context "as a student" do
    before (:each) do
      course_with_teacher(:name => 'teacher@example.com', :active_all => true)
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :name => 'student@example.com', :password => 'asdfasdf')
      @course.enroll_student(@student).accept
      @topic = @course.discussion_topics.create!(:user => @teacher, :message => 'new topic from teacher', :discussion_type => 'side_comment')
      @entry = @topic.discussion_entries.create!(:user => @teacher, :message => 'new entry from teacher')
      user_session(@student)
    end

    it "should not allow students to create discussions according to setting" do
      @course.allow_student_discussion_topics = false
      @course.save!
      get "/courses/#{@course.id}/discussion_topics/"
      wait_for_ajax_requests
      f('#new-discussion-button').should be_nil
    end

    it "should not show an empty gear menu to students who've created a discussion" do
      @student_topic = @course.discussion_topics.create!(:user => @student, :message => 'student topic', :discussion_type => 'side_comment')
      @student_entry = @student_topic.discussion_entries.create!(:user => @student, :message => 'student entry')
      get "/courses/#{@course.id}/discussion_topics/#{@student_topic.id}"
      wait_for_ajax_requests
      f('.headerBar .admin-links').should be_nil
    end

    it "should allow students to reply to a discussion even if they cannot create a topic" do
      @course.allow_student_discussion_topics = false
      @course.save!
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}/"
      wait_for_ajax_requests
      new_student_entry_text = "'ello there"
      f('#content').should_not include_text(new_student_entry_text)
      add_reply new_student_entry_text
      f('#content').should include_text(new_student_entry_text)
    end

    it "should validate a group assignment discussion" do
      group_assignment = @course.assignments.create!({
                                              :name => 'group assignment',
                                              :due_at => (Time.now + 1.week),
                                              :points_possible => 5,
                                              :submission_types => 'online_text_entry',
                                              :assignment_group => @course.assignment_groups.create!(:name => 'new assignment groups'),
                                              :group_category => GroupCategory.create!(:name => "groups", :context => @course),
                                              :grade_group_students_individually => true
                                          })
      topic = @course.discussion_topics.build(:assignment => group_assignment, :title => "some topic", :message => "a little bit of content")
      topic.save!
      get "/courses/#{@course.id}/discussion_topics/#{topic.id}"
      f('.entry_content').should include_text('Since this is a group assignment')
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

    it "should not show file attachment if allow_student_forum_attachments is not true" do
      # given
      get "/courses/#{@course.id}/discussion_topics/new"
      f('#attachment_uploaded_data').should be_nil
      # when
      @course.allow_student_forum_attachments = true
      @course.save!
      # expect
      get "/courses/#{@course.id}/discussion_topics/new"
      f('#attachment_uploaded_data').should_not be_nil
    end

    context "in a group" do
      before(:each) do
        group_with_user :user => @student, :context => @course
      end

      it "should not show file attachment if allow_student_forum_attachments is not true" do
        # given
        get "/groups/#{@group.id}/discussion_topics/new"
        f('label[for=attachment_uploaded_data]').should be_nil
        # when
        @course.allow_student_forum_attachments = true
        @course.save!
        # expect
        get "/groups/#{@group.id}/discussion_topics/new"
        f('label[for=attachment_uploaded_data]').should be_displayed
      end

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
      f("#entry-#{entry.id}").should include_text('new entry from student')
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
        wait_for_ajaximations

        last_entry = DiscussionEntry.last
        last_entry.depth.should == 2
        last_entry.message.should include_text(side_comment_text)
        keep_trying_until do
          f("#entry-#{last_entry.id}").should include_text(side_comment_text)
        end
      end

      it "should create multiple side comments but only show 3 and expand the rest" do
        side_comment_number = 10
        side_comment_number.times { |i| @topic.discussion_entries.create!(:user => @student, :message => "new side comment #{i} from student", :parent_entry => @entry) }
        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
        wait_for_ajaximations
        DiscussionEntry.last.depth.should == 2
        keep_trying_until do
          ff('.discussion-entries .entry').count.should == 4 # +1 because of the initial entry
        end
        f('.showMore').click
        ff('.discussion-entries .entry').count.should == (side_comment_number + 1) # +1 because of the initial entry
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
        text = "new side comment from student"
        entry = @topic.discussion_entries.create!(:user => @student, :message => "new side comment from student", :parent_entry => @entry)
        @topic.discussion_entries.last.message.should == text
        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
        sleep 5
        validate_entry_text(entry, text)
        edit_entry(entry, edit_text)
      end

      it "should put order by date, descending"
      it "should flatten threaded replies into their root entries"
      it "should show the latest three entries"
      it "should deep link to an entry rendered on the first page"
      it "should deep link to an entry rendered on a different page"
      it "should deep link to a non-rendered child entry of a rendered parent"
      it "should deep link to a child entry of a non-rendered parent"
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
      ff('.can_be_marked_as_read.unread').length.should == reply_count + 1
      f('.new-and-total-badge .new-items').text.should == reply_count.to_s

      #wait for the discussionEntryReadMarker to run, make sure it marks everything as .just_read
      sleep 2
      ff('.can_be_marked_as_read.unread').should be_empty
      ff('.can_be_marked_as_read.just_read').length.should == reply_count + 1
      f('.new-and-total-badge .new-items').text.should == ''

      # refresh page and make sure nothing is unread/just_read and everthing is .read
      get("/courses/#{@course.id}/discussion_topics/#{@topic.id}", false)
      ['unread', 'just_read'].each do |state|
        ff(".can_be_marked_as_read.#{state}").should be_empty
      end
      f('.new-and-total-badge .new-items').text.should == ''
    end
  end
end
