require File.expand_path(File.dirname(__FILE__) + '/helpers/discussions_common')


describe "discussions" do
  it_should_behave_like "in-process server selenium tests"
  describe "topics permissions specs" do
    let(:url) { "/courses/#{@course.id}/discussion_topics/" }
    let(:what_to_create) { DiscussionTopic }

    def check_permissions(number_of_checkboxes = 1)
      get url
      wait_for_ajaximations
      checkboxes = ff('.discussion .al-trigger')
      checkboxes.length.should == number_of_checkboxes
      ff('.discussion-list li.discussion').length.should == what_to_create.count
    end

    before (:each) do
      course
      @course.offer!
      @teacher = user_with_pseudonym({:unique_id => 'firststudent@example.com', :password => 'asdfasdf'})
      @course.enroll_user(@teacher, 'TeacherEnrollment').accept!
      @other_user = user_with_pseudonym({:unique_id => 'otheruser@example.com', :password => 'asdfasdf'})
      @course.enroll_user(@other_user, 'StudentEnrollment').accept!
      3.times { |i| what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => "new topic #{i}", :user => @teacher) : announcement_model(:title => "new topic #{i}", :user => @teacher) }
    end

    it "should allow the student user who created the topic to delete/lock a topic" do
      what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => 'other users', :user => @other_user) : announcement_model(:title => 'other users', :user => @other_user)
      login_as(@other_user.primary_pseudonym.unique_id, 'asdfasdf')
      check_permissions
    end

    it "should not allow a student to pin a topic, even if they are the author" do
      topic = what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => 'other users', :user => @other_user) : announcement_model(:title => 'other users', :user => @other_user)
      login_as(@other_user.primary_pseudonym.unique_id, 'asdfasdf')
      get(url)
      wait_for_ajaximations
      fj("[data-id=#{topic.id}] .al-trigger").click
      ffj('.icon-pin:visible').length.should == 0
    end

    it "should not allow a student to delete/edit topics if they didn't create any" do
      login_as(@other_user.primary_pseudonym.unique_id, 'asdfasdf')
      check_permissions(0)
    end

    it "should not allow a student to delete/edit topics if allow_student_discussion_editing = false" do
      @course.update_attributes(:allow_student_discussion_editing => false)
      what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => 'other users', :user => @other_user) : announcement_model(:title => 'other users', :user => @other_user)
      login_as(@other_user.primary_pseudonym.unique_id, 'asdfasdf')
      check_permissions(0)
    end

    it "should give the teacher delete/lock permissions on all topics" do
      what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => 'other users', :user => @other_user) : announcement_model(:title => 'other users', :user => @other_user)
      login_as(@teacher.primary_pseudonym.unique_id, 'asdfasdf')
      get url
      check_permissions(what_to_create.count)
    end

    it "should bucket topics based on section-specific locks" do
      sec = @course.course_sections.create!(:name => "Section 2")
      topic = @course.discussion_topics.build(:title => "topic closed to section 2", :user => @user)
      topic.assignment = @course.assignments.build
      topic.save!
      topic.assignment.assignment_overrides.create! { |override|
        override.set = sec 
        override.lock_at = 1.day.ago
        override.lock_at_overridden = true
      }

      student = user_with_pseudonym({:unique_id => 'sectionuser@example.com', :password => 'asdfasdf'})
      @course.enroll_user(student, 'StudentEnrollment', :section => sec).accept!
      login_as(student.primary_pseudonym.unique_id, 'asdfasdf')
      get url
      wait_for_ajaximations
      f('#locked-discussions .collectionViewItems .discussion').should_not be_nil 
    end
  end

  context "as a teacher" do

    before (:each) do
      course_with_teacher_logged_in
    end

    describe "shared bulk topics specs" do
      let(:url) { "/courses/#{@course.id}/discussion_topics/" }
      let(:what_to_create) { DiscussionTopic }

      before (:each) do
        @context = @course
        5.times do |i|
          title = "new #{i.to_s.rjust(3, '0')}"
          what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => title, :user => @user) : announcement_model(:title => title, :user => @user)
        end
        get url
        wait_for_ajaximations
        @checkboxes = ff('.discussion .al-trigger')
      end

      def update_attributes_and_validate(attribute, update_value, search_term = update_value, expected_results = 1)
        what_to_create.last.update_attributes(attribute => update_value)
        refresh_page # in order to get the new topic information
        replace_content(f('#searchTerm'), search_term)
        ffj('.discussion-list li.discussion:visible').count.should == expected_results
      end

      def refresh_and_filter(filter_type, filter, expected_text, expected_results = 1)
        refresh_page # in order to get the new topic information
        wait_for_ajaximations
        keep_trying_until { ff('.discussion .al-trigger').count.should == what_to_create.count }
        filter_type == :css ? driver.execute_script("$('#{filter}').click()") : replace_content(f('#searchTerm'), filter)
        ffj('.discussion-list li.discussion:visible').count.should == expected_results
        if expected_results > 1
          ffj('.discussion-list li.discussion:visible').each { |topic| topic.should include_text(expected_text) }
        else
          f('.discussion-list li.discussion').should include_text(expected_text)
        end
      end

      it "should search by title" do
        expected_text = 'hey there'
        update_attributes_and_validate(:title, expected_text)
      end

      it "should search by body" do
        body_text = 'new topic body'
        update_attributes_and_validate(:message, body_text, 'topic')
      end

      it "should search by author" do
        user_name = 'jake@instructure.com'
        title = 'new one'
        new_teacher = teacher_in_course(:course => @course, :active_all => true, :name => user_name)
        what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => title, :user => new_teacher.user) : announcement_model(:title => title, :user => new_teacher.user)
        refresh_and_filter(:string, 'jake', 'new one')
      end

      it "should return multiple items in the search" do
        new_title = 'updated'
        what_to_create.first.update_attributes(:title => "#{new_title} first")
        what_to_create.last.update_attributes(:title => "#{new_title} last")
        refresh_and_filter(:string, new_title, new_title, 2)
      end

      it "should filter by unread" do
        what_to_create.last.change_read_state('unread', @user)
        refresh_and_filter(:css, '#onlyUnread', 'new 004')
      end
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
        wait_for_ajaximations
        get_all_replies.first.should include_text @fake_student.name
      end

      it "should validate closing the discussion for comments" do
        create_and_go_to_topic
        f("#discussion-toolbar .al-trigger").click
        expect_new_page_load { f(".discussion_locked_toggler").click }
        f('.discussion-fyi').text.should == 'This topic is closed for comments'
        ff('.discussion-reply-action').should be_empty
        DiscussionTopic.last.locked?.should be_true
      end

      it "should validate reopening the discussion for comments" do
        create_and_go_to_topic('closed discussion', 'side_comment', true)
        f("#discussion-toolbar .al-trigger").click
        expect_new_page_load { f(".discussion_locked_toggler").click }
        ff('.discussion-reply-action').should_not be_empty
        DiscussionTopic.last.workflow_state.should == 'active'
        DiscussionTopic.last.locked?.should be_false
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
        11.times do
          attachment = @course.attachments.create!(:context => @course, :filename => "text.txt", :user => @user, :uploaded_data => StringIO.new("testing"))
          reply = @entry.discussion_subentries.create!(
              :user => @user, :message => 'i haz attachments', :discussion_topic => @topic, :attachment => attachment)
          @replies << reply
        end
        @topic.create_materialized_view
        go_to_topic
        ffj('.comment_attachments').count.should == 10
        fj('.showMore').click
        wait_for_ajaximations
        ffj('.comment_attachments').count.should == @replies.count
      end

      it "should hide the speedgrader in large courses" do
        Course.any_instance.stubs(:large_roster?).returns(true)
        @topic = @course.discussion_topics.create!(:title => 'discussion', :user => @user, :assignment => @course.assignments.create!(:name => 'assignment'))
        go_to_topic
        f('.al-trigger').click
        f('.al-options').text.should_not match(/Speed Grader/)
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

        def add_attachment_and_validate
          filename, fullpath, data = get_file("testfile5.zip")
          f('input[name=attachment]').send_keys(fullpath)
          type_in_tiny('textarea[name=message]', 'file attachement discussion')
          yield if block_given?
          expect_new_page_load { submit_form('.form-actions') }
          wait_for_ajaximations

          f('.zip').should include_text(filename)
        end

        def edit(title, message)
          replace_content(f('input[name=title]'), title)
          type_in_tiny('textarea[name=message]', message)
          expect_new_page_load { submit_form('.form-actions') }
          f('#discussion_topic .discussion-title').text.should == title
        end

        before (:each) do
          @topic_title = 'new discussion'
          @context = @course
        end

        it "should start a new topic" do
          get url

          expect_new_page_load { f('.btn-primary').click }
          edit(@topic_title, 'new topic')
        end

        it "should add an attachment to a new topic" do
          topic_title = 'new topic with file'
          get url

          expect_new_page_load { f('.btn-primary').click }
          replace_content(f('input[name=title]'), topic_title)
          add_attachment_and_validate
          what_to_create.find_by_title(topic_title).attachment_id.should be_present
        end

        it "should add an attachment to a graded topic" do
          what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => 'graded attachment topic', :user => @user) : announcement_model(:title => 'graded attachment topic', :user => @user)
          if what_to_create == DiscussionTopic
            what_to_create.last.update_attributes(:assignment => @course.assignments.create!(:name => 'graded topic assignment'))
          end
          get url
          expect_new_page_load { f('li.discussion .title').click }
          expect_new_page_load { f(".edit-btn").click }

          add_attachment_and_validate do
            # should correctly save changes to the assignment
            set_value f('#discussion_topic_assignment_points_possible'), '123'
          end
          if what_to_create == DiscussionTopic
            Assignment.last.points_possible.should == 123
          end
        end

        it "should edit a topic" do
          edit_name = 'edited discussion name'
          topic = what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => @topic_title, :user => @user) : announcement_model(:title => @topic_title, :user => @user)
          get url + "#{topic.id}"
          expect_new_page_load { f(".edit-btn").click }

          edit(edit_name, 'edit message')
        end

        it "should delete a topic" do
          what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => @topic_title, :user => @user) : announcement_model(:title => @topic_title, :user => @user)
          get url

          f('.al-trigger').click
          fj('.icon-trash:visible').click
          driver.switch_to.alert.accept
          wait_for_ajaximations
          what_to_create.last.workflow_state.should == 'deleted'
          f('.discussion-list li.discussion').should be_nil
        end

        it "should allow a teacher to pin a topic" do
          topic = @course.discussion_topics.create!(title: 'Test Discussion', user: @user)
          get(url)
          wait_for_ajaximations

          f('.open.discussion-list .al-trigger').click
          fj('.icon-pin:visible').click
          wait_for_ajaximations
          topic.reload.should be_pinned
          ffj('.pinned.discussion-list li.discussion:visible').length.should == 1
        end

        it "should allow a teacher to unpin a topic" do
          topic = @course.discussion_topics.create!(title: 'Test Discussion', user: @user, pinned: true)
          get(url)
          wait_for_ajaximations

          f('.pinned.discussion-list .al-trigger').click
          fj('.icon-pin:visible').click
          wait_for_ajaximations
          topic.reload.should_not be_pinned
          ffj('.open.discussion-list li.discussion:visible').length.should == 1
        end

        it "should allow pinning of all pages of topics" do
          100.times do |n|
            DiscussionTopic.create!(context: @course, user: @teacher,
              title: "Discussion Topic #{n+1}")
          end
          topic = DiscussionTopic.where(context_id: @course.id).order('id DESC').last
          topic.should_not be_pinned
          get(url)
          wait_for_ajaximations
          keep_trying_until { fj(".al-trigger") }
          fj("[data-id=#{topic.id}] .al-trigger").click
          fj('.icon-pin:visible').click
          wait_for_ajaximations
          topic.reload.should be_pinned
        end

        it "should allow locking a pinned topic" do
          topic = @course.discussion_topics.create!(title: 'Test Discussion', user: @user, pinned: true)
          get(url)
          wait_for_ajaximations

          f('.pinned.discussion-list .al-trigger').click
          ffj('.icon-lock:visible').length.should == 1
        end

        it "should allow pinning a locked topic" do
          topic = @course.discussion_topics.create!(title: 'Test Discussion', user: @user)
          topic.lock!
          get(url)
          wait_for_ajaximations

          f('.locked.discussion-list .al-trigger').click
          ffj('.icon-pin:visible').length.should == 1
        end

        it "should show subscription icons" do
          topic = @course.discussion_topics.create!(title: 'Test Discussion', user: @user)
          topic.subscribed?(@user).should be_true
          get(url)
          wait_for_ajaximations
          f('.discussion .icon-discussion-check').should be_displayed
          f('.discussion .icon-discussion').should be_nil

          topic.unsubscribe(@user)
          get(url)
          wait_for_ajaximations
          f('.discussion .icon-discussion-check').should be_nil
          f('.discussion .icon-discussion').should be_displayed
        end

        it "should allow subscribing to a topic" do
          topic = @course.discussion_topics.create!(title: 'Test Discussion', user: @user)
          topic.unsubscribe(@user)
          get(url)
          wait_for_ajaximations
          f('.icon-discussion').should be_displayed
          f('.subscription-toggler').click
          wait_for_ajaximations
          driver.execute_script(%{$('.subscription-toggler').trigger('mouseleave')})
          f('.icon-discussion').should be_nil
          f('.icon-discussion-check').should be_displayed
          topic.reload
          topic.subscribed?(@user).should be_true
        end

        it "should allow unsubscribing from a topic" do
          topic = @course.discussion_topics.create!(title: 'Test Discussion', user: @user)
          topic.subscribe(@user)
          get(url)
          wait_for_ajaximations
          driver.execute_script(%{$('.subscription-toggler').trigger('mouseleave')})
          f('.icon-discussion-check').should be_displayed
          f('.subscription-toggler').click
          wait_for_ajaximations
          driver.execute_script(%{$('.subscription-toggler').trigger('mouseleave')})
          f('.icon-discussion-check').should be_nil
          f('.icon-discussion').should be_displayed
          topic.reload
          topic.subscribed?(@user).should be_false
        end
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
        ffj('.discussion-list li.discussion:visible').count.should == 1
        fj('.discussion-list li.discussion:visible').should include_text(title)
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
        ffj('.discussion-list li.discussion:visible').count.should == 1
        fj('.discussion-list li.discussion:visible').should include_text(title)
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
        # TODO: talk to UI, figure out what to display here
        # f('.discussion-topic .icon-rss').should be_displayed
        DiscussionTopic.last.podcast_enabled.should be_true
      end

      it "should exclude deleted entries from unread and total reply count" do
        course_with_teacher_logged_in
        discussion_topic_model(:user => @teacher)
        @student = student_in_course(:active_all => true).user

        @assignment = assignment_model(:course => @course)
        @topic.assignment = @assignment
        @topic.save

        # Add two replies, delete one
        @topic.reply_from(:user => @student, :text => "entry")
        entry = @topic.reply_from(:user => @student, :text => "another entry")
        entry.destroy

        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
        f('.new-items').text.should == '1'
        f('.total-items').text.should == '1'
      end
    end

    context "editing" do
      it "should save and display all changes" do
        @topic = @course.discussion_topics.create!(:title => "topic", :user => @user)
        @course.require_assignment_group

        def confirm(state)
          checkbox_state = state == :on ? 'true' : nil
          get "/courses/#{@course.id}/discussion_topics/#{@topic.id}/edit"
          wait_for_ajaximations

          f('input[type=checkbox][name=threaded]')[:checked].should == checkbox_state
          f('input[type=checkbox][name=require_initial_post]')[:checked].should == checkbox_state
          f('input[type=checkbox][name=podcast_enabled]')[:checked].should == checkbox_state
          f('input[type=checkbox][name=podcast_has_student_posts]')[:checked].should == checkbox_state
          f('input[type=checkbox][name="assignment[set_assignment]"]')[:checked].should == checkbox_state
        end

        def toggle(state)
          f('input[type=checkbox][name=threaded]').click
          set_value f('input[name=delayed_post_at]'), 2.weeks.from_now.strftime('%m/%d/%Y') if state == :on
          f('input[type=checkbox][name=require_initial_post]').click
          f('input[type=checkbox][name=podcast_enabled]').click
          f('input[type=checkbox][name=podcast_has_student_posts]').click if state == :on
          f('input[type=checkbox][name="assignment[set_assignment]"]').click

          expect_new_page_load { f('.form-actions button[type=submit]').click }
          wait_for_ajaximations
        end

        confirm(:off)
        toggle(:on)
        confirm(:on)
        toggle(:off)
        confirm(:off)
      end

      context "graded" do
        before do
          @topic = @course.discussion_topics.build(:title => "topic", :user => @user)
          @topic.assignment = @course.assignments.build
          @topic.save!
        end

        it "should allow editing the assignment group" do
          assign_group_2 = @course.assignment_groups.create!(:name => "Group 2")

          get "/courses/#{@course.id}/discussion_topics/#{@topic.id}/edit"
          wait_for_ajaximations

          click_option("#assignment_group_id", assign_group_2.name)

          expect_new_page_load { f('.form-actions button[type=submit]').click }
          @topic.reload.assignment.assignment_group_id.should == assign_group_2.id
        end

        it "should allow editing the grading type" do
          get "/courses/#{@course.id}/discussion_topics/#{@topic.id}/edit"
          wait_for_ajaximations

          click_option("#assignment_grading_type", "Letter Grade")

          expect_new_page_load { f('.form-actions button[type=submit]').click }
          @topic.reload.assignment.grading_type.should == "letter_grade"
        end

        it "should allow editing the group category" do
          group_cat = @course.group_categories.create!(:name => "Groupies")
          get "/courses/#{@course.id}/discussion_topics/#{@topic.id}/edit"
          wait_for_ajaximations

          f("#assignment_has_group_category").click
          click_option("#assignment_group_category_id", group_cat.name)

          expect_new_page_load { f('.form-actions button[type=submit]').click }
          @topic.reload.assignment.group_category_id.should == group_cat.id
        end

        it "should allow editing the peer review" do
          get "/courses/#{@course.id}/discussion_topics/#{@topic.id}/edit"
          wait_for_ajaximations

          f("#assignment_peer_reviews").click

          expect_new_page_load { f('.form-actions button[type=submit]').click }
          @topic.reload.assignment.peer_reviews.should == true
        end

        it "should allow editing the due dates" do
          get "/courses/#{@course.id}/discussion_topics/#{@topic.id}/edit"
          wait_for_ajaximations

          due_at = Time.zone.now + 3.days
          unlock_at = Time.zone.now + 2.days
          lock_at = Time.zone.now + 4.days

          # set due_at, lock_at, unlock_at
          f('.due-date-overrides [name="due_at"]').send_keys(due_at.strftime('%b %-d, %y'))
          f('.due-date-overrides [name="unlock_at"]').send_keys(unlock_at.strftime('%b %-d, %y'))
          f('.due-date-overrides [name="lock_at"]').send_keys(lock_at.strftime('%b %-d, %y'))

          expect_new_page_load { f('.form-actions button[type=submit]').click }

          a = DiscussionTopic.last.assignment
          a.due_at.strftime('%b %-d, %y').should == due_at.to_date.strftime('%b %-d, %y')
          a.unlock_at.strftime('%b %-d, %y').should == unlock_at.to_date.strftime('%b %-d, %y')
          a.lock_at.strftime('%b %-d, %y').should == lock_at.to_date.strftime('%b %-d, %y')
        end

        it "should allow creating multiple due dates" do
          sec1 = @course.default_section
          sec2 = @course.course_sections.create!(:name => "Section 2")

          get "/courses/#{@course.id}/discussion_topics/new"
          wait_for_ajaximations

          f('input[type=checkbox][name="assignment[set_assignment]"]').click

          due_at1 = Time.zone.now + 3.days
          due_at2 = Time.zone.now + 4.days

          click_option('.due-date-row:first select', sec1.name)
          fj('.due-date-overrides:first [name="due_at"]').send_keys(due_at1.strftime('%b %-d, %y'))

          f('#add_due_date').click
          wait_for_ajaximations

          click_option('.due-date-row:last select', sec2.name)
          ff('.due-date-overrides [name="due_at"]')[1].send_keys(due_at2.strftime('%b %-d, %y'))

          expect_new_page_load { f('.form-actions button[type=submit]').click }
          topic = DiscussionTopic.last

          overrides = topic.assignment.assignment_overrides
          overrides.count.should == 2
          default_override = overrides.detect { |o| o.set_id == sec1.id }
          default_override.due_at.strftime('%b %-d, %y').should == due_at1.to_date.strftime('%b %-d, %y')
          other_override = overrides.detect { |o| o.set_id == sec2.id }
          other_override.due_at.strftime('%b %-d, %y').should == due_at2.to_date.strftime('%b %-d, %y')
        end

        it "should validate that a group category is selected" do
          get "/courses/#{@course.id}/discussion_topics/new"
          wait_for_ajaximations

          f('input[type=checkbox][name="assignment[set_assignment]"]').click
          f('#assignment_has_group_category').click
          close_visible_dialog
          f('.btn-primary[type=submit]').click
          wait_for_ajaximations

          errorBoxes = driver.execute_script("return $('.errorBox').filter('[id!=error_box_template]').toArray();")
          visBoxes, hidBoxes = errorBoxes.partition { |eb| eb.displayed? }
          visBoxes.first.text.should == "Please select a group set for this assignment"
        end
      end

      context "locking" do
        before do
          @topic = @course.discussion_topics.build(:title => "topic", :user => @user)
          @topic.save!
        end

        it "should set as active when removing existing delayed_post_at and lock_at dates" do
          @topic.delayed_post_at = 10.days.ago
          @topic.lock_at         = 5.days.ago
          @topic.locked          = true
          @topic.save!

          get "/courses/#{@course.id}/discussion_topics/#{@topic.id}/edit"
          wait_for_ajaximations

          f('input[type=text][name="delayed_post_at"]').clear
          f('input[type=text][name="lock_at"]').clear

          expect_new_page_load { f('.form-actions button[type=submit]').click }
          wait_for_ajaximations

          @topic.reload
          @topic.delayed_post_at.should be_nil
          @topic.lock_at.should be_nil
          @topic.active?.should be_true
          @topic.locked?.should be_false
        end

        it "should clear lock_at when manually triggering unlock" do
          @topic.delayed_post_at = 10.days.ago
          @topic.lock_at         = 5.days.ago
          @topic.locked          = true
          @topic.save!

          get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
          wait_for_ajaximations

          f("#discussion-toolbar .al-trigger").click
          expect_new_page_load { f(".discussion_locked_toggler").click }

          @topic.reload
          @topic.lock_at.should be_nil
          @topic.active?.should be_true
          @topic.locked?.should be_false
        end

        it "should be locked when delayed_post_at and lock_at are in past" do
          @topic.delayed_post_at = nil
          @topic.lock_at         = nil
          @topic.workflow_state  = 'active'
          @topic.save!

          get "/courses/#{@course.id}/discussion_topics/#{@topic.id}/edit"
          wait_for_ajaximations

          delayed_post_at = Time.zone.now - 10.days
          lock_at = Time.zone.now - 5.days
          date_format = '%b %-d, %Y'

          f('input[type=text][name="delayed_post_at"]').send_keys(delayed_post_at.strftime(date_format))
          f('input[type=text][name="lock_at"]').send_keys(lock_at.strftime(date_format))

          expect_new_page_load { f('.form-actions button[type=submit]').click }
          wait_for_ajaximations

          @topic.reload
          @topic.delayed_post_at.strftime(date_format).should == delayed_post_at.strftime(date_format)
          @topic.lock_at.strftime(date_format).should == lock_at.strftime(date_format)
          @topic.locked?.should be_true
        end

        it "should set workflow to post_delayed when delayed_post_at and lock_at are in the future" do
          @topic.delayed_post_at = nil
          @topic.lock_at         = nil
          @topic.workflow_state  = 'active'
          @topic.save!

          get "/courses/#{@course.id}/discussion_topics/#{@topic.id}/edit"
          wait_for_ajaximations

          delayed_post_at = Time.zone.now + 5.days
          date_format = '%b %-d, %Y'

          f('input[type=text][name="delayed_post_at"]').send_keys(delayed_post_at.strftime(date_format))

          expect_new_page_load { f('.form-actions button[type=submit]').click }
          wait_for_ajaximations

          @topic.reload
          @topic.delayed_post_at.strftime(date_format).should == delayed_post_at.strftime(date_format)
          @topic.post_delayed?.should be_true
        end

        it "should set workflow to active when delayed_post_at in past and lock_at in future" do
          @topic.delayed_post_at = 5.days.from_now
          @topic.lock_at         = 10.days.from_now
          @topic.workflow_state  = 'active'
          @topic.locked          = nil
          @topic.save!

          get "/courses/#{@course.id}/discussion_topics/#{@topic.id}/edit"
          wait_for_ajaximations

          delayed_post_at = Time.zone.now - 5.days
          date_format = '%b %-d, %Y'

          f('input[type=text][name="delayed_post_at"]').clear
          f('input[type=text][name="delayed_post_at"]').send_keys(delayed_post_at.strftime(date_format))

          expect_new_page_load { f('.form-actions button[type=submit]').click }
          wait_for_ajaximations

          @topic.reload
          @topic.delayed_post_at.strftime(date_format).should == delayed_post_at.strftime(date_format)
          @topic.active?.should be_true
          @topic.locked?.should be_false
        end
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
      ff('.no-content').each { |div| div.should be_displayed }
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
      ff('.no-content').each { |div| div.should be_displayed }
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

    it "should not allow subscribing to a topic that requires an initial post" do
      @topic.unsubscribe(@student)
      @topic.require_initial_post = true
      @topic.save!
      get "/courses/#{@course.id}/discussion_topics"
      wait_for_ajaximations
      f('.icon-discussion').should be_displayed
      f('.subscription-toggler').click
      wait_for_ajaximations
      driver.execute_script(%{$('.subscription-toggler').trigger('mouseleave')})
      f('.icon-discussion-check').should be_nil
      f('.icon-discussion').should be_displayed
      @topic.reload
      @topic.subscribed?(@student).should be_false
    end

    it "should display the subscribe button after an initial post" do
      @topic.unsubscribe(@student)
      @topic.require_initial_post = true
      @topic.save!

      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}/"
      wait_for_ajaximations
      f('.topic-unsubscribe-button').should_not be_displayed
      f('.topic-subscribe-button').should_not be_displayed

      f('.discussion-reply-action').click
      wait_for_ajaximations
      type_in_tiny 'textarea', 'initial post text'
      submit_form('.discussion-reply-form')
      wait_for_ajaximations
      f('.topic-unsubscribe-button').should be_displayed
    end

    it "should allow subscribing after an initial post" do
      @topic.unsubscribe(@student)
      @topic.require_initial_post = true
      @topic.save!
      @topic.reply_from(:user => @student, :text => 'initial post')
      @topic.unsubscribe(@student)
      get "/courses/#{@course.id}/discussion_topics"
      wait_for_ajaximations
      driver.execute_script(%{$('.subscription-toggler').trigger('mouseleave')})
      f('.icon-discussion').should be_displayed
      f('.subscription-toggler').click
      wait_for_ajaximations
      driver.execute_script(%{$('.subscription-toggler').trigger('mouseleave')})
      f('.icon-discussion-check').should be_displayed
      @topic.reload.subscribed?(@student).should be_true
    end

    it "should display subscription action icons on hover" do
      @topic.subscribe(@student)
      get "/courses/#{@course.id}/discussion_topics"
      wait_for_ajaximations
      driver.execute_script(%{$('.subscription-toggler').trigger('mouseleave')})
      f('.icon-discussion-check').should be_displayed
      driver.execute_script(%{$('.subscription-toggler').trigger('mouseenter')})
      f('.icon-discussion-check').should be_nil
      f('.icon-discussion-x').should be_displayed
      f('.subscription-toggler').click
      wait_for_ajaximations
      f('.icon-discussion-x').should be_nil
      f('.icon-discussion').should be_displayed
      driver.execute_script(%{$('.subscription-toggler').trigger('mouseleave')})
      f('.icon-discussion').should be_displayed
      @topic.reload
      @topic.require_initial_post = true
      @topic.save!
      get "/courses/#{@course.id}/discussion_topics"
      wait_for_ajaximations
      driver.execute_script(%{$('.subscription-toggler').trigger('mouseenter')})
      f('.icon-discussion').should be_nil
      f('.icon-discussion-x').should be_displayed
    end

    it "should not allow students to create discussions according to setting" do
      @course.allow_student_discussion_topics = false
      @course.save!
      get "/courses/#{@course.id}/discussion_topics/"
      wait_for_ajax_requests
      f('#new-discussion-btn').should be_nil
    end

    it "should not show admin options in gear menu to students who've created a discussion" do
      @student_topic = @course.discussion_topics.create!(:user => @student, :message => 'student topic', :discussion_type => 'side_comment')
      @student_entry = @student_topic.discussion_entries.create!(:user => @student, :message => 'student entry')
      get "/courses/#{@course.id}/discussion_topics/#{@student_topic.id}"
      wait_for_ajax_requests
      f('.headerBar .admin-links').should_not be_nil
      f('.mark_all_as_read').should_not be_nil
      #f('.mark_all_as_unread').should_not be_nil
      f('.delete_discussion').should be_nil
      f('.discussion_locked_toggler').should be_nil
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

    it "should allow a student to create a discussion" do
      get "/courses/#{@course.id}/discussion_topics/"
      wait_for_ajax_requests
      expect_new_page_load { f('#new-discussion-btn').click }
      wait_for_ajax_requests

      edit_topic("from a student", "tell me a story")
    end

    it "should validate that a student can see it and reply to a discussion" do
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

        f('.discussion-entries .discussion-reply-action').click
        wait_for_ajaximations
        type_in_tiny 'textarea', side_comment_text
        submit_form('.discussion-entries .discussion-reply-form')
        wait_for_ajaximations

        last_entry = DiscussionEntry.last
        last_entry.depth.should == 2
        last_entry.message.should include_text(side_comment_text)
        keep_trying_until do
          f("#entry-#{last_entry.id}").should include_text(side_comment_text)
        end
      end

      it "should create multiple side comments but only show 10 and expand the rest" do
        side_comment_number = 11
        side_comment_number.times { |i| @topic.discussion_entries.create!(:user => @student, :message => "new side comment #{i} from student", :parent_entry => @entry) }
        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
        wait_for_ajaximations
        DiscussionEntry.last.depth.should == 2
        keep_trying_until do
          ff('.discussion-entries .entry').count.should == 11 # +1 because of the initial entry
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
        keep_trying_until do
          validate_entry_text(entry, text)
        end
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
    before do
      course_with_student
      course_with_teacher_logged_in(:course => @course)
      @topic = @course.discussion_topics.create!(:title => 'mark as read test', :message => 'test mark as read', :user => @student)
    end

    it "should automatically mark things as read" do
      resize_screen_to_default

      reply_count = 2
      reply_count.times { @topic.discussion_entries.create!(:message => 'Lorem ipsum dolor sit amet', :user => @student) }
      @topic.create_materialized_view

      # make sure everything looks unread
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      ff('.discussion_entry.unread').length.should == reply_count
      f('.new-and-total-badge .new-items').text.should == reply_count.to_s

      #wait for the discussionEntryReadMarker to run, make sure it marks everything as .just_read
      driver.execute_script("$('.entry_content').last().get(0).scrollIntoView()")
      keep_trying_until { ff('.discussion_entry.unread').should be_empty }
      ff('.discussion_entry.read').length.should == reply_count + 1 # +1 because the topic also has the .discussion_entry class

      # refresh page and make sure nothing is unread and everthing is .read
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      ff(".discussion_entry.unread").should be_empty
      f('.new-and-total-badge .new-items').text.should == ''

      # Mark one as unread manually, and create a new reply. The new reply 
      # should be automarked as read, but the manual one should not.
      f('.discussion-read-state-btn').click
      wait_for_ajaximations
      @topic.discussion_entries.create!(:message => 'new lorem ipsum', :user => @student)
      @topic.create_materialized_view

      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      ff(".discussion_entry.unread").size.should == 2
      f('.new-and-total-badge .new-items').text.should == '2'

      driver.execute_script("$('.entry_content').last().get(0).scrollIntoView()")
      keep_trying_until { ff('.discussion_entry.unread').size < 2 }
      wait_for_ajaximations
      ff(".discussion_entry.unread").size.should == 1
    end

    it "should mark all as read" do
      reply_count = 8
      (reply_count / 2).times do |n|
        entry = @topic.reply_from(:user => @student, :text => "entry #{n}")
        entry.reply_from(:user => @student, :text => "sub reply #{n}")
      end
      @topic.create_materialized_view

      # so auto mark as read won't mess up this test
      @teacher.preferences[:manual_mark_as_read] = true
      @teacher.save!

      go_to_topic

      ff('.discussion-entries .unread').length.should == reply_count
      ff('.discussion-entries .read').length.should == 0

      f("#discussion-toolbar .al-trigger").click
      f('.mark_all_as_read').click
      wait_for_ajaximations
      ff('.discussion-entries .unread').length.should == 0
      ff('.discussion-entries .read').length.should == reply_count
    end
  end

  context "topic subscription" do
    before do
      course_with_student
      course_with_teacher_logged_in(:course => @course)
      @topic = @course.discussion_topics.create!(:title => 'mark as read test', :message => 'test mark as read', :user => @student)
    end

    it "should load with the correct status represented" do
      @topic.subscribe(@teacher)
      @topic.create_materialized_view

      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      wait_for_ajaximations
      f('.topic-unsubscribe-button').should be_displayed
      f('.topic-subscribe-button').should_not be_displayed

      @topic.unsubscribe(@teacher)
      @topic.update_materialized_view
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      wait_for_ajaximations
      f('.topic-unsubscribe-button').should_not be_displayed
      f('.topic-subscribe-button').should be_displayed
    end

    it "should unsubscribe from topic" do
      @topic.subscribe(@teacher)
      @topic.create_materialized_view

      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      wait_for_ajaximations
      f('.topic-unsubscribe-button').click
      wait_for_ajaximations
      @topic.reload
      @topic.subscribed?(@teacher).should == false
    end

    it "should subscribe to topic" do
      @topic.unsubscribe(@teacher)
      @topic.create_materialized_view

      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      wait_for_ajaximations
      f('.topic-subscribe-button').click
      wait_for_ajaximations
      @topic.reload
      @topic.subscribed?(@teacher).should == true
    end

    it "should prevent subscribing when a student post is required first" do
      course_with_student_logged_in(:course => @course)
      new_student_entry_text = 'new student entry'
      @topic.require_initial_post = true
      @topic.save
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      wait_for_ajax_requests
      # shouldn't see subscribe button until after posting
      f('.topic-subscribe-button').should_not be_displayed
      add_reply new_student_entry_text
      # now the subscribe button should be available.
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      wait_for_ajax_requests
      # already subscribed because they posted
      f('.topic-unsubscribe-button').should be_displayed
    end

    it "should updated subscribed button when user posts to a topic" do
      course_with_student_logged_in(:course => @course)
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      wait_for_ajax_requests
      f('.topic-subscribe-button').should be_displayed
      add_reply "student posting"
      f('.topic-unsubscribe-button').should be_displayed
    end
  end

end
