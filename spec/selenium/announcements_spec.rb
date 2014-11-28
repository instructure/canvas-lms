require File.expand_path(File.dirname(__FILE__) + '/common')

describe "announcements" do
  include_examples "in-process server selenium tests"

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
    expect(announcement[:require_initial_post]).to eq true
    student_2 = student_in_course.user
    announcement.discussion_entries.create!(:user => student_2, :message => student_2_entry)

    login_as(student.primary_pseudonym.unique_id, password)
    get "/courses/#{@course.id}/announcements/#{announcement.id}"
    expect(f('#discussion_subentries span').text).to eq "Replies are only visible to those who have posted at least one reply."
    ff('.discussion_entry').each { |entry| expect(entry).not_to include_text(student_2_entry) }
    f('.discussion-reply-action').click
    wait_for_ajaximations
    type_in_tiny('textarea', 'reply')
    submit_form('#discussion_topic .discussion-reply-form')
    wait_for_ajaximations
    expect(ff('.discussion_entry .message')[1]).to include_text(student_2_entry)
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

      expect(f(".discussionTopicIndexList")).not_to include_text('discussion_topic')
    end

    it "should validate that a student can not see an announcement with a delayed posting date" do
      announcement_title = 'Hi there!'
      announcement = @course.announcements.create!(:title => announcement_title, :message => 'Announcement time!', :delayed_post_at => Time.now + 1.day)
      get "/courses/#{@course.id}/announcements"
      wait_for_ajaximations

      expect(f('#content')).to include_text('There are no announcements to show')
      announcement.update_attributes(:delayed_post_at => nil)
      announcement.reload
      refresh_page # in order to see the announcement
      expect(f(".discussion-topic")).to include_text(announcement_title)
    end

    it "should allow a group member to create an announcement" do
      gc = group_category
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

      before (:each) do
        @context = @course
        5.times do |i|
          title = "new #{i.to_s.rjust(3, '0')}"
          what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => title, :user => @user) : announcement_model(:title => title, :user => @user)
        end
        get url
        wait_for_ajaximations
        @checkboxes = ff('.toggleSelected')
      end

      def update_attributes_and_validate(attribute, update_value, search_term = update_value, expected_results = 1)
        what_to_create.last.update_attributes(attribute => update_value)
        refresh_page # in order to get the new topic information
        replace_content(f('#searchTerm'), search_term)
        expect(ff('.discussionTopicIndexList .discussion-topic').count).to eq expected_results
      end

      def refresh_and_filter(filter_type, filter, expected_text, expected_results = 1)
        refresh_page # in order to get the new topic information
        wait_for_ajaximations
        keep_trying_until { expect(ff('.toggleSelected').count).to eq what_to_create.count }
        filter_type == :css ? driver.execute_script("$('#{filter}').click()") : replace_content(f('#searchTerm'), filter)
        expect(ff('.discussionTopicIndexList .discussion-topic').count).to eq expected_results
        expected_results > 1 ? ff('.discussionTopicIndexList .discussion-topic').each { |topic| expect(topic).to include_text(expected_text) } : (expect(f('.discussionTopicIndexList .discussion-topic')).to include_text(expected_text))
      end

      it "should bulk delete topics" do
        5.times { |i| @checkboxes[i].click }
        f('#delete').click
        driver.switch_to.alert.accept
        wait_for_ajax_requests
        expect(ff('.discussion-topic').count).to eq 0
        expect(what_to_create.where(:workflow_state => 'active').count).to eq 0
      end

      it "should bulk lock topics" do
        5.times { |i| @checkboxes[i].click }
        f('#lock').click
        wait_for_ajax_requests
        #TODO: check the UI to make sure the topics have a locked symbol
        expect(what_to_create.where(:locked => true).count).to eq 5
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
        refresh_and_filter(:string, 'jake', user_name)
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

    describe "shared main page topics specs" do
      let(:url) { "/courses/#{@course.id}/announcements/" }
      let(:what_to_create) { Announcement }

      def add_attachment_and_validate
        filename, fullpath, data = get_file("testfile5.zip")
        f('input[name=attachment]').send_keys(fullpath)
        type_in_tiny('textarea[name=message]', 'file attachement discussion')
        expect_new_page_load { submit_form('.form-actions') }
        wait_for_ajaximations
        expect(f('.zip')).to include_text(filename)
      end

      def edit(title, message)
        replace_content(f('input[name=title]'), title)
        type_in_tiny('textarea[name=message]', message)
        expect_new_page_load { submit_form('.form-actions') }
        expect(f('#discussion_topic .discussion-title').text).to eq title
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
        expect(what_to_create.find_by_title(topic_title).attachment_id).to be_present
      end

      it "should add an attachment to a graded topic" do
        what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => 'graded attachment topic', :user => @user) : announcement_model(:title => 'graded attachment topic', :user => @user)
        if what_to_create == DiscussionTopic
          what_to_create.last.update_attributes(:assignment => @course.assignments.create!(:name => 'graded topic assignment'))
        end
        get url
        expect_new_page_load { f('.discussion-title').click }
        expect_new_page_load { f(".edit-btn").click }

        add_attachment_and_validate
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

        f('.toggleSelected').click
        f('#delete').click
        driver.switch_to.alert.accept
        wait_for_ajaximations
        expect(what_to_create.last.workflow_state).to eq 'deleted'
        expect(f('.discussionTopicIndexList')).to be_nil
      end

      it "should reorder topics" do
        3.times { |i| what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => "new topic #{i}", :user => @user) : announcement_model(:title => "new topic #{i}", :user => @user) }
        get url
        wait_for_ajax_requests

        topics = ff('.discussion-topic')
        driver.action.move_to(topics[0]).perform
        # drag first topic to second place
        # (using topics[2] as target to get the dragging to work)
        driver.action.drag_and_drop(fj('.discussion-drag-handle:visible', topics[0]), topics[2]).perform
        wait_for_ajax_requests
        new_topics = ffj('.discussion-topic') # using ffj to avoid selenium caching
        expect(new_topics[0]).not_to include_text('new topic 0')
      end
    end

    it "should create a delayed announcement" do
      skip("193")
      get course_announcements_path(@course)
      create_announcement_manual('input[type=checkbox][name=delay_posting]')
      f('.ui-datepicker-trigger').click
      datepicker_next
      f('.ui-datepicker-time .ui-datepicker-ok').click
      expect_new_page_load { submit_form('.form-actions') }
      expect(f('.discussion-fyi')).to include_text('This topic will not be visible')
    end

    it "should add and remove an external feed to announcements" do
      get "/courses/#{@course.id}/announcements"
      wait_for_ajaximations

      #add external feed to announcements
      feed_name = 'http://www.google.com'

      f(".add_external_feed_link").click
      wait_for_ajaximations
      expect(f("#external_feed_url")).to be_displayed
      f('#external_feed_url').send_keys(feed_name)

      f('#external_feed_enable_header_match').click
      wait_for_ajaximations
      expect(f('#external_feed_header_match')).to be_displayed
      f('#external_feed_header_match').send_keys('blah')

      expect {
        submit_form(f('#add_external_feed_form'))
        wait_for_ajaximations
      }.to change(ExternalFeed, :count).by(1)

      #delete external feed
      expect(f(".external_feed")).to include_text('feed')
      expect {
        f('.external_feed .close').click
        wait_for_ajax_requests
        expect(element_exists('.external_feed')).to be_falsey
      }.to change(ExternalFeed, :count).by(-1)
    end

    it "should remove delayed_post_at when unchecking delay_posting" do
      topic = announcement_model(:title => @topic_title, :user => @user, :delayed_post_at => 10.days.ago)
      get "/courses/#{@course.id}/announcements/#{topic.id}"
      expect_new_page_load { f(".edit-btn").click }

      f('input[type=checkbox][name="delay_posting"]').click
      expect_new_page_load { f('.form-actions button[type=submit]').click }

      topic.reload
      expect(topic.delayed_post_at).to be_nil
    end

    it "should have a teacher add a new entry to its own announcement" do
      skip "delayed jobs"
      create_announcement
      get [@course, @announcement]

      f('#content .add_entry_link').click
      entry_text = 'new entry text'
      type_in_tiny('textarea[name=message]', entry_text)
      expect_new_page_load { submit_form('.form-actions') }
      expect(f('#entry_list .discussion_entry .content')).to include_text(entry_text)
      f('#left-side .announcements').click
      expect(f('.topic_reply_count').text).to eq '1'
    end

    it "should show announcements to student view student" do
      create_announcement
      enter_student_view
      get "/courses/#{@course.id}/announcements"

      announcement = f('.discussionTopicIndexList .discussion-topic')
      expect(announcement.find_element(:css, '.discussion-summary')).to include_text(@announcement.message)
    end
  end
end
